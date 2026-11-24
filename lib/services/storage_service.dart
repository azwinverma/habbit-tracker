import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';


class StorageService {
static const _kKey = 'habits_v1';


Future<List<Habit>> loadHabits() async {
final prefs = await SharedPreferences.getInstance();
final raw = prefs.getString(_kKey);
if (raw == null || raw.isEmpty) return [];
final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
return list.map((e) => Habit.fromJson(e)).toList();
}


Future<void> saveHabits(List<Habit> habits) async {
final prefs = await SharedPreferences.getInstance();
final raw = jsonEncode(habits.map((e) => e.toJson()).toList());
await prefs.setString(_kKey, raw);
}
}