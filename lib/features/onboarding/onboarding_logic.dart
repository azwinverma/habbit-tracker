import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/habit.dart';
import '../habits/presentation/habit_flows.dart';

enum OnboardingGoal { health, focus, fitness, calm, learning, routines }

enum Starter { water, medicine, meditate, read, move, journal }

/// Default reminder time per starter habit.
const starterDefaultTime = <Starter, TimeOfDay>{
  Starter.water: TimeOfDay(hour: 8, minute: 0),
  Starter.medicine: TimeOfDay(hour: 8, minute: 0),
  Starter.meditate: TimeOfDay(hour: 6, minute: 30),
  Starter.read: TimeOfDay(hour: 21, minute: 0),
  Starter.move: TimeOfDay(hour: 7, minute: 0),
  Starter.journal: TimeOfDay(hour: 21, minute: 30),
};

/// Water uses a spread of reminders through the day (same as the Water screen).
const waterTimes = ['08:00', '10:00', '12:00', '14:00', '16:00', '18:00'];

const maxStarters = 3;

abstract final class OnboardingLogic {
  static const doneKey = 'onboarding_done_v1';

  /// Starters suggested for the chosen goals, in priority order, at most 3.
  static List<Starter> suggest(Set<OnboardingGoal> goals) {
    const map = <OnboardingGoal, List<Starter>>{
      OnboardingGoal.health: [Starter.water, Starter.medicine],
      OnboardingGoal.calm: [Starter.meditate, Starter.journal],
      OnboardingGoal.fitness: [Starter.move],
      OnboardingGoal.learning: [Starter.read],
      OnboardingGoal.focus: [Starter.read, Starter.meditate],
      OnboardingGoal.routines: [Starter.journal, Starter.water],
    };
    final out = <Starter>[];
    for (final g in OnboardingGoal.values) {
      if (!goals.contains(g)) continue;
      for (final s in map[g]!) {
        if (!out.contains(s) && out.length < maxStarters) out.add(s);
      }
    }
    return out.isEmpty ? [Starter.water] : out;
  }

  /// Builds the habits for the selected starters. [names] are the localised
  /// display names (so Nepali users get Nepali habit names).
  static List<Habit> buildHabits(
    Map<Starter, TimeOfDay> selected,
    Map<Starter, String> names, {
    String Function()? idGen,
  }) {
    final newId = idGen ?? HabitFlows.newId;
    String fmt(TimeOfDay t) => Habit.fmt(t);
    return [
      for (final e in selected.entries)
        switch (e.key) {
          Starter.water => Habit(
              id: newId(), name: '${names[e.key]} 💧', enabled: true,
              reminderHour: 8, reminderMinute: 0, reminderTimes: List.of(waterTimes),
              category: HabitCategory.water, waterTarget: 8, waterCompleted: 0),
          Starter.medicine => Habit(
              id: newId(), name: '${names[e.key]} 💊', enabled: true,
              reminderHour: e.value.hour, reminderMinute: e.value.minute,
              reminderTimes: [fmt(e.value)], category: HabitCategory.medicine,
              medicineName: names[e.key], medicineDose: '', medicineNotes: ''),
          Starter.meditate => Habit(
              id: newId(), name: '${names[e.key]} 🧘', enabled: true,
              reminderHour: e.value.hour, reminderMinute: e.value.minute,
              reminderTimes: [fmt(e.value)], category: HabitCategory.meditation,
              meditationGoalMin: 10, meditationTodayMin: 0),
          Starter.read => Habit(
              id: newId(), name: '${names[e.key]} 📖', enabled: true,
              reminderHour: e.value.hour, reminderMinute: e.value.minute,
              reminderTimes: [fmt(e.value)], category: HabitCategory.reading),
          Starter.move => Habit(
              id: newId(), name: '${names[e.key]} 💪', enabled: true,
              reminderHour: e.value.hour, reminderMinute: e.value.minute,
              reminderTimes: [fmt(e.value)], category: HabitCategory.exercise,
              exerciseGoalMin: 30, exerciseTodayMin: 0, stepsGoal: 6000, stepsToday: 0),
          Starter.journal => Habit(
              id: newId(), name: '${names[e.key]} ✍️', enabled: true,
              reminderHour: e.value.hour, reminderMinute: e.value.minute,
              reminderTimes: [fmt(e.value)]),
        },
    ];
  }

  /// Onboarding shows only to people who have never finished it and have no
  /// habits — existing users upgrading from v1 skip it.
  static Future<bool> isNeeded(List<Habit> existingHabits) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(doneKey) ?? false) return false;
    if (existingHabits.isNotEmpty) {
      await prefs.setBool(doneKey, true);
      return false;
    }
    return true;
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(doneKey, true);
  }
}
