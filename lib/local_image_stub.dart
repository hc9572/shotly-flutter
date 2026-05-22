import 'package:flutter/widgets.dart';

Widget buildLocalImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  return fallback ?? SizedBox(width: width, height: height);
}
