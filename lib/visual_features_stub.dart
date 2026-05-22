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

Future<Map<String, VisualFeature>> extractVisualFeatures(
  Map<String, String> imagePathsById,
) async => const {};

double visualSimilarity(VisualFeature a, VisualFeature b) => 0;
