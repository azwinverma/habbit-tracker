// lib/screens/medicine_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:habit_tracker_nepali/widgets/ad_banner.dart';

import '../models/habit.dart';
import '../services/storage_service.dart';
import '../core/reminders/reminder_service.dart';

class MedicineScreen extends StatefulWidget {
  final Habit habit; // category == HabitCategory.medicine
  const MedicineScreen({super.key, required this.habit});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final _storage = StorageService();

  late Habit _h;

  // Local staged fields (only applied on Save)
  late final TextEditingController _nameCtrl;
  late final TextEditingController _doseCtrl;
  late final TextEditingController _notesCtrl;

  final List<TimeOfDay> _times = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _enabled = true;

  bool _dirty = false; // enable Save when user changes anything


  @override
  void initState() {
    super.initState();
    _h = widget.habit;

    _nameCtrl  = TextEditingController(text: _h.medicineName ?? '');
    _doseCtrl  = TextEditingController(text: _h.medicineDose ?? '');
    _notesCtrl = TextEditingController(text: _h.medicineNotes ?? '');

    _enabled = _h.enabled;

    // Times: use existing or sensible defaults (8:00, 14:00, 20:00)
    if (_h.reminderTimes.isNotEmpty) {
      _times.addAll(_h.reminderTimes.map(Habit.parseHHmm));
    } else {
      _times.addAll(const [
        TimeOfDay(hour: 8,  minute: 0),
        TimeOfDay(hour: 14, minute: 0),
        TimeOfDay(hour: 20, minute: 0),
      ]);
      _dirty = true;
    }

    // Date range
    _startDate = _h.medicineStartDate != null ? DateTime.tryParse(_h.medicineStartDate!) : DateTime.now();
    _endDate   = _h.medicineEndDate   != null ? DateTime.tryParse(_h.medicineEndDate!)   : DateTime.now().add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ---------- Persistence ----------
  Future<void> _persistHabitOnly() async {
    final list = await _storage.loadHabits();
    final i = list.indexWhere((x) => x.id == _h.id);
    if (i >= 0) {
      list[i] = _h;
    } else {
      list.add(_h);
    }
    await _storage.saveHabits(list);
  }

  // ---------- Scheduling ----------
  Future<void> _applyAndSchedule() async {
    // Write staged → model
    _h
      ..enabled = _enabled
      ..name = _h.name.isNotEmpty ? _h.name : (_nameCtrl.text.trim().isEmpty ? 'Medicine 💊' : _nameCtrl.text.trim())
      ..medicineName = _nameCtrl.text.trim().isEmpty ? (_h.medicineName ?? 'Medicine') : _nameCtrl.text.trim()
      ..medicineDose = _doseCtrl.text.trim()
      ..medicineNotes = _notesCtrl.text.trim()
      ..reminderTimes = _times.map(Habit.fmt).toList()
      ..medicineStartDate = _startDate != null ? _yyyyMmDd(_startDate!) : null
      ..medicineEndDate   = _endDate   != null ? _yyyyMmDd(_endDate!)   : null;

    await _persistHabitOnly();

    // One daily alarm per dose time, bounded by the start/end dates and
    // re-armed natively each day. Replaces the old approach of one alarm per
    // dose per day (up to 120 days), whose alarms each re-armed themselves
    // daily forever — piling up duplicate notifications past the end date.
    // Disabling cancels all of this medicine's alarms.
    await ReminderService.instance.syncHabit(_h);

    if (mounted) {
      setState(() => _dirty = false);
      _snack(_h.enabled ? 'Medicine reminders saved.' : 'Saved (reminders are disabled).');
    }
    // No interstitial here: never show ads around recording medication.
  }

  // ---------- UI actions ----------
  Future<void> _pickStart() async {
    final initial = _startDate ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d == null) return;
    setState(() {
      _startDate = d;
      _dirty = true;
    });
  }

  Future<void> _pickEnd() async {
    final initial = _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 14));
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d == null) return;
    setState(() {
      _endDate = d;
      _dirty = true;
    });
    
  }

  Future<void> _addTime() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (t == null) return;
    setState(() {
      _times.add(t);
      _dirty = true;
    });
  }

  Future<void> _editTime(int i) async {
    final t = await showTimePicker(context: context, initialTime: _times[i]);
    if (t == null) return;
    setState(() {
      _times[i] = t;
      _dirty = true;
    });
  }

  void _removeTime(int i) {
    setState(() {
      _times.removeAt(i);
      _dirty = true;
    });
  }

  String _yyyyMmDd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _snack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startStr = _startDate != null ? _yyyyMmDd(_startDate!) : 'Not set';
    final endStr   = _endDate   != null ? _yyyyMmDd(_endDate!)   : 'Not set';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine (💊)'),
        actions: [
          TextButton.icon(
            onPressed: _dirty ? _applyAndSchedule : null,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic info
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: AdBanner(placement: 'home_bottom', padding: EdgeInsets.only(bottom: 8)),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Medicine name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _dirty = true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _doseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dose (e.g., 500 mg, 2 tablets)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _dirty = true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes (before/after meal, etc.)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (_) => setState(() => _dirty = true),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _enabled,
                    onChanged: (v) => setState(() {
                      _enabled = v;
                      _dirty = true;
                    }),
                    title: const Text('Enable reminders'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Date range
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Start date')),
                      Text(startStr),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickStart,
                        icon: const Icon(Icons.event),
                        label: const Text('Pick'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Text('End date')),
                      Text(endStr),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickEnd,
                        icon: const Icon(Icons.event),
                        label: const Text('Pick'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Alarms will be scheduled for each day/time between the start and end (max 120 days).',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Times
          Text('Dose times', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          ...List.generate(_times.length, (i) {
            final t = _times[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(Habit.fmt(t)),
                subtitle: Text(_doseCtrl.text.trim().isEmpty ? 'Dose time' : _doseCtrl.text.trim()),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(onPressed: () => _editTime(i), icon: const Icon(Icons.edit_outlined)),
                    IconButton(onPressed: () => _removeTime(i), icon: const Icon(Icons.delete_outline)),
                  ],
                ),
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add),
              label: const Text('Add time'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),

      // bottom Save
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton.icon(
            onPressed: _dirty ? _applyAndSchedule : null,
            //  () async {
            //                 _dirty ? _applyAndSchedule : null;
            //   // await InterstitialHelper().showIfAvailable();

            // },
            icon: const Icon(Icons.save),
            label: const Text('Save & schedule'),
          ),
        ),
      ),
    );
  }
}
