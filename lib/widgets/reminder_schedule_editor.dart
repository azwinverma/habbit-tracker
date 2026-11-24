import 'package:flutter/material.dart';

/// Shared reminder editor used by the category screens (previously copied
/// into each screen with small differences).
///
/// Controlled widget: it never keeps its own copy of the times; every change
/// is reported through the callbacks with a new, sorted, de-duplicated list.
/// Pass `oneTimeReminders: null` to hide the one-time section.
class ReminderScheduleEditor extends StatelessWidget {
  const ReminderScheduleEditor({
    super.key,
    required this.dailyTimes,
    required this.onDailyTimesChanged,
    this.oneTimeReminders,
    this.onOneTimeRemindersChanged,
    this.dailyTitle = 'Daily times (repeat every day)',
    this.addDailyLabel = 'Add daily time',
    this.emptyDailyText = 'No daily times yet.',
    this.defaultTime = const TimeOfDay(hour: 7, minute: 0),
  });

  final List<TimeOfDay> dailyTimes;
  final ValueChanged<List<TimeOfDay>> onDailyTimesChanged;
  final List<DateTime>? oneTimeReminders;
  final ValueChanged<List<DateTime>>? onOneTimeRemindersChanged;
  final String dailyTitle;
  final String addDailyLabel;
  final String emptyDailyText;
  final TimeOfDay defaultTime;

  static List<TimeOfDay> normalize(Iterable<TimeOfDay> times) {
    final seen = <int>{};
    final out = <TimeOfDay>[];
    for (final t in times) {
      if (seen.add(t.hour * 60 + t.minute)) out.add(t);
    }
    out.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return out;
  }

  static String fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String fmtDateTime(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}, ${fmtTime(TimeOfDay.fromDateTime(d))}';
  }

  Future<void> _addDaily(BuildContext context) async {
    final t = await showTimePicker(context: context, initialTime: defaultTime);
    if (t == null) return;
    onDailyTimesChanged(normalize([...dailyTimes, t]));
  }

  Future<void> _editDaily(BuildContext context, int i) async {
    final t = await showTimePicker(context: context, initialTime: dailyTimes[i]);
    if (t == null) return;
    final next = [...dailyTimes]..[i] = t;
    onDailyTimesChanged(normalize(next));
  }

  Future<void> _addOneTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: defaultTime);
    if (time == null || !context.mounted) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!dt.isAfter(DateTime.now())) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(const SnackBar(content: Text('Pick a time in the future.')));
      return;
    }
    final next = {...?oneTimeReminders, dt}.toList()..sort();
    onOneTimeRemindersChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final once = oneTimeReminders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dailyTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        if (dailyTimes.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(emptyDailyText)),
        for (var i = 0; i < dailyTimes.length; i++)
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(fmtTime(dailyTimes[i])),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Change ${fmtTime(dailyTimes[i])}',
                    onPressed: () => _editDaily(context, i),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Remove ${fmtTime(dailyTimes[i])}',
                    onPressed: () => onDailyTimesChanged([...dailyTimes]..removeAt(i)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _addDaily(context),
            icon: const Icon(Icons.add),
            label: Text(addDailyLabel),
          ),
        ),
        if (once != null) ...[
          const Divider(height: 28),
          Text('One-time reminders', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          if (once.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('No one-time reminders.')),
          for (final dt in once)
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_available),
                title: Text(fmtDateTime(dt)),
                subtitle: const Text('Rings once'),
                trailing: IconButton(
                  tooltip: 'Remove reminder on ${fmtDateTime(dt)}',
                  onPressed: () => onOneTimeRemindersChanged?.call([...once]..remove(dt)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _addOneTime(context),
              icon: const Icon(Icons.event),
              label: const Text('Add one-time reminder'),
            ),
          ),
        ],
      ],
    );
  }
}
