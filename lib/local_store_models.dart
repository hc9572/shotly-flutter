class LocalShotlyState {
  const LocalShotlyState({
    this.manualStackNames = const [],
    this.stackNames = const {},
    this.imageAssignments = const {},
    this.setMemos = const {},
    this.hiddenStackKeys = const {},
    this.excludedImageIds = const {},
  });

  final List<String> manualStackNames;
  final Map<String, String> stackNames;
  final Map<String, String> imageAssignments;
  final Map<String, String> setMemos;
  final Set<String> hiddenStackKeys;
  final Set<String> excludedImageIds;
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
}
