import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/reminders/reminder_service.dart';
import '../content/data/providers/content_provider.dart';
import '../../l10n/app_localizations.dart';
import '../content/data/download_service.dart';
import '../content/presentation/discover_screen.dart' show fmtBytes;
import '../../app/theme.dart';
import '../../design/components.dart';
import '../../design/backdrop.dart';
import '../../design/motion.dart';
import '../../services/ad_service.dart';

/// You: appearance, reminders, content sources & licences, privacy.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final states = ref.watch(contentSyncStatesProvider).valueOrNull ?? const [];
    final providers = ref.watch(contentSyncServiceProvider).providers;
    final exact = ref.watch(exactAlarmAllowedProvider).valueOrNull;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(Space.xs, Space.xl, Space.xs, Space.sm),
      child: Semantics(header: true, child: Text(title, style: theme.textTheme.titleLarge)),
    );

    String when(DateTime? d) {
      if (d == null) return l.never;
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return l.justNow;
      if (diff.inHours < 1) return l.minutesAgo(diff.inMinutes);
      if (diff.inDays < 1) return l.hoursAgo(diff.inHours);
      return l.daysAgo(diff.inDays);
    }

    return BrandBackdrop(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.youTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xxl),
            children: Entrance.list([
              _BrandHeader(l: l),
              section(l.language),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'system', label: Text(l.languageSystem)),
                  const ButtonSegment(value: 'en', label: Text('English')),
                  const ButtonSegment(value: 'ne', label: Text('नेपाली')),
                ],
                selected: {locale?.languageCode ?? 'system'},
                onSelectionChanged:
                    (s) => ref.read(localeProvider.notifier).set(s.first == 'system' ? null : Locale(s.first)),
              ),
              section(l.appearance),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l.themeSystem),
                    icon: const Icon(Icons.brightness_auto_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l.themeLight),
                    icon: const Icon(Icons.light_mode_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l.themeDark),
                    icon: const Icon(Icons.dark_mode_rounded),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
              ),
              section(l.remindersSection),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.alarm_on_outlined),
                  title: Text(l.exactPermissionTitle),
                  subtitle: Text(exact == false ? l.exactOff : l.exactOn),
                  trailing:
                      exact == false
                          ? TextButton(
                            onPressed: () async {
                              await ReminderService.instance.openExactAlarmSettings();
                              ref.invalidate(exactAlarmAllowedProvider);
                            },
                            child: Text(l.allow),
                          )
                          : null,
                ),
              ),
              section(l.freeContent),
              Card(
                child: Column(
                  children: [
                    for (final p in providers)
                      Builder(
                        builder: (_) {
                          final s = states.where((x) => x.provider == p.id).firstOrNull;
                          final status =
                              s == null
                                  ? l.contentNotLoaded
                                  : s.lastError != null &&
                                      (s.lastSuccessAt == null || (s.lastAttemptAt?.isAfter(s.lastSuccessAt!) ?? false))
                                  ? l.contentFailed(s.itemCount)
                                  : l.contentStatus(s.itemCount, when(s.lastSuccessAt));
                          return ListTile(
                            leading: Icon(_iconFor(p)),
                            title: Text(p.displayName),
                            subtitle: Text(status),
                          );
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: Text(l.checkNewContent),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final r = await ref.read(contentSyncServiceProvider).syncIfStale(force: true);
                            final added = r.fold<int>(0, (a, b) => a + b.newItems);
                            final failed = r.where((x) => x.error != null).length;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  failed == r.length
                                      ? l.contentUnreachable
                                      : added > 0
                                      ? l.newItemsAdded(added)
                                      : l.upToDate,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.xs, Space.sm, Space.xs, 0),
                child: Text(l.autoUpdateNote, style: theme.textTheme.bodySmall),
              ),
              section(l.storageTitle),
              const _StorageCard(),
              section(l.sourcesLicences),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.sourcesIntro),
                      const SizedBox(height: 12),
                      for (final p in providers)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('•  '),
                              Expanded(child: Text('${p.displayName}: ${_licenceNote(p, l)}')),
                              IconButton(
                                tooltip: l.copyLink,
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.link, size: 18),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: p.homepage));
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text(l.linkCopied(p.homepage))));
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              section(l.privacy),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline_rounded),
                      title: Text(l.privacyTitle),
                      subtitle: Text(l.privacyBody),
                    ),
                    const Divider(indent: Space.lg, endIndent: Space.lg),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(l.openSourceLicences),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showLicensePage(context: context, applicationName: l.appTitle),
                    ),
                    if (AdService.privacyOptionsRequired) ...[
                      const Divider(indent: Space.lg, endIndent: Space.lg),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: Text(l.adPrivacyChoices),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: AdService.showPrivacyOptions,
                      ),
                    ],
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    ));
  }

  static IconData _iconFor(ContentProvider p) => switch (p.id) {
    'gutenberg' => Icons.menu_book_outlined,
    'commons' => Icons.graphic_eq,
    'wger' => Icons.fitness_center,
    'librivox' => Icons.headphones_outlined,
    'commons-video' => Icons.smart_display_outlined,
    'youtube' => Icons.smart_display_rounded,
    _ => Icons.public,
  };

  static String _licenceNote(ContentProvider p, AppLocalizations l) => switch (p.id) {
    'gutenberg' => l.licNoteGutenberg,
    'commons' => l.licNoteCommons,
    'wger' => l.licNoteWger,
    'librivox' => l.licNoteLibrivox,
    'commons-video' => l.licNoteCommonsVideo,
    'youtube' => l.licNoteYoutube,
    _ => p.homepage,
  };
}

/// Brand card at the top of You: logo mark, name, tagline, local-data status.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(Space.xl - 4),
      decoration: BoxDecoration(color: s.primaryContainer, borderRadius: BorderRadius.circular(Radii.lg + 4)),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: s.primary, borderRadius: BorderRadius.circular(Radii.md + 2)),
            child: Icon(Icons.spa_rounded, color: s.onPrimary, size: 30),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.appTitle, style: theme.textTheme.titleLarge?.copyWith(color: s.onPrimaryContainer)),
                Text(
                  l.profileTagline,
                  style: theme.textTheme.bodyMedium?.copyWith(color: s.onPrimaryContainer.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: Space.sm),
                StatusChip(
                  icon: Icons.phone_android_rounded,
                  label: l.onThisDevice,
                  background: s.surface.withValues(alpha: 0.75),
                  color: s.onSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Space used by offline downloads, with "remove all".
class _StorageCard extends ConsumerWidget {
  const _StorageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(_downloadsProvider).valueOrNull ?? const [];
    final bytes = rows.fold<int>(0, (a, r) => a + r.bytes);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.sd_storage_outlined),
        title: Text(l.storageUsed(fmtBytes(bytes), rows.length)),
        trailing: rows.isEmpty
            ? null
            : TextButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l.clearDownloads),
                      content: Text(l.clearDownloadsConfirm),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.remove)),
                      ],
                    ),
                  );
                  if (ok == true) await DownloadService.instance.clearAll();
                },
                child: Text(l.remove),
              ),
      ),
    );
  }
}

final _downloadsProvider = StreamProvider((ref) => DownloadService.instance.watchAll());
