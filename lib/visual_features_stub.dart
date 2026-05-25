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
}

Future<Map<String, VisualFeature>> extractVisualFeatures(
  Map<String, String> imagePathsById,
) async => const {};

Future<List<VisualSmartCleanResult>> analyzeVisualSmartClean(
  List<VisualSmartCleanInput> items,
) async => const [];

double visualSimilarity(VisualFeature a, VisualFeature b) => 0;

int visualHashDistance(int a, int b) => 64;
