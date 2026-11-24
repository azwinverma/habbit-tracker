import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/reminders/reminder_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/storage_service.dart';
import '../../widgets/reminder_schedule_editor.dart';
import 'onboarding_logic.dart';

/// First-run flow: welcome + language → goals → 1–3 starter habits → privacy.
/// Skippable at every step; no account; notification permission is asked only
/// after the habits (and so the first reminders) are created.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  final Set<OnboardingGoal> _goals = {};
  final Map<Starter, TimeOfDay> _selected = {};
  bool _suggestedOnce = false;
  bool _finishing = false;

  static const _pageCount = 4;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    if (page == 2 && !_suggestedOnce) {
      _suggestedOnce = true;
      for (final s in OnboardingLogic.suggest(_goals)) {
        _selected[s] = starterDefaultTime[s]!;
      }
    }
    setState(() => _page = page);
    _pages.animateToPage(page, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  Map<Starter, String> _names(AppLocalizations l) => {
        Starter.water: l.starterWater,
        Starter.medicine: l.starterMedicine,
        Starter.meditate: l.starterMeditate,
        Starter.read: l.starterRead,
        Starter.move: l.starterMove,
        Starter.journal: l.starterJournal,
      };

  Future<void> _finish({required bool withHabits}) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final l = AppLocalizations.of(context);
    try {
      if (withHabits && _selected.isNotEmpty) {
        // Keep the user's chosen order stable (enum order).
        final ordered = {for (final s in Starter.values) if (_selected.containsKey(s)) s: _selected[s]!};
        final habits = OnboardingLogic.buildHabits(ordered, _names(l));
        final storage = StorageService();
        final all = await storage.loadHabits()
          ..addAll(habits);
        await storage.saveHabits(all);
        for (final h in habits) {
          await ReminderService.instance.syncHabit(h); // asks notification permission once
        }
      }
      await OnboardingLogic.markDone();
      if (mounted) context.go('/today');
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton.icon(
                      onPressed: () => _go(_page - 1),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(l.obBack),
                    ),
                  const Spacer(),
                  if (_page < _pageCount - 1)
                    TextButton(onPressed: () => _finish(withHabits: false), child: Text(l.obSkip)),
                ],
              ),
            ),
            Semantics(
              label: '${_page + 1} / $_pageCount',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(
                  value: (_page + 1) / _pageCount,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(onNext: () => _go(1)),
                  _GoalsPage(
                    goals: _goals,
                    onToggle: (g) => setState(() => _goals.contains(g) ? _goals.remove(g) : _goals.add(g)),
                    onNext: () => _go(2),
                  ),
                  _StartersPage(
                    names: _names(l),
                    selected: _selected,
                    onToggle: (s) {
                      setState(() {
                        if (_selected.containsKey(s)) {
                          _selected.remove(s);
                        } else if (_selected.length < maxStarters) {
                          _selected[s] = starterDefaultTime[s]!;
                        } else {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(l.obMaxThree)));
                        }
                      });
                    },
                    onTime: (s, t) => setState(() => _selected[s] = t),
                    onNext: () => _go(3),
                  ),
                  _FinishPage(
                    busy: _finishing,
                    hasHabits: _selected.isNotEmpty,
                    onStart: () => _finish(withHabits: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.children, required this.button});
  final List<Widget> children;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ListView(children: children)),
          const SizedBox(height: 12),
          button,
        ],
      ),
    );
  }
}

class _WelcomePage extends ConsumerWidget {
  const _WelcomePage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = ref.watch(localeProvider) ?? Localizations.localeOf(context);
    return _PageScaffold(
      button: FilledButton(onPressed: onNext, child: Text(l.obContinue)),
      children: [
        const SizedBox(height: 24),
        Icon(Icons.spa_outlined, size: 72, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(l.appTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(l.tagline, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 16),
        Text(l.obWelcomeBody, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 32),
        Text(l.obChooseLanguage, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'en', label: Text('English')),
            ButtonSegment(value: 'ne', label: Text('नेपाली')),
          ],
          selected: {current.languageCode == 'ne' ? 'ne' : 'en'},
          onSelectionChanged: (s) => ref.read(localeProvider.notifier).set(Locale(s.first)),
        ),
      ],
    );
  }
}

class _GoalsPage extends StatelessWidget {
  const _GoalsPage({required this.goals, required this.onToggle, required this.onNext});
  final Set<OnboardingGoal> goals;
  final ValueChanged<OnboardingGoal> onToggle;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final labels = {
      OnboardingGoal.health: (l.goalHealth, Icons.favorite_outline),
      OnboardingGoal.focus: (l.goalFocus, Icons.center_focus_strong_outlined),
      OnboardingGoal.fitness: (l.goalFitness, Icons.directions_run),
      OnboardingGoal.calm: (l.goalCalm, Icons.self_improvement),
      OnboardingGoal.learning: (l.goalLearning, Icons.menu_book_outlined),
      OnboardingGoal.routines: (l.goalRoutines, Icons.wb_twilight),
    };
    return _PageScaffold(
      button: FilledButton(onPressed: onNext, child: Text(l.obContinue)),
      children: [
        Text(l.obGoalsTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(l.obGoalsBody, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final g in OnboardingGoal.values)
              FilterChip(
                avatar: Icon(labels[g]!.$2, size: 20),
                label: Text(labels[g]!.$1),
                selected: goals.contains(g),
                onSelected: (_) => onToggle(g),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
          ],
        ),
      ],
    );
  }
}

class _StartersPage extends StatelessWidget {
  const _StartersPage({
    required this.names,
    required this.selected,
    required this.onToggle,
    required this.onTime,
    required this.onNext,
  });
  final Map<Starter, String> names;
  final Map<Starter, TimeOfDay> selected;
  final ValueChanged<Starter> onToggle;
  final void Function(Starter, TimeOfDay) onTime;
  final VoidCallback onNext;

  static const _icons = {
    Starter.water: Icons.local_drink_outlined,
    Starter.medicine: Icons.medication_outlined,
    Starter.meditate: Icons.self_improvement,
    Starter.read: Icons.menu_book_outlined,
    Starter.move: Icons.directions_walk,
    Starter.journal: Icons.edit_note,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _PageScaffold(
      button: FilledButton(onPressed: onNext, child: Text(l.obContinue)),
      children: [
        Text(l.obStartersTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(l.obStartersBody, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        for (final s in Starter.values)
          Card(
            child: CheckboxListTile(
              value: selected.containsKey(s),
              onChanged: (_) => onToggle(s),
              secondary: Icon(_icons[s], color: theme.colorScheme.primary),
              title: Text(names[s]!),
              subtitle: !selected.containsKey(s)
                  ? (s == Starter.medicine ? Text(l.obMedicineNote) : null)
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: s == Starter.water
                          ? Text('${waterTimes.first} – ${waterTimes.last} · ${waterTimes.length}×')
                          : ActionChip(
                              avatar: const Icon(Icons.schedule, size: 18),
                              label: Text(ReminderScheduleEditor.fmtTime(selected[s]!)),
                              onPressed: () async {
                                final t = await showTimePicker(context: context, initialTime: selected[s]!);
                                if (t != null) onTime(s, t);
                              },
                            ),
                    ),
            ),
          ),
      ],
    );
  }
}

class _FinishPage extends StatelessWidget {
  const _FinishPage({required this.busy, required this.hasHabits, required this.onStart});
  final bool busy;
  final bool hasHabits;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _PageScaffold(
      button: FilledButton(
        onPressed: busy ? null : onStart,
        child: busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(l.obStart),
      ),
      children: [
        const SizedBox(height: 24),
        Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(l.obPrivacyTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(l.obPrivacyBody, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        if (hasHabits) ...[
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(l.obRemindersNote),
            ),
          ),
        ],
      ],
    );
  }
}
