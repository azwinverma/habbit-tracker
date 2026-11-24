// lib/screens/meditation_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:habit_tracker_nepali/services/ad_service.dart';
import 'package:habit_tracker_nepali/widgets/ad_banner.dart';

// Models / storage
import '../models/habit.dart';
import '../services/storage_service.dart';

// Audio
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

// Free sounds catalogue (Wikimedia Commons), cached offline
import '../core/db/app_database.dart';
import '../features/content/data/content_repository.dart';
import '../features/content/data/content_sync_service.dart';
import '../features/content/domain/content_item.dart';

// Reminders
import '../core/reminders/reminder_service.dart';

class MeditationScreen extends StatefulWidget {
  final Habit habit; // category == HabitCategory.meditation
  const MeditationScreen({super.key, required this.habit});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  final _storage = StorageService();

  // Habit
  late Habit _h;

  // Reminders (staged; only scheduled after Save)
  final List<TimeOfDay> _dailyTimes = [];
  final List<DateTime> _oneOffReminders = [];
  bool _dirtyReminders = false;

  // Audio catalog
  late final AudioPlayer _player;
  List<_MedApiTrack> _tracks = [];
  bool _loadingTracks = true;
  int? _currentIndex; // selected MP3 (no autoplay on select)

  // Session controls
  int _sessionMin = 15; // default meditation length
  Timer? _sessionTimer;
  int _remainSec = 0;
  bool _running = false;
  int? _sessionAlarmId; // end-of-session alarm id (NativeAlarm)

  @override
  void initState() {
    super.initState();
    _h = widget.habit;
    _ensureToday();

    // staged daily times (require Save to apply)
    if (_h.reminderTimes.isNotEmpty) {
      _dailyTimes.addAll(_h.reminderTimes.map(Habit.parseHHmm));
    } else {
      _dailyTimes.addAll(const [
        TimeOfDay(hour: 6, minute: 30),
        TimeOfDay(hour: 20, minute: 0),
      ]);
      _dirtyReminders = true;
    }

    _setupAudio().then((_) => _loadTracks());
  }

  @override
  void dispose() {
    _cancelSessionTimer(andNotification: true);
    _player.dispose();
    super.dispose();
  }

  // ---------- habit & persistence ----------
  void _ensureToday() {
    final now = DateTime.now();
    final ymd =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_h.meditationLastDate != ymd) {
      _h.meditationLastDate = ymd;
      _h.meditationTodayMin = 0;
    }
  }

  Future<void> _persistHabitOnly() async {
    final all = await _storage.loadHabits();
    final i = all.indexWhere((x) => x.id == _h.id);
    if (i >= 0) {
      all[i] = _h;
    } else {
      all.add(_h); // insert if not present yet
    }
    await _storage.saveHabits(all);
  }

  // ---------- Reminder scheduling ----------
  Future<void> _saveReminders() async {
    // Persist the staged daily times into the habit so Home shows them correctly
    _h.reminderTimes = _dailyTimes.map(Habit.fmt).toList();
    // One-time reminders are now stored on the habit (previously they were
    // fire-and-forget, so they could never be cancelled or restored).
    final now = DateTime.now();
    _h.oneTimeReminders = [
      ..._h.oneTimeReminders.where((iso) => DateTime.tryParse(iso)?.isAfter(now) ?? false),
      ..._oneOffReminders.where((dt) => dt.isAfter(now)).map((dt) => dt.toIso8601String()),
    ];
    await _persistHabitOnly();
    await ReminderService.instance.syncHabit(_h);
    _oneOffReminders.clear();

    if (!mounted) return;
    setState(() => _dirtyReminders = false);
    _snack('Reminders saved.');
      await InterstitialHelper().showIfAvailable();

  }

  // ---------- audio ----------
  Future<void> _setupAudio() async {
    _player = AudioPlayer();
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  /// Sounds come from the offline catalogue (freely licensed recordings from
  /// Wikimedia Commons). It refreshes automatically when the app opens; here
  /// we only fetch if it is still empty, or when the user taps refresh.
  Future<void> _loadTracks({bool forceSync = false}) async {
    setState(() => _loadingTracks = true);
    final repo = ContentRepository(AppDatabase.instance);
    try {
      var rows = await repo.list(ContentKind.audio);
      if (rows.isEmpty || forceSync) {
        await ContentSyncService.instance.syncIfStale(force: true);
        rows = await repo.list(ContentKind.audio);
      }
      if (!mounted) return;
      setState(() {
        _tracks = rows.where((r) => r.mediaUrl != null).map(_MedApiTrack.fromContent).toList();
        _loadingTracks = false;
        if (_tracks.isNotEmpty && (_currentIndex == null || _currentIndex! >= _tracks.length)) {
          _currentIndex = 0; // preselect first (no autoplay)
        }
      });
      if (_tracks.isEmpty) _snack('Could not load sounds. Check your connection and tap refresh.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingTracks = false);
      _snack('Could not load sounds: $e');
    }
  }


  Future<void> _prepareSelectedSource() async {
    if (_currentIndex == null || _currentIndex! >= _tracks.length) return;
    final t = _tracks[_currentIndex!];
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(t.url),
        tag: MediaItem(id: 'med-${t.id}', title: t.name),
      ),
      preload: true,
    );
    // Catalogue sounds are short ambient clips: loop them for the session.
    await _player.setLoopMode(LoopMode.one);
  }

  Future<void> _selectTrack(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    setState(() => _currentIndex = index);
    // no autoplay here
  }

  // ---------- session controls ----------
  void _startOrPauseSession() async {
    if (_currentIndex == null || _currentIndex! >= _tracks.length) {
      _snack('Choose a sound first.');
      return;
    }

    if (_running) {
      // Pause
      _sessionTimer?.cancel();
      await _player.pause();
      setState(() => _running = false);
      return;
    }

    // Start / Resume
    if (_player.audioSource == null) {
      await _prepareSelectedSource();
    }

    if (_remainSec <= 0) {
      _remainSec = _sessionMin * 60;
    }

    // schedule end alarm with NativeAlarm so it fires even in background
    final endAt = DateTime.now().add(Duration(seconds: _remainSec));
    _sessionAlarmId = ReminderService.sessionAlarmId(_h.id);
    await ReminderService.instance.scheduleSessionEnd(
      _h.id,
      endAt,
      title: 'Meditation finished',
      body: 'Gently open your eyes 🧘',
    );

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      setState(() {
        _remainSec = (_remainSec - 1).clamp(0, _sessionMin * 60);
      });
      if (_remainSec <= 0) {
        _finishSessionAuto();
      }
    });

    if (!_player.playing) {
      await _player.play();
    }
    setState(() => _running = true);
  }

  Future<void> _finishSessionAuto() async {
    _sessionTimer?.cancel();
    _running = false;
    await _player.stop();

    // credit full session minutes
    final addMin = (_sessionMin).clamp(1, 600);
    _ensureToday();
    _h.meditationTodayMin = (_h.meditationTodayMin ?? 0) + addMin;
    await _persistHabitOnly();

    if (!mounted) return;
    setState(() => _remainSec = 0);
    _snack('Session complete: +$addMin min');
    _showEndDialog();

    // If you add a cancel API in NativeAlarm, you can cancel _sessionAlarmId here.
    _sessionAlarmId = null;
  }

  Future<void> _stopSession() async {
    _sessionTimer?.cancel();
    _running = false;
    await _player.stop();
    setState(() => _remainSec = 0);
    _snack('Session stopped.');
    // Stopped early: the "finished" alarm must not fire later.
    await ReminderService.instance.cancelSessionEnd(_h.id);
    _sessionAlarmId = null;
  }

  Future<void> _cancelSessionTimer({required bool andNotification}) async {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    if (andNotification && _sessionAlarmId != null) {
      await ReminderService.instance.cancelSessionEnd(_h.id);
      _sessionAlarmId = null;
    }
    // No interstitial here: this runs when a meditation session is
    // stopped/left (and from dispose) — ads must not interrupt meditation.

  }

  // ---------- reminder UI actions ----------
  Future<void> _addDailyTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
    );
    if (t == null) return;
    setState(() {
      _dailyTimes.add(t);
      _dirtyReminders = true;
    });
  }

  Future<void> _editDailyTime(int i) async {
    final t = await showTimePicker(
      context: context,
      initialTime: _dailyTimes[i],
    );
    if (t == null) return;
    setState(() {
      _dailyTimes[i] = t;
      _dirtyReminders = true;
    });
  }

  Future<void> _removeDailyTime(int i) async {
    setState(() {
      _dailyTimes.removeAt(i);
      _dirtyReminders = true;
    });
  }

  Future<void> _addOneOffReminder() async {
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

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _oneOffReminders.add(dt);
      _dirtyReminders = true;
    });
  }

  // ---------- track picker (no autoplay) ----------
  Future<void> _openTrackPicker() async {
    if (_loadingTracks) return;
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text(
                  'Choose Meditation Sound',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  iconSize: 28,
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _loadTracks(forceSync: true);
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: _tracks.isEmpty
                    ? const Center(
                        child: Text(
                          'No sounds yet.\nConnect to the internet and tap refresh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _tracks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final t = _tracks[i];
                          final selected = _currentIndex == i;
                          return InkWell(
                            onTap: () {
                              _selectTrack(i); // selection only
                              Navigator.pop(ctx); // close the sheet
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: selected
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                                    : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.name,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (t.credit.isNotEmpty)
                                          Text(
                                            t.credit,
                                            style: Theme.of(context).textTheme.bodySmall,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- helpers ----------
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _showEndDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Session complete'),
        content: const Text('Hope you feel relaxed. 🙏'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final nowPlaying = (_currentIndex != null && _currentIndex! < _tracks.length)
        ? _tracks[_currentIndex!].name
        : 'No sound selected';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _dirtyReminders ? _saveReminders : null,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // NOW PLAYING + SESSION CONTROLS
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: AdBanner(placement: 'home_bottom', padding: EdgeInsets.only(bottom: 8)),
            ),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Column(
                  children: [
                    Text('Now Playing', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      nowPlaying,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    // Session length stepper
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Session length (min)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
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
                    const SizedBox(height: 12),

                    // Big timer
                    Text(
                      _running ? _fmtClock(_remainSec) : _fmtClock(_sessionMin * 60),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Controls (Wrap avoids overflow)
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _BigActionButton(
                          icon: Icons.library_music,
                          label: 'Choose Sound',
                          onTap: _openTrackPicker,
                        ),
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // REMINDERS (Daily + One-off) — staged until Save
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reminders', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Daily times (repeat every day)', style: Theme.of(context).textTheme.titleMedium),
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
                              IconButton(onPressed: () => _editDailyTime(i), icon: const Icon(Icons.edit_outlined)),
                              IconButton(onPressed: () => _removeDailyTime(i), icon: const Icon(Icons.delete_outline)),
                            ],
                          ),
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _addDailyTime,
                        icon: const Icon(Icons.add),
                        label: const Text('Add daily time'),
                      ),
                    ),
                    const Divider(height: 28),

                    Text('One-time reminders (specific date & time)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    if (_oneOffReminders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('No one-time reminders yet.'),
                      ),
                    ..._oneOffReminders.map(
                      (dt) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_available),
                          title: Text(_prettyDateTime(dt)),
                          subtitle: const Text('This will ring once (on Save).'),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _addOneOffReminder,
                        icon: const Icon(Icons.event),
                        label: const Text('Add one-time reminder'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_loadingTracks)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      // Bottom-wide Save (reminders)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton.icon(
            onPressed: _dirtyReminders ? _saveReminders : null,
            icon: const Icon(Icons.save),
            label: const Text('Save reminders'),
          ),
        ),
      ),
    );
  }
}

// ======== Big action button (responsive) ========
class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BigActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

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
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// ======== Track model (from the content catalogue) ========
class _MedApiTrack {
  final String id;
  final String name;
  final String url; // direct MP3 link
  final String credit; // collection · author · licence (attribution)

  _MedApiTrack({required this.id, required this.name, required this.url, this.credit = ''});

  factory _MedApiTrack.fromContent(ContentItemRow r) => _MedApiTrack(
        id: r.id,
        name: r.title,
        url: r.mediaUrl!,
        credit: [
          if (r.subtitle != null) r.subtitle!,
          if (r.attribution != null) r.attribution!,
          r.license,
        ].join(' · '),
      );
}
