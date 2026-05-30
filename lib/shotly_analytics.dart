import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Privacy-safe product event logger.
///
/// Keep payloads aggregate-only. Never add screenshots, thumbnails, file names,
/// file paths, memos, folder names, search queries, image IDs, or image content.
class ShotlyAnalytics {
  const ShotlyAnalytics._();

  static const bool enabled = true;
  static const _channel = MethodChannel('shotly/native');
  static const Set<String> _allowedEvents = {
    'app_open',
    'photo_permission_granted',
    'photo_permission_denied',
    'screen_analysis_started',
    'screen_analysis_completed',
    'screen_analysis_failed',
    'backup_exported',
    'backup_imported',
    'delete_original_requested',
    'delete_original_succeeded',
    'delete_original_failed',
  };

  static Future<void> log(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    final safeParameters = Map<String, Object?>.from(parameters)
      ..removeWhere((key, value) => value == null);
    if (kDebugMode) {
      debugPrint('ShotlyAnalytics $name $safeParameters');
    }
    if (!enabled || kIsWeb) return;
    if (!_allowedEvents.contains(name)) {
      if (kDebugMode) {
        debugPrint('ShotlyAnalytics blocked non-allowlisted event: $name');
      }
      return;
    }

    try {
      await _channel.invokeMethod<bool>('logAnalyticsEvent', {
        'name': name,
        'parameters': safeParameters,
      });
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('ShotlyAnalytics provider unavailable: $error');
        debugPrintStack(stackTrace: stack);
      }
    }
  }
}
