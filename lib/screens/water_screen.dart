import 'package:flutter/material.dart';
import 'package:habit_tracker_nepali/services/ad_service.dart';

import '../models/habit.dart';
import '../services/storage_service.dart';
import '../core/reminders/reminder_service.dart';

class WaterScreen extends StatefulWidget {
  final Habit habit; // pass an unsaved or existing water habit
  const WaterScreen({super.key, required this.habit});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final _storage = StorageService();

  late Habit _h;
  late TextEditingController _targetCtrl;

  // Local editable copy until user presses Save
  final List<TimeOfDay> _times = [];
  bool _dirty = false; // enable Save button only when there are pending changes

  @override
  void initState() {
    super.initState();
    _h = widget.habit;
    _ensureWaterDate();

    _targetCtrl = TextEditingController(text: (_h.waterTarget ?? 8).toString());

    // Seed local times from model or sensible defaults (staged; user must Save)
    if (_h.reminderTimes.isEmpty) {
      _times.addAll(const [
        TimeOfDay(hour: 8, minute: 0),
        TimeOfDay(hour: 10, minute: 0),
        TimeOfDay(hour: 12, minute: 0),
        TimeOfDay(hour: 14, minute: 0),
        TimeOfDay(hour: 16, minute: 0),
        TimeOfDay(hour: 18, minute: 0),
      ]);
      _dirty = true;
    } else {
      _times.addAll(_h.reminderTimes.map(Habit.parseHHmm));
    }
  }

  void _ensureWaterDate() {
    final today = DateTime.now();
    final ymd =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (_h.waterLastDate != ymd) {
      _h.waterLastDate = ymd;
      _h.waterCompleted = 0;
    }
  }

  // Persist this habit (insert if new, update if exists)
  Future<void> _persistHabitOnly() async {
    final all = await _storage.loadHabits();
    final idx = all.indexWhere((x) => x.id == _h.id);
    if (idx >= 0) {
      all[idx] = _h;
    } else {
      all.add(_h); // first time: create it
    }
    await _storage.saveHabits(all);
  }

  // Reminders are planned from _h.reminderTimes by HabitReminderPlanner and
  // replace any previously armed ones (removed times are cancelled).
  Future<void> _scheduleAllWithNativeAlarm() =>
      ReminderService.instance.syncHabit(_h);

  Future<void> _applyAndSchedule() async {
    // Apply staged times into model
    _h.reminderTimes = _times.map(Habit.fmt).toList();
    await _persistHabitOnly();

    // Schedule process-independent alarms
    await _scheduleAllWithNativeAlarm();

    if (!mounted) return;
    setState(() => _dirty = false);
    _snack('Reminders saved.');
                  await InterstitialHelper().showIfAvailable();

    // Optionally pop back to Home so it shows in the list immediately:
    // Navigator.pop(context);
  }

  Future<void> _addTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null) {
      setState(() {
        _times.add(t);
        _dirty = true;
      });
    }
  }

  Future<void> _editTime(int i) async {
    final t = await showTimePicker(
      context: context,
      initialTime: _times[i],
    );
    if (t != null) {
      setState(() {
        _times[i] = t;
        _dirty = true;
      });
    }
  }

  Future<void> _removeTime(int i) async {
    setState(() {
      _times.removeAt(i);
      _dirty = true;
    });
  }

  Future<void> _minus() async {
    _ensureWaterDate();
    setState(() {
      final cur = _h.waterCompleted ?? 0;
      _h.waterCompleted = cur > 0 ? cur - 1 : 0;
    });
    await _persistHabitOnly();
  }

  Future<void> _plus() async {
    _ensureWaterDate();
    setState(() {
      final cur = _h.waterCompleted ?? 0;
      _h.waterCompleted = cur + 1;
    });
    await _persistHabitOnly();
  }

  Future<void> _saveTarget() async {
    final v = int.tryParse(_targetCtrl.text.trim());
    if (v != null && v > 0) {
      setState(() => _h.waterTarget = v);
      await _persistHabitOnly();
      _snack('Target saved.');
    }
  }

  void _snack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _h.waterCompleted ?? 0;
    final target = _h.waterTarget ?? 8;
    final pct = (done / (target == 0 ? 1 : target)).clamp(0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Intake'),
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
          // Progress card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Today', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: pct as double?),
                  const SizedBox(height: 8),
                  Text('$done / $target glasses'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _minus,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 36,
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: _plus,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 36,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Target editor
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(child: Text('Daily target (glasses):')),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _targetCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saveTarget,
                    child: const Text('Save target'),
                  ),
                ],
              ),
            ),
          ),

          // Times list (staged until Save)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Reminder times', style: Theme.of(context).textTheme.titleLarge),
          ),
          ...List.generate(_times.length, (i) {
            final t = _times[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(Habit.fmt(t)),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      onPressed: () => _editTime(i),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => _removeTime(i),
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
              onPressed: _addTime,
              icon: const Icon(Icons.add),
              label: const Text('Add time'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),

      // Bottom-wide Save (convenience)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton.icon(
            onPressed: _dirty ? _applyAndSchedule : null,
            icon: const Icon(Icons.save),
            label: const Text('Save reminders'),
          ),
        ),
      ),
    );
  }
}

