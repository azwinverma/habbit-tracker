import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../core/db/app_database.dart';

/// Asks for a store rating at a happy moment (just after completing a
/// habit) and only from engaged users, using Google Play's / Apple's own
/// in-app review sheet (the stores decide whether it actually shows).
///
/// Rules: ≥ 6 completions on ≥ 3 different days, app used for ≥ 4 days,
/// at most once every 120 days and 3 times ever. Ratings and reviews are
/// one of the strongest store-ranking (ASO) signals.
class ReviewPrompt {
  ReviewPrompt(this._db, {InAppReview? review, DateTime Function()? clock})
      : _review = review,
        _clock = clock ?? DateTime.now;

  static ReviewPrompt? _instance;
  static ReviewPrompt get instance => _instance ??= ReviewPrompt(AppDatabase.instance);
  static set instance(ReviewPrompt p) => _instance = p;

  final AppDatabase _db;
  final InAppReview? _review;
  final DateTime Function() _clock;

  static const _key = 'review:state';
  static const minCompletions = 6;
  static const minDays = 3;
  static const minAgeDays = 4;
  static const cooldownDays = 120;
  static const maxAsks = 3;

  /// Records a completed habit and asks for a rating if the rules allow.
  /// Returns true when the review sheet was requested.
  Future<bool> onHabitCompleted() async {
    try {
      final now = _clock();
      final st = await _load(now);
      st.count++;
      final day = '${now.year}-${now.month}-${now.day}';
      if (!st.days.contains(day)) st.days.add(day);
      if (st.days.length > 10) st.days.removeAt(0);
      final ask = shouldAsk(st, now);
      if (ask) {
        st.asks++;
        st.lastAsked = now;
      }
      await _db.setMeta(_key, jsonEncode(st.toJson()));
      if (ask) {
        final r = _review ?? InAppReview.instance;
        if (await r.isAvailable()) await r.requestReview();
      }
      return ask;
    } catch (e) {
      debugPrint('[Review] $e');
      return false;
    }
  }

  @visibleForTesting
  static bool shouldAsk(ReviewState st, DateTime now) =>
      st.count >= minCompletions &&
      st.days.length >= minDays &&
      now.difference(st.firstSeen).inDays >= minAgeDays &&
      st.asks < maxAsks &&
      (st.lastAsked == null || now.difference(st.lastAsked!).inDays >= cooldownDays);

  Future<ReviewState> _load(DateTime now) async {
    final raw = await _db.getMeta(_key);
    if (raw == null) return ReviewState(firstSeen: now);
    try {
      return ReviewState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return ReviewState(firstSeen: now);
    }
  }
}

class ReviewState {
  ReviewState({required this.firstSeen, this.count = 0, List<String>? days, this.asks = 0, this.lastAsked})
      : days = days ?? [];
  DateTime firstSeen;
  int count;
  List<String> days;
  int asks;
  DateTime? lastAsked;

  Map<String, Object?> toJson() => {
        'f': firstSeen.millisecondsSinceEpoch,
        'c': count,
        'd': days,
        'a': asks,
        if (lastAsked != null) 'l': lastAsked!.millisecondsSinceEpoch,
      };

  factory ReviewState.fromJson(Map<String, dynamic> j) => ReviewState(
        firstSeen: DateTime.fromMillisecondsSinceEpoch(j['f'] as int),
        count: j['c'] as int? ?? 0,
        days: (j['d'] as List?)?.cast<String>() ?? [],
        asks: j['a'] as int? ?? 0,
        lastAsked: j['l'] == null ? null : DateTime.fromMillisecondsSinceEpoch(j['l'] as int),
      );
}
