import 'package:flutter/material.dart';
import 'package:habit_tracker_nepali/models/habit.dart';

class ExtraTimesEditor extends StatefulWidget {
  final List<String> initial;
  final ValueChanged<List<String>> onChanged;
  const ExtraTimesEditor({required this.initial, required this.onChanged});

  @override
  State<ExtraTimesEditor> createState() => ExtraTimesEditorState();
}

class ExtraTimesEditorState extends State<ExtraTimesEditor> {
  final List<TimeOfDay> _items = [];
  @override
  void initState() {
    super.initState();
    _items.addAll(widget.initial.map(Habit.parseHHmm));
  }

  Future<void> _add() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
    if (t != null) {
      setState(() => _items.add(t));
      widget.onChanged(_items.map(Habit.fmt).toList());
    }
  }

  Future<void> _edit(int i) async {
    final t = await showTimePicker(context: context, initialTime: _items[i]);
    if (t != null) {
      setState(() => _items[i] = t);
      widget.onChanged(_items.map(Habit.fmt).toList());
    }
  }

  void _remove(int i) {
    setState(() => _items.removeAt(i));
    widget.onChanged(_items.map(Habit.fmt).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(_items.length, (i) {
          final t = _items[i];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.schedule),
            title: Text(Habit.fmt(t)),
            trailing: Wrap(
              spacing: 6,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(i)),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _remove(i)),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add time')),
        )
      ],
    );
  }
}
