// lib/screens/exercise_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:habit_tracker_nepali/services/ad_service.dart';
import 'package:habit_tracker_nepali/widgets/ad_banner.dart';

// Models / storage
import '../models/habit.dart';
import '../services/storage_service.dart';

// Notifications
import '../core/reminders/reminder_service.dart';

// In-app video (free resources via YouTube)
import 'package:webview_flutter/webview_flutter.dart';

class ExerciseScreen extends StatefulWidget {
  final Habit habit; // category == HabitCategory.exercise
  const ExerciseScreen({super.key, required this.habit});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with SingleTickerProviderStateMixin {
  final _storage = StorageService();

  // Habit
  late Habit _h;

  // Reminders (staged until Save)
  final List<TimeOfDay> _dailyTimes = [];
  final List<DateTime> _oneOffReminders = [];
  bool _dirtyReminders = false;

  // Session timer
  int _sessionMin = 30;
  int _remainSec = 0;
  bool _running = false;
  Timer? _timer;
  int? _sessionAlarmId;

  // Tabs
  late final TabController _tab;

  // Steps (manual)
  int _lastShownSteps = 0;

  // Schedule editor (decoded from JSON)
  // Map<"Monday", List<{name, bodyPart, level}>>
  Map<String, List<Map<String, String>>> _weekPlan = {};

  // Milestones [{title, notes}]
  List<Map<String, dynamic>> _milestones = [];

  @override
  void initState() {
    super.initState();
    _h = widget.habit;
    _ensureTodayResets();

    // Reminders
    if (_h.reminderTimes.isNotEmpty) {
      _dailyTimes.addAll(_h.reminderTimes.map(Habit.parseHHmm));
    } else {
      _dailyTimes.addAll(const [TimeOfDay(hour: 7, minute: 0)]);
      _dirtyReminders = true;
    }

    // Defaults
    _h.exerciseGoalMin ??= 30;
    _h.exerciseTodayMin ??= 0;
    _h.stepsGoal ??= 6000;
    _h.stepsToday ??= 0;

    // Decode schedule/milestones
    _weekPlan = _decodeSchedule(_h.exerciseScheduleJson);
    if (_weekPlan.isEmpty) _weekPlan = _defaultWeekPlan();
    _milestones = _decodeMilestones(_h.exerciseMilestonesJson);

    _lastShownSteps = _h.stepsToday ?? 0;

    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_sessionAlarmId != null) {
      ReminderService.instance.cancelSessionEnd(_h.id); // left mid-workout
    }
    super.dispose();
  }

  // ---------- Day reset helpers ----------
  void _ensureTodayResets() {
    final today = _ymd(DateTime.now());

    // Steps reset
    if (_h.stepsLastDate != today) {
      _h.stepsLastDate = today;
      _h.stepsToday = 0;
    }

    // Exercise minutes reset (optional daily rollover logic)
    if (_h.exerciseLastDate != today) {
      // New day: reset today's minutes (previously yesterday's total carried over).
      _h.exerciseTodayMin = 0;
      _h.exerciseLastDate = today;
    }
  }

  // ---------- Persistence ----------
  Future<void> _persistHabitOnly() async {
    final all = await _storage.loadHabits();
    final i = all.indexWhere((x) => x.id == _h.id);
    if (i >= 0) {
      all[i] = _h;
    } else {
      all.add(_h);
    }
    await _storage.saveHabits(all);
  }

  // ---------- Reminders ----------
  Future<void> _saveReminders() async {
    _h.reminderTimes = _dailyTimes.map(Habit.fmt).toList();
    // Persist one-time reminders on the habit so they can be cancelled and
    // restored (they used to be fire-and-forget).
    final now = DateTime.now();
    _h.oneTimeReminders = [
      ..._h.oneTimeReminders.where((iso) => DateTime.tryParse(iso)?.isAfter(now) ?? false),
      ..._oneOffReminders.where((dt) => dt.isAfter(now)).map((dt) => dt.toIso8601String()),
    ];
    await _persistHabitOnly();
    await ReminderService.instance.syncHabit(_h);
    _oneOffReminders.clear();

    if (mounted) {
      setState(() => _dirtyReminders = false);
      _snack('Reminders saved.');
    }
  }

  // ---------- Session (start/pause/stop) ----------
  Future<void> _startOrPauseSession() async {
    if (_running) {
      // Pause
      _timer?.cancel();
      await _cancelSessionAlarm();
      setState(() => _running = false);
      return;
    }

    // Start
    _remainSec = _sessionMin * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remainSec = (_remainSec - 1).clamp(0, _sessionMin * 60));
      if (_remainSec <= 0) {
        _finalizeSessionAndNotify();
      }
    });

    final endAt = DateTime.now().add(Duration(seconds: _remainSec));
    _sessionAlarmId = ReminderService.sessionAlarmId(_h.id);
    await ReminderService.instance.scheduleSessionEnd(
      _h.id,
      endAt,
      title: 'Workout done',
      body: 'Nice work! Cool down & hydrate. 💪',
    );

    setState(() => _running = true);
  }

  /// Cancels the end-of-workout alarm (it used to stay armed after Stop and,
  /// via the old scheduler, re-fire daily forever).
  Future<void> _cancelSessionAlarm() async {
    if (_sessionAlarmId == null) return;
    _sessionAlarmId = null;
    await ReminderService.instance.cancelSessionEnd(_h.id);
  }

  Future<void> _stopSession() async {
    _timer?.cancel();
    _timer = null;
    await _cancelSessionAlarm();
    _running = false;
    _remainSec = 0;
    setState(() {});
    _snack('Workout session stopped.');
    await InterstitialHelper().showIfAvailable();

  }

  Future<void> _finalizeSessionAndNotify() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _remainSec = 0;

    // Add minutes to today
    final addMin = (_sessionMin).clamp(0, 720);
    _ensureTodayResets();
    _h.exerciseTodayMin = (_h.exerciseTodayMin ?? 0) + addMin;
    _h.exerciseLastDate = _ymd(DateTime.now());
    await _persistHabitOnly();

    if (!mounted) return;
    setState(() {});
    _snack('Workout session finished (+$addMin min).');
    await _showEndDialog();
  }

  // ---------- Steps ----------
  void _incSteps(int n) async {
    _ensureTodayResets();
    _h.stepsToday = (_h.stepsToday ?? 0) + n;
    await _persistHabitOnly();
    setState(() => _lastShownSteps = _h.stepsToday ?? 0);
  }

  void _resetStepsToday() async {
    _ensureTodayResets();
    _h.stepsToday = 0;
    await _persistHabitOnly();
    setState(() => _lastShownSteps = 0);
  }

  // ---------- Office worker cues (stored only; schedule later if you want) ----------
  Future<void> _setWalkInterval() async {
    final v = await _askInt(context,
        title: 'Walk every (minutes)',
        initial: _h.officeWalkEveryMin ?? 60,
        min: 10,
        max: 240,
        step: 5);
    if (v != null) {
      _h.officeWalkEveryMin = v;
      await _persistHabitOnly();
      _snack('Saved walk interval ($v min).');
      setState(() {});
    }
  }

  Future<void> _setStretchInterval() async {
    final v = await _askInt(context,
        title: 'Stretch every (minutes)',
        initial: _h.officeStretchEveryMin ?? 120,
        min: 10,
        max: 240,
        step: 5);
    if (v != null) {
      _h.officeStretchEveryMin = v;
      await _persistHabitOnly();
      _snack('Saved stretch interval ($v min).');
      setState(() {});
    }
  }

  // ---------- Schedule ----------
  Future<void> _openScheduleEditor(String day) async {
    final before = List<Map<String, String>>.from(_weekPlan[day] ?? []);
    final res = await showModalBottomSheet<List<Map<String, String>>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ScheduleEditorSheet(day: day, initial: before),
    );
    if (res != null) {
      _weekPlan[day] = res;
      _h.exerciseScheduleJson = json.encode(_weekPlan);
      await _persistHabitOnly();
      setState(() {});
    }
  }

  // ---------- Milestones ----------
  Future<void> _addMilestone() async {
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _MilestoneDialog(),
    );
    if (res != null) {
      _milestones.add(res);
      _h.exerciseMilestonesJson = json.encode(_milestones);
      await _persistHabitOnly();
      setState(() {});
    }
  }

  void _removeMilestone(int i) async {
    _milestones.removeAt(i);
    _h.exerciseMilestonesJson = json.encode(_milestones);
    await _persistHabitOnly();
    setState(() {});
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final goalMin = _h.exerciseGoalMin ?? 30;
    final todayMin = _h.exerciseTodayMin ?? 0;
    final progress = (todayMin / (goalMin == 0 ? 1 : goalMin)).clamp(0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Reminders'),
            Tab(text: 'Schedule'),
            Tab(text: 'Library'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add milestone',
            onPressed: _addMilestone,
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: 
      TabBarView(
        controller: _tab,
        children: [
          _buildOverview(progress as double, todayMin, goalMin),
          _buildReminders(),
          _buildSchedule(),
          _buildLibrary(),
        ],
      ),
    );
  }

  // ---- Tab: Overview ----
  Widget _buildOverview(double progress, int todayMin, int goalMin) {
    final stepsGoal = _h.stepsGoal ?? 6000;
    final stepsToday = _h.stepsToday ?? 0;
    final stepPct = (stepsToday / (stepsGoal == 0 ? 1 : stepsGoal)).clamp(0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: AdBanner(placement: 'home_bottom', padding: EdgeInsets.only(bottom: 8)),
            ),
        // Session & goals
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              children: [
                
                Text('Workout Session', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Session length (min)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => setState(() => _sessionMin = (_sessionMin - 5).clamp(5, 180)),
                      icon: const Icon(Icons.remove, size: 26),
                      style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$_sessionMin',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => setState(() => _sessionMin = (_sessionMin + 5).clamp(5, 180)),
                      icon: const Icon(Icons.add, size: 26),
                      style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_running ? _fmtClock(_remainSec) : _fmtClock(_sessionMin * 60),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _BigActionButton(
                      icon: _running ? Icons.pause : Icons.play_arrow,
                      label: _running ? 'Pause' : 'Start',
                      onTap: _startOrPauseSession,
                    ),
                    _BigActionButton(
                      icon: Icons.stop,
                      label: 'Stop',
                      onTap: _running ? _stopSession : null,
                    ),
                  ],
                ),
                const Divider(height: 28),
                Text('Today\'s Minutes', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$todayMin / $goalMin min'),
                    const SizedBox(width: 16),
                    IconButton.filledTonal(
                      tooltip: 'Decrease daily goal',
                      onPressed: () async {
                        _h.exerciseGoalMin = (_h.exerciseGoalMin ?? 30) - 5;
                        if ((_h.exerciseGoalMin ?? 0) < 5) _h.exerciseGoalMin = 5;
                        await _persistHabitOnly();
                        setState(() {});
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Increase daily goal',
                      onPressed: () async {
                        _h.exerciseGoalMin = (_h.exerciseGoalMin ?? 30) + 5;
                        await _persistHabitOnly();
                        setState(() {});
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Steps
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              children: [
                Text('Steps', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: stepPct as double?),
                const SizedBox(height: 6),
                Text('$_lastShownSteps / $stepsGoal'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SmallChipButton(label: '+50', onTap: () => _incSteps(50)),
                    _SmallChipButton(label: '+100', onTap: () => _incSteps(100)),
                    _SmallChipButton(label: '+500', onTap: () => _incSteps(500)),
                    _SmallChipButton(label: 'Reset today', onTap: _resetStepsToday, outline: true),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Office worker helpers
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Office Worker Helpers', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Walk every'),
                        subtitle: Text('${_h.officeWalkEveryMin ?? 60} min'),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _setWalkInterval,
                      icon: const Icon(Icons.directions_walk),
                      label: const Text('Set'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Stretch every'),
                        subtitle: Text('${_h.officeStretchEveryMin ?? 120} min'),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _setStretchInterval,
                      icon: const Icon(Icons.self_improvement),
                      label: const Text('Set'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tip: these intervals are saved in your habit. You can later map them to actual daily times for notifications.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Milestones
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Milestones', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (_milestones.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('No milestones yet. Tap the flag icon to add!'),
                  )
                else
                  ...List.generate(_milestones.length, (i) {
                    final m = _milestones[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.flag),
                        title: Text(m['title']?.toString() ?? 'Goal'),
                        subtitle: Text(m['notes']?.toString() ?? ''),
                        trailing: IconButton(
                          onPressed: () => _removeMilestone(i),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- Tab: Reminders ----
  Widget _buildReminders() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
         Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: AdBanner(placement: 'home_bottom', padding: EdgeInsets.only(bottom: 8)),
            ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exercise Reminders', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Daily times', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                if (_dailyTimes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('No daily times yet.'),
                  ),
                ...List.generate(_dailyTimes.length, (i) {
                  final t = _dailyTimes[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text(Habit.fmt(t)),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            onPressed: () async {
                              final nt = await showTimePicker(
                                  context: context, initialTime: t);
                              if (nt == null) return;
                              setState(() {
                                _dailyTimes[i] = nt;
                                _dirtyReminders = true;
                              });
                            },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _dailyTimes.removeAt(i);
                                _dirtyReminders = true;
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 7, minute: 0));
                      if (t == null) return;
                      setState(() {
                        _dailyTimes.add(t);
                        _dirtyReminders = true;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add daily time'),
                  ),
                ),
                const Divider(height: 28),
                Text('One-time reminders', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                if (_oneOffReminders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('No one-time reminders yet.'),
                  ),
                ..._oneOffReminders.map((dt) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.event_available),
                        title: Text(_prettyDateTime(dt)),
                        subtitle: const Text('Will ring once (on Save).'),
                      ),
                    )),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: now.add(const Duration(days: 1)),
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 7, minute: 0),
                      );
                      if (time == null) return;
                      final dt = DateTime(
                          date.year, date.month, date.day, time.hour, time.minute);
                      setState(() {
                        _oneOffReminders.add(dt);
                        _dirtyReminders = true;
                      });
                    },
                    icon: const Icon(Icons.event),
                    label: const Text('Add one-time reminder'),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () async {
                    _dirtyReminders ? _saveReminders : null;
                    await InterstitialHelper().showIfAvailable();

                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save reminders'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- Tab: Schedule ----
  Widget _buildSchedule() {
    final days = _weekPlan.keys.toList()
      ..sort((a, b) => _weekdayIndex(a).compareTo(_weekdayIndex(b)));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
         Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: AdBanner(placement: 'home_bottom', padding: EdgeInsets.only(bottom: 8)),
            ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly Gym Plan', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('Tap a day to add/edit exercises (body part + level).'),
                const SizedBox(height: 12),
                ...days.map((d) {
                  final list = _weekPlan[d] ?? const [];
                  return Card(
                    child: ListTile(
                      title: Text(d),
                      subtitle: list.isEmpty
                          ? const Text('No exercises yet')
                          : Text(list.map((e) => e['name']).join(', ')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openScheduleEditor(d),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- Tab: Library (free videos) ----
  Widget _buildLibrary() {
    final items = _videoLibraryItems;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final v = items[i];
        if(i==0){
          return Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: AdBanner(placement: 'home_bottom', padding: EdgeInsets.only(bottom: 8)),
            );
        }
        return Card(
          child: ListTile(
            leading: const Icon(Icons.play_circle),
            title: Text(v.title),
            subtitle: Text('${v.bodyPart} • ${v.level}'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _VideoPage(url: v.url, title: v.title),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- utils ----------

  String _fmtClock(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _prettyDateTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hh:$mm';
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _weekdayIndex(String day) {
    const order = [
      'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ];
    final i = order.indexOf(day);
    return i < 0 ? 99 : i;
  }

  Map<String, List<Map<String, String>>> _defaultWeekPlan() => {
        'Monday': [], 'Tuesday': [], 'Wednesday': [],
        'Thursday': [], 'Friday': [], 'Saturday': [], 'Sunday': [],
      };

  Map<String, List<Map<String, String>>> _decodeSchedule(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final d = json.decode(raw);
      if (d is Map<String, dynamic>) {
        return d.map<String, List<Map<String, String>>>((k, v) {
          final list = (v as List)
              .map<Map<String, String>>((e) => Map<String, String>.from(e))
              .toList();
          return MapEntry(k, list);
        });
      }
    } catch (_) {}
    return {};
  }

  List<Map<String, dynamic>> _decodeMilestones(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final d = json.decode(raw);
      if (d is List) {
        return d.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _showEndDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Session complete'),
        content: const Text('Great job finishing your workout!'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
}

// ================== Schedule Editor Sheet ==================
class _ScheduleEditorSheet extends StatefulWidget {
  final String day;
  final List<Map<String, String>> initial;
  const _ScheduleEditorSheet({required this.day, required this.initial});

  @override
  State<_ScheduleEditorSheet> createState() => _ScheduleEditorSheetState();
}

class _ScheduleEditorSheetState extends State<_ScheduleEditorSheet> {
  final List<Map<String, String>> _list = [];
  String _bodyPart = 'Chest';
  String _level = 'Beginner';

  @override
  void initState() {
    super.initState();
    _list.addAll(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog[_bodyPart]![_level]!;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Text('Edit ${widget.day}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Dropdown<String>(
                      label: 'Body Part',
                      value: _bodyPart,
                      items: _catalog.keys.toList(),
                      onChanged: (v) => setState(() => _bodyPart = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Dropdown<String>(
                      label: 'Level',
                      value: _level,
                      items: const ['Beginner', 'Mild', 'Pro'],
                      onChanged: (v) => setState(() => _level = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: catalog.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final ex = catalog[i];
                    final already = _list.any((e) => e['name'] == ex);
                    return ListTile(
                      leading: Icon(already ? Icons.check_circle : Icons.add_circle_outline),
                      title: Text(ex),
                      subtitle: Text('$_bodyPart • $_level'),
                      onTap: () {
                        if (already) {
                          _list.removeWhere((e) => e['name'] == ex);
                        } else {
                          _list.add({'name': ex, 'bodyPart': _bodyPart, 'level': _level});
                        }
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, _list),
                icon: const Icon(Icons.save),
                label: const Text('Save day plan'),
              )
            ],
          ),
        );
      },
    );
  }
}

// ================== Video Library (free YT) ==================
class _VideoItem {
  final String title;
  final String url; // YouTube link
  final String bodyPart;
  final String level;
  const _VideoItem(
      {required this.title, required this.url, required this.bodyPart, required this.level});
}

final List<_VideoItem> _videoLibraryItems = [
  // Chest
  _VideoItem(
    title: 'Beginner Chest Workout (No Equipment)',
    url: 'https://www.youtube.com/watch?v=IODxDxX7oi4',
    bodyPart: 'Chest',
    level: 'Beginner',
  ),
  _VideoItem(
    title: 'Chest Workout at Gym (Intermediate)',
    url: 'https://www.youtube.com/watch?v=rT7DgCr-3pg',
    bodyPart: 'Chest',
    level: 'Mild',
  ),
  // Back
  _VideoItem(
    title: 'Beginner Back Workout',
    url: 'https://www.youtube.com/watch?v=UoC_O3HzsH0',
    bodyPart: 'Back',
    level: 'Beginner',
  ),
  _VideoItem(
    title: 'Complete Back Day (Advanced)',
    url: 'https://www.youtube.com/watch?v=GZbfZ033f74',
    bodyPart: 'Back',
    level: 'Pro',
  ),
  // Legs
  _VideoItem(
    title: '20-Min Leg Workout at Home',
    url: 'https://www.youtube.com/watch?v=2pLT-olgUJs',
    bodyPart: 'Legs',
    level: 'Beginner',
  ),
  _VideoItem(
    title: 'Leg Day at the Gym',
    url: 'https://www.youtube.com/watch?v=2PNqBPi4XRM',
    bodyPart: 'Legs',
    level: 'Mild',
  ),
  // Shoulders
  _VideoItem(
    title: 'Shoulder Workout (Dumbbells)',
    url: 'https://www.youtube.com/watch?v=8d2mF-8Cw2o',
    bodyPart: 'Shoulders',
    level: 'Mild',
  ),
  // Arms
  _VideoItem(
    title: 'Arms & Biceps (No Equipment)',
    url: 'https://www.youtube.com/watch?v=2-MBfn8XjIU',
    bodyPart: 'Arms',
    level: 'Beginner',
  ),
  // Abs
  _VideoItem(
    title: '10-Min Ab Workout',
    url: 'https://www.youtube.com/watch?v=1919eTCoESo',
    bodyPart: 'Abdomen',
    level: 'Beginner',
  ),
];

class _VideoPage extends StatefulWidget {
  final String url;
  final String title;
  const _VideoPage({required this.url, required this.title});

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late final WebViewController _c;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => setState(() => _loading = false)),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis)),
      body: Stack(
        children: [
          WebViewWidget(controller: _c),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

// ================== Small Widgets ==================
class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _BigActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 200, minHeight: 56),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _SmallChipButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outline;
  const _SmallChipButton({required this.label, this.onTap, this.outline = false});

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton(onPressed: onTap, child: Text(label));
    final filled = FilledButton.tonal(onPressed: onTap, child: Text(label));
    return outline ? btn : filled;
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: '', border: OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          onChanged: onChanged,
          items: items
              .map((e) => DropdownMenuItem<T>(value: e, child: Text(e.toString())))
              .toList(),
        ),
      ),
    );
  }
}

// ================== Dialogs ==================
Future<int?> _askInt(
  BuildContext context, {
  required String title,
  required int initial,
  int min = 0,
  int max = 10000,
  int step = 1,
}) async {
  final ctrl = TextEditingController(text: '$initial');
  return showDialog<int>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final v = int.tryParse(ctrl.text.trim());
            if (v == null) return;
            final clamped = v.clamp(min, max);
            Navigator.pop(context, clamped);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class _MilestoneDialog extends StatefulWidget {
  const _MilestoneDialog();

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog> {
  final _title = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New milestone'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes'),
            minLines: 1,
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_title.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'title': _title.text.trim(),
              'notes': _notes.text.trim(),
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// ================== Exercise Catalog ==================
final Map<String, Map<String, List<String>>> _catalog = {
  'Chest': {
    'Beginner': [
      'Push-ups (knee/incline)',
      'Wall push-ups',
      'Decline push-up hold',
    ],
    'Mild': [
      'Bench press (barbell/dumbbell)',
      'Incline dumbbell press',
      'Cable flyes',
    ],
    'Pro': [
      'Weighted dips',
      'Barbell bench heavy sets',
      'Paused bench press',
    ],
  },
  'Back': {
    'Beginner': [
      'Supermans',
      'Bird-dogs',
      'Resistance band rows',
    ],
    'Mild': [
      'Lat pulldown',
      'Seated cable row',
      'Dumbbell rows',
    ],
    'Pro': [
      'Weighted pull-ups',
      'T-bar row',
      'Deadlifts (advanced)',
    ],
  },
  'Legs': {
    'Beginner': [
      'Bodyweight squats',
      'Glute bridges',
      'Lunges (assisted)',
    ],
    'Mild': [
      'Barbell back squat',
      'Leg press',
      'Romanian deadlift',
    ],
    'Pro': [
      'Front squats heavy',
      'Bulgarian split squats',
      'Power cleans (advanced)',
    ],
  },
  'Shoulders': {
    'Beginner': [
      'Arm circles',
      'Wall slides',
      'Band lateral raises',
    ],
    'Mild': [
      'Dumbbell shoulder press',
      'Lateral raises',
      'Face pulls',
    ],
    'Pro': [
      'Barbell overhead press',
      'Arnold press',
      'Snatch press (advanced)',
    ],
  },
  'Arms': {
    'Beginner': [
      'Bicep curls (light)',
      'Bench dips (assisted)',
      'Band triceps extensions',
    ],
    'Mild': [
      'EZ-bar curls',
      'Skull crushers',
      'Cable triceps pressdown',
    ],
    'Pro': [
      'Weighted dips',
      'Heavy preacher curls',
      'Close-grip bench press',
    ],
  },
  'Abdomen': {
    'Beginner': [
      'Crunches',
      'Dead bug',
      'Plank (short holds)',
    ],
    'Mild': [
      'Hanging knee raises',
      'Side plank',
      'Bicycle crunch',
    ],
    'Pro': [
      'Dragon flags (advanced)',
      'Ab wheel rollouts',
      'Long plank holds',
    ],
  },
};

