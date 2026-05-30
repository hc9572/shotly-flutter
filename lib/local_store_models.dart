class LocalShotlyState {
  const LocalShotlyState({
    this.manualStackNames = const [],
    this.stackNames = const {},
    this.imageAssignments = const {},
    this.setMemos = const {},
    this.folderNames = const {},
    this.folderColors = const {},
    this.setAssignments = const {},
    this.hiddenStackKeys = const {},
    this.excludedImageIds = const {},
    this.favoriteImageIds = const {},
    this.pinnedStackKeys = const [],
    this.sortModeName,
  });

  final List<String> manualStackNames;
  final Map<String, String> stackNames;
  final Map<String, String> imageAssignments;
  final Map<String, String> setMemos;
  final Map<String, String> folderNames;
  final Map<String, String> folderColors;
  final Map<String, String> setAssignments;
  final Set<String> hiddenStackKeys;
  final Set<String> excludedImageIds;
  final Set<String> favoriteImageIds;
  final List<String> pinnedStackKeys;
  final String? sortModeName;

  Map<String, Object?> toBackupJson() => {
    'manualStackNames': manualStackNames,
    'stackNames': stackNames,
    'imageAssignments': imageAssignments,
    'setMemos': setMemos,
    'folderNames': folderNames,
    'folderColors': folderColors,
    'setAssignments': setAssignments,
    'hiddenStackKeys': hiddenStackKeys.toList(),
    'excludedImageIds': excludedImageIds.toList(),
    'favoriteImageIds': favoriteImageIds.toList(),
    'pinnedStackKeys': pinnedStackKeys,
    if (sortModeName != null) 'sortModeName': sortModeName,
  };

  factory LocalShotlyState.fromBackupJson(Map<String, Object?> json) {
    return LocalShotlyState(
      manualStackNames: _stringList(json['manualStackNames']),
      stackNames: _stringMap(json['stackNames']),
      imageAssignments: _stringMap(json['imageAssignments']),
      setMemos: _stringMap(json['setMemos']),
      folderNames: _stringMap(json['folderNames']),
      folderColors: _stringMap(json['folderColors']),
      setAssignments: _stringMap(json['setAssignments']),
      hiddenStackKeys: _stringList(json['hiddenStackKeys']).toSet(),
      excludedImageIds: _stringList(json['excludedImageIds']).toSet(),
      favoriteImageIds: _stringList(json['favoriteImageIds']).toSet(),
      pinnedStackKeys: _stringList(json['pinnedStackKeys']),
      sortModeName: json['sortModeName']?.toString(),
    );
  }
}

class ShotlyBackupDocument {
  const ShotlyBackupDocument({
    required this.version,
    required this.exportedAt,
    required this.state,
  });

  factory ShotlyBackupDocument.fromJson(Map<String, Object?> json) {
    if (json['app'] != 'Shotly') {
      throw const FormatException('Not a Shotly backup file');
    }
    final version = (json['version'] as num?)?.toInt() ?? 0;
    if (version != 1) {
      throw FormatException('Unsupported Shotly backup version: $version');
    }
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Shotly backup data is missing');
    }
    return ShotlyBackupDocument(
      version: version,
      exportedAt:
          DateTime.tryParse('${json['exportedAt'] ?? ''}') ?? DateTime.now(),
      state: LocalShotlyState.fromBackupJson(data.cast<String, Object?>()),
    );
  }

  final int version;
  final DateTime exportedAt;
  final LocalShotlyState state;

  Map<String, Object?> toJson() => {
    'app': 'Shotly',
    'version': version,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'containsOriginalImages': false,
    'data': state.toBackupJson(),
  };

  static ShotlyBackupDocument current(LocalShotlyState state) =>
      ShotlyBackupDocument(
        version: 1,
        exportedAt: DateTime.now(),
        state: state,
      );
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return [for (final item in value) '$item'];
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry('$key', '$item'));
}

abstract class LocalStore {
  Future<LocalShotlyState> load();
  Future<void> replaceAll(LocalShotlyState state);
  Future<void> upsertManualStack(String name);
  Future<void> renameStack(String stackKey, String name);
  Future<void> hideStack(String stackKey);
  Future<void> restoreStack(String stackKey);
  Future<void> excludeImage(String imageId);
  Future<void> restoreImage(String imageId);
  Future<void> favoriteImage(String imageId);
  Future<void> unfavoriteImage(String imageId);
  Future<void> moveImage(String imageId, String stackKey);
  Future<void> saveSetMemo(String setKey, String memo);
  Future<void> saveFolderName(String folderKey, String name);
  Future<void> saveFolderColor(String folderKey, String colorKey);
  Future<void> assignImageToSet(String imageId, String setKey);
  Future<void> pinStack(String stackKey);
  Future<void> unpinStack(String stackKey);
  Future<void> saveSortMode(String sortModeName);
}
