// lib/screens/medicine_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/db/app_database.dart' show DoseStatus;
import '../core/reminders/reminder_service.dart';
import '../features/habits/data/habit_repository.dart';
import '../features/medicine/data/dose_log_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../services/native_alarm.dart';
import '../services/storage_service.dart';
import '../widgets/reminder_schedule_editor.dart';

/// Medicine: course details, dose times, and today's taken/skipped log.
///
/// No ads anywhere on this screen (blueprint: never around medication).
class MedicineScreen extends ConsumerStatefulWidget {
  final Habit habit; // category == HabitCategory.medicine
  const MedicineScreen({super.key, required this.habit});

  @override
  ConsumerState<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends ConsumerState<MedicineScreen> {
  final _storage = StorageService();

  late Habit _h;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _doseCtrl;
  late final TextEditingController _notesCtrl;

  List<TimeOfDay> _times = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _enabled = true;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _h = widget.habit;
    _nameCtrl = TextEditingController(text: _h.medicineName ?? '');
    _doseCtrl = TextEditingController(text: _h.medicineDose ?? '');
    _notesCtrl = TextEditingController(text: _h.medicineNotes ?? '');
    _enabled = _h.enabled;

    if (_h.reminderTimes.isNotEmpty) {
      _times = ReminderScheduleEditor.normalize(_h.reminderTimes.map(Habit.parseHHmm));
    } else {
      _times = const [
        TimeOfDay(hour: 8, minute: 0),
        TimeOfDay(hour: 14, minute: 0),
        TimeOfDay(hour: 20, minute: 0),
      ];
      _dirty = true;
    }

    // Pick up "Taken" taps from notifications made while this app was open.
    ref.read(doseLogRepositoryProvider).importNativeActions(NativeAlarmBackend());

    _startDate = _parse(_h.medicineStartDate) ?? _today();
    _endDate = _parse(_h.medicineEndDate) ?? _today().add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime? _parse(String? ymd) {
    final d = ymd == null ? null : DateTime.tryParse(ymd);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  void _touch(VoidCallback f) => setState(() {
        f();
        _dirty = true;
      });

  // ---------- Save ----------
  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    _h
      ..enabled = _enabled
      ..name = _h.name.isNotEmpty ? _h.name : (name.isEmpty ? l.medDefaultName : name)
      ..medicineName = name.isEmpty ? (_h.medicineName ?? l.medDefaultName) : name
      ..medicineDose = _doseCtrl.text.trim()
      ..medicineNotes = _notesCtrl.text.trim()
      ..reminderTimes = _times.map(Habit.fmt).toList()
      ..medicineStartDate = _startDate != null ? HabitRepository.ymd(_startDate!) : null
      ..medicineEndDate = _endDate != null ? HabitRepository.ymd(_endDate!) : null;

    final list = await _storage.loadHabits();
    final i = list.indexWhere((x) => x.id == _h.id);
    if (i >= 0) {
      list[i] = _h;
    } else {
      list.add(_h);
    }
    await _storage.saveHabits(list);

    // One daily alarm per dose time, bounded by the course dates.
    await ReminderService.instance.syncHabit(_h);

    if (!mounted) return;
    setState(() => _dirty = false);
    _snack(_h.enabled ? l.medSaved : l.medSavedDisabled);
  }

  Future<void> _pickDate({required bool start}) async {
    final first = start ? _today().subtract(const Duration(days: 30)) : (_startDate ?? _today());
    final current = start ? _startDate : _endDate;
    final initial = (current == null || current.isBefore(first)) ? first : current;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: _today().add(const Duration(days: 365 * 2)),
    );
    if (d == null) return;
    _touch(() {
      if (start) {
        _startDate = d;
        if (_endDate != null && _endDate!.isBefore(d)) _endDate = d;
      } else {
        _endDate = d;
      }
    });
  }

  void _snack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s), behavior: SnackBarBehavior.floating),
    );
  }

  String _fmtDate(DateTime? d, AppLocalizations l) {
    if (d == null) return l.medNotSet;
    return MaterialLocalizations.of(context).formatMediumDate(d);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // The saved copy drives today's dose list (staged edits apply on Save).
    final saved = ref.watch(habitsProvider).valueOrNull?.where((x) => x.id == _h.id).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.medTitle),
        actions: [
          TextButton.icon(
            onPressed: _dirty ? _save : null,
            icon: const Icon(Icons.save, size: 18),
            label: Text(l.medSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TodayDoses(habit: saved),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(labelText: l.medName, border: const OutlineInputBorder()),
                    onChanged: (_) => setState(() => _dirty = true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _doseCtrl,
                    decoration: InputDecoration(labelText: l.medDose, border: const OutlineInputBorder()),
                    onChanged: (_) => setState(() => _dirty = true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    decoration: InputDecoration(labelText: l.medNotes, border: const OutlineInputBorder()),
                    maxLines: 2,
                    onChanged: (_) => setState(() => _dirty = true),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _enabled,
                    onChanged: (v) => _touch(() => _enabled = v),
                    title: Text(l.medEnable),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DateRow(label: l.medStart, value: _fmtDate(_startDate, l), pick: l.medPick,
                      onPick: () => _pickDate(start: true)),
                  const SizedBox(height: 8),
                  _DateRow(label: l.medEnd, value: _fmtDate(_endDate, l), pick: l.medPick,
                      onPick: () => _pickDate(start: false)),
                  const SizedBox(height: 8),
                  Text(l.medCourseHint, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ReminderScheduleEditor(
                dailyTimes: _times,
                onDailyTimesChanged: (t) => _touch(() => _times = t),
                dailyTitle: l.medDoseTimes,
                addDailyLabel: l.medAddTime,
                emptyDailyText: l.medNoTimes,
                defaultTime: const TimeOfDay(hour: 8, minute: 0),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(l.reminderAidDisclaimer, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton.icon(
            onPressed: _dirty ? _save : null,
            icon: const Icon(Icons.save),
            label: Text(l.medSaveSchedule),
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value, required this.pick, required this.onPick});
  final String label, value, pick;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: onPick, icon: const Icon(Icons.event), label: Text(pick)),
        ],
      );
}

/// Today's scheduled doses with Taken / Skip, plus 7-day adherence.
class _TodayDoses extends ConsumerWidget {
  const _TodayDoses({required this.habit});
  final Habit? habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final h = habit;

    Widget card(List<Widget> children) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.medToday, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...children,
            ]),
          ),
        );

    if (h == null) return card([Text(l.medSaveFirst)]);

    final now = DateTime.now();
    final today = HabitRepository.ymd(now);
    final start = DateTime.tryParse(h.medicineStartDate ?? '');
    final end = DateTime.tryParse(h.medicineEndDate ?? '');
    final todayDate = DateTime(now.year, now.month, now.day);
    final inCourse = (start == null || !todayDate.isBefore(start)) && (end == null || !todayDate.isAfter(end));
    final times = ReminderScheduleEditor.normalize(h.reminderTimes.map(Habit.parseHHmm)).map(Habit.fmt).toList();

    final statuses = ref.watch(doseStatusesProvider(h.id)).valueOrNull ?? const {};
    final repo = ref.read(doseLogRepositoryProvider);

    if (!inCourse || times.isEmpty) return card([Text(l.medNoDosesToday)]);

    final adherence = Adherence.compute(h, statuses, now: now);
    return card([
      for (final t in times)
        _DoseRow(
          time: t,
          status: statuses[today]?[t],
          onSet: (s) => repo.setStatus(h.id, today, t, s),
        ),
      const Divider(height: 20),
      Text(
        adherence.due == 0 ? l.medAdherenceNone : l.medAdherence(adherence.taken, adherence.due),
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 4),
      Text(l.medNotificationHint, style: theme.textTheme.bodySmall),
    ]);
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({required this.time, required this.status, required this.onSet});
  final String time;
  final int? status;
  final ValueChanged<int?> onSet;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = switch (status) {
      DoseStatus.taken => l.medTaken,
      DoseStatus.skipped => l.medSkipped,
      _ => l.medPending,
    };
    final icon = switch (status) {
      DoseStatus.taken => Icon(Icons.check_circle, color: scheme.primary),
      DoseStatus.skipped => Icon(Icons.remove_circle_outline, color: scheme.outline),
      _ => Icon(Icons.radio_button_unchecked, color: scheme.outline),
    };
    return Semantics(
      label: l.medDoseSemantics(time, label),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text('$time · $label', style: Theme.of(context).textTheme.bodyLarge),
            ),
            if (status == null) ...[
              TextButton(onPressed: () => onSet(DoseStatus.skipped), child: Text(l.medSkip)),
              const SizedBox(width: 4),
              FilledButton.tonal(onPressed: () => onSet(DoseStatus.taken), child: Text(l.medTaken)),
            ] else
              TextButton(onPressed: () => onSet(null), child: Text(l.medUndo)),
          ],
        ),
      ),
    );
  }
}
