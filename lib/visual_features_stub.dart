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
}

Future<Map<String, VisualFeature>> extractVisualFeatures(
  Map<String, String> imagePathsById,
) async => const {};

Future<List<VisualSmartCleanResult>> analyzeVisualSmartClean(
  List<VisualSmartCleanInput> items,
) async => const [];

Future<List<VisualSmartCleanResult>> analyzeVisualSmartCleanFromFeatures(
  List<VisualSmartCleanInput> items,
  Map<String, VisualFeature> features,
) async => const [];

double visualSimilarity(VisualFeature a, VisualFeature b) => 0;

int visualHashDistance(int a, int b) => 64;
