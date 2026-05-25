import 'dart:io';

import 'package:flutter/widgets.dart';

Widget buildLocalImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  if (path.isEmpty) return fallback ?? SizedBox(width: width, height: height);
  // Pass only one decode target so Flutter preserves source aspect ratio.
  // Supplying both cacheWidth and cacheHeight can decode thumbnails into the
  // frame ratio first, which makes screenshots look flattened before BoxFit
  // gets a chance to crop them correctly.
  final cacheWidth = width == null || !width.isFinite
      ? null
      : (width * 3).round();
  return Image.file(
    File(path),
    width: width,
    height: height,
    cacheWidth: cacheWidth,
    fit: fit,
    filterQuality: FilterQuality.low,
    gaplessPlayback: true,
    errorBuilder: (context, error, stackTrace) =>
        fallback ?? SizedBox(width: width, height: height),
  );
}
