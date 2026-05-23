part of 'main.dart';

class ScreenshotItem {
  const ScreenshotItem({
    required this.id,
    required this.displayName,
    required this.relativePath,
    required this.dateTakenMillis,
    required this.appName,
    required this.thumbnailPath,
  });

  final String id;
  final String displayName;
  final String relativePath;
  final int dateTakenMillis;
  final String appName;
  final String thumbnailPath;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateTakenMillis);

  bool matches(String query) {
    final q = query.toLowerCase();
    return appName.toLowerCase().contains(q) ||
        displayName.toLowerCase().contains(q) ||
        relativePath.toLowerCase().contains(q) ||
        _aliases(appName).any((alias) => alias.toLowerCase().contains(q));
  }

  static List<String> _aliases(String name) {
    final n = name.toLowerCase();
    if (n.contains('kakao')) return ['카카오톡', '카톡', 'KakaoTalk'];
    if (n.contains('karrot') || n.contains('carrot')) {
      return ['당근', '당근마켓', 'Karrot'];
    }
    if (n.contains('instagram')) return ['인스타그램', '인스타', 'Instagram'];
    if (n.contains('smartthings')) return ['스마트싱스', 'SmartThings'];
    return const [];
  }

  factory ScreenshotItem.fromMap(Map<dynamic, dynamic> map) {
    return ScreenshotItem(
      id: '${map['id']}',
      displayName: '${map['displayName'] ?? ''}',
      relativePath: '${map['relativePath'] ?? ''}',
      dateTakenMillis: (map['dateTakenMillis'] as num?)?.toInt() ?? 0,
      appName: '${map['appName'] ?? 'Unknown'}',
      thumbnailPath: '${map['thumbnailPath'] ?? ''}',
    );
  }
}

enum StackSortMode { latest, name, mostImages, fewestImages }

StackSortMode? _sortModeFromName(String? name) {
  if (name == null) return null;
  for (final mode in StackSortMode.values) {
    if (mode.name == name) return mode;
  }
  return null;
}

class StackItem {
  const StackItem({required this.key, required this.name, required this.items});

  final String key;
  final String name;
  final List<ScreenshotItem> items;
}

class ScreenshotSet {
  const ScreenshotSet({
    required this.key,
    required this.title,
    required this.timeRange,
    required this.items,
    this.memo = '',
    this.folderName,
  });

  final String key;
  final String title;
  final String timeRange;
  final List<ScreenshotItem> items;
  final String memo;
  final String? folderName;
}

class ShotlyNative {
  static const _channel = MethodChannel('shotly/native');

  static Future<bool> requestPhotoPermission() async {
    if (kIsWeb) return true;
    final result = await _channel.invokeMethod<bool>('requestPhotoPermission');
    return result ?? false;
  }

  static Future<bool> openPhotoSettings() async {
    if (kIsWeb) return false;
    final result = await _channel.invokeMethod<bool>('openPhotoSettings');
    return result ?? false;
  }

  static Future<List<ScreenshotItem>> getScreenshots() async {
    if (kIsWeb) return mockScreenshots();
    final result = await _channel.invokeMethod<List<dynamic>>('getScreenshots');
    return (result ?? const [])
        .map((item) => ScreenshotItem.fromMap(item as Map<dynamic, dynamic>))
        .toList();
  }

  static Future<ScreenshotItem?> pickImage() async {
    if (kIsWeb) return null;
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'pickImage',
    );
    if (result == null) return null;
    return ScreenshotItem.fromMap(result);
  }

  static Future<String?> getImagePreview(
    String imageId,
    String fallbackPath,
  ) async {
    if (kIsWeb) return fallbackPath;
    final result = await _channel.invokeMethod<String>('getImagePreview', {
      'imageId': imageId,
    });
    return result?.isEmpty == true ? fallbackPath : result ?? fallbackPath;
  }

  static Future<bool> deleteOriginalImage(String imageId) async {
    if (kIsWeb) return false;
    final result = await _channel.invokeMethod<bool>('deleteOriginalImage', {
      'imageId': imageId,
    });
    return result ?? false;
  }

  static Future<bool> deleteOriginalImages(List<String> imageIds) async {
    if (kIsWeb || imageIds.isEmpty) return false;
    final result = await _channel.invokeMethod<bool>('deleteOriginalImages', {
      'imageIds': imageIds,
    });
    return result ?? false;
  }

  static Future<bool> shareImages(List<String> imageIds) async {
    if (kIsWeb || imageIds.isEmpty) return false;
    final result = await _channel.invokeMethod<bool>('shareImages', {
      'imageIds': imageIds,
    });
    return result ?? false;
  }
}
