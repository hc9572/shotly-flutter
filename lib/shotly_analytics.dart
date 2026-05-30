import 'package:flutter/foundation.dart';

/// Privacy-safe product event logger.
///
/// Keep payloads aggregate-only. Never add screenshots, thumbnails, file names,
/// file paths, memos, folder names, search queries, image IDs, or image content.
class ShotlyAnalytics {
  const ShotlyAnalytics._();

  static const bool enabled = false;

  static Future<void> log(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    final safeParameters = Map<String, Object?>.from(parameters)
      ..removeWhere((key, value) => value == null);
    if (kDebugMode) {
      debugPrint('ShotlyAnalytics $name $safeParameters');
    }
    if (!enabled) return;

    // Future provider hook: Firebase Analytics, custom server log, etc.
    // Only send the allowlisted product events/aggregate parameters documented in
    // docs/release/ANALYTICS_EVENTS.md.
  }
}
