import 'dart:convert';

/// Deterministic, platform-independent alarm id for a reminder key.
///
/// Dart's `String.hashCode` is not guaranteed to be stable across SDK
/// versions or isolates, so it must never be used for ids that are persisted
/// in the OS (AlarmManager request codes). This is 32-bit FNV-1a, masked to a
/// positive 31-bit int so it is a valid Android request code / Java `int`.
int stableAlarmId(String key) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(key)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  final id = hash & 0x7fffffff;
  return id == 0 ? 1 : id;
}
