import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class VisualFeature {
  const VisualFeature({required this.aHash, required this.dHash, required this.histogram});

  final int aHash;
  final int dHash;
  final List<double> histogram;
}

Future<Map<String, VisualFeature>> extractVisualFeatures(Map<String, String> imagePathsById) async {
  if (imagePathsById.isEmpty) return const {};
  return compute(_extractVisualFeaturesSync, imagePathsById);
}

Map<String, VisualFeature> _extractVisualFeaturesSync(Map<String, String> imagePathsById) {
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
  return img.copyCrop(source, x: 0, y: top, width: source.width, height: cropHeight);
}

int _averageHash(img.Image source) {
  final resized = img.copyResize(source, width: 8, height: 8, interpolation: img.Interpolation.average);
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
  final resized = img.copyResize(source, width: 9, height: 8, interpolation: img.Interpolation.average);
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
  final resized = img.copyResize(source, width: 32, height: 32, interpolation: img.Interpolation.average);
  final bins = List<double>.filled(24, 0);
  for (final pixel in resized) {
    bins[(pixel.r / 32).floor().clamp(0, 7)] += 1;
    bins[8 + (pixel.g / 32).floor().clamp(0, 7)] += 1;
    bins[16 + (pixel.b / 32).floor().clamp(0, 7)] += 1;
  }
  final total = resized.width * resized.height * 3.0;
  return [for (final value in bins) value / total];
}

int _luma(img.Pixel pixel) => (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();

double visualSimilarity(VisualFeature a, VisualFeature b) {
  final aHashSimilarity = 1 - (_hammingDistance(a.aHash, b.aHash) / 64);
  final dHashSimilarity = 1 - (_hammingDistance(a.dHash, b.dHash) / 64);
  final hashSimilarity = (aHashSimilarity * 0.45) + (dHashSimilarity * 0.55);
  final histogramSimilarity = _histogramIntersection(a.histogram, b.histogram);
  return (hashSimilarity * 0.82) + (histogramSimilarity * 0.18);
}

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
