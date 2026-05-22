class LocalShotlyState {
  const LocalShotlyState({
    this.manualStackNames = const [],
    this.stackNames = const {},
    this.imageAssignments = const {},
    this.setMemos = const {},
    this.folderNames = const {},
    this.setAssignments = const {},
    this.hiddenStackKeys = const {},
    this.excludedImageIds = const {},
    this.pinnedStackKeys = const [],
    this.sortModeName,
  });

  final List<String> manualStackNames;
  final Map<String, String> stackNames;
  final Map<String, String> imageAssignments;
  final Map<String, String> setMemos;
  final Map<String, String> folderNames;
  final Map<String, String> setAssignments;
  final Set<String> hiddenStackKeys;
  final Set<String> excludedImageIds;
  final List<String> pinnedStackKeys;
  final String? sortModeName;
}

abstract class LocalStore {
  Future<LocalShotlyState> load();
  Future<void> upsertManualStack(String name);
  Future<void> renameStack(String stackKey, String name);
  Future<void> hideStack(String stackKey);
  Future<void> restoreStack(String stackKey);
  Future<void> excludeImage(String imageId);
  Future<void> restoreImage(String imageId);
  Future<void> moveImage(String imageId, String stackKey);
  Future<void> saveSetMemo(String setKey, String memo);
  Future<void> saveFolderName(String folderKey, String name);
  Future<void> assignImageToSet(String imageId, String setKey);
  Future<void> pinStack(String stackKey);
  Future<void> unpinStack(String stackKey);
  Future<void> saveSortMode(String sortModeName);
}
