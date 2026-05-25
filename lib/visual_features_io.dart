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
    this.targetFolderKey,
    this.targetFolderName,
    this.selectableImageIds = const [],
  });

  final String type;
  final String title;
  final String subtitle;
  final List<String> imageIds;
  final String? targetFolderKey;
  final String? targetFolderName;
  final List<String> selectableImageIds;
}

class VisualSmartCleanInput {
  const VisualSmartCleanInput({
    required this.id,
    required this.path,
    required this.dateMillis,
    this.assignmentRaw = '',
    this.folderName = '',
  });

  final String id;
  final String path;
  final int dateMillis;
  final String assignmentRaw;
  final String folderName;

  Map<String, Object?> toJson() => {
    'id': id,
    'path': path,
    'dateMillis': dateMillis,
    'assignmentRaw': assignmentRaw,
    'folderName': folderName,
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
        targetFolderKey: result['targetFolderKey'] as String?,
        targetFolderName: result['targetFolderName'] as String?,
        selectableImageIds:
            ((result['selectableImageIds'] as List?) ?? const [])
                .cast<String>(),
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
              assignmentRaw: (item['assignmentRaw'] as String?) ?? '',
              folderName: (item['folderName'] as String?) ?? '',
            ),
          )
          .where(
            (item) => item.path.isNotEmpty && !item.path.startsWith('mock://'),
          )
          .toList()
        ..sort((a, b) => b.dateMillis.compareTo(a.dateMillis));
  if (items.length < 2) return const [];

  const maxItems = 500;
  final scopedItems = items.take(maxItems).toList();
  final itemById = {for (final item in scopedItems) item.id: item};
  final assignedFolderKeysById = <String, List<String>>{
    for (final item in scopedItems)
      item.id: _folderAssignmentKeys(item.assignmentRaw),
  };
  final folderGroups =
      <
        String,
        List<
          ({
            String id,
            String path,
            int dateMillis,
            String assignmentRaw,
            String folderName,
          })
        >
      >{};
  final folderNames = <String, String>{};
  for (final item in scopedItems) {
    for (final folderKey in assignedFolderKeysById[item.id]!) {
      folderGroups.putIfAbsent(folderKey, () => []).add(item);
      if (item.folderName.trim().isNotEmpty)
        folderNames[folderKey] = item.folderName.trim();
    }
  }
  for (final group in folderGroups.values) {
    group.sort((a, b) => b.dateMillis.compareTo(a.dateMillis));
  }

  final unassigned = scopedItems
      .where((item) => assignedFolderKeysById[item.id]!.isEmpty)
      .toList();
  final analysisItemsById =
      <
        String,
        ({
          String id,
          String path,
          int dateMillis,
          String assignmentRaw,
          String folderName,
        })
      >{
        for (final item in unassigned) item.id: item,
        for (final group in folderGroups.values)
          for (final item in group.take(6)) item.id: item,
      };
  final features = <String, VisualFeature>{};
  for (final item in analysisItemsById.values) {
    try {
      final file = File(item.path);
      final decoded = img.decodeImage(file.readAsBytesSync());
      if (decoded != null) features[item.id] = _featureFromImage(decoded);
    } catch (_) {
      // Ignore unreadable thumbnails.
    }
  }
  if (features.length < 2) return const [];
  final readableUnassigned = unassigned
      .where((item) => features.containsKey(item.id))
      .toList();

  final results = <Map<String, Object?>>[];
  final consumedUnassignedIds = <String>{};

  // Existing confirmed folders win first. Display representative is newest item.
  for (final entry in folderGroups.entries) {
    final folderKey = entry.key;
    final groupItems = entry.value
        .where((item) => features.containsKey(item.id))
        .toList();
    if (groupItems.isEmpty) continue;
    final samples = groupItems.take(6).toList();
    final matched = <String>[];
    for (final candidate in readableUnassigned) {
      if (consumedUnassignedIds.contains(candidate.id)) continue;
      final candidateFeature = features[candidate.id];
      if (candidateFeature == null) continue;
      var bestSimilarity = 0.0;
      var bestDistance = 64;
      for (final sample in samples) {
        final sampleFeature = features[sample.id];
        if (sampleFeature == null) continue;
        final similarity = visualSimilarity(candidateFeature, sampleFeature);
        final distance = visualHashDistance(
          candidateFeature.dHash,
          sampleFeature.dHash,
        );
        if (similarity > bestSimilarity) bestSimilarity = similarity;
        if (distance < bestDistance) bestDistance = distance;
      }
      if (bestSimilarity >= 0.88 || bestDistance <= 10)
        matched.add(candidate.id);
    }
    if (matched.isEmpty) continue;
    consumedUnassignedIds.addAll(matched);
    final representativeId = groupItems.first.id;
    final folderName = folderNames[folderKey] ?? '기존 폴더';
    final imageIds = [representativeId, ...matched.take(11)];
    results.add({
      'type': 'existingFolder',
      'title': '$folderName에 추가 후보 ${matched.length}장',
      'subtitle': '최신 대표 이미지와 비슷한 새 화면이에요',
      'imageIds': imageIds,
      'targetFolderKey': folderKey,
      'targetFolderName': folderName,
      'selectableImageIds': matched.take(11).toList(),
    });
    if (results.length >= 3) break;
  }

  final freeUnassigned = readableUnassigned
      .where((item) => !consumedUnassignedIds.contains(item.id))
      .take(180)
      .toList();

  // Near-duplicates across the whole same-stack scope. No time window.
  final usedDuplicateIds = <String>{};
  for (var i = 0; i < freeUnassigned.length; i++) {
    final a = freeUnassigned[i];
    if (usedDuplicateIds.contains(a.id)) continue;
    final aFeature = features[a.id];
    if (aFeature == null) continue;
    final ids = <String>{a.id};
    for (var j = i + 1; j < freeUnassigned.length; j++) {
      final b = freeUnassigned[j];
      if (usedDuplicateIds.contains(b.id)) continue;
      final bFeature = features[b.id];
      if (bFeature == null) continue;
      final distance = visualHashDistance(aFeature.dHash, bFeature.dHash);
      final similarity = visualSimilarity(aFeature, bFeature);
      if (similarity >= 0.96 || distance <= 5) ids.add(b.id);
    }
    if (ids.length >= 2) {
      final sortedIds = _sortIdsByNewest(ids, itemById).take(10).toList();
      usedDuplicateIds.addAll(sortedIds);
      consumedUnassignedIds.addAll(sortedIds);
      results.add({
        'type': 'duplicates',
        'title': '거의 같은 화면 ${sortedIds.length}장',
        'subtitle': '최신 1장만 대표로 보고 나머지를 선택해둘게요',
        'imageIds': sortedIds,
        'selectableImageIds': sortedIds.skip(1).toList(),
      });
      if (results.length >= 4) return results.take(4).toList();
    }
  }

  // Similar new groups across the whole same-stack scope. No time window.
  final remaining = freeUnassigned
      .where((item) => !consumedUnassignedIds.contains(item.id))
      .toList();
  final parent = <String, String>{
    for (final item in remaining) item.id: item.id,
  };
  String find(String id) {
    var root = parent[id] ?? id;
    while (parent[root] != root) {
      root = parent[root]!;
    }
    var current = id;
    while (parent[current] != current) {
      final next = parent[current]!;
      parent[current] = root;
      current = next;
    }
    return root;
  }

  void union(String a, String b) {
    final ar = find(a);
    final br = find(b);
    if (ar != br) parent[br] = ar;
  }

  for (var i = 0; i < remaining.length; i++) {
    final a = remaining[i];
    final aFeature = features[a.id];
    if (aFeature == null) continue;
    for (var j = i + 1; j < remaining.length; j++) {
      final b = remaining[j];
      final bFeature = features[b.id];
      if (bFeature == null) continue;
      final similarity = visualSimilarity(aFeature, bFeature);
      final distance = visualHashDistance(aFeature.dHash, bFeature.dHash);
      if (similarity >= 0.90 || distance <= 10) union(a.id, b.id);
    }
  }

  final groups = <String, List<String>>{};
  for (final item in remaining) {
    groups.putIfAbsent(find(item.id), () => []).add(item.id);
  }
  final sortedGroups =
      groups.values
          .where((ids) => ids.length >= 2)
          .map((ids) => _sortIdsByNewest(ids, itemById).take(12).toList())
          .toList()
        ..sort((a, b) {
          final at = itemById[a.first]?.dateMillis ?? 0;
          final bt = itemById[b.first]?.dateMillis ?? 0;
          return bt.compareTo(at);
        });
  for (final ids in sortedGroups.take(4 - results.length)) {
    results.add({
      'type': 'flow',
      'title': '비슷한 화면 ${ids.length}장',
      'subtitle': '같은 앱 안에서 한 폴더로 묶기 좋은 화면이에요',
      'imageIds': ids,
      'selectableImageIds': ids,
    });
  }

  return results.take(4).toList();
}

List<String> _folderAssignmentKeys(String raw) => raw
    .split('\u001F')
    .map((key) => key.trim())
    .where((key) => key.contains('::folder::'))
    .toList();

List<String> _sortIdsByNewest(
  Iterable<String> ids,
  Map<
    String,
    ({
      String id,
      String path,
      int dateMillis,
      String assignmentRaw,
      String folderName,
    })
  >
  itemById,
) {
  final sorted = ids.toList()
    ..sort(
      (a, b) => (itemById[b]?.dateMillis ?? 0).compareTo(
        itemById[a]?.dateMillis ?? 0,
      ),
    );
  return sorted;
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
