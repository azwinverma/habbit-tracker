// lib/screens/meditation_screen.dart
import 'dart:async';
import 'dart:convert';
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

// Network
import 'package:http/http.dart' as http;

// Alarms (use NativeAlarm as requested)
import '../core/reminders/reminder_service.dart';

class MeditationScreen extends StatefulWidget {
  final Habit habit; // category == HabitCategory.meditation
  const MeditationScreen({super.key, required this.habit});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  // ======== API CONFIG ========
  static const String _apiBase = 'https://aswiniverma.pythonanywhere.com';
  static const String _audioListPath = '/api/list/audio';

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

    _setupAudio().then((_) => _loadTracksFromApi());
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

  Future<void> _loadTracksFromApi() async {
    setState(() => _loadingTracks = true);
    try {
      final uri = Uri.parse('$_apiBase$_audioListPath');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final list = (json.decode(resp.body) as List)
            .map((e) => _MedApiTrack.fromJson(e as Map<String, dynamic>, _apiBase))
            .toList();
        setState(() {
          _tracks = list;
          _loadingTracks = false;
          if (_tracks.isNotEmpty && _currentIndex == null) {
            _currentIndex = 0; // preselect first (no autoplay)
          }
        });
      } else {
        setState(() => _loadingTracks = false);
        _snack('Could not load audio (${resp.statusCode}).');
      }
    } catch (e) {
      setState(() => _loadingTracks = false);
      _snack('Network error: $e');
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
                    await _loadTracksFromApi();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: _tracks.isEmpty
                    ? const Center(
                        child: Text(
                          'No audio found.\nUpload from backend.',
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
                                    child: Text(
                                      t.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
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

// ======== API track model ========
class _MedApiTrack {
  final int id;
  final String type; // "audio"
  final String name;
  final String url; // absolute url
  final int? sizeBytes;
  final DateTime? created;

  _MedApiTrack({
    required this.id,
    required this.type,
    required this.name,
    required this.url,
    this.sizeBytes,
    this.created,
  });

  factory _MedApiTrack.fromJson(Map<String, dynamic> j, String base) {
    String u = (j['url'] ?? '').toString();
    if (u.startsWith('/')) u = '$base$u'; // prefix host for "/media/..."
    DateTime? c;
    try {
      c = j['created'] != null ? DateTime.parse(j['created']) : null;
    } catch (_) {}
    return _MedApiTrack(
      id: (j['id'] ?? 0) is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
      type: (j['type'] ?? '').toString(),
      name: (j['name'] ?? 'Meditation Audio').toString(),
      url: u,
      sizeBytes: j['size_bytes'] is int ? j['size_bytes'] as int : int.tryParse('${j['size_bytes']}'),
      created: c,
    );
  }
}







// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';

// // Models / storage
// import '../models/habit.dart';
// import '../services/storage_service.dart';

// // Audio
// import 'package:audio_session/audio_session.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:just_audio_background/just_audio_background.dart';

// // Network
// import 'package:http/http.dart' as http;

// // Notifications
// import '../services/notification_service.dart';
// import '../services/native_alarm.dart'; // <-- use NativeAlarm for process-independent alarms

// class MeditationScreen extends StatefulWidget {
//   final Habit habit; // category == HabitCategory.meditation
//   const MeditationScreen({super.key, required this.habit});

//   @override
//   State<MeditationScreen> createState() => _MedititationScreenState();
// }

// class _MedititationScreenState extends State<MeditationScreen> {
//   // ======== API CONFIG ========
//   static const String _apiBase = 'https://aswiniverma.pythonanywhere.com';
//   static const String _audioListPath = '/api/list/audio';

//   final _storage = StorageService();

//   // Habit
//   late Habit _h;

//   // Progress / timer
//   Timer? _timer;
//   int _elapsedSec = 0;
//   bool _running = false;
//   int _goalMin = 10;

//   // Reminders (staged until Save)
//   final List<TimeOfDay> _dailyTimes = [];
//   final List<DateTime> _oneOffReminders = [];
//   bool _dirtyReminders = false;

//   // Audio
//   late final AudioPlayer _player;
//   List<_MedApiTrack> _tracks = [];
//   bool _loadingTracks = true;
//   int? _currentIndex; // selected MP3 (no autoplay)

//   @override
//   void initState() {
//     super.initState();
//     _h = widget.habit;
//     _ensureToday();
//     _goalMin = _h.meditationGoalMin ?? 10;

//     // Load daily times from habit or seed defaults (staged; require Save)
//     if (_h.reminderTimes.isNotEmpty) {
//       _dailyTimes.addAll(_h.reminderTimes.map(Habit.parseHHmm));
//     } else {
//       _dailyTimes.addAll(const [
//         TimeOfDay(hour: 6, minute: 30),
//         TimeOfDay(hour: 20, minute: 0),
//       ]);
//       _dirtyReminders = true;
//     }

//     _setupAudio().then((_) => _loadTracksFromApi());
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _player.dispose();
//     super.dispose();
//   }

//   // ---------- Habit & persistence ----------
//   void _ensureToday() {
//     final now = DateTime.now();
//     final ymd =
//         '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
//     if (_h.meditationLastDate != ymd) {
//       _h.meditationLastDate = ymd;
//       _h.meditationTodayMin = 0;
//     }
//   }

//   Future<void> _persistHabitOnly() async {
//     final all = await _storage.loadHabits();
//     final i = all.indexWhere((x) => x.id == _h.id);
//     if (i >= 0) {
//       all[i] = _h;
//     } else {
//       all.add(_h); // first-time insert
//     }
//     await _storage.saveHabits(all);
//   }

//   // ---------- Alarm IDs ----------
//   int _dailyAlarmId(String habitId, TimeOfDay t) {
//     final key = '$habitId-${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}';
//     return key.hashCode & 0x7fffffff;
//   }

//   int _oneOffAlarmId(DateTime dt) {
//     final base = _h.id.hashCode & 0x7fffffff;
//     return base ^ dt.millisecondsSinceEpoch.hashCode;
//   }

//   // ---------- Reminders: SAVE & SCHEDULE ----------
//   Future<void> _saveReminders() async {
//     // Persist staged daily times
//     _h.reminderTimes = _dailyTimes.map(Habit.fmt).toList();
//     await _persistHabitOnly();

//     // Schedule daily reminders with NativeAlarm (process-independent)
//     if (_h.enabled) {
//       if (_dailyTimes.isNotEmpty) {
//         for (final t in _dailyTimes) {
//           final when = NotificationService.nextOccurrence(t.hour, t.minute);
//           await NativeAlarm.scheduleExact(
//             id: _dailyAlarmId(_h.id, t),
//             when: when,
//             title: 'Meditation Reminder',
//             body: 'Time to meditate 🧘',
//             daily: true, // repeat every day
//             hour: t.hour,
//             minute: t.minute,
//           );
//         }
//       } else {
//         // Fallback single daily time from reminderHour/minute
//         final when = NotificationService.nextOccurrence(_h.reminderHour, _h.reminderMinute);
//         await NativeAlarm.scheduleExact(
//           id: _dailyAlarmId(_h.id, TimeOfDay(hour: _h.reminderHour, minute: _h.reminderMinute)),
//           when: when,
//           title: 'Meditation Reminder',
//           body: 'Time to meditate 🧘',
//           daily: true,
//           hour: _h.reminderHour,
//           minute: _h.reminderMinute,
//         );
//       }
//     }

//     // Schedule staged one-off reminders (fire once, no daily flag)
//     for (final dt in _oneOffReminders) {
//       await NativeAlarm.scheduleExact(
//         id: _oneOffAlarmId(dt),
//         when: dt,
//         title: 'Meditation Reminder',
//         body: 'One-time reminder 🧘',
//         daily: false,
//         hour: dt.hour,
//         minute: dt.minute,
//       );
//     }
//     _oneOffReminders.clear();

//     if (!mounted) return;
//     setState(() => _dirtyReminders = false);
//     _snack('Reminders saved.');
//     // Optionally, Navigator.pop(context) to go back after saving.
//   }

//   // ---------- Audio ----------
//   Future<void> _setupAudio() async {
//     _player = AudioPlayer();
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.music());
//   }

//   Future<void> _loadTracksFromApi() async {
//     setState(() => _loadingTracks = true);
//     try {
//       final uri = Uri.parse('$_apiBase$_audioListPath');
//       final resp = await http.get(uri);
//       if (resp.statusCode == 200) {
//         final list = (json.decode(resp.body) as List)
//             .map((e) => _MedApiTrack.fromJson(e as Map<String, dynamic>, _apiBase))
//             .toList();
//         setState(() {
//           _tracks = list;
//           _loadingTracks = false;
//           if (_tracks.isNotEmpty && _currentIndex == null) {
//             _currentIndex = 0; // preselect first, but do not autoplay
//           }
//         });
//       } else {
//         setState(() => _loadingTracks = false);
//         _snack('Could not load audio list (${resp.statusCode}).');
//       }
//     } catch (e) {
//       setState(() => _loadingTracks = false);
//       _snack('Network error: $e');
//     }
//   }

//   Future<void> _prepareSelectedSource() async {
//     if (_currentIndex == null || _currentIndex! >= _tracks.length) return;
//     final t = _tracks[_currentIndex!];
//     await _player.setAudioSource(
//       AudioSource.uri(
//         Uri.parse(t.url),
//         tag: MediaItem(id: 'med-${t.id}', title: t.name),
//       ),
//       preload: true,
//     );
//   }

//   Future<void> _selectTrack(int index) async {
//     if (index < 0 || index >= _tracks.length) return;
//     setState(() => _currentIndex = index);
//     // No autoplay; actual source is set lazily when Start is pressed.
//   }

//   // ---------- Timer ----------
//   void _toggleTimerAndAudio() async {
//     if (_currentIndex == null) {
//       _snack('Choose a sound first.');
//       return;
//     }

//     if (!_player.playing && _player.audioSource == null) {
//       await _prepareSelectedSource();
//     }

//     if (_running) {
//       _timer?.cancel();
//       _running = false;
//       await _player.pause();
//     } else {
//       if (_player.audioSource == null) {
//         await _prepareSelectedSource();
//       }
//       _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//         setState(() => _elapsedSec++);
//       });
//       _running = true;
//       if (!_player.playing) {
//         await _player.play();
//       }
//     }
//     setState(() {});
//   }

//   Future<void> _saveSession() async {
//     _timer?.cancel();
//     _running = false;
//     await _player.stop();

//     final addMin = (_elapsedSec / 60).floor();
//     if (addMin > 0) {
//       _ensureToday();
//       _h.meditationTodayMin = (_h.meditationTodayMin ?? 0) + addMin;
//       await _persistHabitOnly();
//       _snack('Saved $addMin minute(s).');
//     }
//     setState(() => _elapsedSec = 0);
//   }

//   String _fmtClock(int sec) {
//     final m = (sec ~/ 60).toString().padLeft(2, '0');
//     final s = (sec % 60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   // ---------- Reminder UI actions (staged) ----------
//   Future<void> _addDailyTime() async {
//     final t = await showTimePicker(
//       context: context,
//       initialTime: const TimeOfDay(hour: 7, minute: 0),
//     );
//     if (t == null) return;
//     setState(() {
//       _dailyTimes.add(t);
//       _dirtyReminders = true;
//     });
//   }

//   Future<void> _editDailyTime(int i) async {
//     final t = await showTimePicker(
//       context: context,
//       initialTime: _dailyTimes[i],
//     );
//     if (t == null) return;
//     setState(() {
//       _dailyTimes[i] = t;
//       _dirtyReminders = true;
//     });
//   }

//   Future<void> _removeDailyTime(int i) async {
//     setState(() {
//       _dailyTimes.removeAt(i);
//       _dirtyReminders = true;
//     });
//   }

//   Future<void> _addOneOffReminder() async {
//     final now = DateTime.now();
//     final date = await showDatePicker(
//       context: context,
//       initialDate: now.add(const Duration(days: 1)),
//       firstDate: now,
//       lastDate: now.add(const Duration(days: 365)),
//     );
//     if (date == null) return;

//     final time = await showTimePicker(
//       context: context,
//       initialTime: const TimeOfDay(hour: 7, minute: 0),
//     );
//     if (time == null) return;

//     final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
//     setState(() {
//       _oneOffReminders.add(dt);
//       _dirtyReminders = true;
//     });
//   }

//   String _prettyDateTime(DateTime dt) {
//     final hh = dt.hour.toString().padLeft(2, '0');
//     final mm = dt.minute.toString().padLeft(2, '0');
//     return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hh:$mm';
//   }

//   // ---------- Track picker ----------
//   Future<void> _openTrackPicker() async {
//     if (_loadingTracks) return;
//     await showModalBottomSheet(
//       context: context,
//       useSafeArea: true,
//       showDragHandle: true,
//       builder: (ctx) {
//         return Padding(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(children: [
//                 const Text(
//                   'Choose Meditation Sound',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 const Spacer(),
//                 IconButton(
//                   tooltip: 'Refresh',
//                   iconSize: 28,
//                   onPressed: () async {
//                     Navigator.pop(ctx);
//                     await _loadTracksFromApi();
//                   },
//                   icon: const Icon(Icons.refresh),
//                 ),
//               ]),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: _tracks.isEmpty
//                     ? const Center(
//                         child: Text(
//                           'No audio found.\nUpload from backend.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(fontSize: 16),
//                         ),
//                       )
//                     : ListView.separated(
//                         itemCount: _tracks.length,
//                         separatorBuilder: (_, __) => const SizedBox(height: 8),
//                         itemBuilder: (_, i) {
//                           final t = _tracks[i];
//                           final selected = _currentIndex == i;
//                           return InkWell(
//                             onTap: () async {
//                               await _selectTrack(i); // select only
//                               if (mounted) Navigator.pop(ctx); // close
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.all(14),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(14),
//                                 color: selected
//                                     ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
//                                     : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     selected ? Icons.radio_button_checked : Icons.radio_button_off,
//                                     size: 26,
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Text(
//                                       t.name,
//                                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 4),
//                                   const Icon(Icons.chevron_right),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ---------- UI ----------
//   @override
//   Widget build(BuildContext context) {
//     final today = _h.meditationTodayMin ?? 0;
//     final goal = _goalMin;
//     final progress = (today / (goal == 0 ? 1 : goal)).clamp(0, 1.0);

//     final nowPlaying = (_currentIndex != null && _currentIndex! < _tracks.length)
//         ? _tracks[_currentIndex!].name
//         : 'No sound selected';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Meditation'),
//         centerTitle: true,
//         actions: [
//           TextButton.icon(
//             onPressed: _dirtyReminders ? _saveReminders : null,
//             icon: const Icon(Icons.save, size: 18),
//             label: const Text('Save'),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             // NOW PLAYING + BIG CONTROLS
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   children: [
//                     Text('Now Playing', style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 6),
//                     Text(
//                       nowPlaying,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _fmtClock(_elapsedSec),
//                       style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),

//                     Wrap(
//                       alignment: WrapAlignment.center,
//                       spacing: 16,
//                       runSpacing: 12,
//                       children: [
//                         _BigActionButton(
//                           icon: Icons.library_music,
//                           label: 'Choose Sound',
//                           onTap: _openTrackPicker,
//                         ),
//                         _BigActionButton(
//                           icon: (_player.playing && _running) ? Icons.pause : Icons.play_arrow,
//                           label: (_player.playing && _running) ? 'Pause' : 'Start',
//                           onTap: _toggleTimerAndAudio,
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 12),
//                     FilledButton.icon(
//                       onPressed: _elapsedSec == 0 ? null : _saveSession,
//                       icon: const Icon(Icons.save),
//                       label: const Text('Save Minutes'),
//                       style: FilledButton.styleFrom(
//                         minimumSize: const Size(240, 48),
//                         textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // TODAY PROGRESS + GOAL
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   children: [
//                     Text('Today\'s Progress', style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     LinearProgressIndicator(value: progress as double?),
//                     const SizedBox(height: 8),
//                     Text('$today / $goal min', style: const TextStyle(fontSize: 16)),
//                     const Divider(height: 24),
//                     Row(
//                       children: [
//                         const Expanded(
//                           child: Text(
//                             'Daily Goal (min)',
//                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                           ),
//                         ),
//                         IconButton.filledTonal(
//                           onPressed: () {
//                             setState(() {
//                               _goalMin = (_goalMin - 5).clamp(5, 180);
//                             });
//                             _h.meditationGoalMin = _goalMin;
//                             _persistHabitOnly();
//                           },
//                           icon: const Icon(Icons.remove, size: 26),
//                           style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                           child: Text('$_goalMin', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//                         ),
//                         IconButton.filledTonal(
//                           onPressed: () {
//                             setState(() {
//                               _goalMin = (_goalMin + 5).clamp(5, 180);
//                             });
//                             _h.meditationGoalMin = _goalMin;
//                             _persistHabitOnly();
//                           },
//                           icon: const Icon(Icons.add, size: 26),
//                           style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // REMINDERS (Daily + One-off) — staged until Save
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Reminders', style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     Text('Daily times (repeat every day)', style: Theme.of(context).textTheme.titleMedium),
//                     const SizedBox(height: 6),
//                     if (_dailyTimes.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 6),
//                         child: Text('No daily times yet.'),
//                       ),
//                     ...List.generate(_dailyTimes.length, (i) {
//                       final t = _dailyTimes[i];
//                       return Card(
//                         child: ListTile(
//                           leading: const Icon(Icons.schedule),
//                           title: Text(Habit.fmt(t)),
//                           trailing: Wrap(
//                             spacing: 8,
//                             children: [
//                               IconButton(
//                                 onPressed: () => _editDailyTime(i),
//                                 icon: const Icon(Icons.edit_outlined),
//                               ),
//                               IconButton(
//                                 onPressed: () => _removeDailyTime(i),
//                                 icon: const Icon(Icons.delete_outline),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     }),
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: OutlinedButton.icon(
//                         onPressed: _addDailyTime,
//                         icon: const Icon(Icons.add),
//                         label: const Text('Add daily time'),
//                       ),
//                     ),
//                     const Divider(height: 28),

//                     Text('One-time reminders (specific date & time)', style: Theme.of(context).textTheme.titleMedium),
//                     const SizedBox(height: 6),
//                     if (_oneOffReminders.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 6),
//                         child: Text('No one-time reminders yet.'),
//                       ),
//                     ..._oneOffReminders.map((dt) => Card(
//                           child: ListTile(
//                             leading: const Icon(Icons.event_available),
//                             title: Text(_prettyDateTime(dt)),
//                             subtitle: const Text('This will ring once (on Save).'),
//                           ),
//                         )),
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: OutlinedButton.icon(
//                         onPressed: _addOneOffReminder,
//                         icon: const Icon(Icons.event),
//                         label: const Text('Add one-time reminder'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             if (_loadingTracks)
//               const Padding(
//                 padding: EdgeInsets.all(12.0),
//                 child: Center(child: CircularProgressIndicator()),
//               ),
//           ],
//         ),
//       ),

//       // Bottom-wide Save (reminders)
//       bottomNavigationBar: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//           child: FilledButton.icon(
//             onPressed: _dirtyReminders ? _saveReminders : null,
//             icon: const Icon(Icons.save),
//             label: const Text('Save reminders'),
//           ),
//         ),
//       ),
//     );
//   }

//   void _snack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
//     );
//   }
// }

// // ======== Big action button (responsive) ========
// class _BigActionButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback? onTap;

//   const _BigActionButton({
//     required this.icon,
//     required this.label,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ConstrainedBox(
//       constraints: const BoxConstraints(minWidth: 140, maxWidth: 200, minHeight: 56),
//       child: ElevatedButton.icon(
//         onPressed: onTap,
//         icon: Icon(icon, size: 28),
//         label: Text(
//           label,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//         ),
//         style: ElevatedButton.styleFrom(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         ),
//       ),
//     );
//   }
// }

// // ======== API track model ========
// class _MedApiTrack {
//   final int id;
//   final String type; // "audio"
//   final String name;
//   final String url;  // absolute url
//   final int? sizeBytes;
//   final DateTime? created;

//   _MedApiTrack({
//     required this.id,
//     required this.type,
//     required this.name,
//     required this.url,
//     this.sizeBytes,
//     this.created,
//   });

//   factory _MedApiTrack.fromJson(Map<String, dynamic> j, String base) {
//     String u = (j['url'] ?? '').toString();
//     if (u.startsWith('/')) u = '$base$u'; // prefix host if API gave "/media/.."
//     DateTime? c;
//     try { c = j['created'] != null ? DateTime.parse(j['created']) : null; } catch (_) {}
//     return _MedApiTrack(
//       id: (j['id'] ?? 0) is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
//       type: (j['type'] ?? '').toString(),
//       name: (j['name'] ?? 'Meditation Audio').toString(),
//       url: u,
//       sizeBytes: j['size_bytes'] is int ? j['size_bytes'] as int : int.tryParse('${j['size_bytes']}'),
//       created: c,
//     );
//   }
// }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////





// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';

// // Models / storage
// import '../models/habit.dart';
// import '../services/storage_service.dart';

// // Audio
// import 'package:audio_session/audio_session.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:just_audio_background/just_audio_background.dart';

// // Network
// import 'package:http/http.dart' as http;

// // Notifications
// import '../services/notification_service.dart';

// class MeditationScreen extends StatefulWidget {
//   final Habit habit; // category == HabitCategory.meditation
//   const MeditationScreen({super.key, required this.habit});

//   @override
//   State<MeditationScreen> createState() => _MeditationScreenState();
// }

// class _MeditationScreenState extends State<MeditationScreen> {
//   // ======== API CONFIG ========
//   static const String _apiBase = 'https://aswiniverma.pythonanywhere.com';
//   static const String _audioListPath = '/api/list/audio';

//   final _storage = StorageService();

//   // Habit
//   late Habit _h;

//   // Progress / timer
//   Timer? _timer;
//   int _elapsedSec = 0;
//   bool _running = false;
//   int _goalMin = 10;

//   // Reminders (local staged)
//   final List<TimeOfDay> _dailyTimes = [];
//   final List<DateTime> _oneOffReminders = [];
//   bool _dirtyReminders = false; // enable Save when edits pending

//   // Audio
//   late final AudioPlayer _player;
//   List<_MedApiTrack> _tracks = [];
//   bool _loadingTracks = true;
//   int? _currentIndex; // selected MP3 (no autoplay)

//   @override
//   void initState() {
//     super.initState();
//     _h = widget.habit;
//     _ensureToday();
//     _goalMin = _h.meditationGoalMin ?? 10;

//     // Load daily times from habit or seed defaults (staged, require Save)
//     if (_h.reminderTimes.isNotEmpty) {
//       _dailyTimes.addAll(_h.reminderTimes.map(Habit.parseHHmm));
//     } else {
//       _dailyTimes.addAll(const [
//         TimeOfDay(hour: 6, minute: 30),
//         TimeOfDay(hour: 20, minute: 0),
//       ]);
//       _dirtyReminders = true;
//     }

//     _setupAudio().then((_) => _loadTracksFromApi());
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _player.dispose();
//     super.dispose();
//   }

//   // ---------- Habit & persistence ----------
//   void _ensureToday() {
//     final now = DateTime.now();
//     final ymd =
//         '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
//     if (_h.meditationLastDate != ymd) {
//       _h.meditationLastDate = ymd;
//       _h.meditationTodayMin = 0;
//     }
//   }

//   // Future<void> _persistHabitOnly() async {
//   //   final all = await _storage.loadHabits();
//   //   final i = all.indexWhere((x) => x.id == _h.id);
//   //   if (i >= 0) {
//   //     all[i] = _h;
//   //     await _storage.saveHabits(all);
//   //   }
//   // }
//   Future<void> _persistHabitOnly() async {
//   final all = await _storage.loadHabits();
//   final i = all.indexWhere((x) => x.id == _h.id);
//   if (i >= 0) {
//     all[i] = _h;
//   } else {
//     all.add(_h); // <-- INSERT if not present yet
//   }
//   await _storage.saveHabits(all);
// }

//   Future<void> _saveReminders() async {
//     // Apply staged daily times to habit + schedule them
//     _h.reminderTimes = _dailyTimes.map(Habit.fmt).toList();
//     await _persistHabitOnly();

//     if (_h.enabled && _h.reminderTimes.isNotEmpty) {
//       await NotificationService.scheduleMultipleTimes(
//         habitId: _h.id,
//         hhmmList: _h.reminderTimes,
//         title: 'Meditation Reminder',
//         bodyPrefix: 'Time to meditate 🧘',
//       );
//     } else if (_h.enabled) {
//       final when = NotificationService.nextOccurrence(
//           _h.reminderHour, _h.reminderMinute);
//       await NotificationService.scheduleExactWithAlarmManager(
//         alarmId: _h.id.hashCode & 0x7fffffff,
//         when: when,
//         title: 'Meditation Reminder',
//         body: 'Time to meditate 🧘',
//       );
//     }

//     // Schedule staged one-time reminders
//     for (final dt in _oneOffReminders) {
//       final alarmId = _uniqueAlarmId(dt);
//       await NotificationService.scheduleExactWithAlarmManager(
//         alarmId: alarmId,
//         when: dt,
//         title: 'Meditation Reminder',
//         body: 'One-time reminder 🧘',
//       );
//     }
//     _oneOffReminders.clear();

//     if (mounted) {
//       setState(() => _dirtyReminders = false);
//       _snack('Reminders saved.');
//     }
//   }

//   // ---------- Audio ----------
//   Future<void> _setupAudio() async {
//     _player = AudioPlayer();
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.music());
//   }

//   Future<void> _loadTracksFromApi() async {
//     setState(() => _loadingTracks = true);
//     try {
//       final uri = Uri.parse('$_apiBase$_audioListPath');
//       final resp = await http.get(uri);
//       if (resp.statusCode == 200) {
//         final list = (json.decode(resp.body) as List)
//             .map((e) => _MedApiTrack.fromJson(e as Map<String, dynamic>, _apiBase))
//             .toList();
//         setState(() {
//           _tracks = list;
//           _loadingTracks = false;
//           if (_tracks.isNotEmpty && _currentIndex == null) {
//             _currentIndex = 0; // preselect first
//           }
//         });
//       } else {
//         setState(() => _loadingTracks = false);
//         _snack('Could not load audio list (${resp.statusCode}).');
//       }
//     } catch (e) {
//       setState(() => _loadingTracks = false);
//       _snack('Network error: $e');
//     }
//   }

//   Future<void> _prepareSelectedSource() async {
//     if (_currentIndex == null || _currentIndex! >= _tracks.length) return;
//     final t = _tracks[_currentIndex!];
//     await _player.setAudioSource(
//       AudioSource.uri(
//         Uri.parse(t.url),
//         tag: MediaItem(id: 'med-${t.id}', title: t.name),
//       ),
//       preload: true,
//     );
//   }

//   Future<void> _selectTrack(int index) async {
//     if (index < 0 || index >= _tracks.length) return;
//     setState(() => _currentIndex = index);
//     // DO NOT play here; lazy-prepare on Start
//   }

//   // ---------- Timer ----------
//   void _toggleTimerAndAudio() async {
//     if (_currentIndex == null) {
//       _snack('Choose a sound first.');
//       return;
//     }

//     if (!_player.playing && _player.audioSource == null) {
//       await _prepareSelectedSource();
//     }

//     if (_running) {
//       _timer?.cancel();
//       _running = false;
//       await _player.pause();
//     } else {
//       if (_player.audioSource == null) {
//         await _prepareSelectedSource();
//       }
//       _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//         setState(() => _elapsedSec++);
//       });
//       _running = true;
//       if (!_player.playing) {
//         await _player.play();
//       }
//     }
//     setState(() {});
//   }

//   Future<void> _saveSession() async {
//     _timer?.cancel();
//     _running = false;
//     await _player.stop();

//     final addMin = (_elapsedSec / 60).floor();
//     if (addMin > 0) {
//       _ensureToday();
//       _h.meditationTodayMin = (_h.meditationTodayMin ?? 0) + addMin;
//       await _persistHabitOnly();
//       _snack('Saved $addMin minute(s).');
//     }
//     setState(() => _elapsedSec = 0);
//   }

//   String _fmtClock(int sec) {
//     final m = (sec ~/ 60).toString().padLeft(2, '0');
//     final s = (sec % 60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   // ---------- Reminder UI actions (staged) ----------
//   Future<void> _addDailyTime() async {
//     final t = await showTimePicker(
//       context: context,
//       initialTime: const TimeOfDay(hour: 7, minute: 0),
//     );
//     if (t == null) return;
//     setState(() {
//       _dailyTimes.add(t);
//       _dirtyReminders = true;
//     });
//   }

//   Future<void> _editDailyTime(int i) async {
//     final t = await showTimePicker(
//       context: context,
//       initialTime: _dailyTimes[i],
//     );
//     if (t == null) return;
//     setState(() {
//       _dailyTimes[i] = t;
//       _dirtyReminders = true;
//     });
//   }

//   Future<void> _removeDailyTime(int i) async {
//     setState(() {
//       _dailyTimes.removeAt(i);
//       _dirtyReminders = true;
//     });
//   }

//   Future<void> _addOneOffReminder() async {
//     final now = DateTime.now();
//     final date = await showDatePicker(
//       context: context,
//       initialDate: now.add(const Duration(days: 1)),
//       firstDate: now,
//       lastDate: now.add(const Duration(days: 365)),
//     );
//     if (date == null) return;

//     final time = await showTimePicker(
//       context: context,
//       initialTime: const TimeOfDay(hour: 7, minute: 0),
//     );
//     if (time == null) return;

//     final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
//     setState(() {
//       _oneOffReminders.add(dt);
//       _dirtyReminders = true;
//     });
//   }

//   int _uniqueAlarmId(DateTime dt) {
//     final base = _h.id.hashCode & 0x7fffffff;
//     return base ^ dt.millisecondsSinceEpoch.hashCode;
//   }

//   String _prettyDateTime(DateTime dt) {
//     final hh = dt.hour.toString().padLeft(2, '0');
//     final mm = dt.minute.toString().padLeft(2, '0');
//     return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hh:$mm';
//   }

//   // ---------- Track picker ----------
//   Future<void> _openTrackPicker() async {
//     if (_loadingTracks) return;
//     await showModalBottomSheet(
//       context: context,
//       useSafeArea: true,
//       showDragHandle: true,
//       builder: (ctx) {
//         return Padding(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(children: [
//                 const Text(
//                   'Choose Meditation Sound',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 const Spacer(),
//                 IconButton(
//                   tooltip: 'Refresh',
//                   iconSize: 28,
//                   onPressed: () async {
//                     Navigator.pop(ctx);
//                     await _loadTracksFromApi();
//                   },
//                   icon: const Icon(Icons.refresh),
//                 ),
//               ]),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: _tracks.isEmpty
//                     ? const Center(
//                         child: Text(
//                           'No audio found.\nUpload from backend.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(fontSize: 16),
//                         ),
//                       )
//                     : ListView.separated(
//                         itemCount: _tracks.length,
//                         separatorBuilder: (_, __) => const SizedBox(height: 8),
//                         itemBuilder: (_, i) {
//                           final t = _tracks[i];
//                           final selected = _currentIndex == i;
//                           return InkWell(
//                             onTap: () async {
//                               await _selectTrack(i); // selection only
//                               if (mounted) Navigator.pop(ctx); // close
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.all(14),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(14),
//                                 color: selected
//                                     ? Theme.of(context)
//                                         .colorScheme
//                                         .primary
//                                         .withOpacity(0.12)
//                                     : Theme.of(context)
//                                         .colorScheme
//                                         .surfaceVariant
//                                         .withOpacity(0.4),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     selected
//                                         ? Icons.radio_button_checked
//                                         : Icons.radio_button_off,
//                                     size: 26,
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Text(
//                                       t.name,
//                                       style: const TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.w600),
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 4),
//                                   const Icon(Icons.chevron_right),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ---------- UI ----------
//   @override
//   Widget build(BuildContext context) {
//     final today = _h.meditationTodayMin ?? 0;
//     final goal = _goalMin;
//     final progress = (today / (goal == 0 ? 1 : goal)).clamp(0, 1.0);

//     final nowPlaying = (_currentIndex != null && _currentIndex! < _tracks.length)
//         ? _tracks[_currentIndex!].name
//         : 'No sound selected';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Meditation'),
//         centerTitle: true,
//         actions: [
//           TextButton.icon(
//             onPressed: _dirtyReminders ? _saveReminders : null,
//             icon: const Icon(Icons.save, size: 18),
//             label: const Text('Save'),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             // NOW PLAYING + BIG CONTROLS
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   children: [
//                     Text('Now Playing',
//                         style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 6),
//                     Text(
//                       nowPlaying,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                           fontSize: 18, fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _fmtClock(_elapsedSec),
//                       style: const TextStyle(
//                           fontSize: 40, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),

//                     Wrap(
//                       alignment: WrapAlignment.center,
//                       spacing: 16,
//                       runSpacing: 12,
//                       children: [
//                         _BigActionButton(
//                           icon: Icons.library_music,
//                           label: 'Choose Sound',
//                           onTap: _openTrackPicker,
//                         ),
//                         _BigActionButton(
//                           icon: (_player.playing && _running)
//                               ? Icons.pause
//                               : Icons.play_arrow,
//                           label:
//                               (_player.playing && _running) ? 'Pause' : 'Start',
//                           onTap: _toggleTimerAndAudio,
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 12),
//                     FilledButton.icon(
//                       onPressed: _elapsedSec == 0 ? null : _saveSession,
//                       icon: const Icon(Icons.save),
//                       label: const Text('Save Minutes'),
//                       style: FilledButton.styleFrom(
//                         minimumSize: const Size(240, 48),
//                         textStyle: const TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // TODAY PROGRESS + GOAL STEPPER
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   children: [
//                     Text('Today\'s Progress',
//                         style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     LinearProgressIndicator(value: progress as double?),
//                     const SizedBox(height: 8),
//                     Text('$today / $goal min',
//                         style: const TextStyle(fontSize: 16)),
//                     const Divider(height: 24),
//                     Row(
//                       children: [
//                         const Expanded(
//                           child: Text(
//                             'Daily Goal (min)',
//                             style: TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.w600),
//                           ),
//                         ),
//                         IconButton.filledTonal(
//                           onPressed: () {
//                             setState(() {
//                               _goalMin = (_goalMin - 5).clamp(5, 180);
//                             });
//                             _h.meditationGoalMin = _goalMin;
//                             _persistHabitOnly();
//                           },
//                           icon: const Icon(Icons.remove, size: 26),
//                           style: IconButton.styleFrom(
//                               fixedSize: const Size(52, 52)),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                           child: Text('$_goalMin',
//                               style: const TextStyle(
//                                   fontSize: 22, fontWeight: FontWeight.bold)),
//                         ),
//                         IconButton.filledTonal(
//                           onPressed: () {
//                             setState(() {
//                               _goalMin = (_goalMin + 5).clamp(5, 180);
//                             });
//                             _h.meditationGoalMin = _goalMin;
//                             _persistHabitOnly();
//                           },
//                           icon: const Icon(Icons.add, size: 26),
//                           style: IconButton.styleFrom(
//                               fixedSize: const Size(52, 52)),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // REMINDERS (Daily + One-off) — staged until Save
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Reminders',
//                         style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     Text('Daily times (repeat every day)',
//                         style: Theme.of(context).textTheme.titleMedium),
//                     const SizedBox(height: 6),
//                     if (_dailyTimes.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 6),
//                         child: Text('No daily times yet.'),
//                       ),
//                     ...List.generate(_dailyTimes.length, (i) {
//                       final t = _dailyTimes[i];
//                       return Card(
//                         child: ListTile(
//                           leading: const Icon(Icons.schedule),
//                           title: Text(Habit.fmt(t)),
//                           trailing: Wrap(
//                             spacing: 8,
//                             children: [
//                               IconButton(
//                                 onPressed: () => _editDailyTime(i),
//                                 icon: const Icon(Icons.edit_outlined),
//                               ),
//                               IconButton(
//                                 onPressed: () => _removeDailyTime(i),
//                                 icon: const Icon(Icons.delete_outline),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     }),
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: OutlinedButton.icon(
//                         onPressed: _addDailyTime,
//                         icon: const Icon(Icons.add),
//                         label: const Text('Add daily time'),
//                       ),
//                     ),
//                     const Divider(height: 28),

//                     Text('One-time reminders (specific date & time)',
//                         style: Theme.of(context).textTheme.titleMedium),
//                     const SizedBox(height: 6),
//                     if (_oneOffReminders.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 6),
//                         child: Text('No one-time reminders yet.'),
//                       ),
//                     ..._oneOffReminders.map((dt) => Card(
//                           child: ListTile(
//                             leading: const Icon(Icons.event_available),
//                             title: Text(_prettyDateTime(dt)),
//                             subtitle: const Text('This will ring once (on Save).'),
//                           ),
//                         )),
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: OutlinedButton.icon(
//                         onPressed: _addOneOffReminder,
//                         icon: const Icon(Icons.event),
//                         label: const Text('Add one-time reminder'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             if (_loadingTracks)
//               const Padding(
//                 padding: EdgeInsets.all(12.0),
//                 child: Center(child: CircularProgressIndicator()),
//               ),
//           ],
//         ),
//       ),
//       // Bottom-wide Save (reminders)
//       bottomNavigationBar: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//           child: FilledButton.icon(
//             onPressed: _dirtyReminders ? _saveReminders : null,
//             icon: const Icon(Icons.save),
//             label: const Text('Save reminders'),
//           ),
//         ),
//       ),
//     );
//   }

//   void _snack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
//     );
//   }
// }

// // ======== Big action button (responsive) ========
// class _BigActionButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback? onTap;

//   const _BigActionButton({
//     required this.icon,
//     required this.label,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ConstrainedBox(
//       constraints:
//           const BoxConstraints(minWidth: 140, maxWidth: 200, minHeight: 56),
//       child: ElevatedButton.icon(
//         onPressed: onTap,
//         icon: Icon(icon, size: 28),
//         label: Text(
//           label,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//         ),
//         style: ElevatedButton.styleFrom(
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         ),
//       ),
//     );
//   }
// }

// // ======== API track model ========
// class _MedApiTrack {
//   final int id;
//   final String type; // "audio"
//   final String name;
//   final String url; // absolute url
//   final int? sizeBytes;
//   final DateTime? created;

//   _MedApiTrack({
//     required this.id,
//     required this.type,
//     required this.name,
//     required this.url,
//     this.sizeBytes,
//     this.created,
//   });

//   factory _MedApiTrack.fromJson(Map<String, dynamic> j, String base) {
//     String u = (j['url'] ?? '').toString();
//     if (u.startsWith('/')) u = '$base$u';
//     DateTime? c;
//     try {
//       c = j['created'] != null ? DateTime.parse(j['created']) : null;
//     } catch (_) {}
//     return _MedApiTrack(
//       id: (j['id'] ?? 0) is int
//           ? j['id'] as int
//           : int.tryParse('${j['id']}') ?? 0,
//       type: (j['type'] ?? '').toString(),
//       name: (j['name'] ?? 'Meditation Audio').toString(),
//       url: u,
//       sizeBytes: j['size_bytes'] is int
//           ? j['size_bytes'] as int
//           : int.tryParse('${j['size_bytes']}'),
//       created: c,
//     );
//   }
// }

///////////////////////////////////////////////////////////////////////////////////////////////////




// // lib/screens/meditation_screen.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';

// // Models / storage
// import '../models/habit.dart';
// import '../services/storage_service.dart';

// // Audio
// import 'package:audio_session/audio_session.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:just_audio_background/just_audio_background.dart';

// // Network
// import 'package:http/http.dart' as http;

// // Notifications
// import '../services/notification_service.dart';

// class MeditationScreen extends StatefulWidget {
//   final Habit habit; // category == HabitCategory.meditation
//   const MeditationScreen({super.key, required this.habit});

//   @override
//   State<MeditationScreen> createState() => _MeditationScreenState();
// }

// class _MeditationScreenState extends State<MeditationScreen> {
//   // ======== API CONFIG ========
//   static const String _apiBase = 'https://aswiniverma.pythonanywhere.com';
//   static const String _audioListPath = '/api/list/audio';

//   final _storage = StorageService();

//   // Habit
//   late Habit _h;

//   // Progress / timer
//   Timer? _timer;
//   int _elapsedSec = 0;
//   bool _running = false;
//   int _goalMin = 10;

//   // Reminders
//   final List<TimeOfDay> _dailyTimes = [];
//   final List<DateTime> _oneOffReminders = []; // one-time alarms (not persisted)

//   // Audio
//   late final AudioPlayer _player;
//   List<_MedApiTrack> _tracks = [];
//   bool _loadingTracks = true;
//   int? _currentIndex; // selected MP3

//   @override
//   void initState() {
//     super.initState();
//     _h = widget.habit;
//     _ensureToday();
//     _goalMin = _h.meditationGoalMin ?? 10;

//     // Load daily times from habit or seed defaults
//     if (_h.reminderTimes.isNotEmpty) {
//       _dailyTimes.addAll(_h.reminderTimes.map(Habit.parseHHmm));
//     } else {
//       _dailyTimes.addAll(const [
//         TimeOfDay(hour: 6, minute: 30),
//         TimeOfDay(hour: 20, minute: 0),
//       ]);
//       _saveDailyTimes(); // persist + schedule
//     }

//     _setupAudio().then((_) => _loadTracksFromApi());
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _player.dispose();
//     super.dispose();
//   }

//   // ---------- Habit & persistence ----------
//   void _ensureToday() {
//     final now = DateTime.now();
//     final ymd =
//         '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
//     if (_h.meditationLastDate != ymd) {
//       _h.meditationLastDate = ymd;
//       _h.meditationTodayMin = 0;
//     }
//   }

//   Future<void> _persistHabit() async {
//     final all = await _storage.loadHabits();
//     final i = all.indexWhere((x) => x.id == _h.id);
//     if (i >= 0) {
//       all[i] = _h;
//       await _storage.saveHabits(all);
//     }
//   }

//   Future<void> _saveDailyTimes() async {
//     _h.reminderTimes = _dailyTimes.map(Habit.fmt).toList();
//     await _persistHabit();

//     if (_h.enabled && _h.reminderTimes.isNotEmpty) {
//       await NotificationService.scheduleMultipleTimes(
//         habitId: _h.id,
//         hhmmList: _h.reminderTimes,
//         title: 'Meditation Reminder',
//         bodyPrefix: 'Time to meditate 🧘',
//       );
//       _showSnack('Daily reminders updated.');
//     }
//   }

//   // ---------- Audio ----------
//   Future<void> _setupAudio() async {
//     _player = AudioPlayer();
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.music());
//   }

//   Future<void> _loadTracksFromApi() async {
//     setState(() => _loadingTracks = true);
//     try {
//       final uri = Uri.parse('$_apiBase$_audioListPath');
//       final resp = await http.get(uri);
//       if (resp.statusCode == 200) {
//         final list = (json.decode(resp.body) as List)
//             .map((e) => _MedApiTrack.fromJson(e as Map<String, dynamic>, _apiBase))
//             .toList();
//         setState(() {
//           _tracks = list;
//           _loadingTracks = false;
//         });
//         if (_tracks.isNotEmpty) {
//           // Preselect first, but DO NOT autoplay and DO NOT load source yet.
//           _currentIndex = 0;
//           setState(() {});
//         }
//       } else {
//         setState(() => _loadingTracks = false);
//         _showSnack('Could not load audio list (${resp.statusCode}).');
//       }
//     } catch (e) {
//       setState(() => _loadingTracks = false);
//       _showSnack('Network error: $e');
//     }
//   }

//   Future<void> _prepareSelectedSource() async {
//     // Set the player's source for the currently selected track (no autoplay)
//     if (_currentIndex == null || _currentIndex! >= _tracks.length) return;
//     final t = _tracks[_currentIndex!];
//     await _player.setAudioSource(
//       AudioSource.uri(
//         Uri.parse(t.url),
//         tag: MediaItem(id: 'med-${t.id}', title: t.name),
//       ),
//       preload: true,
//     );
//   }

//   Future<void> _selectTrack(int index) async {
//     if (index < 0 || index >= _tracks.length) return;
//     _currentIndex = index;
//     // Do not play here. Just set selected (and close the sheet).
//     // We'll lazily load the source on first Play.
//     setState(() {});
//   }

//   // ---------- Timer ----------
//   void _toggleTimerAndAudio() async {
//     if (_currentIndex == null) {
//       _showSnack('Choose a sound first.');
//       return;
//     }

//     // Lazily prepare the audio source if not yet set or if changed.
//     if (!_player.playing && _player.audioSource == null) {
//       await _prepareSelectedSource();
//     }

//     if (_running) {
//       _timer?.cancel();
//       _running = false;
//       await _player.pause();
//     } else {
//       // If selection changed after a previous play/stop, ensure correct source.
//       if (_player.audioSource == null) {
//         await _prepareSelectedSource();
//       }
//       _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//         setState(() => _elapsedSec++);
//       });
//       _running = true;
//       if (!_player.playing) {
//         await _player.play();
//       }
//     }
//     setState(() {});
//   }

//   Future<void> _saveSession() async {
//     _timer?.cancel();
//     _running = false;
//     await _player.stop();

//     final addMin = (_elapsedSec / 60).floor();
//     if (addMin > 0) {
//       _ensureToday();
//       _h.meditationTodayMin = (_h.meditationTodayMin ?? 0) + addMin;
//       await _persistHabit();
//       _showSnack('Saved $addMin minute(s).');
//     }
//     setState(() => _elapsedSec = 0);
//   }

//   String _fmtClock(int sec) {
//     final m = (sec ~/ 60).toString().padLeft(2, '0');
//     final s = (sec % 60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   // ---------- Reminders UI Actions ----------
//   Future<void> _addDailyTime() async {
//     final t = await showTimePicker(
//       context: context,
//       initialTime: const TimeOfDay(hour: 7, minute: 0),
//     );
//     if (t == null) return;
//     setState(() => _dailyTimes.add(t));
//     await _saveDailyTimes();
//   }

//   Future<void> _editDailyTime(int i) async {
//     final t = await showTimePicker(
//       context: context,
//       initialTime: _dailyTimes[i],
//     );
//     if (t == null) return;
//     setState(() => _dailyTimes[i] = t);
//     await _saveDailyTimes();
//   }

//   Future<void> _removeDailyTime(int i) async {
//     setState(() => _dailyTimes.removeAt(i));
//     await _saveDailyTimes();
//   }

//   Future<void> _addOneOffReminder() async {
//     final now = DateTime.now();
//     final date = await showDatePicker(
//       context: context,
//       initialDate: now.add(const Duration(days: 1)),
//       firstDate: now,
//       lastDate: now.add(const Duration(days: 365)),
//     );
//     if (date == null) return;

//     final time = await showTimePicker(
//       context: context,
//       initialTime: const TimeOfDay(hour: 7, minute: 0),
//     );
//     if (time == null) return;

//     final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
//     _oneOffReminders.add(dt);

//     final alarmId = _uniqueAlarmId(dt);
//     await NotificationService.scheduleExactWithAlarmManager(
//       alarmId: alarmId,
//       when: dt,
//       title: 'Meditation Reminder',
//       body: 'One-time reminder 🧘',
//     );
//     if (mounted) setState(() {});
//     _showSnack('One-time reminder set for ${_prettyDateTime(dt)}');
//   }

//   int _uniqueAlarmId(DateTime dt) {
//     final base = _h.id.hashCode & 0x7fffffff;
//     return base ^ dt.millisecondsSinceEpoch.hashCode;
//   }

//   String _prettyDateTime(DateTime dt) {
//     final hh = dt.hour.toString().padLeft(2, '0');
//     final mm = dt.minute.toString().padLeft(2, '0');
//     return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hh:$mm';
//   }

//   // ---------- Track picker (NO AUTOPLAY) ----------
//   Future<void> _openTrackPicker() async {
//     if (_loadingTracks) return;
//     await showModalBottomSheet(
//       context: context,
//       useSafeArea: true,
//       showDragHandle: true,
//       builder: (ctx) {
//         return Padding(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(children: [
//                 const Text(
//                   'Choose Meditation Sound',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 const Spacer(),
//                 IconButton(
//                   tooltip: 'Refresh',
//                   iconSize: 28,
//                   onPressed: () async {
//                     Navigator.pop(ctx);
//                     await _loadTracksFromApi();
//                   },
//                   icon: const Icon(Icons.refresh),
//                 ),
//               ]),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: _tracks.isEmpty
//                     ? const Center(
//                         child: Text(
//                           'No audio found.\nUpload from backend.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(fontSize: 16),
//                         ),
//                       )
//                     : ListView.separated(
//                         itemCount: _tracks.length,
//                         separatorBuilder: (_, __) => const SizedBox(height: 8),
//                         itemBuilder: (_, i) {
//                           final t = _tracks[i];
//                           final selected = _currentIndex == i;
//                           return InkWell(
//                             onTap: () async {
//                               await _selectTrack(i); // select only, no autoplay
//                               if (mounted) Navigator.pop(ctx); // close sheet
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.all(14),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(14),
//                                 color: selected
//                                     ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
//                                     : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     selected ? Icons.radio_button_checked : Icons.radio_button_off,
//                                     size: 26,
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Text(
//                                       t.name,
//                                       style: const TextStyle(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ),
//                                   // No play icon here — selection only.
//                                   const SizedBox(width: 4),
//                                   const Icon(Icons.chevron_right),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ---------- UI ----------
//   @override
//   Widget build(BuildContext context) {
//     final today = _h.meditationTodayMin ?? 0;
//     final goal = _goalMin;
//     final progress = (today / (goal == 0 ? 1 : goal)).clamp(0, 1.0);

//     final nowPlaying = (_currentIndex != null && _currentIndex! < _tracks.length)
//         ? _tracks[_currentIndex!].name
//         : 'No sound selected';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Meditation'),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             // NOW PLAYING + BIG CONTROLS
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   children: [
//                     Text('Now Playing', style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 6),
//                     Text(
//                       nowPlaying,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _fmtClock(_elapsedSec),
//                       style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),

//                     // Use Wrap to avoid overflow on small screens
//                     Wrap(
//                       alignment: WrapAlignment.center,
//                       spacing: 16,
//                       runSpacing: 12,
//                       children: [
//                         _BigActionButton(
//                           icon: Icons.library_music,
//                           label: 'Choose Sound',
//                           onTap: _openTrackPicker,
//                         ),
//                         _BigActionButton(
//                           icon: (_player.playing && _running) ? Icons.pause : Icons.play_arrow,
//                           label: (_player.playing && _running) ? 'Pause' : 'Start',
//                           onTap: _toggleTimerAndAudio,
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 12),
//                     FilledButton.icon(
//                       onPressed: _elapsedSec == 0 ? null : _saveSession,
//                       icon: const Icon(Icons.save),
//                       label: const Text('Save Minutes'),
//                       style: FilledButton.styleFrom(
//                         minimumSize: const Size(240, 48),
//                         textStyle:
//                             const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // TODAY PROGRESS + GOAL STEPPER
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   children: [
//                     Text('Today\'s Progress', style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     LinearProgressIndicator(value: progress as double?),
//                     const SizedBox(height: 8),
//                     Text('$today / $goal min', style: const TextStyle(fontSize: 16)),
//                     const Divider(height: 24),
//                     Row(
//                       children: [
//                         const Expanded(
//                           child: Text(
//                             'Daily Goal (min)',
//                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                           ),
//                         ),
//                         IconButton.filledTonal(
//                           onPressed: () {
//                             setState(() {
//                               _goalMin = (_goalMin - 5).clamp(5, 180);
//                             });
//                             _h.meditationGoalMin = _goalMin;
//                             _persistHabit();
//                           },
//                           icon: const Icon(Icons.remove, size: 26),
//                           style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                           child: Text('$_goalMin',
//                               style: const TextStyle(
//                                   fontSize: 22, fontWeight: FontWeight.bold)),
//                         ),
//                         IconButton.filledTonal(
//                           onPressed: () {
//                             setState(() {
//                               _goalMin = (_goalMin + 5).clamp(5, 180);
//                             });
//                             _h.meditationGoalMin = _goalMin;
//                             _persistHabit();
//                           },
//                           icon: const Icon(Icons.add, size: 26),
//                           style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // REMINDERS (Daily + One-off)
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Reminders', style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     Text('Daily times (repeat every day)',
//                         style: Theme.of(context).textTheme.titleMedium),
//                     const SizedBox(height: 6),
//                     if (_dailyTimes.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 6),
//                         child: Text('No daily times yet.'),
//                       ),
//                     ...List.generate(_dailyTimes.length, (i) {
//                       final t = _dailyTimes[i];
//                       return Card(
//                         child: ListTile(
//                           leading: const Icon(Icons.schedule),
//                           title: Text(Habit.fmt(t)),
//                           trailing: Wrap(
//                             spacing: 8,
//                             children: [
//                               IconButton(
//                                 onPressed: () => _editDailyTime(i),
//                                 icon: const Icon(Icons.edit_outlined),
//                               ),
//                               IconButton(
//                                 onPressed: () => _removeDailyTime(i),
//                                 icon: const Icon(Icons.delete_outline),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     }),
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: OutlinedButton.icon(
//                         onPressed: _addDailyTime,
//                         icon: const Icon(Icons.add),
//                         label: const Text('Add daily time'),
//                       ),
//                     ),
//                     const Divider(height: 28),

//                     Text('One-time reminders (specific date & time)',
//                         style: Theme.of(context).textTheme.titleMedium),
//                     const SizedBox(height: 6),
//                     if (_oneOffReminders.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 6),
//                         child: Text('No one-time reminders yet.'),
//                       ),
//                     ..._oneOffReminders.map((dt) => Card(
//                           child: ListTile(
//                             leading: const Icon(Icons.event_available),
//                             title: Text(_prettyDateTime(dt)),
//                             subtitle: const Text('This will ring once.'),
//                           ),
//                         )),
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: OutlinedButton.icon(
//                         onPressed: _addOneOffReminder,
//                         icon: const Icon(Icons.event),
//                         label: const Text('Add one-time reminder'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             if (_loadingTracks)
//               const Padding(
//                 padding: EdgeInsets.all(12.0),
//                 child: Center(child: CircularProgressIndicator()),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSnack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
//     );
//   }
// }

// // ======== Big action button (responsive) ========
// class _BigActionButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback? onTap;

//   const _BigActionButton({
//     required this.icon,
//     required this.label,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ConstrainedBox(
//       constraints: const BoxConstraints(minWidth: 140, maxWidth: 200, minHeight: 56),
//       child: ElevatedButton.icon(
//         onPressed: onTap,
//         icon: Icon(icon, size: 28),
//         label: Text(
//           label,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//         ),
//         style: ElevatedButton.styleFrom(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         ),
//       ),
//     );
//   }
// }

// // ======== API track model ========
// class _MedApiTrack {
//   final int id;
//   final String type; // "audio"
//   final String name;
//   final String url;  // absolute url
//   final int? sizeBytes;
//   final DateTime? created;

//   _MedApiTrack({
//     required this.id,
//     required this.type,
//     required this.name,
//     required this.url,
//     this.sizeBytes,
//     this.created,
//   });

//   factory _MedApiTrack.fromJson(Map<String, dynamic> j, String base) {
//     String u = (j['url'] ?? '').toString();
//     if (u.startsWith('/')) u = '$base$u'; // prefix host if API returned "/media/.."
//     DateTime? c;
//     try { c = j['created'] != null ? DateTime.parse(j['created']) : null; } catch (_) {}
//     return _MedApiTrack(
//       id: (j['id'] ?? 0) is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
//       type: (j['type'] ?? '').toString(),
//       name: (j['name'] ?? 'Meditation Audio').toString(),
//       url: u,
//       sizeBytes: j['size_bytes'] is int
//           ? j['size_bytes'] as int
//           : int.tryParse('${j['size_bytes']}'),
//       created: c,
//     );
//   }
// }






// // lib/screens/meditation_screen.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';

// // Models / storage
// import '../models/habit.dart';
// import '../services/storage_service.dart';

// // Audio
// import 'package:audio_session/audio_session.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:just_audio_background/just_audio_background.dart';

// // Network
// import 'package:http/http.dart' as http;

// // Notifications
// import '../services/notification_service.dart';

// class MeditationScreen extends StatefulWidget {
//   final Habit habit; // category == HabitCategory.meditation
//   const MeditationScreen({super.key, required this.habit});

//   @override
//   State<MeditationScreen> createState() => _MeditationScreenState();
// }

// class _MeditationScreenState extends State<MeditationScreen> {
//   // ======== API CONFIG ========
//   static const String _apiBase = 'https://aswiniverma.pythonanywhere.com';
//   static const String _audioListPath = '/api/list/audio';

//   final _storage = StorageService();

//   // Habit
//   late Habit _h;

//   // Progress / timer
//   Timer? _timer;
//   int _elapsedSec = 0;
//   bool _running = false;
//   int _goalMin = 10;

//   // Reminders
//   final List<TimeOfDay> _dailyTimes = [];
//   final List<DateTime> _oneOffReminders = []; // one-time alarms (in-app only)

//   // Audio
//   late final AudioPlayer _player;
//   List<_MedApiTrack> _tracks = [];
//   bool _loadingTracks = true;
//   int? _currentIndex; // selected MP3

//   @override
//   void initState() {
//     super.initState();
//     _h = widget.habit;
//     _ensureToday();
//     _goalMin = _h.meditationGoalMin ?? 10;

//     // Load daily times from habit
//     if (_h.reminderTimes.isNotEmpty) {
//       _dailyTimes.addAll(_h.reminderTimes.map(Habit.parseHHmm));
//     } else {
//       // seed two easy defaults
//       _dailyTimes.addAll(const [
//         TimeOfDay(hour: 6, minute: 30),
//         TimeOfDay(hour: 20, minute: 0),
//       ]);
//       _saveDailyTimes(); // persist + schedule
//     }

//     _setupAudio().then((_) => _loadTracksFromApi());
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _player.dispose();
//     super.dispose();
//   }

//   // ---------- Habit & persistence ----------
//   void _ensureToday() {
//     final now = DateTime.now();
//     final ymd =
//         '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
//     if (_h.meditationLastDate != ymd) {
//       _h.meditationLastDate = ymd;
//       _h.meditationTodayMin = 0;
//     }
//   }

//   Future<void> _persistHabit() async {
//     final all = await _storage.loadHabits();
//     final i = all.indexWhere((x) => x.id == _h.id);
//     if (i >= 0) {
//       all[i] = _h;
//       await _storage.saveHabits(all);
//     }
//   }

//   Future<void> _saveDailyTimes() async {
//     _h.reminderTimes = _dailyTimes.map(Habit.fmt).toList();
//     await _persistHabit();

//     if (_h.enabled && _h.reminderTimes.isNotEmpty) {
//       await NotificationService.scheduleMultipleTimes(
//         habitId: _h.id,
//         hhmmList: _h.reminderTimes,
//         title: 'Meditation Reminder',
//         bodyPrefix: 'Time to meditate 🧘',
//       );
//       _showSnack('Daily reminders updated.');
//     }
//   }

//   // ---------- Audio ----------
//   Future<void> _setupAudio() async {
//     _player = AudioPlayer();
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.music());
//   }

//   Future<void> _loadTracksFromApi() async {
//     setState(() => _loadingTracks = true);
//     try {
//       final uri = Uri.parse('$_apiBase$_audioListPath');
//       final resp = await http.get(uri);
//       if (resp.statusCode == 200) {
//         final list = (json.decode(resp.body) as List)
//             .map((e) => _MedApiTrack.fromJson(e as Map<String, dynamic>, _apiBase))
//             .toList();
//         setState(() {
//           _tracks = list;
//           _loadingTracks = false;
//         });
//         if (_tracks.isNotEmpty) {
//           await _selectTrack(0, autoplay: false);
//         }
//       } else {
//         setState(() => _loadingTracks = false);
//         _showSnack('Could not load audio list (${resp.statusCode}).');
//       }
//     } catch (e) {
//       setState(() => _loadingTracks = false);
//       _showSnack('Network error: $e');
//     }
//   }

//   Future<void> _selectTrack(int index, {bool autoplay = true}) async {
//     if (index < 0 || index >= _tracks.length) return;
//     final t = _tracks[index];
//     _currentIndex = index;
//     try {
//       await _player.setAudioSource(
//         AudioSource.uri(
//           Uri.parse(t.url),
//           tag: MediaItem(id: 'med-${t.id}', title: t.name),
//         ),
//         preload: true,
//       );
//       if (autoplay) await _player.play();
//       setState(() {});
//     } catch (_) {
//       _showSnack('Unable to play "${t.name}".');
//     }
//   }

//   // ---------- Timer ----------
//   void _toggleTimerAndAudio() async {
//     if (_currentIndex == null) {
//       _showSnack('Choose a sound first.');
//       return;
//     }
//     if (_running) {
//       _timer?.cancel();
//       _running = false;
//       await _player.pause();
//     } else {
//       _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//         setState(() => _elapsedSec++);
//       });
//       _running = true;
//       if (!_player.playing) {
//         await _player.play();
//       }
//     }
//     setState(() {});
//   }

//   Future<void> _saveSession() async {
//     _timer?.cancel();
//     _running = false;
//     await _player.stop();

//     final addMin = (_elapsedSec / 60).floor();
//     if (addMin > 0) {
//       _ensureToday();
//       _h.meditationTodayMin = (_h.meditationTodayMin ?? 0) + addMin;
//       await _persistHabit();
//       _showSnack('Saved $addMin minute(s).');
//     }
//     setState(() => _elapsedSec = 0);
//   }

//   String _fmtClock(int sec) {
//     final m = (sec ~/ 60).toString().padLeft(2, '0');
//     final s = (sec % 60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   // ---------- Reminders UI Actions ----------
//   Future<void> _addDailyTime() async {
//     final t = await showTimePicker(
//       context: context,
//       initialTime: const TimeOfDay(hour: 7, minute: 0),
//     );
//     if (t == null) return;
//     setState(() => _dailyTimes.add(t));
//     await _saveDailyTimes();
//   }

//   Future<void> _editDailyTime(int i) async {
//     final t = await showTimePicker(
//       context: context,
//       initialTime: _dailyTimes[i],
//     );
//     if (t == null) return;
//     setState(() => _dailyTimes[i] = t);
//     await _saveDailyTimes();
//   }

//   Future<void> _removeDailyTime(int i) async {
//     setState(() => _dailyTimes.removeAt(i));
//     await _saveDailyTimes();
//   }

//   Future<void> _addOneOffReminder() async {
//     final now = DateTime.now();
//     final date = await showDatePicker(
//       context: context,
//       initialDate: now.add(const Duration(days: 1)),
//       firstDate: now,
//       lastDate: now.add(const Duration(days: 365)),
//     );
//     if (date == null) return;

//     final time = await showTimePicker(
//       context: context,
//       initialTime: const TimeOfDay(hour: 7, minute: 0),
//     );
//     if (time == null) return;

//     final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
//     _oneOffReminders.add(dt);

//     // Use a stable unique id for the alarm
//     final alarmId = _uniqueAlarmId(dt);
//     await NotificationService.scheduleExactWithAlarmManager(
//       alarmId: alarmId,
//       when: dt,
//       title: 'Meditation Reminder',
//       body: 'One-time reminder 🧘',
//     );
//     if (mounted) setState(() {});
//     _showSnack('One-time reminder set for ${_prettyDateTime(dt)}');
//   }

//   int _uniqueAlarmId(DateTime dt) {
//     // combine habit id and timestamp for a stable unique int
//     final base = _h.id.hashCode & 0x7fffffff;
//     return base ^ dt.millisecondsSinceEpoch.hashCode;
//   }

//   String _prettyDateTime(DateTime dt) {
//     final hh = dt.hour.toString().padLeft(2, '0');
//     final mm = dt.minute.toString().padLeft(2, '0');
//     return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hh:$mm';
//   }

//   // ---------- Track picker ----------
//   Future<void> _openTrackPicker() async {
//     if (_loadingTracks) return;
//     await showModalBottomSheet(
//       context: context,
//       useSafeArea: true,
//       showDragHandle: true,
//       builder: (ctx) {
//         return Padding(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(children: [
//                 const Text('Choose Meditation Sound',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                 const Spacer(),
//                 IconButton(
//                   tooltip: 'Refresh',
//                   iconSize: 28,
//                   onPressed: () async {
//                     Navigator.pop(ctx);
//                     await _loadTracksFromApi();
//                   },
//                   icon: const Icon(Icons.refresh),
//                 ),
//               ]),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: _tracks.isEmpty
//                     ? const Center(
//                         child: Text(
//                           'No audio found.\nUpload from backend.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(fontSize: 16),
//                         ),
//                       )
//                     : ListView.separated(
//                         itemCount: _tracks.length,
//                         separatorBuilder: (_, __) => const SizedBox(height: 8),
//                         itemBuilder: (_, i) {
//                           final t = _tracks[i];
//                           final selected = _currentIndex == i;
//                           return InkWell(
//                             onTap: () async {
//                               await _selectTrack(i, autoplay: true);
//                               if (mounted) Navigator.pop(ctx);
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.all(14),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(14),
//                                 color: selected
//                                     ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
//                                     : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     selected ? Icons.radio_button_checked : Icons.radio_button_off,
//                                     size: 26,
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Text(
//                                       t.name,
//                                       style: const TextStyle(
//                                         fontSize: 18, fontWeight: FontWeight.w600),
//                                     ),
//                                   ),
//                                   IconButton(
//                                     tooltip: 'Play',
//                                     onPressed: () async {
//                                       await _selectTrack(i, autoplay: true);
//                                       if (mounted) Navigator.pop(ctx);
//                                     },
//                                     icon: const Icon(Icons.play_arrow, size: 28),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ---------- UI ----------
//   @override
//   Widget build(BuildContext context) {
//     final today = _h.meditationTodayMin ?? 0;
//     final goal = _goalMin;
//     final progress = (today / (goal == 0 ? 1 : goal)).clamp(0, 1.0);

//     final nowPlaying = (_currentIndex != null && _currentIndex! < _tracks.length)
//         ? _tracks[_currentIndex!].name
//         : 'No sound selected';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Meditation'),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             // NOW PLAYING + BIG CONTROLS
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   children: [
//                     Text('Now Playing', style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 6),
//                     Text(
//                       nowPlaying,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _fmtClock(_elapsedSec),
//                       style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         _BigActionButton(
//                           icon: Icons.library_music,
//                           label: 'Choose Sound',
//                           onTap: _openTrackPicker,
//                         ),
//                         const SizedBox(width: 16),
//                         _BigActionButton(
//                           icon: (_player.playing && _running) ? Icons.pause : Icons.play_arrow,
//                           label: (_player.playing && _running) ? 'Pause' : 'Play',
//                           onTap: _toggleTimerAndAudio,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     FilledButton.icon(
//                       onPressed: _elapsedSec == 0 ? null : _saveSession,
//                       icon: const Icon(Icons.save),
//                       label: const Text('Save Minutes'),
//                       style: FilledButton.styleFrom(
//                         minimumSize: const Size(240, 48),
//                         textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // TODAY PROGRESS + GOAL STEPPER
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   children: [
//                     Text('Today\'s Progress', style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     LinearProgressIndicator(value: progress as double?),
//                     const SizedBox(height: 8),
//                     Text('$today / $goal min', style: const TextStyle(fontSize: 16)),
//                     const Divider(height: 24),
//                     Row(
//                       children: [
//                         const Expanded(
//                           child: Text(
//                             'Daily Goal (min)',
//                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                           ),
//                         ),
//                         IconButton.filledTonal(
//                           onPressed: () {
//                             setState(() {
//                               _goalMin = (_goalMin - 5).clamp(5, 180);
//                             });
//                             _h.meditationGoalMin = _goalMin;
//                             _persistHabit();
//                           },
//                           icon: const Icon(Icons.remove, size: 26),
//                           style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                           child: Text('$_goalMin',
//                               style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//                         ),
//                         IconButton.filledTonal(
//                           onPressed: () {
//                             setState(() {
//                               _goalMin = (_goalMin + 5).clamp(5, 180);
//                             });
//                             _h.meditationGoalMin = _goalMin;
//                             _persistHabit();
//                           },
//                           icon: const Icon(Icons.add, size: 26),
//                           style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // REMINDERS (Daily + One-off)
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Reminders', style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     Text('Daily times (repeat every day)',
//                         style: Theme.of(context).textTheme.titleMedium),
//                     const SizedBox(height: 6),
//                     if (_dailyTimes.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 6),
//                         child: Text('No daily times yet.'),
//                       ),
//                     ...List.generate(_dailyTimes.length, (i) {
//                       final t = _dailyTimes[i];
//                       return Card(
//                         child: ListTile(
//                           leading: const Icon(Icons.schedule),
//                           title: Text(Habit.fmt(t)),
//                           trailing: Wrap(
//                             spacing: 8,
//                             children: [
//                               IconButton(
//                                 onPressed: () => _editDailyTime(i),
//                                 icon: const Icon(Icons.edit_outlined),
//                               ),
//                               IconButton(
//                                 onPressed: () => _removeDailyTime(i),
//                                 icon: const Icon(Icons.delete_outline),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     }),
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: OutlinedButton.icon(
//                         onPressed: _addDailyTime,
//                         icon: const Icon(Icons.add),
//                         label: const Text('Add daily time'),
//                       ),
//                     ),
//                     const Divider(height: 28),

//                     Text('One-time reminders (specific date & time)',
//                         style: Theme.of(context).textTheme.titleMedium),
//                     const SizedBox(height: 6),
//                     if (_oneOffReminders.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 6),
//                         child: Text('No one-time reminders yet.'),
//                       ),
//                     ..._oneOffReminders.map((dt) => Card(
//                           child: ListTile(
//                             leading: const Icon(Icons.event_available),
//                             title: Text(_prettyDateTime(dt)),
//                             subtitle: const Text('This will ring once.'),
//                           ),
//                         )),
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: OutlinedButton.icon(
//                         onPressed: _addOneOffReminder,
//                         icon: const Icon(Icons.event),
//                         label: const Text('Add one-time reminder'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             if (_loadingTracks)
//               const Padding(
//                 padding: EdgeInsets.all(12.0),
//                 child: Center(child: CircularProgressIndicator()),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSnack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
//     );
//   }
// }

// // ======== Big action button (accessible) ========
// class _BigActionButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback? onTap;

//   const _BigActionButton({
//     required this.icon,
//     required this.label,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final enabled = onTap != null;
//     return SizedBox(
//       width: 150,
//       height: 64,
//       child: ElevatedButton.icon(
//         onPressed: onTap,
//         icon: Icon(icon, size: 30),
//         label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
//         style: ElevatedButton.styleFrom(
//           disabledBackgroundColor: Theme.of(context).disabledColor.withOpacity(0.3),
//           disabledForegroundColor: Colors.white,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         ),
//       ),
//     );
//   }
// }

// // ======== API track model ========
// class _MedApiTrack {
//   final int id;
//   final String type; // "audio"
//   final String name;
//   final String url;  // absolute url
//   final int? sizeBytes;
//   final DateTime? created;

//   _MedApiTrack({
//     required this.id,
//     required this.type,
//     required this.name,
//     required this.url,
//     this.sizeBytes,
//     this.created,
//   });

//   factory _MedApiTrack.fromJson(Map<String, dynamic> j, String base) {
//     String u = (j['url'] ?? '').toString();
//     if (u.startsWith('/')) u = '$base$u'; // prefix host if API returned "/media/.."
//     DateTime? c;
//     try { c = j['created'] != null ? DateTime.parse(j['created']) : null; } catch (_) {}
//     return _MedApiTrack(
//       id: (j['id'] ?? 0) is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
//       type: (j['type'] ?? '').toString(),
//       name: (j['name'] ?? 'Meditation Audio').toString(),
//       url: u,
//       sizeBytes: j['size_bytes'] is int
//           ? j['size_bytes'] as int
//           : int.tryParse('${j['size_bytes']}'),
//       created: c,
//     );
//   }
// }





// // lib/screens/meditation_screen.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';

// // App models/services
// import '../models/habit.dart';
// import '../services/storage_service.dart';

// // Audio
// import 'package:audio_session/audio_session.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:just_audio_background/just_audio_background.dart';

// // Network
// import 'package:http/http.dart' as http;

// class MeditationScreen extends StatefulWidget {
//   final Habit habit; // HabitCategory.meditation
//   const MeditationScreen({super.key, required this.habit});

//   @override
//   State<MeditationScreen> createState() => _MeditationScreenState();
// }

// class _MeditationScreenState extends State<MeditationScreen> {
//   // ======== SIMPLE CONFIG ========
//   static const String _apiBase = 'https://aswiniverma.pythonanywhere.com';
//   static const String _audioListPath = '/api/list/audio';

//   final _storage = StorageService();

//   // Habit / day state
//   late Habit _h;
//   Timer? _timer;
//   int _elapsedSec = 0;
//   bool _running = false;

//   // Goal (simple stepper)
//   int _goalMin = 10;

//   // Audio
//   late final AudioPlayer _player;
//   List<_MedApiTrack> _tracks = [];
//   int? _currentIndex; // selected/playing index
//   bool _loadingTracks = true;

//   @override
//   void initState() {
//     super.initState();
//     _h = widget.habit;
//     _ensureToday();
//     _goalMin = _h.meditationGoalMin ?? 10;

//     _setupAudio().then((_) => _loadTracksFromApi());
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _player.dispose();
//     super.dispose();
//   }

//   // ---------- Persistence ----------
//   void _ensureToday() {
//     final now = DateTime.now();
//     final ymd =
//         '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
//     if (_h.meditationLastDate != ymd) {
//       _h.meditationLastDate = ymd;
//       _h.meditationTodayMin = 0;
//     }
//   }

//   Future<void> _saveHabit() async {
//     _h.meditationGoalMin = _goalMin;
//     final all = await _storage.loadHabits();
//     final i = all.indexWhere((x) => x.id == _h.id);
//     if (i >= 0) {
//       all[i] = _h;
//       await _storage.saveHabits(all);
//     }
//   }

//   // ---------- Audio ----------
//   Future<void> _setupAudio() async {
//     _player = AudioPlayer();
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.music());
//   }

//   Future<void> _loadTracksFromApi() async {
//     setState(() => _loadingTracks = true);
//     try {
//       final uri = Uri.parse('$_apiBase$_audioListPath');
//       final resp = await http.get(uri);
//       if (resp.statusCode == 200) {
//         final list = (json.decode(resp.body) as List)
//             .map((e) => _MedApiTrack.fromJson(e as Map<String, dynamic>, _apiBase))
//             .toList();
//         setState(() {
//           _tracks = list;
//           _loadingTracks = false;
//         });

//         // Auto-select first track
//         if (_tracks.isNotEmpty) {
//           await _selectTrack(0, autoplay: false);
//         }
//       } else {
//         setState(() => _loadingTracks = false);
//         _showSnack('Could not load audio list (${resp.statusCode}).');
//       }
//     } catch (e) {
//       setState(() => _loadingTracks = false);
//       _showSnack('Network error: $e');
//     }
//   }

//   Future<void> _selectTrack(int index, {bool autoplay = true}) async {
//     if (index < 0 || index >= _tracks.length) return;
//     final t = _tracks[index];
//     _currentIndex = index;
//     try {
//       await _player.setAudioSource(
//         AudioSource.uri(
//           Uri.parse(t.url),
//           tag: MediaItem(id: 'med-${t.id}', title: t.name),
//         ),
//         preload: true,
//       );
//       if (autoplay) await _player.play();
//       setState(() {});
//     } catch (e) {
//       _showSnack('Unable to play "${t.name}".');
//     }
//   }

//   // ---------- Timer ----------
//   void _toggleTimerAndAudio() async {
//     if (_running) {
//       _timer?.cancel();
//       _running = false;
//       await _player.pause();
//     } else {
//       _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//         setState(() => _elapsedSec++);
//       });
//       _running = true;
//       if (!_player.playing && _currentIndex != null) {
//         await _player.play();
//       }
//     }
//     setState(() {});
//   }

//   Future<void> _saveSession() async {
//     _timer?.cancel();
//     _running = false;
//     await _player.stop();

//     final addMin = (_elapsedSec / 60).floor();
//     if (addMin > 0) {
//       _ensureToday();
//       _h.meditationTodayMin = (_h.meditationTodayMin ?? 0) + addMin;
//       await _saveHabit();
//       _showSnack('Saved $addMin minute(s).');
//     }
//     setState(() => _elapsedSec = 0);
//   }

//   String _fmtClock(int sec) {
//     final m = (sec ~/ 60).toString().padLeft(2, '0');
//     final s = (sec % 60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   // ---------- Picker ----------
//   Future<void> _openPicker() async {
//     if (_loadingTracks) return;
//     await showModalBottomSheet(
//       context: context,
//       useSafeArea: true,
//       showDragHandle: true,
//       builder: (ctx) {
//         return Padding(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(children: [
//                 const Text('Choose a Sound',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                 const Spacer(),
//                 IconButton(
//                   tooltip: 'Refresh',
//                   iconSize: 28,
//                   onPressed: () async {
//                     Navigator.pop(ctx);
//                     await _loadTracksFromApi();
//                   },
//                   icon: const Icon(Icons.refresh),
//                 ),
//               ]),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: _tracks.isEmpty
//                     ? const Center(
//                         child: Text(
//                           'No audio found.\nUpload from backend.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(fontSize: 16),
//                         ),
//                       )
//                     : ListView.separated(
//                         itemCount: _tracks.length,
//                         separatorBuilder: (_, __) => const SizedBox(height: 8),
//                         itemBuilder: (_, i) {
//                           final t = _tracks[i];
//                           final selected = _currentIndex == i;
//                           return InkWell(
//                             onTap: () async {
//                               await _selectTrack(i, autoplay: true);
//                               if (mounted) Navigator.pop(ctx);
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.all(14),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(14),
//                                 color: selected
//                                     ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
//                                     : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     selected ? Icons.radio_button_checked : Icons.radio_button_off,
//                                     size: 28,
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Text(
//                                       t.name,
//                                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   IconButton(
//                                     tooltip: 'Preview',
//                                     onPressed: () async {
//                                       await _selectTrack(i, autoplay: true);
//                                       if (mounted) Navigator.pop(ctx);
//                                     },
//                                     icon: const Icon(Icons.play_arrow, size: 30),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ---------- UI ----------
//   @override
//   Widget build(BuildContext context) {
//     final today = _h.meditationTodayMin ?? 0;
//     final goal = _goalMin;
//     final progress = (today / (goal == 0 ? 1 : goal)).clamp(0, 1.0);

//     final nowPlaying = (_currentIndex != null && _currentIndex! < _tracks.length)
//         ? _tracks[_currentIndex!].name
//         : 'No sound selected';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Meditation'),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             // NOW PLAYING + BIG CONTROLS
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   children: [
//                     Text('Now Playing',
//                         style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 6),
//                     Text(
//                       nowPlaying,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _fmtClock(_elapsedSec),
//                       style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),
//                     // LARGE BUTTON ROW
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         // Choose
//                         _BigActionButton(
//                           icon: Icons.library_music,
//                           label: 'Choose Sound',
//                           onTap: _openPicker,
//                         ),
//                         const SizedBox(width: 16),
//                         // Play/Pause
//                         _BigActionButton(
//                           icon: (_player.playing && _running) ? Icons.pause : Icons.play_arrow,
//                           label: (_player.playing && _running) ? 'Pause' : 'Play',
//                           onTap: _currentIndex == null
//                               ? null
//                               : _toggleTimerAndAudio,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     // Save session
//                     FilledButton.icon(
//                       onPressed: _elapsedSec == 0 ? null : _saveSession,
//                       icon: const Icon(Icons.save),
//                       label: const Text('Save Minutes'),
//                       style: FilledButton.styleFrom(
//                         minimumSize: const Size(240, 48),
//                         textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // TODAY PROGRESS + SIMPLE GOAL STEPPER
//             Card(
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//                 child: Column(
//                   children: [
//                     Text('Today\'s Progress',
//                         style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     LinearProgressIndicator(value: progress as double?),
//                     const SizedBox(height: 8),
//                     Text('$today / $goal min', style: const TextStyle(fontSize: 16)),
//                     const Divider(height: 24),
//                     Row(
//                       children: [
//                         const Expanded(
//                           child: Text(
//                             'Daily Goal (min)',
//                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                           ),
//                         ),
//                         IconButton.filledTonal(
//                           onPressed: () {
//                             setState(() {
//                               _goalMin = (_goalMin - 5).clamp(5, 180);
//                             });
//                             _saveHabit();
//                           },
//                           icon: const Icon(Icons.remove, size: 26),
//                           style: IconButton.styleFrom(
//                             fixedSize: const Size(52, 52),
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                           child: Text('$_goalMin',
//                               style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//                         ),
//                         IconButton.filledTonal(
//                           onPressed: () {
//                             setState(() {
//                               _goalMin = (_goalMin + 5).clamp(5, 180);
//                             });
//                             _saveHabit();
//                           },
//                           icon: const Icon(Icons.add, size: 26),
//                           style: IconButton.styleFrom(
//                             fixedSize: const Size(52, 52),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 12),
//             if (_loadingTracks)
//               const Center(
//                 child: Padding(
//                   padding: EdgeInsets.all(12.0),
//                   child: CircularProgressIndicator(),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSnack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
//     );
//     }
// }

// // ======== Simple big button widget ========
// class _BigActionButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback? onTap;

//   const _BigActionButton({
//     required this.icon,
//     required this.label,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final enabled = onTap != null;
//     return SizedBox(
//       width: 150,
//       height: 64,
//       child: ElevatedButton.icon(
//         onPressed: onTap,
//         icon: Icon(icon, size: 30),
//         label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
//         style: ElevatedButton.styleFrom(
//           disabledBackgroundColor: Theme.of(context).disabledColor.withOpacity(0.3),
//           disabledForegroundColor: Colors.white,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         ),
//       ),
//     );
//   }
// }

// // ======== API track model ========
// class _MedApiTrack {
//   final int id;
//   final String type; // "audio"
//   final String name;
//   final String url;  // absolute url
//   final int? sizeBytes;
//   final DateTime? created;

//   _MedApiTrack({
//     required this.id,
//     required this.type,
//     required this.name,
//     required this.url,
//     this.sizeBytes,
//     this.created,
//   });

//   factory _MedApiTrack.fromJson(Map<String, dynamic> j, String base) {
//     String u = (j['url'] ?? '').toString();
//     if (u.startsWith('/')) u = '$base$u';
//     DateTime? c;
//     try {
//       c = j['created'] != null ? DateTime.parse(j['created']) : null;
//     } catch (_) {}
//     return _MedApiTrack(
//       id: (j['id'] ?? 0) is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
//       type: (j['type'] ?? '').toString(),
//       name: (j['name'] ?? 'Meditation Audio').toString(),
//       url: u,
//       sizeBytes: j['size_bytes'] is int
//           ? j['size_bytes'] as int
//           : int.tryParse('${j['size_bytes']}'),
//       created: c,
//     );
//   }
// }






// // lib/screens/meditation_screen.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';

// // App models/services
// import '../models/habit.dart';
// import '../services/storage_service.dart';
// import '../services/notification_service.dart';

// // Audio
// import 'package:audio_session/audio_session.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:just_audio_background/just_audio_background.dart';

// // Network
// import 'package:http/http.dart' as http;

// class MeditationScreen extends StatefulWidget {
//   final Habit habit; // category == HabitCategory.meditation
//   const MeditationScreen({super.key, required this.habit});

//   @override
//   State<MeditationScreen> createState() => _MeditationScreenState();
// }

// class _MeditationScreenState extends State<MeditationScreen> {
//   // ======== CONFIG ========
//   static const String _apiBase = 'https://aswiniverma.pythonanywhere.com';
//   static const String _audioListPath = '/api/list/audio';

//   final _storage = StorageService();

//   // -------- Model / state --------
//   late Habit _h;
//   late TextEditingController _goalCtrl;
//   final List<TimeOfDay> _times = [];

//   // Timer
//   Timer? _timer;
//   int _elapsedSec = 0;
//   bool _running = false;

//   // Audio
//   AudioPlayer? _player;
//   String? _mp3Url;

//   // API tracks
//   List<_MedApiTrack> _tracks = [];
//   int? _currentTrack; // index into _tracks

//   @override
//   void initState() {
//     super.initState();
//     _h = widget.habit;
//     _ensureToday();

//     _goalCtrl =
//         TextEditingController(text: (_h.meditationGoalMin ?? 10).toString());

//     // Seed default reminder times if empty (morning + evening)
//     if (_h.reminderTimes.isEmpty) {
//       _times.addAll(const [
//         TimeOfDay(hour: 6, minute: 30),
//         TimeOfDay(hour: 20, minute: 0),
//       ]);
//       _h.reminderTimes = _times.map(Habit.fmt).toList();
//       _saveAndSchedule();
//     } else {
//       _times.addAll(_h.reminderTimes.map(Habit.parseHHmm));
//     }

//     _setupAudio();
//     _loadTracksFromApi(); // <— fetch your Django list
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _goalCtrl.dispose();
//     _player?.dispose();
//     super.dispose();
//   }

//   // -------- Persistence / scheduling --------

//   void _ensureToday() {
//     final today = DateTime.now();
//     final ymd =
//         '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
//     if (_h.meditationLastDate != ymd) {
//       _h.meditationLastDate = ymd;
//       _h.meditationTodayMin = 0;
//     }
//   }

//   Future<void> _persist() async {
//     final all = await _storage.loadHabits();
//     final idx = all.indexWhere((x) => x.id == _h.id);
//     if (idx >= 0) {
//       all[idx] = _h;
//       await _storage.saveHabits(all);
//     }
//   }

//   Future<void> _saveAndSchedule() async {
//     _h.reminderTimes = _times.map(Habit.fmt).toList();
//     await _persist();

//     if (_h.enabled) {
//       if (_h.reminderTimes.isNotEmpty) {
//         await NotificationService.scheduleMultipleTimes(
//           habitId: _h.id,
//           hhmmList: _h.reminderTimes,
//           title: 'Meditation Reminder',
//           bodyPrefix: 'Time to meditate 🧘',
//         );
//       } else {
//         final when = NotificationService.nextOccurrence(
//             _h.reminderHour, _h.reminderMinute);
//         await NotificationService.scheduleExactWithAlarmManager(
//           alarmId: _h.id.hashCode & 0x7fffffff,
//           when: when,
//           title: 'Meditation Reminder',
//           body: 'Time to meditate 🧘',
//         );
//       }
//     }
//   }

//   // -------- Timer controls --------

//   void _startPause() async {
//     if (_running) {
//       _timer?.cancel();
//       setState(() => _running = false);
//       await _player?.pause();
//     } else {
//       _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//         setState(() => _elapsedSec++);
//       });
//       setState(() => _running = true);

//       if (_player?.playing != true && _mp3Url != null) {
//         await _player?.play();
//       }
//     }
//   }

//   Future<void> _resetSave() async {
//     _timer?.cancel();
//     _running = false;
//     await _player?.stop();

//     final addMin = (_elapsedSec / 60).floor();
//     if (addMin > 0) {
//       _ensureToday();
//       _h.meditationTodayMin = (_h.meditationTodayMin ?? 0) + addMin;
//       await _persist();
//     }
//     setState(() => _elapsedSec = 0);
//   }

//   String _fmtClock(int sec) {
//     final m = (sec ~/ 60).toString().padLeft(2, '0');
//     final s = (sec % 60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   Future<void> _saveGoal() async {
//     final v = int.tryParse(_goalCtrl.text.trim());
//     if (v != null && v > 0) {
//       _h.meditationGoalMin = v;
//       await _persist();
//       setState(() {});
//     }
//   }

//   // -------- Reminder times CRUD --------

//   Future<void> _addTime() async {
//     final t = await showTimePicker(
//         context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
//     if (t != null) {
//       setState(() => _times.add(t));
//       await _saveAndSchedule();
//     }
//   }

//   Future<void> _editTime(int i) async {
//     final t = await showTimePicker(context: context, initialTime: _times[i]);
//     if (t != null) {
//       setState(() => _times[i] = t);
//       await _saveAndSchedule();
//     }
//   }

//   Future<void> _removeTime(int i) async {
//     setState(() => _times.removeAt(i));
//     await _saveAndSchedule();
//   }

//   // -------- Audio setup / tracks (API) --------

//   Future<void> _setupAudio() async {
//     _player = AudioPlayer();
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.music());
//   }

//   Future<void> _loadTracksFromApi() async {
//     try {
//       final uri = Uri.parse('$_apiBase$_audioListPath');
//       final resp = await http.get(uri);
//       if (resp.statusCode == 200) {
//         final jsonList = json.decode(resp.body) as List<dynamic>;
//         final tracks = jsonList.map((e) => _MedApiTrack.fromJson(e as Map<String, dynamic>, _apiBase)).toList();
//         setState(() => _tracks = tracks);

//         if (_tracks.isNotEmpty) {
//           _currentTrack = 0;
//           _mp3Url = _tracks[0].url;
//           await _player?.setAudioSource(
//             AudioSource.uri(
//               Uri.parse(_mp3Url!),
//               tag: MediaItem(
//                 id: 'med-${_tracks[0].id}',
//                 title: _tracks[0].name,
//               ),
//             ),
//             preload: true,
//           );
//         }
//       } else {
//         // Optional: show a snackbar with error
//       }
//     } catch (_) {
//       // Optional: show a snackbar with error
//     }
//   }

//   Future<void> _pickTrackSheet() async {
//     await showModalBottomSheet(
//       context: context,
//       showDragHandle: true,
//       isScrollControlled: true,
//       builder: (ctx) {
//         return SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   children: [
//                     const Text(
//                       'Meditation Sounds',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const Spacer(),
//                     IconButton(
//                       tooltip: 'Refresh',
//                       onPressed: () async {
//                         await _loadTracksFromApi();
//                         if (mounted) setState(() {});
//                       },
//                       icon: const Icon(Icons.refresh),
//                     )
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 if (_tracks.isEmpty)
//                   const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     child: Text(
//                       'No audio yet. Please upload from the backend.',
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 Flexible(
//                   child: ListView.builder(
//                     shrinkWrap: true,
//                     itemCount: _tracks.length,
//                     itemBuilder: (_, i) {
//                       final t = _tracks[i];
//                       return Card(
//                         child: ListTile(
//                           leading: const Icon(Icons.music_note),
//                           title: Text(t.name),
//                           // subtitle: Text(
//                           //   t.url,
//                           //   maxLines: 1,
//                           //   overflow: TextOverflow.ellipsis,
//                           // ),
//                           onTap: () async {
//                             _currentTrack = i;
//                             _mp3Url = t.url;
//                             await _player?.setAudioSource(
//                               AudioSource.uri(
//                                 Uri.parse(_mp3Url!),
//                                 tag: MediaItem(
//                                   id: 'med-${t.id}',
//                                   title: t.name,
//                                 ),
//                               ),
//                               preload: true,
//                             );
//                             await _player?.play();
//                             if (mounted) Navigator.pop(ctx);
//                             setState(() {});
//                           },
//                           trailing: _currentTrack == i && _player?.playing == true
//                               ? const Icon(Icons.equalizer)
//                               : const Icon(Icons.play_arrow),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // -------- UI --------

//   @override
//   Widget build(BuildContext context) {
//     final goal = _h.meditationGoalMin ?? 10;
//     final today = _h.meditationTodayMin ?? 0;
//     final pct = (today / (goal == 0 ? 1 : goal)).clamp(0, 1.0);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Meditation')),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // Progress + Timer
//           Card(
//             elevation: 1,
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   Text('Today', style: Theme.of(context).textTheme.titleLarge),
//                   const SizedBox(height: 8),
//                   LinearProgressIndicator(value: pct as double?),
//                   const SizedBox(height: 8),
//                   Text('$today / $goal min'),
//                   const SizedBox(height: 12),
//                   Text(
//                     _fmtClock(_elapsedSec),
//                     style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   Wrap(
//                     spacing: 12,
//                     runSpacing: 8,
//                     alignment: WrapAlignment.center,
//                     children: [
//                       FilledButton.icon(
//                         onPressed: _startPause,
//                         icon: Icon(_running ? Icons.pause_circle_filled : Icons.play_circle_fill),
//                         label: Text(_running ? 'Pause' : 'Start'),
//                       ),
//                       OutlinedButton.icon(
//                         onPressed: _resetSave,
//                         icon: const Icon(Icons.save_outlined),
//                         label: const Text('Save & Reset'),
//                       ),
//                       FilledButton.icon(
//                         onPressed: _pickTrackSheet,
//                         icon: const Icon(Icons.queue_music),
//                         label: const Text('Choose sound'),
//                       ),
//                       OutlinedButton.icon(
//                         onPressed: () async {
//                           if (_player?.playing == true) {
//                             await _player?.pause();
//                           } else {
//                             if (_mp3Url == null) {
//                               await _pickTrackSheet();
//                             } else {
//                               await _player?.play();
//                             }
//                           }
//                           setState(() {});
//                         },
//                         icon: Icon(_player?.playing == true ? Icons.pause : Icons.play_arrow),
//                         label: Text(_player?.playing == true ? 'Pause' : 'Play'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Goal
//           Card(
//             elevation: 1,
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   const Expanded(child: Text('Daily goal (minutes):')),
//                   SizedBox(
//                     width: 90,
//                     child: TextField(
//                       controller: _goalCtrl,
//                       textAlign: TextAlign.center,
//                       keyboardType: TextInputType.number,
//                       decoration: const InputDecoration(
//                         isDense: true,
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   FilledButton(onPressed: _saveGoal, child: const Text('Save')),
//                 ],
//               ),
//             ),
//           ),

//           // Reminder times
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             child: Text('Reminder times', style: Theme.of(context).textTheme.titleLarge),
//           ),
//           ...List.generate(_times.length, (i) {
//             final t = _times[i];
//             return Card(
//               child: ListTile(
//                 leading: const Icon(Icons.schedule),
//                 title: Text(Habit.fmt(t)),
//                 trailing: Wrap(
//                   spacing: 8,
//                   children: [
//                     IconButton(onPressed: () => _editTime(i), icon: const Icon(Icons.edit_outlined)),
//                     IconButton(onPressed: () => _removeTime(i), icon: const Icon(Icons.delete_outline)),
//                   ],
//                 ),
//               ),
//             );
//           }),
//           Align(
//             alignment: Alignment.centerLeft,
//             child: OutlinedButton.icon(
//               onPressed: _addTime,
//               icon: const Icon(Icons.add),
//               label: const Text('Add time'),
//             ),
//           ),
//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }
// }

// // ======== API track model ========
// class _MedApiTrack {
//   final int id;
//   final String type; // "audio"
//   final String name; // display name
//   final String url;  // absolute url to mp3
//   final int? sizeBytes;
//   final DateTime? created;

//   _MedApiTrack({
//     required this.id,
//     required this.type,
//     required this.name,
//     required this.url,
//     this.sizeBytes,
//     this.created,
//   });

//   factory _MedApiTrack.fromJson(Map<String, dynamic> j, String base) {
//     String u = (j['url'] ?? '').toString();
//     if (u.startsWith('/')) u = '$base$u'; // prefix host if needed
//     DateTime? c;
//     try { c = j['created'] != null ? DateTime.parse(j['created']) : null; } catch (_) {}
//     return _MedApiTrack(
//       id: (j['id'] ?? 0) is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
//       type: (j['type'] ?? '').toString(),
//       name: (j['name'] ?? 'Meditation Audio').toString(),
//       url: u,
//       sizeBytes: j['size_bytes'] is int ? j['size_bytes'] as int : int.tryParse('${j['size_bytes']}'),
//       created: c,
//     );
//   }
// }





// // Flutter Meditation Module — Full API client + list + audio player
// // Paste this file anywhere in your lib/ and import it in your app.
// //
// // QUICK START
// // 1) pubspec.yaml deps:
// //    http: ^1.2.2
// //    just_audio: ^0.9.40
// //    audio_session: ^0.1.21
// //    cached_network_image: ^3.3.1
// // 2) Update `MeditationApiClient.baseUrl` and `tracksEndpoint` below to match your Django API.
// // 3) Use `MeditationPage()` in your Navigator routes.
// // 4) Android: add INTERNET permission to AndroidManifest.xml if missing.
// //    <uses-permission android:name="android.permission.INTERNET"/>
// //
// // EXPECTED JSON (flexible mapping in fromJson handles common variations):
// // [
// //   {
// //     "id": 1,
// //     "title": "Morning Calm",
// //     "subtitle": "10-minute breath focus",
// //     "audio_url": "https://example.com/audio/morning-calm.mp3",
// //     "image_url": "https://example.com/images/morning.jpg",
// //     "duration": 600,
// //     "category": "Breath"
// //   }
// // ]
// // If your field names differ (e.g., "file", "audio", "cover", "thumb", etc.),
// // this module will try to map them. Adjust `fromJson` if needed.

// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:just_audio/just_audio.dart';
// import 'package:audio_session/audio_session.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// // ------------------------------
// // Model
// // ------------------------------
// class MeditationTrack {
//   final String id;
//   final String title;
//   final String? subtitle;
//   final String audioUrl;
//   final String? imageUrl;
//   final Duration? duration;
//   final String? category;

//   MeditationTrack({
//     required this.id,
//     required this.title,
//     required this.audioUrl,
//     this.subtitle,
//     this.imageUrl,
//     this.duration,
//     this.category,
//   });

//   static String? _firstNonEmpty(Map<String, dynamic> j, List<String> keys) {
//     for (final k in keys) {
//       final v = j[k];
//       if (v == null) continue;
//       if (v is String && v.trim().isNotEmpty) return v.trim();
//       if (v is num) return v.toString();
//     }
//     return null;
//   }

//   static Duration? _durationFromAny(Map<String, dynamic> j) {
//     // Supports: seconds (int), duration (int), duration_seconds, length, or ISO 8601 like "PT10M" not parsed here.
//     final secondsStr = _firstNonEmpty(j, [
//       'duration_seconds',
//       'duration',
//       'length',
//     ]);
//     if (secondsStr == null) return null;
//     final s = int.tryParse(secondsStr);
//     if (s != null) return Duration(seconds: s);
//     return null;
//   }

//   factory MeditationTrack.fromJson(Map<String, dynamic> j) {
//     final id = _firstNonEmpty(j, ['id', 'uuid', 'pk', 'slug']) ?? UniqueKey().toString();
//     final title = _firstNonEmpty(j, ['title', 'name', 'track_title']) ?? 'Untitled';
//     final subtitle = _firstNonEmpty(j, ['subtitle', 'description', 'summary']);
//     final audioUrl = _firstNonEmpty(j, ['audio_url', 'audio', 'file', 'url', 'mp3', 'stream']) ?? '';
//     final imageUrl = _firstNonEmpty(j, ['image_url', 'cover', 'thumbnail', 'thumb', 'image']);
//     final category = _firstNonEmpty(j, ['category', 'tag']);
//     final dur = _durationFromAny(j);

//     if (audioUrl.isEmpty) {
//       throw FormatException('Missing audio URL in track JSON');
//     }

//     return MeditationTrack(
//       id: id,
//       title: title,
//       subtitle: subtitle,
//       audioUrl: audioUrl,
//       imageUrl: imageUrl,
//       duration: dur,
//       category: category,
//     );
//   }
// }

// // ------------------------------
// // API Client
// // ------------------------------
// class MeditationApiClient {
//   // TODO: set these to your Django API
//   static String baseUrl = 'https://aswiniverma.pythonanywhere.com';
//   static String tracksEndpoint = '/api/list/audio'; // e.g., DRF viewset list endpoint

//   static Map<String, String> get _headers => {
//         'Accept': 'application/json',
//         'Content-Type': 'application/json',
//       };

//   static Uri _buildUri({String? category, int? page, int? pageSize}) {
//     final qp = <String, String>{};
//     if (category != null && category.isNotEmpty) qp['category'] = category;
//     if (page != null) qp['page'] = '$page';
//     if (pageSize != null) qp['page_size'] = '$pageSize';
//     return Uri.parse('$baseUrl$tracksEndpoint').replace(queryParameters: qp.isEmpty ? null : qp);
//   }

//   /// Fetch list of tracks. Supports both plain-list and DRF paginated format.
//   static Future<List<MeditationTrack>> fetchTracks({String? category, int? page, int? pageSize}) async {
//     final uri = _buildUri(category: category, page: page, pageSize: pageSize);
//     final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 20));

//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw Exception('API ${res.statusCode}: ${res.body}');
//     }

//     final body = jsonDecode(res.body);
//     List dataList;
//     if (body is List) {
//       dataList = body;
//     } else if (body is Map && body['results'] is List) {
//       dataList = body['results'];
//     } else {
//       throw FormatException('Unexpected API shape. Expected list or {"results": [...]}');
//     }

//     return dataList.map<MeditationTrack>((e) => MeditationTrack.fromJson(Map<String, dynamic>.from(e))).toList();
//   }
// }

// // ------------------------------
// // Repository (abstraction point if you add caching)
// // ------------------------------
// class MeditationRepository {
//   Future<List<MeditationTrack>> list({String? category}) => MeditationApiClient.fetchTracks(category: category);
// }

// // ------------------------------
// // Player Controller
// // ------------------------------
// class MeditationPlayerController extends ChangeNotifier {
//   final AudioPlayer _player = AudioPlayer();
//   List<MeditationTrack> _tracks = [];
//   int? _currentIndex;
//   bool _loading = false;

//   List<MeditationTrack> get tracks => _tracks;
//   int? get currentIndex => _currentIndex;
//   bool get isLoading => _loading;
//   bool get isPlaying => _player.playing;
//   Duration get position => _player.position;
//   Duration? get duration => _player.duration;

//   MeditationTrack? get currentTrack =>
//       (_currentIndex != null && _currentIndex! >= 0 && _currentIndex! < _tracks.length) ? _tracks[_currentIndex!] : null;

//   Future<void> initSession() async {
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.music());
//   }

//   Future<void> loadTracks(List<MeditationTrack> tracks, {int startIndex = 0}) async {
//     _loading = true;
//     notifyListeners();
//     _tracks = tracks;
//     _currentIndex = null;

//     // Build playlist
//     final sources = tracks
//         .map((t) => AudioSource.uri(Uri.parse(t.audioUrl), tag: t.title))
//         .toList(growable: false);
//     await _player.setAudioSource(ConcatenatingAudioSource(children: sources));

//     _player.currentIndexStream.listen((i) {
//       _currentIndex = i;
//       notifyListeners();
//     });
//     _player.playerStateStream.listen((_) => notifyListeners());
//     _player.positionStream.listen((_) => notifyListeners());

//     // Start at requested index (will only take effect after setAudioSource)
//     if (startIndex >= 0 && startIndex < tracks.length) {
//       await _player.seek(Duration.zero, index: startIndex);
//     }

//     _loading = false;
//     notifyListeners();
//   }

//   Future<void> playAt(int index) async {
//     if (index < 0 || index >= _tracks.length) return;
//     if (_player.audioSource == null) return;
//     await _player.seek(Duration.zero, index: index);
//     await _player.play();
//   }

//   Future<void> togglePlayPause() async {
//     if (_player.playing) {
//       await _player.pause();
//     } else {
//       await _player.play();
//     }
//   }

//   Future<void> next() => _player.seekToNext();
//   Future<void> previous() => _player.seekToPrevious();
//   Future<void> seek(Duration position) => _player.seek(position);

//   @override
//   Future<void> dispose() async {
//     await _player.dispose();
//     super.dispose();
//   }
// }

// // ------------------------------
// // UI Page
// // ------------------------------
// class MeditationPage extends StatefulWidget {
//   final String? category;
//   const MeditationPage({super.key, this.category});

//   @override
//   State<MeditationPage> createState() => _MeditationPageState();
// }

// class _MeditationPageState extends State<MeditationPage> {
//   final repo = MeditationRepository();
//   final controller = MeditationPlayerController();
//   late Future<List<MeditationTrack>> _future;

//   @override
//   void initState() {
//     super.initState();
//     _future = repo.list(category: widget.category);
//     controller.initSession();
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Meditation'),
//       ),
//       body: FutureBuilder<List<MeditationTrack>>(
//         future: _future,
//         builder: (context, snap) {
//           if (snap.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snap.hasError) {
//             return _ErrorView(error: snap.error.toString(), onRetry: () => setState(() => _future = repo.list(category: widget.category)));
//           }
//           final tracks = snap.data ?? [];
//           if (tracks.isEmpty) {
//             return const Center(child: Text('No tracks found'));
//           }
//           return _TracksWithPlayer(controller: controller, tracks: tracks);
//         },
//       ),
//     );
//   }
// }

// class _TracksWithPlayer extends StatefulWidget {
//   final MeditationPlayerController controller;
//   final List<MeditationTrack> tracks;
//   const _TracksWithPlayer({required this.controller, required this.tracks});

//   @override
//   State<_TracksWithPlayer> createState() => _TracksWithPlayerState();
// }

// class _TracksWithPlayerState extends State<_TracksWithPlayer> {
//   @override
//   void initState() {
//     super.initState();
//     widget.controller.addListener(_onChanged);
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await widget.controller.loadTracks(widget.tracks);
//     });
//   }

//   @override
//   void dispose() {
//     widget.controller.removeListener(_onChanged);
//     super.dispose();
//   }

//   void _onChanged() => setState(() {});

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         ListView.separated(
//           padding: const EdgeInsets.only(bottom: 96),
//           itemBuilder: (context, index) {
//             final t = widget.tracks[index];
//             final isCurrent = widget.controller.currentIndex == index;
//             return ListTile(
//               leading: _Artwork(url: t.imageUrl),
//               title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
//               subtitle: Text(t.subtitle ?? t.category ?? ''),
//               trailing: IconButton(
//                 icon: Icon(isCurrent && widget.controller.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
//                 onPressed: () => widget.controller.playAt(index),
//               ),
//               onTap: () => widget.controller.playAt(index),
//             );
//           },
//           separatorBuilder: (_, __) => const Divider(height: 1),
//           itemCount: widget.tracks.length,
//         ),
//         _MiniPlayerBar(controller: widget.controller),
//       ],
//     );
//   }
// }

// class _Artwork extends StatelessWidget {
//   final String? url;
//   const _Artwork({this.url});

//   @override
//   Widget build(BuildContext context) {
//     final placeholder = Container(
//       width: 56,
//       height: 56,
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surfaceVariant,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: const Icon(Icons.spa_outlined),
//     );

//     if (url == null || url!.isEmpty) return placeholder;

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(8),
//       child: CachedNetworkImage(
//         imageUrl: url!,
//         width: 56,
//         height: 56,
//         fit: BoxFit.cover,
//         placeholder: (_, __) => placeholder,
//         errorWidget: (_, __, ___) => placeholder,
//       ),
//     );
//   }
// }

// class _MiniPlayerBar extends StatelessWidget {
//   final MeditationPlayerController controller;
//   const _MiniPlayerBar({required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     final t = controller.currentTrack;
//     return Positioned(
//       left: 0,
//       right: 0,
//       bottom: 0,
//       child: Material(
//         elevation: 8,
//         color: Theme.of(context).colorScheme.surface,
//         child: SafeArea(
//           top: false,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: Row(
//               children: [
//                 if (t != null) _Artwork(url: t.imageUrl) else const SizedBox(width: 56, height: 56),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         t?.title ?? 'Nothing playing',
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: Theme.of(context).textTheme.bodyLarge,
//                       ),
//                       Text(
//                         t?.subtitle ?? t?.category ?? '',
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.skip_previous),
//                   onPressed: controller.previous,
//                   tooltip: 'Previous',
//                 ),
//                 IconButton(
//                   icon: Icon(controller.isPlaying ? Icons.pause : Icons.play_arrow),
//                   onPressed: controller.togglePlayPause,
//                   tooltip: controller.isPlaying ? 'Pause' : 'Play',
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.skip_next),
//                   onPressed: controller.next,
//                   tooltip: 'Next',
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ErrorView extends StatelessWidget {
//   final String error;
//   final VoidCallback onRetry;
//   const _ErrorView({required this.error, required this.onRetry});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.error_outline, size: 48),
//             const SizedBox(height: 12),
//             Text('Failed to load tracks', style: Theme.of(context).textTheme.titleMedium),
//             const SizedBox(height: 8),
//             Text(error, textAlign: TextAlign.center),
//             const SizedBox(height: 12),
//             ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ------------------------------
// // OPTIONAL: Simple route helper
// // ------------------------------
// class MeditationRoute extends MaterialPageRoute<void> {
//   MeditationRoute({String? category})
//       : super(builder: (_) => MeditationPage(category: category));
// }





// // lib/screens/meditation_screen.dart
// import 'dart:async';
// import 'package:flutter/material.dart';

// // App models/services
// import '../models/habit.dart';
// import '../services/storage_service.dart';
// import '../services/notification_service.dart';

// // Audio
// import 'package:audio_session/audio_session.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:just_audio_background/just_audio_background.dart';

// // Drive helpers
// import 'package:flutter/services.dart';
// import '../utils/drive_link.dart';
// import '../services/track_library.dart';

// class MeditationScreen extends StatefulWidget {
//   final Habit habit; // Meditation habit (category == HabitCategory.meditation)
//   const MeditationScreen({super.key, required this.habit});

//   @override
//   State<MeditationScreen> createState() => _MeditationScreenState();
// }

// class _MeditationScreenState extends State<MeditationScreen> {
//   final _storage = StorageService();

//   // -------- Model / state --------
//   late Habit _h;
//   late TextEditingController _goalCtrl;
//   final List<TimeOfDay> _times = [];

//   // Timer
//   Timer? _timer;
//   int _elapsedSec = 0;
//   bool _running = false;

//   // Audio
//   AudioPlayer? _player;
//   String? _mp3Url;
//   List<MedTrack> _tracks = [];
//   int? _currentTrack; // index into _tracks

//   @override
//   void initState() {
//     super.initState();
//     _h = widget.habit;
//     _ensureToday();

//     _goalCtrl =
//         TextEditingController(text: (_h.meditationGoalMin ?? 10).toString());

//     // Seed default reminder times if empty (morning + evening)
//     if (_h.reminderTimes.isEmpty) {
//       _times.addAll(
//           [const TimeOfDay(hour: 6, minute: 30), const TimeOfDay(hour: 20, minute: 0)]);
//       _h.reminderTimes = _times.map(Habit.fmt).toList();
//       _saveAndSchedule();
//     } else {
//       _times.addAll(_h.reminderTimes.map(Habit.parseHHmm));
//     }

//     _setupAudio();
//     _loadTracks();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _goalCtrl.dispose();
//     _player?.dispose();
//     super.dispose();
//   }

//   // -------- Persistence / scheduling --------

//   void _ensureToday() {
//     final today = DateTime.now();
//     final ymd =
//         '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
//     if (_h.meditationLastDate != ymd) {
//       _h.meditationLastDate = ymd;
//       _h.meditationTodayMin = 0;
//     }
//   }

//   Future<void> _persist() async {
//     final all = await _storage.loadHabits();
//     final idx = all.indexWhere((x) => x.id == _h.id);
//     if (idx >= 0) {
//       all[idx] = _h;
//       await _storage.saveHabits(all);
//     }
//   }

//   Future<void> _saveAndSchedule() async {
//     _h.reminderTimes = _times.map(Habit.fmt).toList();
//     await _persist();

//     if (_h.enabled) {
//       if (_h.reminderTimes.isNotEmpty) {
//         await NotificationService.scheduleMultipleTimes(
//           habitId: _h.id,
//           hhmmList: _h.reminderTimes,
//           title: 'Meditation Reminder',
//           bodyPrefix: 'Time to meditate 🧘',
//         );
//       } else {
//         final when = NotificationService.nextOccurrence(
//             _h.reminderHour, _h.reminderMinute);
//         await NotificationService.scheduleExactWithAlarmManager(
//           alarmId: _h.id.hashCode & 0x7fffffff,
//           when: when,
//           title: 'Meditation Reminder',
//           body: 'Time to meditate 🧘',
//         );
//       }
//     }
//   }

//   // -------- Timer controls --------

//   void _startPause() async {
//     if (_running) {
//       _timer?.cancel();
//       setState(() => _running = false);
//       await _player?.pause();
//     } else {
//       _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//         setState(() => _elapsedSec++);
//       });
//       setState(() => _running = true);

//       if (_player?.playing != true && _mp3Url != null) {
//         await _player?.play();
//       }
//     }
//   }

//   Future<void> _resetSave() async {
//     _timer?.cancel();
//     _running = false;
//     await _player?.stop();

//     final addMin = (_elapsedSec / 60).floor();
//     if (addMin > 0) {
//       _ensureToday();
//       _h.meditationTodayMin = (_h.meditationTodayMin ?? 0) + addMin;
//       await _persist();
//     }
//     setState(() => _elapsedSec = 0);
//   }

//   String _fmtClock(int sec) {
//     final m = (sec ~/ 60).toString().padLeft(2, '0');
//     final s = (sec % 60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   Future<void> _saveGoal() async {
//     final v = int.tryParse(_goalCtrl.text.trim());
//     if (v != null && v > 0) {
//       _h.meditationGoalMin = v;
//       await _persist();
//       setState(() {});
//     }
//   }

//   // -------- Reminder times CRUD --------

//   Future<void> _addTime() async {
//     final t = await showTimePicker(
//         context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
//     if (t != null) {
//       setState(() => _times.add(t));
//       await _saveAndSchedule();
//     }
//   }

//   Future<void> _editTime(int i) async {
//     final t =
//         await showTimePicker(context: context, initialTime: _times[i]);
//     if (t != null) {
//       setState(() => _times[i] = t);
//       await _saveAndSchedule();
//     }
//   }

//   Future<void> _removeTime(int i) async {
//     setState(() => _times.removeAt(i));
//     await _saveAndSchedule();
//   }

//   // -------- Audio setup / tracks --------

//   Future<void> _setupAudio() async {
//     _player = AudioPlayer();
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.music());
//   }

//   Future<void> _loadTracks() async {
//     final list = await TrackLibrary.load();
//     setState(() => _tracks = list);
//     if (_tracks.isNotEmpty) {
//       _currentTrack = 0;
//       _mp3Url = _tracks[0].url;
//       await _player?.setAudioSource(
//         AudioSource.uri(
//           Uri.parse(_mp3Url!),
//           tag: MediaItem(id: 'med-0', title: _tracks[0].title),
//         ),
//         preload: true,
//       );
//     }
//   }

//   Future<void> _pickTrackSheet() async {
//     await showModalBottomSheet(
//       context: context,
//       showDragHandle: true,
//       isScrollControlled: true,
//       builder: (ctx) {
//         return StatefulBuilder(builder: (ctx, setSt) {
//           Future<void> addFromClipboard() async {
//             final data = await Clipboard.getData(Clipboard.kTextPlain);
//             final raw = (data?.text ?? '').trim();
//             if (raw.isEmpty) return;
//             final direct = DriveLink.toDirect(raw);
//             if (direct == null) return;
//             final title = raw.length > 32 ? 'Meditation Audio' : raw;
//             await TrackLibrary.add(MedTrack(title, direct));
//             final list = await TrackLibrary.load();
//             setSt(() => _tracks = list);
//             setState(() => _tracks = list);
//           }

//           Future<void> addManual() async {
//             final titleCtrl = TextEditingController();
//             final linkCtrl = TextEditingController();
//             await showDialog(context: ctx, builder: (_) {
//               return AlertDialog(
//                 title: const Text('Add track'),
//                 content: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: titleCtrl,
//                       decoration: const InputDecoration(labelText: 'Title'),
//                     ),
//                     TextField(
//                       controller: linkCtrl,
//                       decoration: const InputDecoration(
//                         labelText: 'Drive link or file id',
//                       ),
//                     ),
//                   ],
//                 ),
//                 actions: [
//                   TextButton(
//                       onPressed: () => Navigator.pop(ctx),
//                       child: const Text('Cancel')),
//                   FilledButton(
//                     onPressed: () async {
//                       final t = titleCtrl.text.trim().isEmpty
//                           ? 'Meditation Audio'
//                           : titleCtrl.text.trim();
//                       final direct = DriveLink.toDirect(linkCtrl.text.trim());
//                       if (direct != null) {
//                         await TrackLibrary.add(MedTrack(t, direct));
//                         final list = await TrackLibrary.load();
//                         setSt(() => _tracks = list);
//                         setState(() => _tracks = list);
//                       }
//                       // ignore: use_build_context_synchronously
//                       Navigator.pop(ctx);
//                     },
//                     child: const Text('Add'),
//                   ),
//                 ],
//               );
//             });
//           }

//           return SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     children: [
//                       const Text('Meditation Sounds',
//                           style: TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold)),
//                       const Spacer(),
//                       IconButton(
//                           onPressed: addFromClipboard,
//                           tooltip: 'Paste Drive link',
//                           icon: const Icon(Icons.content_paste)),
//                       IconButton(
//                           onPressed: addManual,
//                           tooltip: 'Add manually',
//                           icon: const Icon(Icons.add)),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   if (_tracks.isEmpty)
//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 12),
//                       child: Text(
//                         'No tracks yet.\nPaste a Google Drive link from your folder (Anyone with the link → Viewer).',
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   Flexible(
//                     child: ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: _tracks.length,
//                       itemBuilder: (_, i) {
//                         final t = _tracks[i];
//                         return Card(
//                           child: ListTile(
//                             leading: const Icon(Icons.music_note),
//                             title: Text(t.title),
//                             subtitle: Text(
//                               t.url,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             trailing: IconButton(
//                               icon: const Icon(Icons.delete_outline),
//                               onPressed: () async {
//                                 await TrackLibrary.removeAt(i);
//                                 final list = await TrackLibrary.load();
//                                 setSt(() => _tracks = list);
//                                 setState(() => _tracks = list);
//                               },
//                             ),
//                             onTap: () async {
//                               _currentTrack = i;
//                               _mp3Url = t.url;
//                               await _player?.setAudioSource(
//                                 AudioSource.uri(
//                                   Uri.parse(_mp3Url!),
//                                   tag: MediaItem(
//                                       id: 'med-$i', title: t.title),
//                                 ),
//                                 preload: true,
//                               );
//                               await _player?.play();
//                               if (mounted) Navigator.pop(ctx);
//                               setState(() {});
//                             },
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         });
//       },
//     );
//   }

//   // -------- UI --------

//   @override
//   Widget build(BuildContext context) {
//     final goal = _h.meditationGoalMin ?? 10;
//     final today = _h.meditationTodayMin ?? 0;
//     final pct = (today / (goal == 0 ? 1 : goal)).clamp(0, 1.0);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Meditation')),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // Progress + Timer
//           Card(
//             elevation: 1,
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   Text('Today',
//                       style: Theme.of(context).textTheme.titleLarge),
//                   const SizedBox(height: 8),
//                   LinearProgressIndicator(value: pct as  double?),
//                   const SizedBox(height: 8),
//                   Text('$today / $goal min'),
//                   const SizedBox(height: 12),
//                   Text(
//                     _fmtClock(_elapsedSec),
//                     style: const TextStyle(
//                         fontSize: 36, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   Wrap(
//                     spacing: 12,
//                     runSpacing: 8,
//                     alignment: WrapAlignment.center,
//                     children: [
//                       FilledButton.icon(
//                         onPressed: _startPause,
//                         icon: Icon(_running
//                             ? Icons.pause_circle_filled
//                             : Icons.play_circle_fill),
//                         label: Text(_running ? 'Pause' : 'Start'),
//                       ),
//                       OutlinedButton.icon(
//                         onPressed: _resetSave,
//                         icon: const Icon(Icons.save_outlined),
//                         label: const Text('Save & Reset'),
//                       ),
//                       FilledButton.icon(
//                         onPressed: _pickTrackSheet,
//                         icon: const Icon(Icons.queue_music),
//                         label: const Text('Choose sound'),
//                       ),
//                       OutlinedButton.icon(
//                         onPressed: () async {
//                           if (_player?.playing == true) {
//                             await _player?.pause();
//                           } else {
//                             if (_mp3Url == null) {
//                               await _pickTrackSheet();
//                             } else {
//                               await _player?.play();
//                             }
//                           }
//                           setState(() {});
//                         },
//                         icon: Icon(_player?.playing == true
//                             ? Icons.pause
//                             : Icons.play_arrow),
//                         label: Text(_player?.playing == true ? 'Pause' : 'Play'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Goal
//           Card(
//             elevation: 1,
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   const Expanded(child: Text('Daily goal (minutes):')),
//                   SizedBox(
//                     width: 90,
//                     child: TextField(
//                       controller: _goalCtrl,
//                       textAlign: TextAlign.center,
//                       keyboardType: TextInputType.number,
//                       decoration: const InputDecoration(
//                         isDense: true,
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   FilledButton(onPressed: _saveGoal, child: const Text('Save')),
//                 ],
//               ),
//             ),
//           ),

//           // Reminder times
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             child: Text('Reminder times',
//                 style: Theme.of(context).textTheme.titleLarge),
//           ),
//           ...List.generate(_times.length, (i) {
//             final t = _times[i];
//             return Card(
//               child: ListTile(
//                 leading: const Icon(Icons.schedule),
//                 title: Text(Habit.fmt(t)),
//                 trailing: Wrap(
//                   spacing: 8,
//                   children: [
//                     IconButton(
//                         onPressed: () => _editTime(i),
//                         icon: const Icon(Icons.edit_outlined)),
//                     IconButton(
//                         onPressed: () => _removeTime(i),
//                         icon: const Icon(Icons.delete_outline)),
//                   ],
//                 ),
//               ),
//             );
//           }),
//           Align(
//             alignment: Alignment.centerLeft,
//             child: OutlinedButton.icon(
//               onPressed: _addTime,
//               icon: const Icon(Icons.add),
//               label: const Text('Add time'),
//             ),
//           ),
//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }
// }
