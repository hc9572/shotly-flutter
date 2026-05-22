import 'main.dart';

List<ScreenshotItem> mockScreenshots() {
  final now = DateTime.now();
  final apps = ['SmartThings', 'Instagram', 'KakaoTalk', 'Figma', 'Chrome', 'Karrot'];
  return List.generate(42, (index) {
    final app = apps[index % apps.length];
    final date = now.subtract(Duration(days: index % 12, hours: index % 5, minutes: index * 7));
    return ScreenshotItem(
      id: 'mock-$index',
      displayName: 'Screenshot_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${app}_$index.png',
      relativePath: 'Pictures/Screenshots/$app',
      dateTakenMillis: date.millisecondsSinceEpoch,
      appName: app,
      thumbnailPath: 'mock://$app/$index',
    );
  });
}
