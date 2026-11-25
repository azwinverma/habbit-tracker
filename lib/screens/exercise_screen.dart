// lib/screens/exercise_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:habit_tracker_nepali/services/ad_service.dart';
import 'package:habit_tracker_nepali/widgets/ad_banner.dart';

// Models / storage
import '../models/habit.dart';
import '../widgets/reminder_schedule_editor.dart';
import '../services/storage_service.dart';

// Notifications
import '../core/reminders/reminder_service.dart';
import '../core/reminders/habit_reminder_planner.dart';
import '../l10n/app_localizations.dart';

// Free exercise library (wger) with demo videos, cached offline
import '../core/db/app_database.dart';
import '../features/content/data/content_repository.dart';
import '../features/content/data/content_sync_service.dart';
import '../features/content/domain/content_item.dart';
import '../features/content/presentation/exercise_detail_screen.dart';
import '../features/content/data/youtube_workouts.dart';
import '../features/content/presentation/youtube_workout_screen.dart';
import '../features/content/presentation/home_workouts_screen.dart';
import '../features/steps/step_service.dart';
import '../design/backdrop.dart';
import '../app/theme.dart';

class ExerciseScreen extends StatefulWidget {
  final Habit habit; // category == HabitCategory.exercise
  const ExerciseScreen({super.key, required this.habit});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> with SingleTickerProviderStateMixin {
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

  // Steps (phone sensor when enabled, plus manual additions)
  int _lastShownSteps = 0;
  bool _autoSteps = false;
  final _steps = StepService.instance;

  // Schedule editor (decoded from JSON)
  // Map<"Monday", List<{name, bodyPart, level}>>
  Map<String, List<Map<String, String>>> _weekPlan = {};

  // Milestones [{title, notes}]
  List<Map<String, dynamic>> _milestones = [];

  // Free exercise catalogue (for "watch how" on planned exercises)
  List<ContentItemRow> _exercises = const [];

  @override
  void initState() {
    super.initState();
    _h = widget.habit;

    // Show saved (future) one-time reminders so they can be reviewed/removed.
    final nowInit = DateTime.now();
    _oneOffReminders.addAll(
      _h.oneTimeReminders.map(DateTime.tryParse).whereType<DateTime>().where((d) => d.isAfter(nowInit)),
    );
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
    _loadExercises();
    _initSteps();
  }

  Future<void> _initSteps() async {
    _steps.today.addListener(_onSteps);
    final on = await _steps.isEnabled();
    if (!on) {
      // Keep steps typed in before this update.
      final today = _ymd(DateTime.now());
      if (_h.stepsLastDate == today && (_h.stepsToday ?? 0) > 0) {
        final st = await _steps.loadState();
        if ((st.manual[today] ?? 0) == 0 && (st.days[today] ?? 0) == 0) await _steps.addManual(_h.stepsToday!);
      }
    }
    if (!mounted) return;
    setState(() => _autoSteps = on);
    if (on) {
      await _steps.sync();
      await _steps.startLive();
    }
  }

  void _onSteps() {
    final v = _steps.today.value;
    if (v == null || !mounted) return;
    // Keep the in-memory habit in step, so saving the screen never writes
    // an old count back.
    _h.stepsToday = v;
    _h.stepsLastDate = _ymd(DateTime.now());
    setState(() => _lastShownSteps = v);
  }

  Future<void> _enableAutoSteps() async {
    final l = AppLocalizations.of(context);
    await _persistHabitOnly(); // counting is shown on this (now saved) habit
    final r = await _steps.enable();
    if (!mounted) return;
    switch (r) {
      case StepEnableResult.enabled:
        setState(() => _autoSteps = true);
        await _steps.startLive();
        _snack(l.stepsEnabled);
      case StepEnableResult.denied:
        _snack(l.stepsDenied);
      case StepEnableResult.permanentlyDenied:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.stepsDenied),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: l.stepsOpenSettings, onPressed: StepService.openSettings),
        ));
      case StepEnableResult.noSensor:
        _snack(l.stepsNoSensor);
    }
  }

  Future<void> _disableAutoSteps() async {
    await _steps.disable();
    if (mounted) setState(() => _autoSteps = false);
  }

  Future<void> _loadExercises() async {
    final rows = await ContentRepository(AppDatabase.instance).list(ContentKind.exercise);
    if (mounted) setState(() => _exercises = rows);
  }

  /// Opens the demo (video when available) for a planned exercise name.
  void _watch(Map<String, String> e) {
    final match = ExerciseText.bestMatch(e['name'] ?? '', _exercises);
    if (match != null) {
      ExerciseDetailScreen.open(context, match);
      return;
    }
    // No catalogue match: the coach's exercise guide, else a free YouTube
    // workout for that body part/level.
    final guide = ExerciseText.howToFor(e['name'] ?? '');
    if (guide != null) {
      YoutubeWorkoutScreen.open(context, guide);
      return;
    }
    final group = youtubeWorkouts.where((v) => v.group == e['bodyPart']);
    final yt = group.where((v) => v.level == e['level']).firstOrNull ?? group.firstOrNull;
    if (yt != null) {
      YoutubeWorkoutScreen.open(context, yt);
    } else {
      _tab.animateTo(3); // show the library to browse
    }
  }

  @override
  void dispose() {
    _steps.today.removeListener(_onSteps);
    _steps.stopLive();
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
    _h.oneTimeReminders = _oneOffReminders.where((dt) => dt.isAfter(now)).map((dt) => dt.toIso8601String()).toList();
    await _persistHabitOnly();
    await ReminderService.instance.syncHabit(_h);

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
  // Manual steps go through StepService (kept apart from sensor counts).
  // Saving first matters for a quick-added habit: like any other change on
  // this screen, using the step buttons creates the habit.
  Future<void> _incSteps(int n) async {
    await _persistHabitOnly();
    await _steps.addManual(n);
  }

  Future<void> _resetStepsToday() async {
    await _persistHabitOnly();
    await _steps.resetManual();
  }

  // ---------- Office move breaks (D18: now actually scheduled) ----------
  Future<void> _setOfficeInterval({required bool walk}) async {
    final l = AppLocalizations.of(context);
    final v = await _askInt(
      context,
      title: walk ? l.exWalkEvery : l.exStretchEvery,
      initial: (walk ? _h.officeWalkEveryMin : _h.officeStretchEveryMin) ?? (walk ? 60 : 120),
      min: HabitReminderPlanner.minOfficeInterval,
      max: 240,
      step: 15,
    );
    if (v == null) return;
    await _applyOffice(walk: walk, minutes: v);
  }

  Future<void> _applyOffice({required bool walk, required int? minutes}) async {
    setState(() {
      if (walk) {
        _h.officeWalkEveryMin = minutes;
      } else {
        _h.officeStretchEveryMin = minutes;
      }
    });
    await _persistHabitOnly();
    await ReminderService.instance.syncHabit(_h);
  }

  Widget _officeRow(AppLocalizations l, {required bool walk}) {
    final every = walk ? _h.officeWalkEveryMin : _h.officeStretchEveryMin;
    final on = every != null && every > 0;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(walk ? Icons.directions_walk : Icons.self_improvement),
      title: Text(walk ? l.exWalk : l.exStretch),
      subtitle: InkWell(
        onTap: on ? () => _setOfficeInterval(walk: walk) : null,
        child: Text(on ? '${l.exEvery(every)}  ✎' : l.exOff),
      ),
      value: on,
      onChanged: (v) => v ? _setOfficeInterval(walk: walk) : _applyOffice(walk: walk, minutes: null),
    );
  }

  // ---------- Schedule ----------
  Future<void> _openScheduleEditor(String day) async {
    final before = List<Map<String, String>>.from(_weekPlan[day] ?? []);
    final res = await showModalBottomSheet<List<Map<String, String>>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ScheduleEditorSheet(day: day, initial: before, exercises: _exercises),
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
    final res = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => const _MilestoneDialog());
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

    return BrandBackdrop(
      tint: context.dm.movement.container,
      glow: context.dm.movement.accent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Exercise'),
          bottom: TabBar(
            controller: _tab,
            isScrollable: true,
            tabs: [
              const Tab(text: 'Overview'),
              const Tab(text: 'Reminders'),
              const Tab(text: 'Schedule'),
              Tab(text: AppLocalizations.of(context).exLibraryTitle),
            ],
          ),
          actions: [
            IconButton(tooltip: 'Add milestone', onPressed: _addMilestone, icon: const Icon(Icons.flag_outlined)),
          ],
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _buildOverview(progress as double, todayMin, goalMin),
            _buildReminders(),
            _buildSchedule(),
            _buildLibrary(),
          ],
        ),
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
        const HomeWorkoutsCard(margin: EdgeInsets.only(bottom: 14)),
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
                      child: Text('Session length (min)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => setState(() => _sessionMin = (_sessionMin - 5).clamp(5, 180)),
                      icon: const Icon(Icons.remove, size: 26),
                      style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$_sessionMin', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => setState(() => _sessionMin = (_sessionMin + 5).clamp(5, 180)),
                      icon: const Icon(Icons.add, size: 26),
                      style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _running ? _fmtClock(_remainSec) : _fmtClock(_sessionMin * 60),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
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
                    _BigActionButton(icon: Icons.stop, label: 'Stop', onTap: _running ? _stopSession : null),
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
            child: Builder(builder: (context) {
              final l = AppLocalizations.of(context);
              final theme = Theme.of(context);
              return Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(l.stepsTitle, style: theme.textTheme.titleLarge),
                    if (_autoSteps) ...[
                      const SizedBox(width: 8),
                      Chip(
                        avatar: const Icon(Icons.directions_walk_rounded, size: 16),
                        label: Text(l.stepsAutoChip),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: stepPct as double?),
                  const SizedBox(height: 6),
                  Text('${_fmtInt(_lastShownSteps)} / ${_fmtInt(stepsGoal)}',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  if (!_autoSteps) ...[
                    FilledButton.tonalIcon(
                      onPressed: _enableAutoSteps,
                      icon: const Icon(Icons.directions_walk_rounded),
                      label: Text(l.stepsEnable),
                    ),
                    const SizedBox(height: 6),
                    Text(l.stepsEnableHint, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 12),
                  ] else ...[
                    Text(l.stepsCountingNote, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 10),
                    Text(l.stepsAddWithoutPhone, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _SmallChipButton(label: '+50', onTap: () => _incSteps(50)),
                      _SmallChipButton(label: '+100', onTap: () => _incSteps(100)),
                      _SmallChipButton(label: '+500', onTap: () => _incSteps(500)),
                      _SmallChipButton(
                          label: _autoSteps ? l.stepsResetAdded : l.stepsResetToday,
                          onTap: _resetStepsToday,
                          outline: true),
                    ],
                  ),
                  if (_autoSteps)
                    TextButton(onPressed: _disableAutoSteps, child: Text(l.stepsTurnOff)),
                ],
              );
            }),
          ),
        ),

        const SizedBox(height: 14),

        // Office move breaks
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Builder(
              builder: (context) {
                final l = AppLocalizations.of(context);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.exOfficeTitle, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    _officeRow(l, walk: true),
                    _officeRow(l, walk: false),
                    const SizedBox(height: 6),
                    Text(
                      l.exOfficeHint(
                        Habit.fmt(HabitReminderPlanner.officeStart),
                        Habit.fmt(HabitReminderPlanner.officeEnd),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
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
                ReminderScheduleEditor(
                  dailyTimes: _dailyTimes,
                  onDailyTimesChanged:
                      (l) => setState(() {
                        _dailyTimes
                          ..clear()
                          ..addAll(l);
                        _dirtyReminders = true;
                      }),
                  oneTimeReminders: _oneOffReminders,
                  onOneTimeRemindersChanged:
                      (l) => setState(() {
                        _oneOffReminders
                          ..clear()
                          ..addAll(l);
                        _dirtyReminders = true;
                      }),
                  dailyTitle: 'Daily times',
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  // Bug fix: this used to evaluate `_saveReminders` without
                  // calling it, so exercise reminders were never saved.
                  onPressed:
                      _dirtyReminders
                          ? () async {
                            await _saveReminders();
                            await InterstitialHelper().showIfAvailable();
                          }
                          : null,
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
    final days = _weekPlan.keys.toList()..sort((a, b) => _weekdayIndex(a).compareTo(_weekdayIndex(b)));
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
                      subtitle:
                          list.isEmpty
                              ? const Text('No exercises yet')
                              : Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final e in list)
                                      ActionChip(
                                        avatar: const Icon(Icons.play_circle_outline_rounded, size: 18),
                                        label: Text(e['name'] ?? ''),
                                        tooltip: AppLocalizations.of(context).exWatchHow,
                                        onPressed: () => _watch(e),
                                      ),
                                  ],
                                ),
                              ),
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

  // ---- Tab: Library (free exercises with demo videos) ----
  Widget _buildLibrary() => _ExerciseLibrary(onChanged: _loadExercises);

  // ---------- utils ----------

  String _fmtClock(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String _fmtInt(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _weekdayIndex(String day) {
    const order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final i = order.indexOf(day);
    return i < 0 ? 99 : i;
  }

  Map<String, List<Map<String, String>>> _defaultWeekPlan() => {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };

  Map<String, List<Map<String, String>>> _decodeSchedule(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final d = json.decode(raw);
      if (d is Map<String, dynamic>) {
        return d.map<String, List<Map<String, String>>>((k, v) {
          final list = (v as List).map<Map<String, String>>((e) => Map<String, String>.from(e)).toList();
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _showEndDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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
  final List<ContentItemRow> exercises;
  const _ScheduleEditorSheet({required this.day, required this.initial, this.exercises = const []});

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
              Text('Edit ${widget.day}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    final demo = ExerciseText.bestMatch(ex, widget.exercises);
                    return ListTile(
                      leading: Icon(already ? Icons.check_circle : Icons.add_circle_outline),
                      title: Text(ex),
                      subtitle: Text('$_bodyPart • $_level'),
                      trailing:
                          demo == null
                              ? null
                              : IconButton(
                                tooltip: AppLocalizations.of(context).exWatchHow,
                                icon: Icon(
                                  demo.mediaFormat == 'video' ? Icons.play_circle_fill_rounded : Icons.image_outlined,
                                ),
                                onPressed: () => ExerciseDetailScreen.open(context, demo),
                              ),
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
              ),
            ],
          ),
        );
      },
    );
  }
}

// ================== Exercise library (wger) ==================
/// Searchable exercise catalogue; "With video" (on by default) shows the
/// exercises that have a demo video. Tapping opens the exercise page with
/// the video on top.
class _ExerciseLibrary extends StatefulWidget {
  const _ExerciseLibrary({required this.onChanged});
  final VoidCallback onChanged;

  @override
  State<_ExerciseLibrary> createState() => _ExerciseLibraryState();
}

class _ExerciseLibraryState extends State<_ExerciseLibrary> with AutomaticKeepAliveClientMixin {
  final _repo = ContentRepository(AppDatabase.instance);
  String _query = '';
  bool _videoOnly = true;
  String? _group;
  bool _youtube = false; // Exercises | YouTube workouts
  String? _ytGroup;
  Timer? _debounce;
  late Stream<List<ContentItemRow>> _stream = _repo.watch(ContentKind.exercise);

  @override
  bool get wantKeepAlive => true;

  List<YoutubeWorkout> get _ytList =>
      _ytGroup == null ? youtubeWorkouts : youtubeWorkouts.where((v) => v.group == _ytGroup).toList();

  void _setQuery(String q) {
    setState(() {
      _query = q;
      _stream = _repo.watch(ContentKind.exercise, search: q.isEmpty ? null : q);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ContentSyncService.instance.syncIfStale(force: true);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    return StreamBuilder<List<ContentItemRow>>(
      stream: _stream,
      builder: (context, snap) {
        final all = snap.data ?? const <ContentItemRow>[];
        final groups =
            {
                for (final e in all)
                  if (e.tags.isNotEmpty) e.tags.first,
              }.toList()
              ..sort();
        final list =
            all
                .where((e) => !_videoOnly || e.mediaFormat == 'video')
                .where((e) => _group == null || e.tags.firstOrNull == _group)
                .toList()
              // Videos first, then by name.
              ..sort((a, b) {
                final v = (b.mediaFormat == 'video' ? 1 : 0) - (a.mediaFormat == 'video' ? 1 : 0);
                return v != 0 ? v : a.title.compareTo(b.title);
              });
        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: false,
                              icon: const Icon(Icons.fitness_center_rounded),
                              label: Text(l.exExercises),
                            ),
                            ButtonSegment(
                              value: true,
                              icon: const Icon(Icons.smart_display_rounded),
                              label: Text(l.ytWorkouts),
                            ),
                          ],
                          selected: {_youtube},
                          onSelectionChanged: (v) => setState(() => _youtube = v.first),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_youtube) ...[
                        Text(l.ytWorkoutsHint, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final g in youtubeWorkoutGroups) ...[
                                ChoiceChip(
                                  label: Text(g),
                                  selected: _ytGroup == g,
                                  onSelected: (v) => setState(() => _ytGroup = v ? g : null),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ],
                          ),
                        ),
                      ] else ...[
                        TextField(
                          decoration: InputDecoration(
                            hintText: l.exSearchHint,
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            _debounce?.cancel();
                            _debounce = Timer(const Duration(milliseconds: 250), () => _setQuery(v.trim()));
                          },
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                avatar: const Icon(Icons.play_circle_outline_rounded, size: 18),
                                label: Text(l.exWithVideo),
                                selected: _videoOnly,
                                showCheckmark: false,
                                onSelected: (v) => setState(() => _videoOnly = v),
                              ),
                              for (final g in groups) ...[
                                const SizedBox(width: 6),
                                ChoiceChip(
                                  label: Text(g),
                                  selected: _group == g,
                                  onSelected: (v) => setState(() => _group = v ? g : null),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_youtube)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 200,
                    ),
                    itemCount: _ytList.length,
                    itemBuilder: (_, i) => YoutubeWorkoutCard(video: _ytList[i]),
                  ),
                )
              else if (snap.hasData && list.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      all.isEmpty && _query.isEmpty ? l.exLibraryEmpty : l.nothingMatches(_query),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: list.length,
                    itemBuilder:
                        (_, i) => ExerciseCard(item: list[i], onTap: () => ExerciseDetailScreen.open(context, list[i])),
                  ),
                ),
            ],
          ),
        );
      },
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
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: '', border: OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text(e.toString()))).toList(),
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
    builder:
        (_) => AlertDialog(
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
            Navigator.pop(context, {'title': _title.text.trim(), 'notes': _notes.text.trim()});
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
    'Beginner': ['Push-ups (knee/incline)', 'Wall push-ups', 'Decline push-up hold'],
    'Mild': ['Bench press (barbell/dumbbell)', 'Incline dumbbell press', 'Cable flyes'],
    'Pro': ['Weighted dips', 'Barbell bench heavy sets', 'Paused bench press'],
  },
  'Back': {
    'Beginner': ['Supermans', 'Bird-dogs', 'Resistance band rows'],
    'Mild': ['Lat pulldown', 'Seated cable row', 'Dumbbell rows'],
    'Pro': ['Weighted pull-ups', 'T-bar row', 'Deadlifts (advanced)'],
  },
  'Legs': {
    'Beginner': ['Bodyweight squats', 'Glute bridges', 'Lunges (assisted)'],
    'Mild': ['Barbell back squat', 'Leg press', 'Romanian deadlift'],
    'Pro': ['Front squats heavy', 'Bulgarian split squats', 'Power cleans (advanced)'],
  },
  'Shoulders': {
    'Beginner': ['Arm circles', 'Wall slides', 'Band lateral raises'],
    'Mild': ['Dumbbell shoulder press', 'Lateral raises', 'Face pulls'],
    'Pro': ['Barbell overhead press', 'Arnold press', 'Snatch press (advanced)'],
  },
  'Arms': {
    'Beginner': ['Bicep curls (light)', 'Bench dips (assisted)', 'Band triceps extensions'],
    'Mild': ['EZ-bar curls', 'Skull crushers', 'Cable triceps pressdown'],
    'Pro': ['Weighted dips', 'Heavy preacher curls', 'Close-grip bench press'],
  },
  'Abdomen': {
    'Beginner': ['Crunches', 'Dead bug', 'Plank (short holds)'],
    'Mild': ['Hanging knee raises', 'Side plank', 'Bicycle crunch'],
    'Pro': ['Dragon flags (advanced)', 'Ab wheel rollouts', 'Long plank holds'],
  },
};
