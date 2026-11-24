import 'dart:math';
import 'package:flutter/material.dart';
import 'package:habit_tracker_nepali/screens/exercise_screen.dart';
import 'package:habit_tracker_nepali/screens/medicine_screen.dart';
import 'package:habit_tracker_nepali/screens/meditation_screen.dart';
import 'package:habit_tracker_nepali/screens/reading_screen.dart';
import 'package:habit_tracker_nepali/screens/water_screen.dart';
import 'package:habit_tracker_nepali/widgets/ad_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/reminders/reminder_service.dart';

import '../models/habit.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../services/quote_service.dart';
import '../widgets/habit_tile.dart';
import 'add_edit_habit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  final _interstitial = InterstitialHelper();
  List<Habit> _habits = [];

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(999)}';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _interstitial.load();
    final list = await _storage.loadHabits();
    if (!mounted) return;
    setState(() => _habits = list);
    // One coordinated pass: retire pre-2.0 alarms (first run only), re-arm
    // every habit's reminders from saved data, cancel deleted habits' alarms.
    await ReminderService.instance.startup(list);
    await _maybeAskForExactAlarms();
  }

  /// Android 12+: without "Alarms & reminders" access, reminders still fire
  /// but may be delayed by several minutes. Ask once, only if the user has
  /// reminders, with an explanation (never a bare system prompt).
  Future<void> _maybeAskForExactAlarms() async {
    if (_habits.every((h) => !h.enabled)) return;
    if (await ReminderService.instance.canScheduleExact()) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('exact_alarm_prompt_shown') ?? false) return;
    await prefs.setBool('exact_alarm_prompt_shown', true);
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('On-time reminders'),
        content: const Text(
          'To deliver medicine and habit reminders at the exact minute, '
          'DailyMantra needs the "Alarms & reminders" permission. Without it, '
          'reminders may arrive a few minutes late.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Allow')),
        ],
      ),
    );
    if (go == true) {
      await ReminderService.instance.openExactAlarmSettings();
    }
  }

  Future<void> _refreshHabits() async {
    final list = await _storage.loadHabits();
    setState(() => _habits = list);
  }

  Future<void> _save() async => _storage.saveHabits(_habits);


  /// Reminders for any category are planned from the habit's data by
  /// HabitReminderPlanner; this replaces (not adds to) existing alarms.
  Future<void> _schedule(Habit h) => ReminderService.instance.syncHabit(h);

  Future<void> _addOrUpdateHabit(Habit h, {bool schedule = true}) async {
    final idx = _habits.indexWhere((x) => x.id == h.id);
    setState(() {
      if (idx >= 0) {
        _habits[idx] = h;
      } else {
        _habits.add(h);
      }
    });
    await _save();
    if (schedule) await _schedule(h);
  }

  Future<void> _addHabit() async {
    // Fallback add button → open generic Add/Edit screen
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
    );
    if (res is Map<String, dynamic>) {
      final h = Habit(
        id: _newId(),
        name: res['name'] as String,
        enabled: res['enabled'] as bool,
        reminderHour: res['hour'] as int,
        reminderMinute: res['minute'] as int,
        streak: 0,
        reminderTimes: (res['reminderTimes'] is List<String>)
            ? List<String>.from(res['reminderTimes'] as List)
            : const [],
      );
      await _addOrUpdateHabit(h, schedule: true);
      _interstitial.showIfAvailable();
    }
  }

  // ---------- GRID ----------
  final List<_CategoryTemplate> _templates = const [
    _CategoryTemplate(
  title: 'Medicine',
  icon: Icons.medication, // or Icons.medical_services
  defaultName: 'Medicine 💊',
  defaultHour: 8,
  defaultMinute: 0,
),
    _CategoryTemplate(
      title: 'Water Intake',
      icon: Icons.local_drink,
      defaultName: 'Drink Water 💧',
      defaultHour: 8,
      defaultMinute: 0,
    ),
    _CategoryTemplate(
      title: 'Meditation',
      icon: Icons.self_improvement,
      defaultName: 'Meditation 🧘',
      defaultHour: 6,
      defaultMinute: 30,
    ),
    _CategoryTemplate(
      title: 'Reading',
      icon: Icons.menu_book,
      defaultName: 'Reading 📖',
      defaultHour: 21,
      defaultMinute: 0,
    ),
    _CategoryTemplate(
      title: 'Exercise',
      icon: Icons.fitness_center,
      defaultName: 'Exercise 🏃',
      defaultHour: 7,
      defaultMinute: 0,
    ),
    _CategoryTemplate(
      title: 'Others',
      icon: Icons.apps,
      defaultName: 'Custom Habit ✨',
      defaultHour: 9,
      defaultMinute: 0,
    ),
  ];

  Future<void> _onTemplateTap(_CategoryTemplate t) async {
//     _interstitial.showIfAvailable();

if (t.title == 'Medicine') {
  // No interstitial: users must never have to sit through an ad to set up
  // medication reminders.
  final temp = Habit(
    id: _newId(),
    name: 'Medicine 💊',
    enabled: true,
    reminderHour: t.defaultHour,
    reminderMinute: t.defaultMinute,
    category: HabitCategory.medicine,
    reminderTimes: const [],
    // medicine-specific (optional defaults)
    medicineName: 'Medicine',
    medicineDose: '',
    medicineNotes: '',
    medicineStartDate: null,
    medicineEndDate: null,
    streak: 0,
  );

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => MedicineScreen(habit: temp)),
  );

  await _refreshHabits(); // if user pressed Save inside MedicineScreen
  return;
}


    // IMPORTANT: Do not add habit now. Open the specific page first.
    if (t.title == 'Water Intake') {
       _interstitial.showIfAvailable();
      // Build an unsaved, temporary habit object with sensible defaults
      final temp = Habit(
        id: _newId(),
        name: 'Drink Water 💧',
        enabled: true,
        reminderHour: 8,
        reminderMinute: 0,
        category: HabitCategory.water,
        waterTarget: 8,
        waterCompleted: 0,
        reminderTimes: const [], // user will set in screen
        streak: 0,
      );

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WaterScreen(habit: temp)),
      );

      // If user pressed Save on that page, the screen inserts/updates.
      await _refreshHabits();
      return;
    }

    if (t.title == 'Meditation') {
       _interstitial.showIfAvailable();
      final temp = Habit(
        id: _newId(),
        name: 'Meditation 🧘',
        enabled: true,
        reminderHour: 6,
        reminderMinute: 30,
        category: HabitCategory.meditation,
        meditationGoalMin: 10,
        meditationTodayMin: 0,
        reminderTimes: const [], // set in screen
        streak: 0,
      );

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MeditationScreen(habit: temp)),
      );

      await _refreshHabits();
      return;
    }

    if (t.title == 'Reading') {
       _interstitial.showIfAvailable();
  final temp = Habit(
    id: _newId(),
    name: 'Reading 📖',
    enabled: true,
    reminderHour: 21,
    reminderMinute: 0,
    category: HabitCategory.reading,
    reminderTimes: const [], // user will set on Reading screen
    streak: 0,
  );

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ReadingScreen(habit: temp)),
  );

  await _refreshHabits();
  return;
}

if (t.title == 'Exercise') {
   _interstitial.showIfAvailable();
  final temp = Habit(
    id: _newId(),
    name: 'Exercise 💪',
    enabled: true,
    reminderHour: t.defaultHour,
    reminderMinute: t.defaultMinute,
    category: HabitCategory.exercise,
    reminderTimes: const [],
    // optional exercise defaults
    stepsGoal: 8000,
    stepsToday: 0,
    stepsLastDate: null,
  );

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ExerciseScreen(habit: temp)),
  );

  await _refreshHabits();
  return;
}


    // Other categories → open Add/Edit with defaults, persist only if user saves
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditHabitScreen(
          habit: Habit(
            id: _newId(),
            name: t.defaultName,
            enabled: true,
            reminderHour: t.defaultHour,
            reminderMinute: t.defaultMinute,
            category: _mapTitleToCategory(t.title),
            streak: 0,
          ),
        ),
      ),
    );

    if (res is Map<String, dynamic>) {
      final h = Habit(
        id: _newId(),
        name: res['name'] as String,
        enabled: res['enabled'] as bool,
        reminderHour: res['hour'] as int,
        reminderMinute: res['minute'] as int,
        streak: 0,
        category: _mapTitleToCategory(t.title),
        reminderTimes: (res['reminderTimes'] is List<String>)
            ? List<String>.from(res['reminderTimes'] as List)
            : const [],
      );
      await _addOrUpdateHabit(h, schedule: true);
      _interstitial.showIfAvailable();
    }
  }

  HabitCategory _mapTitleToCategory(String title) {
    switch (title) {
        case 'Medicine':
        return HabitCategory.medicine;
      case 'Water Intake':
        return HabitCategory.water;
      case 'Meditation':
        return HabitCategory.meditation;
      case 'Reading':
        return HabitCategory.reading;
      case 'Exercise':
        return HabitCategory.exercise;
      default:
        return HabitCategory.generic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = QuoteService.quoteForDate(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('DailyMantra'),
      ),
      body: CustomScrollView(
        slivers: [
          // Quote
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote),
                      const SizedBox(width: 8),
                      Expanded(child: Text(quote, style: Theme.of(context).textTheme.titleMedium)),
                    ],
                  ),
                ),
              ),
            ),
          ),

                    // Ad banner
           SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: AdBanner(placement: 'home_bottom', padding: EdgeInsets.only(bottom: 8)),
            ),
          ),
          // Grid header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Text('Quick Add', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),

          // Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final t = _templates[index];
                  return _GridTile(
                    title: t.title,
                    icon: t.icon,
                    onTap: () => _onTemplateTap(t),
                  );
                },
                childCount: _templates.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10,
              ),
            ),
          ),

          // Your Habits
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text('Your Habits', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          _habits.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Tap a quick tile above or + to add your first habit'),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _addHabit,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Habit'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList.separated(
                  itemCount: _habits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (c, i) {
                    final h = _habits[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: HabitTile(
                        habit: h,
                        onToggleComplete: () {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final last = h.lastCompleted == null
                              ? null
                              : DateTime(h.lastCompleted!.year, h.lastCompleted!.month, h.lastCompleted!.day);
                          if (last == today) {
                            h.lastCompleted = null;
                            h.streak = (h.streak - 1).clamp(0, 9999);
                          } else {
                            final yesterday = today.subtract(const Duration(days: 1));
                            h.streak = (last == yesterday) ? (h.streak + 1) : 1;
                            h.lastCompleted = now;
                          }
                          setState(() {});
                          _save();
                        },
                        onEdit: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddEditHabitScreen(habit: h)),
                          );
                          if (res is Map<String, dynamic>) {
                            h
                              ..name = res['name'] as String
                              ..enabled = res['enabled'] as bool
                              ..reminderHour = res['hour'] as int
                              ..reminderMinute = res['minute'] as int
                              ..reminderTimes = (res['reminderTimes'] is List<String>)
                                  ? List<String>.from(res['reminderTimes'] as List)
                                  : h.reminderTimes;
                            await _addOrUpdateHabit(h, schedule: true);
                            
                          }
                        },
                        onDelete: () async {
                          setState(() => _habits.removeWhere((x) => x.id == h.id));
                          await _save();
                          // Without this, a deleted habit's daily alarms
                          // kept re-arming themselves forever.
                          await ReminderService.instance.cancelHabit(h.id);
                        },
                      ),
                    );
                  },
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addHabit, child: const Icon(Icons.add)),
    );
  }
}

class _CategoryTemplate {
  final String title;
  final IconData icon;
  final String defaultName;
  final int defaultHour;
  final int defaultMinute;
  const _CategoryTemplate({
    required this.title,
    required this.icon,
    required this.defaultName,
    required this.defaultHour,
    required this.defaultMinute,
  });
}

class _GridTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _GridTile({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(2, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 28, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

