import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_store_models.dart';

class ShotlyLocalStore implements LocalStore {
  static const _manualStacksPrefsKey = 'shotly.manualStacks';
  static const _stackNamesPrefsKey = 'shotly.stackNames';
  static const _hiddenStacksPrefsKey = 'shotly.hiddenStacks';
  static const _excludedImagesPrefsKey = 'shotly.excludedImages';
  static const _favoriteImagesPrefsKey = 'shotly.favoriteImages';
  static const _imageAssignmentsPrefsKey = 'shotly.imageAssignments';
  static const _setMemosPrefsKey = 'shotly.setMemos';
  static const _folderNamesPrefsKey = 'shotly.folderNames';
  static const _folderColorsPrefsKey = 'shotly.folderColors';
  static const _setAssignmentsPrefsKey = 'shotly.setAssignments';
  static const _pinnedStacksPrefsKey = 'shotly.pinnedStacks';
  static const _sortModePrefsKey = 'shotly.sortMode';
  static const _ocrIndexPrefsKey = 'shotly.ocrIndex';

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
      folderColors: _decodeStringMap(prefs.getString(_folderColorsPrefsKey)),
      setAssignments: _decodeStringMap(
        prefs.getString(_setAssignmentsPrefsKey),
      ),
      hiddenStackKeys: (prefs.getStringList(_hiddenStacksPrefsKey) ?? const [])
          .toSet(),
      excludedImageIds:
          (prefs.getStringList(_excludedImagesPrefsKey) ?? const []).toSet(),
      favoriteImageIds:
          (prefs.getStringList(_favoriteImagesPrefsKey) ?? const []).toSet(),
      pinnedStackKeys: prefs.getStringList(_pinnedStacksPrefsKey) ?? const [],
      sortModeName: prefs.getString(_sortModePrefsKey),
    );
  }

  @override
  Future<void> replaceAll(LocalShotlyState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_manualStacksPrefsKey, state.manualStackNames);
    await prefs.setString(_stackNamesPrefsKey, jsonEncode(state.stackNames));
    await prefs.setString(
      _imageAssignmentsPrefsKey,
      jsonEncode(state.imageAssignments),
    );
    await prefs.setString(_setMemosPrefsKey, jsonEncode(state.setMemos));
    await prefs.setString(_folderNamesPrefsKey, jsonEncode(state.folderNames));
    await prefs.setString(
      _folderColorsPrefsKey,
      jsonEncode(state.folderColors),
    );
    await prefs.setString(
      _setAssignmentsPrefsKey,
      jsonEncode(state.setAssignments),
    );
    await prefs.setStringList(
      _hiddenStacksPrefsKey,
      state.hiddenStackKeys.toList(),
    );
    await prefs.setStringList(
      _excludedImagesPrefsKey,
      state.excludedImageIds.toList(),
    );
    await prefs.setStringList(
      _favoriteImagesPrefsKey,
      state.favoriteImageIds.toList(),
    );
    await prefs.setStringList(_pinnedStacksPrefsKey, state.pinnedStackKeys);
    if (state.sortModeName == null) {
      await prefs.remove(_sortModePrefsKey);
    } else {
      await prefs.setString(_sortModePrefsKey, state.sortModeName!);
    }
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
  Future<void> favoriteImage(String imageId) =>
      _updateList(_favoriteImagesPrefsKey, imageId);

  @override
  Future<void> unfavoriteImage(String imageId) =>
      _removeFromList(_favoriteImagesPrefsKey, imageId);

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
  Future<void> saveFolderColor(String folderKey, String colorKey) =>
      colorKey.trim().isEmpty
      ? _removeFromMap(_folderColorsPrefsKey, folderKey)
      : _updateMap(_folderColorsPrefsKey, folderKey, colorKey);

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

  @override
  Future<Map<String, OcrIndexEntry>> loadOcrIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ocrIndexPrefsKey);
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((imageId, value) {
      final map = value is Map ? value.cast<String, dynamic>() : const {};
      return MapEntry(
        imageId,
        OcrIndexEntry(
          imageId: imageId,
          status: _ocrStatusFromName('${map['status'] ?? 'pending'}'),
          text: '${map['text'] ?? ''}',
          updatedAtMillis: (map['updatedAtMillis'] as num?)?.toInt() ?? 0,
          errorMessage: map['errorMessage']?.toString(),
        ),
      );
    });
  }

  @override
  Future<void> saveOcrText(String imageId, String text) async {
    await _updateOcrIndex(
      imageId,
      OcrIndexEntry(
        imageId: imageId,
        status: OcrIndexStatus.done,
        text: text,
        updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> saveOcrFailure(String imageId, String errorMessage) async {
    await _updateOcrIndex(
      imageId,
      OcrIndexEntry(
        imageId: imageId,
        status: OcrIndexStatus.failed,
        text: '',
        updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
        errorMessage: errorMessage,
      ),
    );
  }

  Future<void> _updateOcrIndex(String imageId, OcrIndexEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await loadOcrIndex();
    final next = {...entries, imageId: entry};
    await prefs.setString(
      _ocrIndexPrefsKey,
      jsonEncode({
        for (final item in next.values)
          item.imageId: {
            'status': item.status.name,
            'text': item.text,
            'updatedAtMillis': item.updatedAtMillis,
            if (item.errorMessage != null) 'errorMessage': item.errorMessage,
          },
      }),
    );
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

OcrIndexStatus _ocrStatusFromName(String name) {
  for (final status in OcrIndexStatus.values) {
    if (status.name == name) return status;
  }
  return OcrIndexStatus.pending;
}
