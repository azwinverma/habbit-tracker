// lib/screens/reading_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:habit_tracker_nepali/services/ad_service.dart';
import 'package:habit_tracker_nepali/widgets/ad_banner.dart';

// Models / storage
import '../models/habit.dart';
import '../services/storage_service.dart';

// Notifications
import '../core/reminders/reminder_service.dart';

// Network
import 'package:http/http.dart' as http;

// EPUB reader
import 'package:epub_view/epub_view.dart';

// WebView (fallback for non-EPUB URLs)
import 'package:webview_flutter/webview_flutter.dart';

class ReadingScreen extends StatefulWidget {
  final Habit habit; // category == HabitCategory.reading
  const ReadingScreen({super.key, required this.habit});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  // ======== API CONFIG ========
  static const String _apiBase = 'https://aswiniverma.pythonanywhere.com';
  static const String _ebooksListPath = '/api/list/ebooks';

  final _storage = StorageService();

  // Habit
  late Habit _h;

  // Reminders (staged until user presses Save)
  final List<TimeOfDay> _dailyTimes = [];
  final List<DateTime> _oneOffReminders = [];
  bool _dirtyReminders = false;

  // Books
  List<_BookItem> _books = [];
  bool _loadingBooks = true;
  int? _currentIndex; // selected book

  // Reading session
  int _sessionMin = 25; // default session length (user adjustable)
  Timer? _sessionTimer;
  int _remainSec = 0;
  bool _running = false;

  // Notification ID for session end
  int? _sessionAlarmId;

  // Live countdown for the reader page
  final ValueNotifier<int> _remainVN = ValueNotifier<int>(0);
  bool _readerOpen = false;

  @override
  void initState() {
    super.initState();
    _h = widget.habit;

    if (_h.reminderTimes.isNotEmpty) {
      _dailyTimes.addAll(_h.reminderTimes.map(Habit.parseHHmm));
    } else {
      _dailyTimes.addAll(const [TimeOfDay(hour: 21, minute: 0)]);
      _dirtyReminders = true; // user needs to Save to apply
    }

    _loadBooksFromApi();
  }

  @override
  void dispose() {
    _cancelSessionTimer(andNotification: true);
    super.dispose();
  }

  // ---------- Storage ----------
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

  // ---------- API ----------
  Future<void> _loadBooksFromApi() async {
    setState(() => _loadingBooks = true);
    try {
      final uri = Uri.parse('$_apiBase$_ebooksListPath');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final list = (json.decode(resp.body) as List)
            .map((e) => _BookItem.fromJson(e as Map<String, dynamic>, _apiBase))
            .toList();
        setState(() {
          _books = list;
          _loadingBooks = false;
          if (_books.isNotEmpty && _currentIndex == null) {
            _currentIndex = 0; // preselect first
          }
        });
      } else {
        setState(() => _loadingBooks = false);
        _snack('Could not load books (${resp.statusCode}).');
      }
    } catch (e) {
      setState(() => _loadingBooks = false);
      _snack('Network error: $e');
    }
  }

  // ---------- Reminder save ----------
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
          await InterstitialHelper().showIfAvailable();

  }

  // ---------- Session (Start / Pause / Stop) ----------
  void _startOrPauseSession() async {
    if (_currentIndex == null || _currentIndex! >= _books.length) {
      _snack('Choose a book first.');
      return;
    }

    if (_running) {
      // Pause
      _cancelSessionTimer(andNotification: false);
      setState(() => _running = false);
      return;
    }

    // --- Start session immediately BEFORE navigation ---
    _remainSec = _sessionMin * 60;
    _remainVN.value = _remainSec;

    _sessionTimer?.cancel();


    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
  if (!mounted) return;

  // ✅ integer-safe decrement (no num -> int issues)
  if (_remainSec > 0) {
    _remainSec -= 1;
    _remainVN.value = _remainSec; // updates the Reader AppBar countdown
    if (mounted) setState(() {}); // updates the Reading screen label if visible
  }

  if (_remainSec <= 0) {
    _cancelSessionTimer(andNotification: true);
    _running = false;
    if (mounted) setState(() {});    // reflect stopped state
    if (_readerOpen && context.mounted) {
      Navigator.of(context).maybePop();
    }
    _snack('Reading session finished.');
  }
});

    final endAt = DateTime.now().add(Duration(seconds: _remainSec));
    _sessionAlarmId = ReminderService.sessionAlarmId(_h.id);
    await ReminderService.instance.scheduleSessionEnd(
      _h.id,
      endAt,
      title: 'Reading session done',
      body: 'Time to take a break 📚',
    );

    setState(() => _running = true);

    // --- Navigate to reader WITHOUT await so timer keeps running ---
    final book = _books[_currentIndex!];
    _readerOpen = true;
    // ignore: use_build_context_synchronously
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => _ReaderHostPage(
            book: book,
            remainVN: _remainVN,
            onEndNow: _stopSession,
          ),
        ))
        .whenComplete(() {
          _readerOpen = false;
        });
  }

  Future<void> _stopSession() async {
    _cancelSessionTimer(andNotification: true);
    setState(() {
      _running = false;
      _remainSec = 0;
      _remainVN.value = 0;
    });
    _snack('Reading session stopped.');
    // No interstitial: this is triggered from inside the reader ("End now"),
    // and ads must not interrupt reading.

  }

  void _cancelSessionTimer({required bool andNotification}) {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    // Cancel the end-of-session alarm on stop AND pause; previously it was
    // never cancelled and (via the old scheduler) re-fired daily forever.
    if (_sessionAlarmId != null) {
      ReminderService.instance.cancelSessionEnd(_h.id);
      _sessionAlarmId = null;
    }
  }

  // ---------- UI events ----------
  Future<void> _addDailyTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 21, minute: 0),
    );
    if (t == null) return;
    setState(() {
      _dailyTimes.add(t);
      _dirtyReminders = true;
    });
  }

  Future<void> _editDailyTime(int i) async {
    final t =
        await showTimePicker(context: context, initialTime: _dailyTimes[i]);
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
      initialTime: const TimeOfDay(hour: 21, minute: 0),
    );
    if (time == null) return;

    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _oneOffReminders.add(dt);
      _dirtyReminders = true;
    });
  }

  Future<void> _openBookPicker() async {
    if (_loadingBooks) return;
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
                  'Choose Book',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  iconSize: 28,
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _loadBooksFromApi();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: _books.isEmpty
                    ? const Center(
                        child: Text(
                          'No books found.\nUpload from backend.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _books.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final b = _books[i];
                          final selected = _currentIndex == i;
                          return InkWell(
                            onTap: () {
                              setState(() => _currentIndex = i);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: selected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.12)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant
                                        .withOpacity(0.4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      b.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
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

  // ---------- Helpers ----------

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

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final nowReading =
        (_currentIndex != null && _currentIndex! < _books.length)
            ? _books[_currentIndex!].name
            : 'No book selected';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading'),
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
             Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: AdBanner(placement: 'home_bottom', padding: EdgeInsets.only(bottom: 8)),
            ),
            // NOW READING + CONTROLS
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Column(
                  children: [
                    Text('Now Reading',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      nowReading,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    // Session length selector
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Session length (min)',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => setState(() =>
                              _sessionMin = (_sessionMin - 5).clamp(5, 180)),
                          icon: const Icon(Icons.remove, size: 26),
                          style: IconButton.styleFrom(
                              fixedSize: const Size(52, 52)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('$_sessionMin',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => setState(() =>
                              _sessionMin = (_sessionMin + 5).clamp(5, 180)),
                          icon: const Icon(Icons.add, size: 26),
                          style: IconButton.styleFrom(
                              fixedSize: const Size(52, 52)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Timer label
                    Text(
                      _running
                          ? _fmtClock(_remainSec)
                          : _fmtClock(_sessionMin * 60),
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Controls
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _BigActionButton(
                          icon: Icons.menu_book,
                          label: 'Choose Book',
                          onTap: _openBookPicker,
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
                    Text('Reminders',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Daily times (repeat every day)',
                        style: Theme.of(context).textTheme.titleMedium),
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
                                  onPressed: () => _editDailyTime(i),
                                  icon: const Icon(Icons.edit_outlined)),
                              IconButton(
                                  onPressed: () => _removeDailyTime(i),
                                  icon: const Icon(Icons.delete_outline)),
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

                    Text('One-time reminders (specific date & time)',
                        style: Theme.of(context).textTheme.titleMedium),
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
                          subtitle:
                              const Text('This will ring once (on Save).'),
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

            if (_loadingBooks)
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

// ======== Reader host: decides EPUB vs WebView & shows live countdown ========
class _ReaderHostPage extends StatelessWidget {
  final _BookItem book;
  final ValueNotifier<int> remainVN;
  final VoidCallback onEndNow;
  const _ReaderHostPage({
    required this.book,
    required this.remainVN,
    required this.onEndNow,
  });

  bool get _isEpub => book.url.toLowerCase().endsWith('.epub');

  @override
  Widget build(BuildContext context) {
    return _isEpub
        ? _EpubReaderPage(
            url: book.url,
            title: book.name,
            remainVN: remainVN,
            onEndNow: onEndNow,
          )
        : _WebReaderPage(
            url: book.url,
            title: book.name,
            remainVN: remainVN,
            onEndNow: onEndNow,
          );
  }
}

// ======== EPUB Reader (epub_view ^3.2.0) ========
class _EpubReaderPage extends StatefulWidget {
  final String url;
  final String title;
  final ValueNotifier<int> remainVN;
  final VoidCallback onEndNow;
  const _EpubReaderPage({
    required this.url,
    required this.title,
    required this.remainVN,
    required this.onEndNow,
  });

  @override
  State<_EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<_EpubReaderPage> {
  EpubController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    try {
      final resp = await http.get(Uri.parse(widget.url));
      if (resp.statusCode != 200) {
        setState(() {
          _error = 'Failed to load EPUB (${resp.statusCode})';
          _loading = false;
        });
        return;
      }
      await _openFromBytes(resp.bodyBytes);
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _openFromBytes(Uint8List data) async {
    final controller = EpubController(
      document: EpubDocument.openData(data),
    );
    setState(() {
      _controller = controller;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _goToPrev() {
    final c = _controller;
    if (c == null) return;
    final cur = c.currentValue?.position.index ?? 0;
    final target = (cur - 1) < 0 ? 0 : (cur - 1);
    c.scrollTo(index: target);
  }

  void _goToNext() {
    final c = _controller;
    if (c == null) return;
    final cur = c.currentValue?.position.index ?? 0;
    c.scrollTo(index: cur + 1); // epub_view handles bounds internally
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              )
            : EpubView(controller: _controller!);

    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<int>(
          valueListenable: widget.remainVN,
          builder: (_, remain, __) {
            final t = remain > 0 ? ' ⏳ ${_fmtClock(remain)}' : '';
            return Text('${widget.title}$t', overflow: TextOverflow.ellipsis);
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Table of Contents',
            onPressed: () => _openToc(),
            icon: const Icon(Icons.list),
          ),
          IconButton(
            tooltip: 'End now',
            onPressed: () {
              widget.onEndNow();
              Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.stop_circle_outlined),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _goToPrev,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Prev'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _goToNext,
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _openToc() async {
    if (_controller == null) return;
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: EpubViewTableOfContents(controller: _controller!),
      ),
    );
  }

  String _fmtClock(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ======== WebView fallback (non-EPUB links, e.g., PDFs/HTML) ========
class _WebReaderPage extends StatefulWidget {
  final String url;
  final String title;
  final ValueNotifier<int> remainVN;
  final VoidCallback onEndNow;
  const _WebReaderPage({
    required this.url,
    required this.title,
    required this.remainVN,
    required this.onEndNow,
  });

  @override
  State<_WebReaderPage> createState() => _WebReaderPageState();
}

class _WebReaderPageState extends State<_WebReaderPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  String _fmtClock(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<int>(
          valueListenable: widget.remainVN,
          builder: (_, remain, __) {
            final t = remain > 0 ? ' ⏳ ${_fmtClock(remain)}' : '';
            return Text('${widget.title}$t', overflow: TextOverflow.ellipsis);
          },
        ),
        actions: [
          IconButton(
            tooltip: 'End now',
            onPressed: () {
              widget.onEndNow();
              Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.stop_circle_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
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
      constraints:
          const BoxConstraints(minWidth: 140, maxWidth: 200, minHeight: 56),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// ======== API model ========
class _BookItem {
  final int id;
  final String type; // "ebook"
  final String name;
  final String url; // absolute url (prefix added if necessary)
  final int? sizeBytes;
  final DateTime? created;

  _BookItem({
    required this.id,
    required this.type,
    required this.name,
    required this.url,
    this.sizeBytes,
    this.created,
  });

  factory _BookItem.fromJson(Map<String, dynamic> j, String base) {
    String u = (j['url'] ?? '').toString();
    if (u.startsWith('/')) u = '$base$u';
    DateTime? c;
    try {
      c = j['created'] != null ? DateTime.parse(j['created']) : null;
    } catch (_) {}
    return _BookItem(
      id: (j['id'] ?? 0) is int
          ? j['id'] as int
          : int.tryParse('${j['id']}') ?? 0,
      type: (j['type'] ?? '').toString(),
      name: (j['name'] ?? 'Book').toString(),
      url: u,
      sizeBytes: j['size_bytes'] is int
          ? j['size_bytes'] as int
          : int.tryParse('${j['size_bytes']}'),
      created: c,
    );
  }
}

