import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/habit_repository.dart';

import '../../../core/reminders/reminder_service.dart';
import '../../../models/habit.dart';
import '../../../screens/add_edit_habit_screen.dart';
import '../../../screens/exercise_screen.dart';
import '../../../screens/medicine_screen.dart';
import '../../../screens/meditation_screen.dart';
import '../../../screens/reading_screen.dart';
import '../../../screens/water_screen.dart';
import '../../../services/ad_service.dart';
import '../../../services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/review_prompt.dart';

enum QuickAddKind { medicine, water, meditation, reading, exercise, custom }

extension QuickAddKindUi on QuickAddKind {
  String get label => switch (this) {
        QuickAddKind.medicine => 'Medicine',
        QuickAddKind.water => 'Water Intake',
        QuickAddKind.meditation => 'Meditation',
        QuickAddKind.reading => 'Reading',
        QuickAddKind.exercise => 'Exercise',
        QuickAddKind.custom => 'Custom habit',
      };

  String localized(AppLocalizations l) => switch (this) {
        QuickAddKind.medicine => l.qaMedicine,
        QuickAddKind.water => l.qaWater,
        QuickAddKind.meditation => l.qaMeditation,
        QuickAddKind.reading => l.qaReading,
        QuickAddKind.exercise => l.qaExercise,
        QuickAddKind.custom => l.qaCustom,
      };

  IconData get icon => switch (this) {
        QuickAddKind.medicine => Icons.medication,
        QuickAddKind.water => Icons.local_drink,
        QuickAddKind.meditation => Icons.self_improvement,
        QuickAddKind.reading => Icons.menu_book,
        QuickAddKind.exercise => Icons.fitness_center,
        QuickAddKind.custom => Icons.apps,
      };
}

/// Habit creation and navigation flows, shared by Today, the Add sheet and
/// Plan (previously private to the home screen).
///
/// Category screens persist the habit themselves when the user presses Save,
/// so a quick-add only creates a habit if the user actually saves it.
abstract final class HabitFlows {
  static final _interstitial = InterstitialHelper();

  static String newId() => '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(999)}';

  static Future<void> startQuickAdd(BuildContext context, QuickAddKind kind) async {
    // Ads are never shown before medicine setup (product rule); other
    // placements are unchanged from v1 and move to remote config in Phase 7.
    if (kind != QuickAddKind.medicine) _interstitial.showIfAvailable();

    final Habit temp = switch (kind) {
      QuickAddKind.medicine => Habit(
          id: newId(), name: 'Medicine 💊', enabled: true, reminderHour: 8, reminderMinute: 0,
          category: HabitCategory.medicine, medicineName: 'Medicine', medicineDose: '', medicineNotes: ''),
      QuickAddKind.water => Habit(
          id: newId(), name: 'Drink Water 💧', enabled: true, reminderHour: 8, reminderMinute: 0,
          category: HabitCategory.water, waterTarget: 8, waterCompleted: 0),
      QuickAddKind.meditation => Habit(
          id: newId(), name: 'Meditation 🧘', enabled: true, reminderHour: 6, reminderMinute: 30,
          category: HabitCategory.meditation, meditationGoalMin: 10, meditationTodayMin: 0),
      QuickAddKind.reading => Habit(
          id: newId(), name: 'Reading 📖', enabled: true, reminderHour: 21, reminderMinute: 0,
          category: HabitCategory.reading),
      QuickAddKind.exercise => Habit(
          id: newId(), name: 'Exercise 💪', enabled: true, reminderHour: 7, reminderMinute: 0,
          category: HabitCategory.exercise, stepsGoal: 8000, stepsToday: 0),
      QuickAddKind.custom => Habit(
          id: newId(), name: 'Custom Habit ✨', enabled: true, reminderHour: 9, reminderMinute: 0),
    };

    if (kind == QuickAddKind.custom) {
      await _addOrEditGeneric(context, temp, isNew: true);
    } else {
      await openHabit(context, temp);
    }
  }

  /// Opens the habit's own screen (meditation player, reader, tracker...).
  static Future<void> openHabit(BuildContext context, Habit h) async {
    final Widget? screen = switch (h.category) {
      HabitCategory.medicine => MedicineScreen(habit: h),
      HabitCategory.water => WaterScreen(habit: h),
      HabitCategory.meditation => MeditationScreen(habit: h),
      HabitCategory.reading => ReadingScreen(habit: h),
      HabitCategory.exercise => ExerciseScreen(habit: h),
      HabitCategory.generic => null,
    };
    if (screen == null) {
      await _addOrEditGeneric(context, h, isNew: false);
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Generic name/time editor. Saves through StorageService + ReminderService.
  static Future<void> editGeneric(BuildContext context, Habit h) =>
      _addOrEditGeneric(context, h, isNew: false);

  static Future<void> _addOrEditGeneric(BuildContext context, Habit h, {required bool isNew}) async {
    final res = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditHabitScreen(habit: h)),
    );
    if (res is! Map<String, dynamic>) return;
    h
      ..name = res['name'] as String
      ..enabled = res['enabled'] as bool
      ..reminderHour = res['hour'] as int
      ..reminderMinute = res['minute'] as int
      ..reminderTimes = (res['reminderTimes'] is List<String>)
          ? List<String>.from(res['reminderTimes'] as List)
          : h.reminderTimes;
    await upsert(h);
    if (isNew) _interstitial.showIfAvailable();
  }

  static Future<void> upsert(Habit h) async {
    final storage = StorageService();
    final all = await storage.loadHabits();
    final i = all.indexWhere((x) => x.id == h.id);
    if (i >= 0) {
      all[i] = h;
    } else {
      all.add(h);
    }
    await storage.saveHabits(all);
    await ReminderService.instance.syncHabit(h);
  }

  static Future<void> delete(Habit h) async {
    final storage = StorageService();
    final all = await storage.loadHabits()
      ..removeWhere((x) => x.id == h.id);
    await storage.saveHabits(all);
    // Without this, a deleted habit's daily alarms kept re-arming forever.
    await ReminderService.instance.cancelHabit(h.id);
  }

  /// One-tap water logging from Today (same rules as the Water screen:
  /// the counter resets on a new day, never goes below zero).
  static Future<void> addWater(Habit h, {int delta = 1}) async {
    final today = HabitRepository.ymd(DateTime.now());
    if (h.waterLastDate != today) {
      h
        ..waterLastDate = today
        ..waterCompleted = 0;
    }
    h.waterCompleted = ((h.waterCompleted ?? 0) + delta).clamp(0, 99);
    await upsert(h);
  }

  /// One-tap done / undo for today, with streak bookkeeping (v1 rules).
  static Future<void> toggleToday(Habit h) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = h.lastCompleted == null
        ? null
        : DateTime(h.lastCompleted!.year, h.lastCompleted!.month, h.lastCompleted!.day);
    if (last == today) {
      h.lastCompleted = null;
      h.streak = (h.streak - 1).clamp(0, 9999);
    } else {
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      h.streak = (last == yesterday) ? (h.streak + 1) : 1;
      h.lastCompleted = now;
    }
    await upsert(h);
    // Happy moment: maybe ask for a store rating (rare, rules in ReviewPrompt).
    if (h.lastCompleted != null) unawaited(ReviewPrompt.instance.onHabitCompleted());
  }
}
