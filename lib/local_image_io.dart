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
  return Image.file(
    File(path),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) =>
        fallback ?? SizedBox(width: width, height: height),
  );
}
