import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/reminders/reminder_service.dart';
import '../content/data/providers/content_provider.dart';

/// You: appearance, reminders, content sources & licences, privacy.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final states = ref.watch(contentSyncStatesProvider).valueOrNull ?? const [];
    final providers = ref.watch(contentSyncServiceProvider).providers;
    final exact = ref.watch(exactAlarmAllowedProvider).valueOrNull;

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(title, style: theme.textTheme.titleMedium),
        );

    String when(DateTime? d) {
      if (d == null) return 'never';
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inHours < 1) return '${diff.inMinutes} min ago';
      if (diff.inDays < 1) return '${diff.inHours} h ago';
      return '${diff.inDays} d ago';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        children: [
          section('Appearance'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
            ],
            selected: {mode},
            onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
          ),
          section('Reminders'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.alarm_on_outlined),
              title: const Text('Alarms & reminders permission'),
              subtitle: Text(exact == false ? 'Off — reminders may be a few minutes late' : 'On'),
              trailing: exact == false
                  ? TextButton(
                      onPressed: () async {
                        await ReminderService.instance.openExactAlarmSettings();
                        ref.invalidate(exactAlarmAllowedProvider);
                      },
                      child: const Text('Allow'))
                  : null,
            ),
          ),
          section('Free content'),
          Card(
            child: Column(
              children: [
                for (final p in providers)
                  Builder(builder: (_) {
                    final s = states.where((x) => x.provider == p.id).firstOrNull;
                    final status = s == null
                        ? 'Not loaded yet'
                        : s.lastError != null && (s.lastSuccessAt == null ||
                                (s.lastAttemptAt?.isAfter(s.lastSuccessAt!) ?? false))
                            ? 'Last refresh failed · ${s.itemCount} cached · retrying later'
                            : '${s.itemCount} items · updated ${when(s.lastSuccessAt)}';
                    return ListTile(
                      leading: Icon(_iconFor(p)),
                      title: Text(p.displayName),
                      subtitle: Text(status),
                    );
                  }),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check for new content now'),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final r = await ref.read(contentSyncServiceProvider).syncIfStale(force: true);
                        final added = r.fold<int>(0, (a, b) => a + b.newItems);
                        final failed = r.where((x) => x.error != null).length;
                        messenger.showSnackBar(SnackBar(
                          content: Text(failed == r.length
                              ? 'Could not reach content sources. You can still use what\'s saved.'
                              : added > 0
                                  ? '$added new items added'
                                  : 'You\'re up to date'),
                        ));
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          section('Sources & licences'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DailyMantra only uses content that is free to reuse, including in an '
                    'ad-supported app: public domain, CC0, CC BY and CC BY-SA. Each item shows '
                    'its author and licence.',
                  ),
                  const SizedBox(height: 12),
                  for (final p in providers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text('${p.displayName}: ${_licenceNote(p)}')),
                          IconButton(
                            tooltip: 'Copy link',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.link, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: p.homepage));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text('Copied ${p.homepage}')));
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          section('Privacy'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Your data stays on this device'),
              subtitle: Text(
                'Habits, medicine schedules and history are stored only on your phone. '
                'Optional backup and sync will come later and will always be your choice.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(ContentProvider p) => switch (p.id) {
        'gutenberg' => Icons.menu_book_outlined,
        'commons' => Icons.graphic_eq,
        'wger' => Icons.fitness_center,
        _ => Icons.public,
      };

  static String _licenceNote(ContentProvider p) => switch (p.id) {
        'gutenberg' => 'public-domain ebooks (US). Copyright may differ in other countries.',
        'commons' => 'freely licensed recordings (PD, CC0, CC BY, CC BY-SA); author credited.',
        'wger' => 'exercise descriptions CC BY-SA; images credited to their authors.',
        _ => 'see provider',
      };
}
