import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_store_models.dart';

class ShotlyLocalStore implements LocalStore {
  static const _manualStacksPrefsKey = 'shotly.manualStacks';
  static const _stackNamesPrefsKey = 'shotly.stackNames';
  static const _hiddenStacksPrefsKey = 'shotly.hiddenStacks';
  static const _excludedImagesPrefsKey = 'shotly.excludedImages';
  static const _imageAssignmentsPrefsKey = 'shotly.imageAssignments';
  static const _setMemosPrefsKey = 'shotly.setMemos';
  static const _folderNamesPrefsKey = 'shotly.folderNames';
  static const _setAssignmentsPrefsKey = 'shotly.setAssignments';
  static const _pinnedStacksPrefsKey = 'shotly.pinnedStacks';
  static const _sortModePrefsKey = 'shotly.sortMode';

  @override
  Future<LocalShotlyState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalShotlyState(
      manualStackNames: prefs.getStringList(_manualStacksPrefsKey) ?? const [],
      stackNames: _decodeStringMap(prefs.getString(_stackNamesPrefsKey)),
      imageAssignments: _decodeStringMap(
        prefs.getString(_imageAssignmentsPrefsKey),
      ),
      setMemos: _decodeStringMap(prefs.getString(_setMemosPrefsKey)),
      folderNames: _decodeStringMap(prefs.getString(_folderNamesPrefsKey)),
      setAssignments: _decodeStringMap(
        prefs.getString(_setAssignmentsPrefsKey),
      ),
      hiddenStackKeys: (prefs.getStringList(_hiddenStacksPrefsKey) ?? const [])
          .toSet(),
      excludedImageIds:
          (prefs.getStringList(_excludedImagesPrefsKey) ?? const []).toSet(),
      pinnedStackKeys: prefs.getStringList(_pinnedStacksPrefsKey) ?? const [],
      sortModeName: prefs.getString(_sortModePrefsKey),
    );
  }

  @override
  Future<void> upsertManualStack(String name) async {
    final state = await load();
    final names = [...state.manualStackNames];
    if (!names.contains(name)) names.add(name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_manualStacksPrefsKey, names);
  }

  @override
  Future<void> renameStack(String stackKey, String name) =>
      _updateMap(_stackNamesPrefsKey, stackKey, name);

  @override
  Future<void> hideStack(String stackKey) =>
      _updateList(_hiddenStacksPrefsKey, stackKey);

  @override
  Future<void> restoreStack(String stackKey) =>
      _removeFromList(_hiddenStacksPrefsKey, stackKey);

  @override
  Future<void> excludeImage(String imageId) =>
      _updateList(_excludedImagesPrefsKey, imageId);

  @override
  Future<void> restoreImage(String imageId) =>
      _removeFromList(_excludedImagesPrefsKey, imageId);

  @override
  Future<void> moveImage(String imageId, String stackKey) =>
      _updateMap(_imageAssignmentsPrefsKey, imageId, stackKey);

  @override
  Future<void> saveSetMemo(String setKey, String memo) =>
      _updateMap(_setMemosPrefsKey, setKey, memo);

  @override
  Future<void> saveFolderName(String folderKey, String name) =>
      name.trim().isEmpty
      ? _removeFromMap(_folderNamesPrefsKey, folderKey)
      : _updateMap(_folderNamesPrefsKey, folderKey, name);

  @override
  Future<void> assignImageToSet(String imageId, String setKey) => setKey.isEmpty
      ? _removeFromMap(_setAssignmentsPrefsKey, imageId)
      : _updateMap(_setAssignmentsPrefsKey, imageId, setKey);

  @override
  Future<void> pinStack(String stackKey) =>
      _updateList(_pinnedStacksPrefsKey, stackKey);

  @override
  Future<void> unpinStack(String stackKey) =>
      _removeFromList(_pinnedStacksPrefsKey, stackKey);

  @override
  Future<void> saveSortMode(String sortModeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortModePrefsKey, sortModeName);
  }

  Future<void> _updateList(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(key) ?? [];
    if (!values.contains(value)) values.add(value);
    await prefs.setStringList(key, values);
  }

  Future<void> _removeFromList(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(key) ?? [];
    values.remove(value);
    await prefs.setStringList(key, values);
  }

  Future<void> _updateMap(String key, String mapKey, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final values = _decodeStringMap(prefs.getString(key));
    values[mapKey] = value;
    await prefs.setString(key, jsonEncode(values));
  }

  Future<void> _removeFromMap(String key, String mapKey) async {
    final prefs = await SharedPreferences.getInstance();
    final values = _decodeStringMap(prefs.getString(key));
    values.remove(mapKey);
    await prefs.setString(key, jsonEncode(values));
  }

  static Map<String, String> _decodeStringMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, '$value'));
  }
}
