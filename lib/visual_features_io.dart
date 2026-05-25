import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class VisualFeature {
  const VisualFeature({
    required this.aHash,
    required this.dHash,
    required this.histogram,
  });

  final int aHash;
  final int dHash;
  final List<double> histogram;
}

class VisualSmartCleanResult {
  const VisualSmartCleanResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.imageIds,
  });

  final String type;
  final String title;
  final String subtitle;
  final List<String> imageIds;
}

class VisualSmartCleanInput {
  const VisualSmartCleanInput({
    required this.id,
    required this.path,
    required this.dateMillis,
  });

  final String id;
  final String path;
  final int dateMillis;

  Map<String, Object?> toJson() => {
    'id': id,
    'path': path,
    'dateMillis': dateMillis,
  };
}

Future<Map<String, VisualFeature>> extractVisualFeatures(
  Map<String, String> imagePathsById,
) async {
  if (imagePathsById.isEmpty) return const {};
  return compute(_extractVisualFeaturesSync, imagePathsById);
}

Future<List<VisualSmartCleanResult>> analyzeVisualSmartClean(
  List<VisualSmartCleanInput> items,
) async {
  if (items.length < 2) return const [];
  final rawResults = await compute(_analyzeVisualSmartCleanSync, [
    for (final item in items) item.toJson(),
  ]);
  return [
    for (final result in rawResults)
      VisualSmartCleanResult(
        type: result['type'] as String,
        title: result['title'] as String,
        subtitle: result['subtitle'] as String,
        imageIds: (result['imageIds'] as List).cast<String>(),
      ),
  ];
}

List<Map<String, Object?>> _analyzeVisualSmartCleanSync(
  List<Map<String, Object?>> rawItems,
) {
  final items =
      rawItems
          .map(
            (item) => (
              id: item['id'] as String,
              path: item['path'] as String,
              dateMillis: item['dateMillis'] as int,
            ),
          )
          .where(
            (item) => item.path.isNotEmpty && !item.path.startsWith('mock://'),
          )
          .toList()
        ..sort((a, b) => b.dateMillis.compareTo(a.dateMillis));
  if (items.length < 2) return const [];

  final itemById = {for (final item in items) item.id: item};
  final metadata = <String, ({int size})>{};
  final features = <String, VisualFeature>{};
  for (final item in items) {
    try {
      final file = File(item.path);
      metadata[item.id] = (size: file.lengthSync());
      final decoded = img.decodeImage(file.readAsBytesSync());
      if (decoded != null) features[item.id] = _featureFromImage(decoded);
    } catch (_) {
      // Ignore unreadable thumbnails.
    }
  }

  final windows = <List<({String id, String path, int dateMillis})>>[];
  var current = <({String id, String path, int dateMillis})>[];
  for (final item in items) {
    if (current.isEmpty) {
      current = [item];
      continue;
    }
    final gapMillis = (current.first.dateMillis - item.dateMillis).abs();
    if (gapMillis <= const Duration(minutes: 45).inMilliseconds &&
        current.length < 80) {
      current.add(item);
    } else {
      windows.add(current);
      current = [item];
    }
  }
  if (current.isNotEmpty) windows.add(current);

  final results = <Map<String, Object?>>[];
  final usedDuplicateIds = <String>{};
  for (final window in windows) {
    if (window.length < 2) continue;
    final duplicateIds = <String>{};
    final capped = window.take(80).toList();
    for (var i = 0; i < capped.length; i++) {
      final a = capped[i];
      final af = metadata[a.id];
      if (af == null) continue;
      for (var j = i + 1; j < capped.length; j++) {
        final b = capped[j];
        final bf = metadata[b.id];
        if (bf == null) continue;
        final aFeature = features[a.id];
        final bFeature = features[b.id];
        if (aFeature == null || bFeature == null) continue;
        final sizeGap = (af.size - bf.size).abs();
        final timeGap = (a.dateMillis - b.dateMillis).abs();
        final allowedGap = math.max(
          2048,
          (math.max(af.size, bf.size) * 0.025).round(),
        );
        final distance = visualHashDistance(aFeature.dHash, bFeature.dHash);
        final similarity = visualSimilarity(aFeature, bFeature);
        if (timeGap <= const Duration(minutes: 10).inMilliseconds &&
            sizeGap <= allowedGap &&
            (distance <= 6 || similarity >= 0.94)) {
          duplicateIds.add(a.id);
          duplicateIds.add(b.id);
        }
      }
    }
    duplicateIds.removeAll(usedDuplicateIds);
    if (duplicateIds.length >= 2) {
      usedDuplicateIds.addAll(duplicateIds);
      final ids = items
          .where((item) => duplicateIds.contains(item.id))
          .map((item) => item.id)
          .take(10)
          .toList();
      results.add({
        'type': 'duplicates',
        'title': '거의 같은 화면 ${ids.length}장',
        'subtitle': '대표 1장만 남기고 나머지를 선택해둘게요',
        'imageIds': ids,
      });
      if (results.length >= 3) break;
    }
  }

  for (final window in windows) {
    if (window.length < 4) continue;
    final flow = <String>[];
    for (final item in window.take(24)) {
      if (!metadata.containsKey(item.id)) continue;
      if (flow.isEmpty) {
        flow.add(item.id);
        continue;
      }
      final previous = itemById[flow.last];
      final previousMeta = metadata[flow.last];
      final currentMeta = metadata[item.id];
      final previousFeature = features[flow.last];
      final currentFeature = features[item.id];
      if (previous == null ||
          previousMeta == null ||
          currentMeta == null ||
          previousFeature == null ||
          currentFeature == null) {
        continue;
      }
      final gapMillis = (previous.dateMillis - item.dateMillis).abs();
      final sizeRatio =
          math.min(previousMeta.size, currentMeta.size) /
          math.max(previousMeta.size, currentMeta.size);
      final similarity = visualSimilarity(previousFeature, currentFeature);
      final hashDistance = visualHashDistance(
        previousFeature.dHash,
        currentFeature.dHash,
      );
      if (gapMillis <= const Duration(minutes: 7).inMilliseconds &&
          sizeRatio >= 0.35 &&
          (similarity >= 0.74 || hashDistance <= 18)) {
        flow.add(item.id);
      }
    }
    if (flow.length >= 4) {
      final ids = flow.take(12).toList();
      results.add({
        'type': 'flow',
        'title': '비슷한 흐름 ${ids.length}장',
        'subtitle': '한 폴더로 묶기 좋은 연속 화면이에요',
        'imageIds': ids,
      });
      break;
    }
  }

  return results.take(4).toList();
}

Map<String, VisualFeature> _extractVisualFeaturesSync(
  Map<String, String> imagePathsById,
) {
  final features = <String, VisualFeature>{};
  for (final entry in imagePathsById.entries) {
    final path = entry.value;
    if (path.isEmpty || path.startsWith('mock://')) continue;
    try {
      final bytes = File(path).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) continue;
      features[entry.key] = _featureFromImage(decoded);
    } catch (_) {
      // Ignore unreadable thumbnails; caller can use filename fallback.
    }
  }
  return features;
}

VisualFeature _featureFromImage(img.Image source) {
  final cropped = _cropSystemBars(source);
  return VisualFeature(
    aHash: _averageHash(cropped),
    dHash: _differenceHash(cropped),
    histogram: _colorHistogram(cropped),
  );
}

img.Image _cropSystemBars(img.Image source) {
  final top = (source.height * 0.08).round();
  final bottom = (source.height * 0.08).round();
  final cropHeight = math.max(1, source.height - top - bottom);
  return img.copyCrop(
    source,
    x: 0,
    y: top,
    width: source.width,
    height: cropHeight,
  );
}

int _averageHash(img.Image source) {
  final resized = img.copyResize(
    source,
    width: 8,
    height: 8,
    interpolation: img.Interpolation.average,
  );
  final values = <int>[];
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final pixel = resized.getPixel(x, y);
      values.add(_luma(pixel));
    }
  }
  final avg = values.reduce((a, b) => a + b) / values.length;
  var hash = 0;
  for (final value in values) {
    hash = (hash << 1) | (value >= avg ? 1 : 0);
  }
  return hash;
}

int _differenceHash(img.Image source) {
  final resized = img.copyResize(
    source,
    width: 9,
    height: 8,
    interpolation: img.Interpolation.average,
  );
  var hash = 0;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final left = _luma(resized.getPixel(x, y));
      final right = _luma(resized.getPixel(x + 1, y));
      hash = (hash << 1) | (left > right ? 1 : 0);
    }
  }
  return hash;
}

List<double> _colorHistogram(img.Image source) {
  final resized = img.copyResize(
    source,
    width: 32,
    height: 32,
    interpolation: img.Interpolation.average,
  );
  final bins = List<double>.filled(24, 0);
  for (final pixel in resized) {
    bins[(pixel.r / 32).floor().clamp(0, 7)] += 1;
    bins[8 + (pixel.g / 32).floor().clamp(0, 7)] += 1;
    bins[16 + (pixel.b / 32).floor().clamp(0, 7)] += 1;
  }
  final total = resized.width * resized.height * 3.0;
  return [for (final value in bins) value / total];
}

int _luma(img.Pixel pixel) =>
    (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();

double visualSimilarity(VisualFeature a, VisualFeature b) {
  final aHashSimilarity = 1 - (_hammingDistance(a.aHash, b.aHash) / 64);
  final dHashSimilarity = 1 - (_hammingDistance(a.dHash, b.dHash) / 64);
  final hashSimilarity = (aHashSimilarity * 0.45) + (dHashSimilarity * 0.55);
  final histogramSimilarity = _histogramIntersection(a.histogram, b.histogram);
  return (hashSimilarity * 0.82) + (histogramSimilarity * 0.18);
}

int visualHashDistance(int a, int b) => _hammingDistance(a, b);

int _hammingDistance(int a, int b) {
  var value = a ^ b;
  var count = 0;
  while (value != 0) {
    count += value & 1;
    value >>= 1;
  }
  return count;
}

double _histogramIntersection(List<double> a, List<double> b) {
  final length = math.min(a.length, b.length);
  var sum = 0.0;
  for (var i = 0; i < length; i++) {
    sum += math.min(a[i], b[i]);
  }
  return sum;
}
