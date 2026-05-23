import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'local_image.dart';
import 'local_store.dart';
import 'mock_data.dart';
import 'visual_features.dart';

void main() {
  runApp(const ShotlyApp());
}

class ShotlyApp extends StatelessWidget {
  const ShotlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shotly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0058BE),
          brightness: Brightness.light,
          primary: const Color(0xFF0058BE),
          surface: const Color(0xFFF8F9FA),
          surfaceContainerHighest: const Color(0xFFE2E2E2),
          outline: const Color(0xFF727785),
        ),
        textTheme:
            const TextTheme(
              headlineLarge: TextStyle(
                fontSize: 28,
                height: 34 / 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.56,
              ),
              headlineMedium: TextStyle(
                fontSize: 22,
                height: 28 / 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.22,
              ),
              headlineSmall: TextStyle(
                fontSize: 18,
                height: 24 / 18,
                fontWeight: FontWeight.w600,
              ),
              titleLarge: TextStyle(
                fontSize: 22,
                height: 28 / 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.22,
              ),
              titleMedium: TextStyle(
                fontSize: 18,
                height: 24 / 18,
                fontWeight: FontWeight.w600,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w400,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w400,
              ),
              bodySmall: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
              ),
              labelLarge: TextStyle(
                fontSize: 14,
                height: 18 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.14,
              ),
              labelMedium: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
              ),
              labelSmall: TextStyle(
                fontSize: 11,
                height: 14 / 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.33,
              ),
            ).apply(
              bodyColor: const Color(0xFF1A1C1C),
              displayColor: const Color(0xFF1A1C1C),
              fontFamily: 'Inter',
              fontFamilyFallback: ['Pretendard'],
            ),
      ),
      home: const ShotlyHomeScreen(),
    );
  }
}

class ScreenshotItem {
  const ScreenshotItem({
    required this.id,
    required this.displayName,
    required this.relativePath,
    required this.dateTakenMillis,
    required this.appName,
    required this.thumbnailPath,
  });

  final String id;
  final String displayName;
  final String relativePath;
  final int dateTakenMillis;
  final String appName;
  final String thumbnailPath;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateTakenMillis);

  bool matches(String query) {
    final q = query.toLowerCase();
    return appName.toLowerCase().contains(q) ||
        displayName.toLowerCase().contains(q) ||
        relativePath.toLowerCase().contains(q) ||
        _aliases(appName).any((alias) => alias.toLowerCase().contains(q));
  }

  static List<String> _aliases(String name) {
    final n = name.toLowerCase();
    if (n.contains('kakao')) return ['카카오톡', '카톡', 'KakaoTalk'];
    if (n.contains('karrot') || n.contains('carrot')) {
      return ['당근', '당근마켓', 'Karrot'];
    }
    if (n.contains('instagram')) return ['인스타그램', '인스타', 'Instagram'];
    if (n.contains('smartthings')) return ['스마트싱스', 'SmartThings'];
    return const [];
  }

  factory ScreenshotItem.fromMap(Map<dynamic, dynamic> map) {
    return ScreenshotItem(
      id: '${map['id']}',
      displayName: '${map['displayName'] ?? ''}',
      relativePath: '${map['relativePath'] ?? ''}',
      dateTakenMillis: (map['dateTakenMillis'] as num?)?.toInt() ?? 0,
      appName: '${map['appName'] ?? 'Unknown'}',
      thumbnailPath: '${map['thumbnailPath'] ?? ''}',
    );
  }
}

enum StackSortMode { latest, name, mostImages, fewestImages }

StackSortMode? _sortModeFromName(String? name) {
  if (name == null) return null;
  for (final mode in StackSortMode.values) {
    if (mode.name == name) return mode;
  }
  return null;
}

class StackItem {
  const StackItem({required this.key, required this.name, required this.items});

  final String key;
  final String name;
  final List<ScreenshotItem> items;
}

class ScreenshotSet {
  const ScreenshotSet({
    required this.key,
    required this.title,
    required this.timeRange,
    required this.items,
    this.memo = '',
    this.folderName,
  });

  final String key;
  final String title;
  final String timeRange;
  final List<ScreenshotItem> items;
  final String memo;
  final String? folderName;
}

class ShotlyNative {
  static const _channel = MethodChannel('shotly/native');

  static Future<bool> requestPhotoPermission() async {
    if (kIsWeb) return true;
    final result = await _channel.invokeMethod<bool>('requestPhotoPermission');
    return result ?? false;
  }

  static Future<bool> openPhotoSettings() async {
    if (kIsWeb) return false;
    final result = await _channel.invokeMethod<bool>('openPhotoSettings');
    return result ?? false;
  }

  static Future<List<ScreenshotItem>> getScreenshots() async {
    if (kIsWeb) return mockScreenshots();
    final result = await _channel.invokeMethod<List<dynamic>>('getScreenshots');
    return (result ?? const [])
        .map((item) => ScreenshotItem.fromMap(item as Map<dynamic, dynamic>))
        .toList();
  }

  static Future<ScreenshotItem?> pickImage() async {
    if (kIsWeb) return null;
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'pickImage',
    );
    if (result == null) return null;
    return ScreenshotItem.fromMap(result);
  }

  static Future<String?> getImagePreview(
    String imageId,
    String fallbackPath,
  ) async {
    if (kIsWeb) return fallbackPath;
    final result = await _channel.invokeMethod<String>('getImagePreview', {
      'imageId': imageId,
    });
    return result?.isEmpty == true ? fallbackPath : result ?? fallbackPath;
  }

  static Future<bool> deleteOriginalImage(String imageId) async {
    if (kIsWeb) return false;
    final result = await _channel.invokeMethod<bool>('deleteOriginalImage', {
      'imageId': imageId,
    });
    return result ?? false;
  }

  static Future<bool> deleteOriginalImages(List<String> imageIds) async {
    if (kIsWeb || imageIds.isEmpty) return false;
    final result = await _channel.invokeMethod<bool>('deleteOriginalImages', {
      'imageIds': imageIds,
    });
    return result ?? false;
  }

  static Future<bool> shareImages(List<String> imageIds) async {
    if (kIsWeb || imageIds.isEmpty) return false;
    final result = await _channel.invokeMethod<bool>('shareImages', {
      'imageIds': imageIds,
    });
    return result ?? false;
  }
}

class ShotlyHomeScreen extends StatefulWidget {
  const ShotlyHomeScreen({super.key});

  @override
  State<ShotlyHomeScreen> createState() => _ShotlyHomeScreenState();
}

class _ShotlyHomeScreenState extends State<ShotlyHomeScreen> {
  final _searchController = TextEditingController();
  final _localStore = ShotlyLocalStore();
  List<ScreenshotItem> _screenshots = const [];
  final List<String> _manualStackNames = [];
  final Map<String, String> _stackNames = {};
  final Map<String, String> _imageAssignments = {};
  final Map<String, String> _setMemos = {};
  final Map<String, String> _folderNames = {};
  final Map<String, String> _folderColors = {};
  final Map<String, String> _setAssignments = {};
  final Map<String, VisualFeature> _visualFeatures = {};
  final Set<String> _hiddenStackKeys = {};
  final Set<String> _excludedImageIds = {};
  final List<String> _pinnedStackKeys = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  DateTime? _selectedDate;
  String _query = '';
  String? _error;
  bool _showSortMenu = false;
  StackSortMode _sortMode = StackSortMode.latest;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreLocalState());
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _restoreLocalState() async {
    final state = await _localStore.load();
    if (!mounted) return;
    setState(() {
      _manualStackNames
        ..clear()
        ..addAll(state.manualStackNames);
      _stackNames
        ..clear()
        ..addAll(state.stackNames);
      _imageAssignments
        ..clear()
        ..addAll(state.imageAssignments);
      _setMemos
        ..clear()
        ..addAll(state.setMemos);
      _folderNames
        ..clear()
        ..addAll(state.folderNames);
      _folderColors
        ..clear()
        ..addAll(state.folderColors);
      _setAssignments
        ..clear()
        ..addAll(state.setAssignments);
      _hiddenStackKeys
        ..clear()
        ..addAll(state.hiddenStackKeys);
      _excludedImageIds
        ..clear()
        ..addAll(state.excludedImageIds);
      _pinnedStackKeys
        ..clear()
        ..addAll(state.pinnedStackKeys);
      _sortMode = _sortModeFromName(state.sortModeName) ?? _sortMode;
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _hasPermission = await ShotlyNative.requestPhotoPermission();
      if (_hasPermission) {
        final screenshots = await ShotlyNative.getScreenshots();
        screenshots.sort(
          (a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis),
        );
        _screenshots = screenshots;
        _visualFeatures.clear();
      }
    } on PlatformException catch (e) {
      _error = e.message ?? e.code;
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ScreenshotItem> get _calendarScreenshots {
    Iterable<ScreenshotItem> items = _screenshots.where(
      (item) => !_excludedImageIds.contains(item.id),
    );
    if (_selectedDate != null) {
      items = items.where((item) => _isSameDay(item.date, _selectedDate!));
    }
    if (_query.trim().isNotEmpty) {
      items = items.where((item) => item.matches(_query.trim()));
    }
    return items.toList();
  }

  List<ScreenshotItem> get _filteredScreenshots => _calendarScreenshots;

  List<StackItem> get _searchSourceStacks {
    final grouped = <String, List<ScreenshotItem>>{};
    for (final item in _screenshots.where(
      (item) => !_excludedImageIds.contains(item.id),
    )) {
      if (_selectedDate != null && !_isSameDay(item.date, _selectedDate!)) {
        continue;
      }
      final stackKey = _stackKeyFor(item);
      if (_hiddenStackKeys.contains(stackKey)) continue;
      grouped.putIfAbsent(stackKey, () => []).add(item);
    }
    final stacks = grouped.entries
        .map(
          (entry) => StackItem(
            key: entry.key,
            name: _stackNames[entry.key] ?? entry.key,
            items: entry.value
              ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis)),
          ),
        )
        .toList();
    for (final name in _manualStackNames) {
      if (_selectedDate == null &&
          !grouped.containsKey(name) &&
          !_hiddenStackKeys.contains(name)) {
        stacks.add(
          StackItem(
            key: name,
            name: _stackNames[name] ?? name,
            items: const [],
          ),
        );
      }
    }
    return stacks;
  }

  List<StackItem> get _stacks {
    final q = _query.trim();
    final grouped = <String, List<ScreenshotItem>>{};
    for (final item in _calendarScreenshots) {
      final stackKey = _stackKeyFor(item);
      if (_hiddenStackKeys.contains(stackKey)) continue;
      grouped.putIfAbsent(stackKey, () => []).add(item);
    }
    final stacks = grouped.entries
        .map(
          (entry) => StackItem(
            key: entry.key,
            name: _stackNames[entry.key] ?? entry.key,
            items: entry.value
              ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis)),
          ),
        )
        .where((stack) => q.isEmpty || _stackMatchesQuery(stack, q))
        .toList();
    for (final name in _manualStackNames) {
      final matchesQuery =
          q.isEmpty ||
          _textMatches(name, q) ||
          _textMatches(_stackNames[name] ?? '', q);
      if (_selectedDate == null &&
          matchesQuery &&
          !grouped.containsKey(name) &&
          !_hiddenStackKeys.contains(name)) {
        stacks.add(
          StackItem(
            key: name,
            name: _stackNames[name] ?? name,
            items: const [],
          ),
        );
      }
    }
    void sortByMode(List<StackItem> target) {
      switch (_sortMode) {
        case StackSortMode.latest:
          target.sort(
            (a, b) => (b.items.isEmpty ? 0 : b.items.first.dateTakenMillis)
                .compareTo(a.items.isEmpty ? 0 : a.items.first.dateTakenMillis),
          );
        case StackSortMode.name:
          target.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        case StackSortMode.mostImages:
          target.sort((a, b) => b.items.length.compareTo(a.items.length));
        case StackSortMode.fewestImages:
          target.sort((a, b) => a.items.length.compareTo(b.items.length));
      }
    }

    final stackByKey = {for (final stack in stacks) stack.key: stack};
    final pinned = _pinnedStackKeys
        .where(stackByKey.containsKey)
        .map((key) => stackByKey[key]!)
        .toList();
    final unpinned = stacks
        .where((stack) => !_pinnedStackKeys.contains(stack.key))
        .toList();
    sortByMode(unpinned);
    return [...pinned, ...unpinned];
  }

  List<StackItem> get _hiddenStacks {
    final grouped = <String, List<ScreenshotItem>>{};
    for (final item in _screenshots.where(
      (item) => !_excludedImageIds.contains(item.id),
    )) {
      final stackKey = _stackKeyFor(item);
      if (_hiddenStackKeys.contains(stackKey)) {
        grouped.putIfAbsent(stackKey, () => []).add(item);
      }
    }
    final stacks = grouped.entries
        .map(
          (entry) => StackItem(
            key: entry.key,
            name: _stackNames[entry.key] ?? entry.key,
            items: entry.value
              ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis)),
          ),
        )
        .toList();
    for (final name in _manualStackNames) {
      if (_hiddenStackKeys.contains(name) && !grouped.containsKey(name)) {
        stacks.add(
          StackItem(
            key: name,
            name: _stackNames[name] ?? name,
            items: const [],
          ),
        );
      }
    }
    stacks.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return stacks;
  }

  List<ScreenshotItem> get _excludedImages {
    return _screenshots
        .where((item) => _excludedImageIds.contains(item.id))
        .toList()
      ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
  }

  String _stackKeyFor(ScreenshotItem item) =>
      _imageAssignments[item.id] ??
      (item.appName.isEmpty ? 'Unknown' : item.appName);

  Future<void> _showCreateStackDialog() async {
    final name = await _showShotlyTextDialog(
      context: context,
      title: 'Stack 추가',
      hintText: 'Stack 이름',
      primaryLabel: '추가',
      validator: (value) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return null;
        final exists =
            _manualStackNames.any(
              (name) => name.toLowerCase() == trimmed.toLowerCase(),
            ) ||
            _stacks.any(
              (stack) =>
                  stack.name.toLowerCase() == trimmed.toLowerCase() ||
                  stack.key.toLowerCase() == trimmed.toLowerCase(),
            );
        return exists ? '이미 같은 이름의 Stack이 있어요.' : null;
      },
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    setState(() {
      if (!_manualStackNames.contains(trimmed)) _manualStackNames.add(trimmed);
    });
    await _localStore.upsertManualStack(trimmed);
  }

  Future<void> _pickImageFromAlbum() async {
    try {
      final image = await ShotlyNative.pickImage();
      if (image == null) return;
      if (_screenshots.any(
        (item) =>
            item.id == image.id || item.thumbnailPath == image.thumbnailPath,
      )) {
        if (mounted) _showSnack('이미 추가된 이미지예요. 중복 추가하지 않았어.');
        return;
      }
      setState(() {
        _screenshots = [image, ..._screenshots]
          ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
      });
    } on PlatformException catch (e) {
      if (mounted) _showSnack(e.message ?? e.code);
    }
  }

  Future<ScreenshotItem?> _pickAndAddImageToStack(String stackKey) async {
    try {
      final image = await ShotlyNative.pickImage();
      if (image == null) return null;
      if (_screenshots.any(
        (item) =>
            item.id == image.id || item.thumbnailPath == image.thumbnailPath,
      )) {
        await _moveImage(image.id, stackKey);
        return image;
      }
      setState(() {
        _screenshots = [image, ..._screenshots]
          ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
      });
      await _moveImage(image.id, stackKey);
      return image;
    } on PlatformException catch (e) {
      if (mounted) _showSnack(e.message ?? e.code);
      return null;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPhotoSettings() async {
    try {
      await ShotlyNative.openPhotoSettings();
    } on PlatformException catch (e) {
      if (mounted) _showSnack(e.message ?? e.code);
    }
  }

  Future<void> _renameStack(String stackKey, String name) async {
    final trimmed = name.trim().isEmpty ? stackKey : name.trim();
    setState(() => _stackNames[stackKey] = trimmed);
    await _localStore.renameStack(stackKey, trimmed);
  }

  Future<void> _hideStack(String stackKey) async {
    setState(() => _hiddenStackKeys.add(stackKey));
    await _localStore.hideStack(stackKey);
  }

  Future<void> _togglePinStack(String stackKey) async {
    final shouldPin = !_pinnedStackKeys.contains(stackKey);
    setState(() {
      if (shouldPin) {
        _pinnedStackKeys.add(stackKey);
      } else {
        _pinnedStackKeys.remove(stackKey);
      }
    });
    if (shouldPin) {
      await _localStore.pinStack(stackKey);
    } else {
      await _localStore.unpinStack(stackKey);
    }
  }

  Future<void> _restoreStack(String stackKey) async {
    setState(() => _hiddenStackKeys.remove(stackKey));
    await _localStore.restoreStack(stackKey);
  }

  Future<void> _excludeImage(String imageId) async {
    setState(() => _excludedImageIds.add(imageId));
    await _localStore.excludeImage(imageId);
  }

  Future<bool> _deleteOriginalImage(String imageId) async {
    try {
      final deleted = await ShotlyNative.deleteOriginalImage(imageId);
      if (!deleted) {
        if (mounted) _showSnack('원본 파일을 삭제하지 못했어요. 시스템 권한을 확인해줘.');
        return false;
      }
      setState(() {
        _screenshots = _screenshots
            .where((item) => item.id != imageId)
            .toList();
        _excludedImageIds.remove(imageId);
        _imageAssignments.remove(imageId);
        _setAssignments.remove(imageId);
        _visualFeatures.remove(imageId);
      });
      await _localStore.excludeImage(imageId);
      if (mounted) _showSnack('원본 파일을 삭제했어요.');
      return true;
    } on PlatformException catch (e) {
      if (mounted) _showSnack(e.message ?? e.code);
      return false;
    }
  }

  Future<bool> _deleteOriginalImages(List<String> imageIds) async {
    if (imageIds.isEmpty) return false;
    try {
      final deleted = await ShotlyNative.deleteOriginalImages(imageIds);
      if (!deleted) {
        if (mounted) _showSnack('선택한 원본 파일을 삭제하지 못했어요. 시스템 권한을 확인해줘.');
        return false;
      }
      setState(() {
        final ids = imageIds.toSet();
        _screenshots = _screenshots
            .where((item) => !ids.contains(item.id))
            .toList();
        _excludedImageIds.removeAll(ids);
        for (final id in ids) {
          _imageAssignments.remove(id);
          _setAssignments.remove(id);
          _visualFeatures.remove(id);
        }
      });
      for (final id in imageIds) {
        await _localStore.excludeImage(id);
      }
      if (mounted) _showSnack('${imageIds.length}개 원본 파일을 삭제했어요.');
      return true;
    } on PlatformException catch (e) {
      if (mounted) _showSnack(e.message ?? e.code);
      return false;
    }
  }

  Future<void> _pickDateFilter() async {
    final activeScreenshots = _screenshots
        .where((item) => !_excludedImageIds.contains(item.id))
        .toList();
    final earliest = activeScreenshots.isEmpty
        ? DateTime(DateTime.now().year - 5)
        : activeScreenshots
              .map((item) => item.date)
              .reduce((a, b) => a.isBefore(b) ? a : b);
    final picked = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.10),
      builder: (context) => _ShotlyCalendarDialog(
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(earliest.year, earliest.month, 1),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        screenshotDates: activeScreenshots
            .map(
              (item) =>
                  DateTime(item.date.year, item.date.month, item.date.day),
            )
            .toSet(),
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _openSearchPage() async {
    final query = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _SearchPage(
          initialQuery: _query,
          stacks: _searchSourceStacks,
          allStackKeys: _stacks.map((item) => item.key).toList(),
          stackNames: _stackNames,
          setMemos: _setMemos,
          folderNames: _folderNames,
          folderColors: _folderColors,
          setAssignments: _setAssignments,
          stackMatchesQuery: _stackMatchesQuery,
          onRenameStack: _renameStack,
          onHideStack: _hideStack,
          onExcludeImage: _excludeImage,
          onDeleteOriginalImage: _deleteOriginalImage,
          onDeleteOriginalImages: _deleteOriginalImages,
          onMoveImage: _moveImage,
          onAddImageToStack: _pickAndAddImageToStack,
          onSaveSetMemo: _saveSetMemo,
          onSaveFolderName: _saveFolderName,
          onSaveFolderColor: _saveFolderColor,
          onAssignImageToSet: _assignImageToSet,
        ),
      ),
    );
    if (query != null && mounted) {
      setState(() => _query = query);
      _searchController.text = query;
    }
  }

  Future<void> _restoreImage(String imageId) async {
    setState(() => _excludedImageIds.remove(imageId));
    await _localStore.restoreImage(imageId);
  }

  Future<void> _moveImage(String imageId, String stackKey) async {
    setState(() {
      _imageAssignments[imageId] = stackKey;
      _setAssignments.remove(imageId);
    });
    if (!_manualStackNames.contains(stackKey) &&
        !_stacks.any((stack) => stack.key == stackKey)) {
      _manualStackNames.add(stackKey);
    }
    await _localStore.moveImage(imageId, stackKey);
    await _localStore.assignImageToSet(imageId, '');
  }

  Future<void> _saveSetMemo(String setKey, String memo) async {
    setState(() => _setMemos[setKey] = memo);
    await _localStore.saveSetMemo(setKey, memo);
  }

  Future<void> _saveFolderName(String folderKey, String name) async {
    setState(() {
      if (name.trim().isEmpty) {
        _folderNames.remove(folderKey);
      } else {
        _folderNames[folderKey] = name;
      }
    });
    await _localStore.saveFolderName(folderKey, name);
  }

  Future<void> _saveFolderColor(String folderKey, String colorKey) async {
    setState(() {
      if (colorKey.trim().isEmpty) {
        _folderColors.remove(folderKey);
      } else {
        _folderColors[folderKey] = colorKey;
      }
    });
    await _localStore.saveFolderColor(folderKey, colorKey);
  }

  Future<void> _saveSortMode(StackSortMode mode) async {
    setState(() {
      _sortMode = mode;
      _showSortMenu = false;
    });
    await _localStore.saveSortMode(mode.name);
  }

  Future<void> _assignImageToSet(String imageId, String setKey) async {
    final current = _setAssignments[imageId];
    final next = setKey.startsWith(_removeAssignmentPrefix)
        ? _removeAssignmentKey(
            current,
            setKey.substring(_removeAssignmentPrefix.length),
          )
        : setKey.isEmpty
        ? null
        : _addAssignmentKey(current, setKey);
    setState(() {
      if (next == null || next.isEmpty) {
        _setAssignments.remove(imageId);
      } else {
        _setAssignments[imageId] = next;
      }
    });
    await _localStore.assignImageToSet(imageId, next ?? '');
  }

  bool _stackMatchesQuery(StackItem stack, String query) {
    if (_textMatches(stack.name, query) || _textMatches(stack.key, query)) {
      return true;
    }
    if (stack.items.any((item) => item.matches(query))) return true;
    final sets = _buildScreenshotSets(
      stack.key,
      stack.items,
      _setMemos,
      _folderNames,
      _setAssignments,
    );
    return sets.any(
      (set) =>
          _textMatches(set.memo, query) ||
          (_isFolderSetKey(set.key) && _textMatches(_folderName(set), query)) ||
          _textMatches(set.timeRange, query) ||
          (set.items.isNotEmpty &&
              _textMatches(_formatSetDate(set.items.first.date), query)),
    );
  }

  bool _textMatches(String text, String query) =>
      text.toLowerCase().contains(query.toLowerCase());

  Future<void> _showAddMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              _AddMenuTile(
                icon: Icons.layers_rounded,
                title: 'Stack 추가',
                onTap: () => Navigator.of(context).pop('stack'),
              ),
              _AddMenuTile(
                icon: Icons.photo_library_rounded,
                title: '이미지 추가',
                onTap: () => Navigator.of(context).pop('image'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == 'stack') await _showCreateStackDialog();
    if (action == 'image') await _pickImageFromAlbum();
  }

  @override
  Widget build(BuildContext context) {
    final filteredScreenshots = _filteredScreenshots
      ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
    final stacks = _stacks;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF0058BE),
              child: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _ShotlyTopBarDelegate(
                      searchController: _searchController,
                      onSearchTap: _openSearchPage,
                      selectedDate: _selectedDate,
                      onPickDate: _pickDateFilter,
                      onClearDate: () => setState(() => _selectedDate = null),
                      onAdd: _showAddMenu,
                      onSettings: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            hasPermission: _hasPermission,
                            hiddenStacks: _hiddenStacks,
                            excludedImages: _excludedImages,
                            onOpenPhotoSettings: _openPhotoSettings,
                            onRestoreStack: _restoreStack,
                            onRestoreImage: _restoreImage,
                            onDeleteOriginalImage: _deleteOriginalImage,
                            onDeleteOriginalImages: _deleteOriginalImages,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isLoading)
                            const _LoadingState()
                          else if (!_hasPermission)
                            _PermissionState(onRequest: _load)
                          else if (_error != null)
                            _ErrorState(message: _error!, onRetry: _load)
                          else ...[
                            _SummarySortRow(
                              screenshotCount: filteredScreenshots.length,
                              stackCount: stacks.length,
                              sortMode: _sortMode,
                              showSortMenu: _showSortMenu,
                              onToggleSort: () => setState(
                                () => _showSortMenu = !_showSortMenu,
                              ),
                              onSelectSort: _saveSortMode,
                            ),
                            const SizedBox(height: 26),
                            if (_screenshots.isEmpty && stacks.isEmpty)
                              const _EmptyState()
                            else if (stacks.isEmpty)
                              const _NoResultState()
                            else
                              ...stacks.map(
                                (stack) => Padding(
                                  padding: const EdgeInsets.only(bottom: 26),
                                  child: _StackCard(
                                    stack: stack,
                                    allStackKeys: _stacks
                                        .map((item) => item.key)
                                        .toList(),
                                    stackNames: _stackNames,
                                    setMemos: _setMemos,
                                    folderNames: _folderNames,
                                    folderColors: _folderColors,
                                    setAssignments: _setAssignments,
                                    visualFeatures: _visualFeatures,
                                    onRenameStack: _renameStack,
                                    onHideStack: _hideStack,
                                    onTogglePinStack: _togglePinStack,
                                    pinned: _pinnedStackKeys.contains(
                                      stack.key,
                                    ),
                                    onExcludeImage: _excludeImage,
                                    onDeleteOriginalImage: _deleteOriginalImage,
                                    onDeleteOriginalImages:
                                        _deleteOriginalImages,
                                    onMoveImage: _moveImage,
                                    onAddImageToStack: _pickAndAddImageToStack,
                                    onSaveSetMemo: _saveSetMemo,
                                    onSaveFolderName: _saveFolderName,
                                    onSaveFolderColor: _saveFolderColor,
                                    onAssignImageToSet: _assignImageToSet,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showSortMenu)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => setState(() => _showSortMenu = false),
                ),
              ),
            if (_showSortMenu)
              Positioned(
                top: 138,
                right: 20,
                child: _SortDropdown(
                  selected: _sortMode,
                  onSelect: _saveSortMode,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShotlyTopBarDelegate extends SliverPersistentHeaderDelegate {
  const _ShotlyTopBarDelegate({
    required this.searchController,
    required this.onSearchTap,
    required this.selectedDate,
    required this.onPickDate,
    required this.onClearDate,
    required this.onAdd,
    required this.onSettings,
  });

  final TextEditingController searchController;
  final VoidCallback onSearchTap;
  final DateTime? selectedDate;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final VoidCallback onAdd;
  final VoidCallback onSettings;

  @override
  double get minExtent => selectedDate == null ? 70 : 104;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: maxExtent,
      color: const Color(0xFFF8F9FA).withValues(alpha: 0.96),
      padding: const EdgeInsets.fromLTRB(20, 10, 18, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _SearchField(
              controller: searchController,
              onTap: onSearchTap,
              selectedDate: selectedDate,
              onPickDate: onPickDate,
              onClearDate: onClearDate,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TopIconButton(icon: Icons.add_rounded, onTap: onAdd),
                const SizedBox(width: 2),
                _TopIconButton(
                  icon: Icons.more_vert_rounded,
                  onTap: onSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ShotlyTopBarDelegate oldDelegate) =>
      searchController != oldDelegate.searchController ||
      onSearchTap != oldDelegate.onSearchTap ||
      selectedDate != oldDelegate.selectedDate ||
      onPickDate != oldDelegate.onPickDate ||
      onClearDate != oldDelegate.onClearDate ||
      onAdd != oldDelegate.onAdd ||
      onSettings != oldDelegate.onSettings;
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 44,
        child: Icon(icon, size: 23, color: const Color(0xFF111111)),
      ),
    );
  }
}

class _SummarySortRow extends StatelessWidget {
  const _SummarySortRow({
    required this.screenshotCount,
    required this.stackCount,
    required this.sortMode,
    required this.showSortMenu,
    required this.onToggleSort,
    required this.onSelectSort,
  });

  final int screenshotCount;
  final int stackCount;
  final StackSortMode sortMode;
  final bool showSortMenu;
  final VoidCallback onToggleSort;
  final ValueChanged<StackSortMode> onSelectSort;

  @override
  Widget build(BuildContext context) {
    final isFiltered = sortMode != StackSortMode.latest;
    return SizedBox(
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            right: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$screenshotCount개 스크린샷 · $stackCount개 Stack',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF727785),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Positioned(
            top: -1,
            right: 0,
            child: InkWell(
              onTap: onToggleSort,
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.tune_rounded,
                        size: 22,
                        color: Color(0xFF111111),
                      ),
                    ),
                    if (isFiltered)
                      Positioned(
                        right: 0,
                        top: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0058BE),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.selected, required this.onSelect});

  final StackSortMode selected;
  final ValueChanged<StackSortMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      (StackSortMode.latest, '최신순'),
      (StackSortMode.name, '이름 순'),
      (StackSortMode.mostImages, '이미지 많은 순'),
      (StackSortMode.fewestImages, '이미지 적은 순'),
    ];
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 178,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            final isSelected = item.$1 == selected;
            return InkWell(
              onTap: () => onSelect(item.$1),
              child: Container(
                color: isSelected ? const Color(0xFFF9F9F9) : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.$2,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF111111),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF0058BE),
                        size: 18,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ShotlyCalendarDialog extends StatefulWidget {
  const _ShotlyCalendarDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.screenshotDates,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Set<DateTime> screenshotDates;

  @override
  State<_ShotlyCalendarDialog> createState() => _ShotlyCalendarDialogState();
}

class _ShotlyCalendarDialogState extends State<_ShotlyCalendarDialog> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.initialDate);
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFC2C6D6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickYear,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontSize: 18,
                                          height: 24 / 18,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1A1C1C),
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 22,
                                  color: Color(0xFF424754),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _CalendarNavButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: _canMoveMonth(-1) ? () => _moveMonth(-1) : null,
                      ),
                      const SizedBox(width: 8),
                      _CalendarNavButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: _canMoveMonth(1) ? () => _moveMonth(1) : null,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.25,
                    children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                        .map(
                          (day) => Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 11,
                                height: 14 / 11,
                                letterSpacing: 0.33,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF424754),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                  child: GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 4,
                    childAspectRatio: 1,
                    children: _calendarDates()
                        .map((date) => _buildDateCell(context, date))
                        .toList(),
                  ),
                ),
                Container(
                  color: const Color(0xFFF3F3F3),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0058BE),
                          textStyle: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_selectedDate),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0058BE),
                          foregroundColor: Colors.white,
                          textStyle: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('적용'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateCell(BuildContext context, DateTime? date) {
    if (date == null) return const SizedBox.shrink();
    final isCurrentMonth = date.month == _visibleMonth.month;
    final isSelected = _isSameDate(date, _selectedDate);
    final hasScreenshots = widget.screenshotDates.contains(_dateOnly(date));
    final enabled =
        isCurrentMonth &&
        !_dateOnly(date).isBefore(_dateOnly(widget.firstDate)) &&
        !_dateOnly(date).isAfter(_dateOnly(widget.lastDate));
    final textColor = !enabled
        ? const Color(0xFF727785)
        : isSelected
        ? Colors.white
        : const Color(0xFF1A1C1C);

    return Center(
      child: InkWell(
        onTap: enabled
            ? () => setState(() => _selectedDate = _dateOnly(date))
            : null,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0058BE) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${date.day}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (hasScreenshots)
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF0058BE),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<DateTime?> _calendarDates() {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final leadingBlanks = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final cells = <DateTime?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(_visibleMonth.year, _visibleMonth.month, day),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  Future<void> _pickYear() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _MonthYearPickerSheet(
          initialMonth: _visibleMonth,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          monthNames: _monthNames,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      final month = picked.month;
      final maxDay = DateTime(picked.year, month + 1, 0).day;
      final day = _selectedDate.day.clamp(1, maxDay).toInt();
      var selected = DateTime(picked.year, month, day);
      if (selected.isBefore(_dateOnly(widget.firstDate))) {
        selected = _dateOnly(widget.firstDate);
      }
      if (selected.isAfter(_dateOnly(widget.lastDate))) {
        selected = _dateOnly(widget.lastDate);
      }
      _visibleMonth = DateTime(selected.year, selected.month);
      _selectedDate = selected;
    });
  }

  bool _canMoveMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final firstAllowedMonth = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
    );
    final lastAllowedMonth = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
    );
    return !next.isBefore(firstAllowedMonth) && !next.isAfter(lastAllowedMonth);
  }

  void _moveMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MonthYearPickerSheet extends StatefulWidget {
  const _MonthYearPickerSheet({
    required this.initialMonth,
    required this.firstDate,
    required this.lastDate,
    required this.monthNames,
  });

  final DateTime initialMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<String> monthNames;

  @override
  State<_MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<_MonthYearPickerSheet> {
  late int _year = widget.initialMonth.year;

  @override
  Widget build(BuildContext context) {
    final firstYear = widget.firstDate.year;
    final lastYear = widget.lastDate.year;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _CalendarNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: _year > firstYear
                      ? () => setState(() => _year--)
                      : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$_year',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C1C),
                      ),
                    ),
                  ),
                ),
                _CalendarNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: _year < lastYear
                      ? () => setState(() => _year++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.3,
              children: [
                for (var month = 1; month <= 12; month++)
                  _MonthTile(
                    label: widget.monthNames[month - 1].substring(0, 3),
                    selected:
                        _year == widget.initialMonth.year &&
                        month == widget.initialMonth.month,
                    enabled: _monthEnabled(_year, month),
                    onTap: () =>
                        Navigator.of(context).pop(DateTime(_year, month)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _monthEnabled(int year, int month) {
    final candidate = DateTime(year, month);
    final first = DateTime(widget.firstDate.year, widget.firstDate.month);
    final last = DateTime(widget.lastDate.year, widget.lastDate.month);
    return !candidate.isBefore(first) && !candidate.isAfter(last);
  }
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0058BE) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF0058BE) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: !enabled
                ? const Color(0xFFC2C6D6)
                : selected
                ? Colors.white
                : const Color(0xFF1A1C1C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 24,
          color: onTap == null
              ? const Color(0xFFC2C6D6)
              : const Color(0xFF424754),
        ),
      ),
    );
  }
}

enum _SearchResultKind { stack, set, image }

class _SearchResult {
  const _SearchResult.stack(this.stack)
    : kind = _SearchResultKind.stack,
      set = null,
      image = null;

  const _SearchResult.set(this.stack, this.set)
    : kind = _SearchResultKind.set,
      image = null;

  const _SearchResult.image(this.stack, this.image)
    : kind = _SearchResultKind.image,
      set = null;

  final _SearchResultKind kind;
  final StackItem stack;
  final ScreenshotSet? set;
  final ScreenshotItem? image;
}

class _SearchPage extends StatefulWidget {
  const _SearchPage({
    required this.initialQuery,
    required this.stacks,
    required this.allStackKeys,
    required this.stackNames,
    required this.setMemos,
    required this.folderNames,
    required this.folderColors,
    required this.setAssignments,
    required this.stackMatchesQuery,
    required this.onRenameStack,
    required this.onHideStack,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onDeleteOriginalImages,
    required this.onMoveImage,
    this.onAddImageToStack,
    required this.onSaveSetMemo,
    required this.onSaveFolderName,
    required this.onSaveFolderColor,
    required this.onAssignImageToSet,
  });

  final String initialQuery;
  final List<StackItem> stacks;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> setMemos;
  final Map<String, String> folderNames;
  final Map<String, String> folderColors;
  final Map<String, String> setAssignments;
  final bool Function(StackItem stack, String query) stackMatchesQuery;
  final Future<void> Function(String stackKey, String name) onRenameStack;
  final Future<void> Function(String stackKey) onHideStack;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<bool> Function(List<String> imageIds) onDeleteOriginalImages;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<ScreenshotItem?> Function(String stackKey)? onAddImageToStack;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String folderKey, String name) onSaveFolderName;
  final Future<void> Function(String folderKey, String colorKey)
  onSaveFolderColor;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  late final TextEditingController _controller;
  late String _query;
  bool _showAllStacks = false;
  bool _showAllSets = false;
  bool _showAllImages = false;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _controller = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = _query.trim();
    final results = trimmed.isEmpty
        ? const <_SearchResult>[]
        : _results(trimmed);
    final stackResults = results
        .where((result) => result.kind == _SearchResultKind.stack)
        .toList();
    final setResults = results
        .where((result) => result.kind == _SearchResultKind.set)
        .toList();
    final imageResults = results
        .where((result) => result.kind == _SearchResultKind.image)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(_query.trim()),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEFF2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: (value) => setState(() => _query = value),
                        onSubmitted: (value) =>
                            Navigator.of(context).pop(value.trim()),
                        textInputAction: TextInputAction.search,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: '앱 이름, 파일명, 경로 검색',
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF727785),
                                fontWeight: FontWeight.w500,
                              ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF727785),
                          ),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFF727785),
                                  ),
                                ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 13,
                            horizontal: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: trimmed.isEmpty
                  ? const _SearchEmptyHint()
                  : results.isEmpty
                  ? const _SearchNoResults()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        _SearchResultSection(
                          title: 'Stack',
                          results: stackResults,
                          expanded: _showAllStacks,
                          onToggleExpanded: () =>
                              setState(() => _showAllStacks = !_showAllStacks),
                          onOpen: _openResult,
                        ),
                        _SearchResultSection(
                          title: 'Set / 그룹',
                          results: setResults,
                          expanded: _showAllSets,
                          onToggleExpanded: () =>
                              setState(() => _showAllSets = !_showAllSets),
                          onOpen: _openResult,
                        ),
                        _SearchResultSection(
                          title: '사진',
                          results: imageResults,
                          expanded: _showAllImages,
                          onToggleExpanded: () =>
                              setState(() => _showAllImages = !_showAllImages),
                          onOpen: _openResult,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_SearchResult> _results(String query) {
    final results = <_SearchResult>[];
    final imageIds = <String>{};
    final setKeys = <String>{};
    for (final stack in widget.stacks) {
      if (widget.stackMatchesQuery(stack, query)) {
        results.add(_SearchResult.stack(stack));
      }
      final sets = _buildScreenshotSets(
        stack.key,
        stack.items,
        widget.setMemos,
        widget.folderNames,
        widget.setAssignments,
      );
      for (final set in sets) {
        final setMatches =
            _matches(set.memo, query) ||
            (_isFolderSetKey(set.key) && _matches(_folderName(set), query)) ||
            _matches(set.timeRange, query) ||
            (set.items.isNotEmpty &&
                _matches(_formatSetDate(set.items.first.date), query));
        if (setMatches && setKeys.add(set.key)) {
          results.add(_SearchResult.set(stack, set));
        }
      }
      for (final image in stack.items) {
        if (image.matches(query) && imageIds.add(image.id)) {
          results.add(_SearchResult.image(stack, image));
        }
      }
    }
    return results;
  }

  bool _matches(String text, String query) =>
      text.toLowerCase().contains(query.toLowerCase());

  Future<void> _openResult(_SearchResult result) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          switch (result.kind) {
            case _SearchResultKind.stack:
              return StackDetailScreen(
                stack: result.stack,
                allStackKeys: widget.allStackKeys,
                stackNames: widget.stackNames,
                setMemos: widget.setMemos,
                folderNames: widget.folderNames,
                folderColors: widget.folderColors,
                setAssignments: widget.setAssignments,
                visualFeatures: const {},
                onRenameStack: widget.onRenameStack,
                onHideStack: widget.onHideStack,
                onExcludeImage: widget.onExcludeImage,
                onDeleteOriginalImage: widget.onDeleteOriginalImage,
                onDeleteOriginalImages: widget.onDeleteOriginalImages,
                onMoveImage: widget.onMoveImage,
                onAddImageToStack: widget.onAddImageToStack,
                onSaveSetMemo: widget.onSaveSetMemo,
                onSaveFolderName: widget.onSaveFolderName,
                onSaveFolderColor: widget.onSaveFolderColor,
                onAssignImageToSet: widget.onAssignImageToSet,
              );
            case _SearchResultKind.set:
              return _SearchSetResultScreen(
                stack: result.stack,
                set: result.set!,
                allStackKeys: widget.allStackKeys,
                stackNames: widget.stackNames,
                onExcludeImage: widget.onExcludeImage,
                onDeleteOriginalImage: widget.onDeleteOriginalImage,
                onMoveImage: widget.onMoveImage,
                onSaveSetMemo: widget.onSaveSetMemo,
                onAssignImageToSet: widget.onAssignImageToSet,
              );
            case _SearchResultKind.image:
              final images = result.stack.items;
              final index = images.indexWhere(
                (item) => item.id == result.image!.id,
              );
              return ImageViewerScreen(
                items: images,
                initialIndex: index < 0 ? 0 : index,
                onDeleteOriginalImage: widget.onDeleteOriginalImage,
              );
          }
        },
      ),
    );
  }
}

class _SearchEmptyHint extends StatelessWidget {
  const _SearchEmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '찾고 싶은 앱, 파일명, 경로를 검색해보세요.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF727785)),
      ),
    );
  }
}

class _SearchNoResults extends StatelessWidget {
  const _SearchNoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '검색 결과가 없습니다.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF727785)),
      ),
    );
  }
}

class _SearchResultSection extends StatelessWidget {
  const _SearchResultSection({
    required this.title,
    required this.results,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onOpen,
  });

  final String title;
  final List<_SearchResult> results;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<_SearchResult> onOpen;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();
    final isImageSection = results.first.kind == _SearchResultKind.image;
    final collapsedCount = isImageSection ? 12 : 3;
    final visible = expanded ? results : results.take(collapsedCount).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1C),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${results.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF727785),
                ),
              ),
              const Spacer(),
              if (results.length > collapsedCount)
                TextButton(
                  onPressed: onToggleExpanded,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(expanded ? '접기' : '더보기'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (isImageSection)
            _SearchImageGrid(results: visible, onOpen: onOpen)
          else
            ...visible.map(
              (result) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SearchResultCard(
                  result: result,
                  onTap: () => onOpen(result),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchImageGrid extends StatelessWidget {
  const _SearchImageGrid({required this.results, required this.onOpen});

  final List<_SearchResult> results;
  final ValueChanged<_SearchResult> onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: results.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) {
        final result = results[index];
        final image = result.image!;
        return InkWell(
          onTap: () => onOpen(result),
          borderRadius: BorderRadius.circular(14),
          child: _Thumb(path: image.thumbnailPath, radius: 14),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.result, required this.onTap});

  final _SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stack = result.stack;
    final set = result.set;
    final title = switch (result.kind) {
      _SearchResultKind.stack => stack.name,
      _SearchResultKind.set =>
        _isFolderSetKey(set!.key)
            ? _folderName(set)
            : (set.memo.trim().isEmpty ? 'Set' : set.memo.trim()),
      _SearchResultKind.image => stack.name,
    };
    final subtitle = switch (result.kind) {
      _SearchResultKind.stack => '${stack.items.length} images',
      _SearchResultKind.set => '${stack.name} · ${set!.items.length} images',
      _SearchResultKind.image => stack.name,
    };
    final thumbs = switch (result.kind) {
      _SearchResultKind.stack => stack.items.take(8).toList(),
      _SearchResultKind.set => set!.items.take(8).toList(),
      _SearchResultKind.image => [result.image!],
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1C),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF727785),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: const Color(0xFF727785)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: thumbs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 5),
                itemBuilder: (context, index) => _Thumb(
                  path: thumbs[index].thumbnailPath,
                  width: 80,
                  height: 132,
                  radius: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSetResultScreen extends StatelessWidget {
  const _SearchSetResultScreen({
    required this.stack,
    required this.set,
    required this.allStackKeys,
    required this.stackNames,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onMoveImage,
    required this.onSaveSetMemo,
    required this.onAssignImageToSet,
    this.onDeleteFolder,
  });

  final StackItem stack;
  final ScreenshotSet set;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;
  final Future<void> Function()? onDeleteFolder;

  @override
  Widget build(BuildContext context) {
    final isFolder = _isFolderSetKey(set.key);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        isFolder
                            ? _folderName(set)
                            : (set.memo.trim().isEmpty
                                  ? stack.name
                                  : set.memo.trim()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1C1C),
                            ),
                      ),
                    ),
                    if (isFolder && onDeleteFolder != null)
                      IconButton(
                        onPressed: () async {
                          await onDeleteFolder!();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Color(0xFF424754),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverToBoxAdapter(
                child: _SetSection(
                  set: set,
                  allStackKeys: allStackKeys,
                  stackNames: stackNames,
                  onExcludeImage: onExcludeImage,
                  onDeleteOriginalImage: onDeleteOriginalImage,
                  onMoveImage: onMoveImage,
                  selectedIds: const {},
                  onToggleSelection: (_) {},
                  showLocalActionBar: true,
                  onSaveMemo: isFolder ? (_, _) async {} : onSaveSetMemo,
                  onAssignImageToSet: onAssignImageToSet,
                  suppressHeader: isFolder,
                  showTitle: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onTap,
    required this.selectedDate,
    required this.onPickDate,
    required this.onClearDate,
  });

  final TextEditingController controller;
  final VoidCallback onTap;
  final DateTime? selectedDate;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    final date = selectedDate;
    final dateText = date == null
        ? null
        : '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEFF2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TextField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: '검색',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF727785),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF727785),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 44,
              ),
              suffixIcon: InkWell(
                onTap: onPickDate,
                borderRadius: BorderRadius.circular(999),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: date == null
                      ? const Color(0xFF727785)
                      : const Color(0xFF111111),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 44,
              ),
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 0,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        if (dateText != null) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: onClearDate,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateText,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF424754),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF727785),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StackCard extends StatelessWidget {
  const _StackCard({
    required this.stack,
    required this.allStackKeys,
    required this.stackNames,
    required this.setMemos,
    required this.folderNames,
    required this.folderColors,
    required this.setAssignments,
    required this.visualFeatures,
    required this.onRenameStack,
    required this.onHideStack,
    required this.onTogglePinStack,
    required this.pinned,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onDeleteOriginalImages,
    required this.onMoveImage,
    this.onAddImageToStack,
    required this.onSaveSetMemo,
    required this.onSaveFolderName,
    required this.onSaveFolderColor,
    required this.onAssignImageToSet,
  });

  final StackItem stack;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> setMemos;
  final Map<String, String> folderNames;
  final Map<String, String> folderColors;
  final Map<String, String> setAssignments;
  final Map<String, VisualFeature> visualFeatures;
  final Future<void> Function(String stackKey, String name) onRenameStack;
  final Future<void> Function(String stackKey) onHideStack;
  final Future<void> Function(String stackKey) onTogglePinStack;
  final bool pinned;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<bool> Function(List<String> imageIds) onDeleteOriginalImages;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<ScreenshotItem?> Function(String stackKey)? onAddImageToStack;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String folderKey, String name) onSaveFolderName;
  final Future<void> Function(String folderKey, String colorKey)
  onSaveFolderColor;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () => _showStackQuickActions(context),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StackDetailScreen(
            stack: stack,
            allStackKeys: allStackKeys,
            stackNames: stackNames,
            setMemos: setMemos,
            folderNames: folderNames,
            folderColors: folderColors,
            setAssignments: setAssignments,
            visualFeatures: visualFeatures,
            onRenameStack: onRenameStack,
            onHideStack: onHideStack,
            onExcludeImage: onExcludeImage,
            onDeleteOriginalImage: onDeleteOriginalImage,
            onDeleteOriginalImages: onDeleteOriginalImages,
            onMoveImage: onMoveImage,
            onAddImageToStack: onAddImageToStack,
            onSaveSetMemo: onSaveSetMemo,
            onSaveFolderName: onSaveFolderName,
            onSaveFolderColor: onSaveFolderColor,
            onAssignImageToSet: onAssignImageToSet,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (pinned) ...[
                            const Icon(
                              Icons.push_pin_rounded,
                              size: 16,
                              color: Color(0xFF424754),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Expanded(
                            child: Text(
                              stack.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontSize: 18,
                                    height: 24 / 18,
                                    color: const Color(0xFF1A1C1C),
                                    fontWeight: FontWeight.w700,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stack.items.length} images',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF424754),
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF727785),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stack.items.take(8).length,
                separatorBuilder: (context, index) => const SizedBox(width: 5),
                itemBuilder: (context, index) => _Thumb(
                  path: stack.items[index].thumbnailPath,
                  width: 96,
                  height: 160,
                  radius: 12,
                  borderColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStackQuickActions(BuildContext context) async {
    final action = await _showShotlyActionSheet<String>(
      context,
      items: [
        _ShotlyActionItem(
          value: 'pin',
          icon: pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          title: pinned ? '고정 해제' : '고정 하기',
        ),
        const _ShotlyActionItem(
          value: 'rename',
          icon: Icons.edit_rounded,
          title: 'Stack 이름 수정',
        ),
        const _ShotlyActionItem(
          value: 'hide',
          icon: Icons.visibility_off_rounded,
          title: 'Stack 숨기기',
        ),
      ],
    );
    if (action == 'pin') await onTogglePinStack(stack.key);
    if (action == 'rename' && context.mounted) {
      final name = await _showShotlyTextDialog(
        context: context,
        title: 'Stack 이름 수정',
        initialValue: stack.name,
        hintText: 'Stack 이름',
        primaryLabel: '저장',
      );
      if (name != null) await onRenameStack(stack.key, name);
    }
    if (action == 'hide') await onHideStack(stack.key);
  }
}

class StackDetailScreen extends StatefulWidget {
  const StackDetailScreen({
    super.key,
    required this.stack,
    required this.allStackKeys,
    required this.stackNames,
    required this.setMemos,
    required this.folderNames,
    required this.folderColors,
    required this.setAssignments,
    required this.visualFeatures,
    required this.onRenameStack,
    required this.onHideStack,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onDeleteOriginalImages,
    required this.onMoveImage,
    this.onAddImageToStack,
    required this.onSaveSetMemo,
    required this.onSaveFolderName,
    required this.onSaveFolderColor,
    required this.onAssignImageToSet,
  });

  final StackItem stack;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> setMemos;
  final Map<String, String> folderNames;
  final Map<String, String> folderColors;
  final Map<String, String> setAssignments;
  final Map<String, VisualFeature> visualFeatures;
  final Future<void> Function(String stackKey, String name) onRenameStack;
  final Future<void> Function(String stackKey) onHideStack;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<bool> Function(List<String> imageIds) onDeleteOriginalImages;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<ScreenshotItem?> Function(String stackKey)? onAddImageToStack;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String folderKey, String name) onSaveFolderName;
  final Future<void> Function(String folderKey, String colorKey)
  onSaveFolderColor;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;

  @override
  State<StackDetailScreen> createState() => _StackDetailScreenState();
}

class _StackDetailScreenState extends State<StackDetailScreen> {
  final Set<String> _deletedImageIds = <String>{};
  final Set<String> _selectedImageIds = <String>{};
  final List<ScreenshotItem> _addedItems = <ScreenshotItem>[];
  late Map<String, String> _detailFolderNames;
  late Map<String, String> _detailFolderColors;
  late Map<String, String> _detailSetAssignments;

  String get _stackName =>
      widget.stackNames[widget.stack.key] ?? widget.stack.name;

  @override
  void initState() {
    super.initState();
    _detailFolderNames = {...widget.folderNames};
    _detailFolderColors = {...widget.folderColors};
    _detailSetAssignments = {...widget.setAssignments};
  }

  @override
  void didUpdateWidget(covariant StackDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.folderNames, widget.folderNames)) {
      _detailFolderNames = {...widget.folderNames, ..._detailFolderNames};
    }
    if (!identical(oldWidget.folderColors, widget.folderColors)) {
      _detailFolderColors = {...widget.folderColors, ..._detailFolderColors};
    }
    if (!identical(oldWidget.setAssignments, widget.setAssignments)) {
      _detailSetAssignments = {
        ...widget.setAssignments,
        ..._detailSetAssignments,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = [
      ..._addedItems,
      ...widget.stack.items,
    ].where((item) => !_deletedImageIds.contains(item.id)).toList();
    final sets = _buildScreenshotSets(
      widget.stack.key,
      visibleItems,
      widget.setMemos,
      _detailFolderNames,
      _detailSetAssignments,
    );
    final folderSets = sets.where((set) => _isFolderSetKey(set.key)).toList();
    final dateGroups = _groupSetsByDate(
      sets.where((set) => !_isFolderSetKey(set.key)).toList(),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF424754),
                              ),
                            ),
                            const Spacer(),
                            if (widget.onAddImageToStack != null)
                              IconButton(
                                onPressed: _addImageToCurrentStack,
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Color(0xFF424754),
                                ),
                              ),
                            IconButton(
                              onPressed: () => _showStackActions(context),
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Color(0xFF424754),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _selectedImageIds.isNotEmpty
                              ? '${_selectedImageIds.length}개 선택'
                              : _stackName,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: const Color(0xFF1A1C1C),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (folderSets.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _FolderStrip(
                            stack: widget.stack,
                            folders: folderSets,
                            allStackKeys: widget.allStackKeys,
                            stackNames: widget.stackNames,
                            folderColors: _detailFolderColors,
                            selectedIds: _selectedImageIds,
                            onAddSelectedToFolder: _addSelectedToExistingFolder,
                            onDeleteFolder: (folder) =>
                                _deleteFolder(context, folder, visibleItems),
                            onChangeFolderColor: _changeFolderColor,
                            onExcludeImage: widget.onExcludeImage,
                            onDeleteOriginalImage: _deleteOriginalImage,
                            onMoveImage: widget.onMoveImage,
                            onSaveSetMemo: widget.onSaveSetMemo,
                            onAssignImageToSet: widget.onAssignImageToSet,
                          ),
                          const SizedBox(height: 24),
                        ] else
                          const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: dateGroups.isEmpty ? 1 : dateGroups.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 32),
                    itemBuilder: (context, index) {
                      if (dateGroups.isEmpty) {
                        return const _EmptyStackDetail(
                          message: '아직 이미지가 없는 Stack이에요',
                        );
                      }
                      return _SetDateSection(
                        dateLabel: dateGroups[index].dateLabel,
                        sets: dateGroups[index].sets,
                        allStackKeys: widget.allStackKeys,
                        stackNames: widget.stackNames,
                        onExcludeImage: widget.onExcludeImage,
                        onDeleteOriginalImage: _deleteOriginalImage,
                        onMoveImage: widget.onMoveImage,
                        selectedIds: _selectedImageIds,
                        onToggleSelection: _toggleSelection,
                        onToggleDateSelection: _toggleDateSelection,
                        showLocalActionBar: false,
                        onSaveMemo: widget.onSaveSetMemo,
                        onAssignImageToSet: widget.onAssignImageToSet,
                        viewerItems: visibleItems,
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_selectedImageIds.isNotEmpty)
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: _SelectionActionBar(
                  onCancel: () => setState(_selectedImageIds.clear),
                  onShare: _shareSelected,
                  onDelete: () => _deleteSelected(context),
                  onMove: () => _moveSelectedToStack(context),
                  onFolder: () => _addSelectedToFolder(context, folderSets),
                  onHide: _hideSelected,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(String imageId) {
    setState(() {
      if (!_selectedImageIds.add(imageId)) _selectedImageIds.remove(imageId);
    });
  }

  void _toggleDateSelection(List<String> imageIds) {
    setState(() {
      final allSelected = imageIds.every(_selectedImageIds.contains);
      if (allSelected) {
        _selectedImageIds.removeAll(imageIds);
      } else {
        _selectedImageIds.addAll(imageIds);
      }
    });
  }

  Future<void> _shareSelected() async {
    await ShotlyNative.shareImages(_selectedImageIds.toList());
  }

  Future<void> _hideSelected() async {
    final selected = _selectedImageIds.toList();
    for (final id in selected) {
      await widget.onExcludeImage(id);
    }
    if (mounted) {
      setState(() {
        _deletedImageIds.addAll(selected);
        _selectedImageIds.clear();
      });
    }
  }

  Future<void> _addImageToCurrentStack() async {
    final image = await widget.onAddImageToStack?.call(widget.stack.key);
    if (image == null || !mounted) return;
    setState(() {
      if (!_addedItems.any((item) => item.id == image.id) &&
          !widget.stack.items.any((item) => item.id == image.id)) {
        _addedItems.insert(0, image);
      }
    });
  }

  Future<void> _addSelectedToFolder(
    BuildContext context,
    List<ScreenshotSet> folders,
  ) async {
    final target = await _showShotlyActionSheet<String>(
      context,
      title: '추가할 그룹',
      items: [
        const _ShotlyActionItem(
          value: '__new_folder__',
          icon: Icons.grid_view_rounded,
          title: '신규 그룹 만들기',
        ),
        ...folders.map(
          (folder) => _ShotlyActionItem(
            value: folder.key,
            icon: Icons.grid_view_rounded,
            title: _folderName(folder),
          ),
        ),
      ],
    );
    if (target == null) return;
    var folderKey = target;
    if (target == '__new_folder__') {
      if (!context.mounted) return;
      final name = await _showShotlyTextDialog(
        context: context,
        title: '그룹 만들기',
        hintText: '그룹 이름',
        primaryLabel: '만들기',
      );
      final trimmed = name?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      folderKey = await _createFolderWithName(trimmed);
    }
    await _assignSelectedToFolder(folderKey, _selectedImageIds.toList());
  }

  Future<void> _createFolderAndAddSelected(BuildContext context) async {
    final folderKey = await _createFolder(context);
    if (folderKey == null) return;
    await _assignSelectedToFolder(folderKey, _selectedImageIds.toList());
  }

  Future<void> _addSelectedToExistingFolder(ScreenshotSet folder) async {
    await _assignSelectedToFolder(folder.key, _selectedImageIds.toList());
  }

  Future<void> _assignSelectedToFolder(
    String folderKey,
    List<String> selected,
  ) async {
    if (selected.isEmpty) return;
    final nextAssignments = <String, String>{};
    for (final id in selected) {
      final next = _addAssignmentKey(_detailSetAssignments[id], folderKey);
      nextAssignments[id] = next;
    }
    if (mounted) {
      setState(() {
        _detailSetAssignments.addAll(nextAssignments);
        _selectedImageIds.clear();
      });
    }
    for (final id in selected) {
      await widget.onAssignImageToSet(id, folderKey);
    }
  }

  Future<String?> _createFolder(BuildContext context) async {
    final name = await _showShotlyTextDialog(
      context: context,
      title: '그룹 만들기',
      hintText: '그룹 이름',
      primaryLabel: '만들기',
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return _createFolderWithName(trimmed);
  }

  Future<String> _createFolderWithName(String name) async {
    final folderKey = _buildFolderKey(widget.stack.key);
    setState(() => _detailFolderNames[folderKey] = name);
    await widget.onSaveFolderName(folderKey, name);
    return folderKey;
  }

  Future<void> _deleteFolder(
    BuildContext context,
    ScreenshotSet folder,
    List<ScreenshotItem> visibleItems,
  ) async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '그룹 삭제',
      body: '그룹만 삭제하고 사진은 Stack에 그대로 둘까요?',
      primaryLabel: '삭제',
      destructive: true,
    );
    if (confirmed != true) return;
    final assignedIds = visibleItems
        .where(
          (item) =>
              _assignmentContains(_detailSetAssignments[item.id], folder.key),
        )
        .map((item) => item.id)
        .toList();
    for (final id in assignedIds) {
      final next = _removeAssignmentKey(_detailSetAssignments[id], folder.key);
      setState(() {
        if (next == null || next.isEmpty) {
          _detailSetAssignments.remove(id);
        } else {
          _detailSetAssignments[id] = next;
        }
      });
      await widget.onAssignImageToSet(
        id,
        '$_removeAssignmentPrefix${folder.key}',
      );
    }
    setState(() => _detailFolderNames.remove(folder.key));
    await widget.onSaveFolderName(folder.key, '');
    await widget.onSaveSetMemo(folder.key, '');
    if (mounted) setState(() {});
  }

  Future<void> _moveSelectedToStack(BuildContext context) async {
    final target = await _showShotlyActionSheet<String>(
      context,
      title: '이동할 Stack',
      items: widget.allStackKeys
          .where((key) => key != widget.stack.key)
          .map(
            (key) => _ShotlyActionItem(
              value: key,
              icon: Icons.layers_rounded,
              title: widget.stackNames[key] ?? key,
            ),
          )
          .toList(),
    );
    if (target == null) return;
    final selected = _selectedImageIds.toList();
    for (final id in selected) {
      await widget.onMoveImage(id, target);
    }
    if (mounted) {
      setState(() {
        _deletedImageIds.addAll(selected);
        _selectedImageIds.clear();
      });
    }
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '원본 파일 삭제',
      body:
          '선택한 ${_selectedImageIds.length}장을 Shotly뿐 아니라 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
      primaryLabel: '삭제',
      destructive: true,
    );
    if (confirmed != true) return;
    final selected = _selectedImageIds.toList();
    if (await widget.onDeleteOriginalImages(selected) && mounted) {
      setState(() {
        _deletedImageIds.addAll(selected);
        _selectedImageIds.clear();
      });
    }
  }

  Future<void> _renameStack(BuildContext context) async {
    final name = await _showShotlyTextDialog(
      context: context,
      title: 'Stack 이름 수정',
      initialValue: _stackName,
      hintText: 'Stack 이름',
      primaryLabel: '저장',
    );
    if (name == null) return;
    await widget.onRenameStack(widget.stack.key, name);
    if (mounted) setState(() {});
  }

  Future<void> _showStackActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              _AddMenuTile(
                icon: Icons.grid_view_rounded,
                title: _selectedImageIds.isEmpty ? '그룹 추가' : '선택 이미지로 그룹 추가',
                onTap: () => Navigator.of(context).pop('folder'),
              ),
              _AddMenuTile(
                icon: Icons.edit_rounded,
                title: 'Stack 이름 수정',
                onTap: () => Navigator.of(context).pop('rename'),
              ),
              _AddMenuTile(
                icon: Icons.visibility_off_rounded,
                title: 'Stack 숨기기',
                onTap: () => Navigator.of(context).pop('hide'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'folder') {
      if (_selectedImageIds.isEmpty) {
        await _createFolder(context);
      } else {
        await _createFolderAndAddSelected(context);
      }
      return;
    }
    if (action == 'rename') await _renameStack(context);
    if (action == 'hide') {
      await widget.onHideStack(widget.stack.key);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _changeFolderColor(String folderKey, String colorKey) async {
    setState(() {
      if (colorKey.trim().isEmpty) {
        _detailFolderColors.remove(folderKey);
      } else {
        _detailFolderColors[folderKey] = colorKey;
      }
    });
    await widget.onSaveFolderColor(folderKey, colorKey);
  }

  Future<bool> _deleteOriginalImage(String imageId) async {
    final deleted = await widget.onDeleteOriginalImage(imageId);
    if (deleted && mounted) {
      setState(() => _deletedImageIds.add(imageId));
    }
    return deleted;
  }
}

class _FolderColorOption {
  const _FolderColorOption(this.key, this.color, this.darkColor);

  final String key;
  final Color color;
  final Color darkColor;
}

const List<_FolderColorOption> _folderColorOptions = [
  _FolderColorOption('butter', Color(0xFFFFD86B), Color(0xFFE9AE2F)),
  _FolderColorOption('peach', Color(0xFFFFB199), Color(0xFFE8795F)),
  _FolderColorOption('rose', Color(0xFFFF9DB8), Color(0xFFE85D88)),
  _FolderColorOption('lavender', Color(0xFFC9B7FF), Color(0xFF8B6FE8)),
  _FolderColorOption('sky', Color(0xFF9BD4FF), Color(0xFF4C9DD8)),
  _FolderColorOption('mint', Color(0xFF9BE7C1), Color(0xFF4CB783)),
  _FolderColorOption('sand', Color(0xFFE6C79C), Color(0xFFC29055)),
  _FolderColorOption('slate', Color(0xFFC7CFDA), Color(0xFF8C98A8)),
];

_FolderColorOption _folderColorFor(String? key) {
  return _folderColorOptions.firstWhere(
    (option) => option.key == key,
    orElse: () => _folderColorOptions.first,
  );
}

class _FolderStrip extends StatelessWidget {
  const _FolderStrip({
    required this.stack,
    required this.folders,
    required this.allStackKeys,
    required this.stackNames,
    required this.folderColors,
    required this.selectedIds,
    required this.onAddSelectedToFolder,
    required this.onDeleteFolder,
    required this.onChangeFolderColor,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onMoveImage,
    required this.onSaveSetMemo,
    required this.onAssignImageToSet,
  });

  final StackItem stack;
  final List<ScreenshotSet> folders;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> folderColors;
  final Set<String> selectedIds;
  final Future<void> Function(ScreenshotSet folder) onAddSelectedToFolder;
  final Future<void> Function(ScreenshotSet folder) onDeleteFolder;
  final Future<void> Function(String folderKey, String colorKey)
  onChangeFolderColor;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: folders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final folder = folders[index];
          return _FolderCard(
            stack: stack,
            folder: folder,
            colorKey: folderColors[folder.key],
            allStackKeys: allStackKeys,
            stackNames: stackNames,
            selectedIds: selectedIds,
            onAddSelected: () => onAddSelectedToFolder(folder),
            onDelete: () => onDeleteFolder(folder),
            onChangeColor: (colorKey) =>
                onChangeFolderColor(folder.key, colorKey),
            onExcludeImage: onExcludeImage,
            onDeleteOriginalImage: onDeleteOriginalImage,
            onMoveImage: onMoveImage,
            onSaveSetMemo: onSaveSetMemo,
            onAssignImageToSet: onAssignImageToSet,
          );
        },
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.stack,
    required this.folder,
    required this.colorKey,
    required this.allStackKeys,
    required this.stackNames,
    required this.selectedIds,
    required this.onAddSelected,
    required this.onDelete,
    required this.onChangeColor,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onMoveImage,
    required this.onSaveSetMemo,
    required this.onAssignImageToSet,
  });

  final StackItem stack;
  final ScreenshotSet folder;
  final String? colorKey;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Set<String> selectedIds;
  final Future<void> Function() onAddSelected;
  final Future<void> Function() onDelete;
  final Future<void> Function(String colorKey) onChangeColor;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;

  @override
  Widget build(BuildContext context) {
    final option = _folderColorFor(colorKey);
    final isEmpty = folder.items.isEmpty;
    final title = _folderName(folder);
    return InkWell(
      onLongPress: () => _showFolderActions(context),
      onTap: selectedIds.isNotEmpty
          ? onAddSelected
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _SearchSetResultScreen(
                  stack: stack,
                  set: folder,
                  allStackKeys: allStackKeys,
                  stackNames: stackNames,
                  onExcludeImage: onExcludeImage,
                  onDeleteOriginalImage: onDeleteOriginalImage,
                  onMoveImage: onMoveImage,
                  onSaveSetMemo: onSaveSetMemo,
                  onAssignImageToSet: onAssignImageToSet,
                  onDeleteFolder: onDelete,
                ),
              ),
            ),
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FolderShape(
              option: option,
              count: folder.items.length,
              isEmpty: isEmpty,
              onColorTap: () => _showColorPicker(context),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF1A1C1C),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              isEmpty ? '비어 있음' : '그룹',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: const Color(0xFF727785)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFolderActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('폴더 색상 변경'),
                onTap: () => Navigator.pop(context, 'color'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFE05656),
                ),
                title: const Text(
                  '그룹 삭제',
                  style: TextStyle(color: Color(0xFFE05656)),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'delete') {
      await onDelete();
    } else if (action == 'color') {
      await _showColorPicker(context);
    }
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '폴더 색상',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final option in _folderColorOptions)
                    _FolderColorDot(
                      option: option,
                      selected: _folderColorFor(colorKey).key == option.key,
                      onTap: () => Navigator.pop(context, option.key),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await onChangeColor(picked);
  }
}

class _FolderShape extends StatelessWidget {
  const _FolderShape({
    required this.option,
    required this.count,
    required this.isEmpty,
    required this.onColorTap,
  });

  final _FolderColorOption option;
  final int count;
  final bool isEmpty;
  final VoidCallback onColorTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 94,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 4,
            child: Container(
              width: 58,
              height: 24,
              decoration: BoxDecoration(
                color: option.darkColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 19,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: option.color,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: option.darkColor.withValues(alpha: 0.26),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 12,
                    top: 15,
                    child: Icon(
                      isEmpty
                          ? Icons.create_new_folder_outlined
                          : Icons.folder_rounded,
                      size: 30,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count장',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF1A1C1C),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: GestureDetector(
                      onTap: onColorTap,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.palette_outlined,
                          size: 14,
                          color: option.darkColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderColorDot extends StatelessWidget {
  const _FolderColorDot({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _FolderColorOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: option.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF1A1C1C) : Colors.white,
            width: selected ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: option.darkColor.withValues(alpha: 0.20),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: selected
            ? const Icon(
                Icons.check_rounded,
                size: 20,
                color: Color(0xFF1A1C1C),
              )
            : null,
      ),
    );
  }
}

class _SetDateSection extends StatelessWidget {
  const _SetDateSection({
    required this.dateLabel,
    required this.sets,
    required this.allStackKeys,
    required this.stackNames,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onMoveImage,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onToggleDateSelection,
    required this.showLocalActionBar,
    required this.onSaveMemo,
    required this.onAssignImageToSet,
    required this.viewerItems,
  });

  final String dateLabel;
  final List<ScreenshotSet> sets;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<List<String>> onToggleDateSelection;
  final bool showLocalActionBar;
  final Future<void> Function(String setKey, String memo) onSaveMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;
  final List<ScreenshotItem> viewerItems;

  @override
  Widget build(BuildContext context) {
    final dateImageIds = sets
        .expand((set) => set.items.map((item) => item.id))
        .toList();
    final selectedCount = dateImageIds
        .where((id) => selectedIds.contains(id))
        .length;
    final dateCheckValue = selectedCount == 0
        ? false
        : selectedCount == dateImageIds.length
        ? true
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sets.indexed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SetSection(
              set: entry.$2,
              allStackKeys: allStackKeys,
              stackNames: stackNames,
              onExcludeImage: onExcludeImage,
              onDeleteOriginalImage: onDeleteOriginalImage,
              onMoveImage: onMoveImage,
              selectedIds: selectedIds,
              onToggleSelection: onToggleSelection,
              showLocalActionBar: showLocalActionBar,
              onSaveMemo: onSaveMemo,
              onAssignImageToSet: onAssignImageToSet,
              showTitle: false,
              headerLabel: entry.$1 == 0 ? dateLabel : '',
              onHeaderTap: entry.$1 == 0
                  ? () => onToggleDateSelection(dateImageIds)
                  : null,
              headerCheckValue: entry.$1 == 0 ? dateCheckValue : null,
              showHeaderCheckbox: entry.$1 == 0,
              viewerItems: viewerItems,
            ),
          ),
        ),
      ],
    );
  }
}

class _SetSection extends StatefulWidget {
  const _SetSection({
    required this.set,
    required this.allStackKeys,
    required this.stackNames,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onMoveImage,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.showLocalActionBar,
    required this.onSaveMemo,
    required this.onAssignImageToSet,
    this.showTitle = true,
    this.suppressHeader = false,
    this.headerLabel,
    this.onHeaderTap,
    this.headerCheckValue,
    this.showHeaderCheckbox = false,
    this.viewerItems,
  });

  final ScreenshotSet set;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelection;
  final bool showLocalActionBar;
  final Future<void> Function(String setKey, String memo) onSaveMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;
  final bool showTitle;
  final bool suppressHeader;
  final String? headerLabel;
  final VoidCallback? onHeaderTap;
  final bool? headerCheckValue;
  final bool showHeaderCheckbox;
  final List<ScreenshotItem>? viewerItems;
  @override
  State<_SetSection> createState() => _SetSectionState();
}

class _SetSectionState extends State<_SetSection> {
  late final TextEditingController _memoController;
  late String _memoText;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: widget.set.memo);
    _memoText = widget.set.memo;
  }

  @override
  void didUpdateWidget(covariant _SetSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set.memo != widget.set.memo && widget.set.memo != _memoText) {
      _memoText = widget.set.memo;
      _memoController.text = widget.set.memo;
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ImageGridSection(
      title: widget.suppressHeader
          ? ''
          : widget.headerLabel ??
                (widget.showTitle ? widget.set.timeRange : ''),
      titleOnTap: widget.onHeaderTap,
      headerCheckValue: widget.headerCheckValue,
      showHeaderCheckbox: widget.showHeaderCheckbox,
      memoText: widget.suppressHeader || _memoText.trim().isEmpty
          ? null
          : _memoText.trim(),
      items: widget.set.items,
      viewerItems: widget.viewerItems,
      allStackKeys: widget.allStackKeys,
      stackNames: widget.stackNames,
      onExcludeImage: widget.onExcludeImage,
      onDeleteOriginalImage: widget.onDeleteOriginalImage,
      onMoveImage: widget.onMoveImage,
      selectedIds: widget.selectedIds,
      onToggleSelection: widget.onToggleSelection,
      showLocalActionBar: widget.showLocalActionBar,
      onSetAction: widget.suppressHeader
          ? null
          : () => _showSetActions(context),
      onEditMemo: widget.suppressHeader
          ? null
          : () async {
              final memo = await _editMemo(context);
              if (memo != null) await _saveMemo(memo);
            },
    );
  }

  Future<void> _showSetActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              _AddMenuTile(
                icon: Icons.edit_note_rounded,
                title: _memoText.trim().isEmpty ? '메모 추가' : '메모 수정',
                onTap: () => Navigator.of(context).pop('memo'),
              ),
              if (_memoText.trim().isNotEmpty)
                _AddMenuTile(
                  icon: Icons.notes_rounded,
                  title: '메모 삭제',
                  onTap: () => Navigator.of(context).pop('clear_memo'),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == 'memo' && context.mounted) {
      final memo = await _editMemo(context);
      if (memo != null) await _saveMemo(memo);
    }
    if (action == 'clear_memo') {
      await _saveMemo('');
    }
  }

  Future<void> _saveMemo(String memo) async {
    if (!mounted) return;
    final previous = _memoText;
    final trimmed = memo.trim();
    setState(() {
      _memoText = trimmed;
      _memoController.text = trimmed;
    });
    try {
      await widget.onSaveMemo(widget.set.key, trimmed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _memoText = previous;
        _memoController.text = previous;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('메모를 저장하지 못했습니다: $e')));
    }
  }

  Future<String?> _editMemo(BuildContext context) async {
    final value = await _showShotlyTextDialog(
      context: context,
      title: 'Set 메모',
      initialValue: _memoText,
      hintText: '예: 온보딩 플로우',
      primaryLabel: '저장',
      minLines: 1,
      maxLines: 3,
    );
    if (value != null) _memoController.text = value;
    return value;
  }
}

class _ImageGridSection extends StatefulWidget {
  const _ImageGridSection({
    required this.title,
    required this.items,
    required this.allStackKeys,
    this.memoText,
    this.titleOnTap,
    this.headerCheckValue,
    this.showHeaderCheckbox = false,
    this.viewerItems,
    required this.stackNames,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onMoveImage,
    this.selectedIds,
    this.onToggleSelection,
    this.showLocalActionBar = true,
    this.onSetAction,
    this.onEditMemo,
  });

  final String title;
  final List<ScreenshotItem> items;
  final String? memoText;
  final VoidCallback? titleOnTap;
  final bool? headerCheckValue;
  final bool showHeaderCheckbox;
  final List<ScreenshotItem>? viewerItems;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Set<String>? selectedIds;
  final ValueChanged<String>? onToggleSelection;
  final bool showLocalActionBar;
  final VoidCallback? onSetAction;
  final VoidCallback? onEditMemo;

  @override
  State<_ImageGridSection> createState() => _ImageGridSectionState();
}

class _ImageGridSectionState extends State<_ImageGridSection> {
  final Set<String> _selectedIds = <String>{};
  final Set<String> _locallyHiddenIds = <String>{};

  Set<String> get _effectiveSelectedIds => widget.selectedIds ?? _selectedIds;
  bool get _isSelecting => _effectiveSelectedIds.isNotEmpty;
  List<ScreenshotItem> get _visibleItems => widget.items
      .where((item) => !_locallyHiddenIds.contains(item.id))
      .toList();

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    final hasHeader =
        widget.title.isNotEmpty ||
        widget.showHeaderCheckbox ||
        widget.memoText != null ||
        (widget.onSetAction != null && !_isSelecting);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasHeader) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title.isNotEmpty ||
                    widget.showHeaderCheckbox ||
                    (widget.onSetAction != null && !_isSelecting))
                  Row(
                    children: [
                      if (widget.showHeaderCheckbox) ...[
                        Checkbox(
                          value: widget.headerCheckValue,
                          tristate: true,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(
                            color: Color(0xFFD5D8DF),
                            width: 1.4,
                          ),
                          activeColor: const Color(0xFF1A1C1C),
                          checkColor: Colors.white,
                          onChanged: (_) => widget.titleOnTap?.call(),
                        ),
                        const SizedBox(width: 2),
                      ],
                      Expanded(
                        child: InkWell(
                          onTap: widget.titleOnTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              widget.title,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: const Color(0xFF1A1C1C)),
                            ),
                          ),
                        ),
                      ),
                      if (widget.onSetAction != null && !_isSelecting)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: Color(0xFF727785),
                          ),
                          onPressed: widget.onSetAction,
                        ),
                    ],
                  ),
                if (widget.memoText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.memoText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF424754),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 3 / 4,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _SelectableThumb(
              item: item,
              selected: _effectiveSelectedIds.contains(item.id),
              selecting: _isSelecting,
              onTap: () => _isSelecting
                  ? _toggleSelection(item.id)
                  : _openImageViewer(context, item),
              onLongPress: () => _toggleSelection(item.id),
            );
          },
        ),
        if (_isSelecting && widget.showLocalActionBar) ...[
          const SizedBox(height: 12),
          _SelectionActionBar(
            onCancel: () => setState(_selectedIds.clear),
            onShare: _shareSelected,
            onDelete: () => _deleteSelected(context),
            onMove: () => _moveSelected(context),
            onHide: _hideSelected,
          ),
        ],
      ],
    );
  }

  void _toggleSelection(String imageId) {
    if (widget.onToggleSelection != null) {
      widget.onToggleSelection!(imageId);
      return;
    }
    setState(() {
      if (!_selectedIds.add(imageId)) _selectedIds.remove(imageId);
    });
  }

  Future<void> _openImageViewer(
    BuildContext context,
    ScreenshotItem item,
  ) async {
    final viewerItems = (widget.viewerItems ?? widget.items)
        .where((candidate) => !_locallyHiddenIds.contains(candidate.id))
        .toList();
    final index = viewerItems.indexWhere(
      (candidate) => candidate.id == item.id,
    );
    final deletedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(
          items: viewerItems,
          initialIndex: index < 0 ? 0 : index,
          onDeleteOriginalImage: widget.onDeleteOriginalImage,
        ),
      ),
    );
    if (deletedId != null && mounted) {
      setState(() => _locallyHiddenIds.add(deletedId));
    }
  }

  Future<void> _shareSelected() async {
    await ShotlyNative.shareImages(_effectiveSelectedIds.toList());
  }

  Future<void> _hideSelected() async {
    final selected = _effectiveSelectedIds.toList();
    for (final id in selected) {
      await widget.onExcludeImage(id);
    }
    setState(() {
      _locallyHiddenIds.addAll(selected);
      _selectedIds.clear();
    });
  }

  Future<void> _moveSelected(BuildContext context) async {
    final target = await _showShotlyActionSheet<String>(
      context,
      title: '이동할 Stack',
      items: widget.allStackKeys
          .map(
            (key) => _ShotlyActionItem(
              value: key,
              icon: Icons.layers_rounded,
              title: widget.stackNames[key] ?? key,
            ),
          )
          .toList(),
    );
    if (target == null) return;
    final selected = _effectiveSelectedIds.toList();
    for (final id in selected) {
      await widget.onMoveImage(id, target);
    }
    setState(() {
      _locallyHiddenIds.addAll(selected);
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '원본 파일 삭제',
      body:
          '선택한 ${_effectiveSelectedIds.length}장을 Shotly뿐 아니라 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
      primaryLabel: '삭제',
      destructive: true,
    );
    if (confirmed != true) return;
    final selected = _effectiveSelectedIds.toList();
    final deleted = <String>[];
    for (final id in selected) {
      if (await widget.onDeleteOriginalImage(id)) deleted.add(id);
    }
    setState(() {
      _locallyHiddenIds.addAll(deleted);
      _selectedIds.removeAll(deleted);
    });
  }
}

class _SelectableThumb extends StatelessWidget {
  const _SelectableThumb({
    required this.item,
    required this.selected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
  });

  final ScreenshotItem item;
  final bool selected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: _Thumb(
              path: item.thumbnailPath,
              radius: 14,
              borderColor: selected
                  ? const Color(0xFF2170E4)
                  : Colors.transparent,
            ),
          ),
          if (selecting)
            Positioned(
              right: 7,
              top: 7,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF2170E4)
                      : Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF2170E4)
                        : const Color(0xFFD5D8DF),
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.onCancel,
    required this.onShare,
    required this.onDelete,
    required this.onMove,
    required this.onHide,
    this.onFolder,
  });
  final VoidCallback onCancel;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onMove;
  final VoidCallback onHide;
  final VoidCallback? onFolder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SelectionActionButton(
            icon: Icons.drive_file_move_rounded,
            label: '이동',
            onTap: onMove,
          ),
          if (onFolder != null)
            _SelectionActionButton(
              icon: Icons.grid_view_rounded,
              label: '그룹',
              onTap: onFolder!,
            ),
          _SelectionActionButton(
            icon: Icons.share_rounded,
            label: '공유',
            onTap: onShare,
          ),
          _SelectionActionButton(
            icon: Icons.visibility_off_rounded,
            label: '숨기기',
            onTap: onHide,
          ),
          _SelectionActionButton(
            icon: Icons.delete_rounded,
            label: '삭제',
            onTap: onDelete,
            destructive: true,
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: Color(0xFF727785),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionActionButton extends StatelessWidget {
  const _SelectionActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFB42318)
        : const Color(0xFF424754);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStackDetail extends StatelessWidget {
  const _EmptyStackDetail({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF727785)),
        ),
      ),
    );
  }
}

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.onDeleteOriginalImage,
  });

  final List<ScreenshotItem> items;
  final int initialIndex;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _controlsVisible = true;
  final Map<String, Future<String?>> _previewFutures =
      <String, Future<String?>>{};

  ScreenshotItem get _currentItem => widget.items[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<String?> _previewFor(ScreenshotItem item) {
    return _previewFutures.putIfAbsent(
      item.id,
      () => ShotlyNative.getImagePreview(item.id, item.thumbnailPath),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _controlsVisible = !_controlsVisible),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return FutureBuilder<String?>(
                  future: _previewFor(item),
                  builder: (context, snapshot) {
                    final imagePath = snapshot.data ?? item.thumbnailPath;
                    return LayoutBuilder(
                      builder: (context, constraints) => InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: _buildViewerImage(imagePath),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            AnimatedOpacity(
              opacity: _controlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: Stack(
                  children: [
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      left: 8,
                      child: _ViewerCircleButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      right: 8,
                      child: Row(
                        children: [
                          _ViewerCircleButton(
                            icon: Icons.share_rounded,
                            onTap: () =>
                                ShotlyNative.shareImages([_currentItem.id]),
                          ),
                          const SizedBox(width: 10),
                          _ViewerCircleButton(
                            icon: Icons.delete_rounded,
                            destructive: true,
                            onTap: () async {
                              final confirmed = await _showShotlyConfirmDialog(
                                context: context,
                                title: '원본 파일 삭제',
                                body:
                                    '이 이미지를 기기 앨범 원본에서도 삭제할까요? 삭제 후 Shotly 목록에서도 사라져요.',
                                primaryLabel: '삭제',
                                destructive: true,
                              );
                              if (confirmed == true) {
                                final deleted = await widget
                                    .onDeleteOriginalImage(_currentItem.id);
                                if (deleted && context.mounted) {
                                  Navigator.of(context).pop(_currentItem.id);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.paddingOf(context).bottom + 20,
                      child: _ViewerInfo(
                        item: _currentItem,
                        index: _currentIndex,
                        total: widget.items.length,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerCircleButton extends StatelessWidget {
  const _ViewerCircleButton({
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.48),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Icon(
            icon,
            color: destructive ? const Color(0xFFFFD0CC) : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ViewerInfo extends StatelessWidget {
  const _ViewerInfo({
    required this.item,
    required this.index,
    required this.total,
  });

  final ScreenshotItem item;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '${index + 1}/$total · ${item.appName} · ${_formatSetDate(item.date)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

Widget _buildViewerImage(String path) {
  if (path.startsWith('mock://') || kIsWeb || path.isEmpty) {
    return _buildThumbnail(path, null, null);
  }
  return buildLocalImage(
    path,
    width: double.infinity,
    height: double.infinity,
    fit: BoxFit.contain,
    fallback: _buildThumbnail(path, null, null),
  );
}

class _ShotlyActionItem<T> {
  const _ShotlyActionItem({
    required this.value,
    required this.icon,
    required this.title,
  });

  final T value;
  final IconData icon;
  final String title;
}

Future<T?> _showShotlyActionSheet<T>(
  BuildContext context, {
  String? title,
  required List<_ShotlyActionItem<T>> items,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF727785),
                    ),
                  ),
                ),
              ],
              ...items.map(
                (item) => _ShotlyMenuRow(
                  icon: item.icon,
                  title: item.title,
                  onTap: () => Navigator.of(context).pop(item.value),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<String?> _showShotlyTextDialog({
  required BuildContext context,
  required String title,
  String initialValue = '',
  required String hintText,
  required String primaryLabel,
  int minLines = 1,
  int maxLines = 1,
  String? Function(String value)? validator,
}) async {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => _ShotlyTextDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      primaryLabel: primaryLabel,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
    ),
  );
}

class _ShotlyTextDialog extends StatefulWidget {
  const _ShotlyTextDialog({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.primaryLabel,
    required this.minLines,
    required this.maxLines,
    this.validator,
  });

  final String title;
  final String initialValue;
  final String hintText;
  final String primaryLabel;
  final int minLines;
  final int maxLines;
  final String? Function(String value)? validator;

  @override
  State<_ShotlyTextDialog> createState() => _ShotlyTextDialogState();
}

class _ShotlyTextDialogState extends State<_ShotlyTextDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  static const _fieldFillColor = Color(0xFFF7F7F8);
  static const _fieldErrorColor = Color(0xFFB42318);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF1A1C1C),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: widget.minLines,
              maxLines: widget.maxLines,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF727785),
                ),
                filled: true,
                fillColor: _fieldFillColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                errorText: _errorText,
                errorStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _fieldErrorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onChanged: (value) => _validateLive(value),
              onSubmitted: widget.maxLines == 1
                  ? (value) => _submit(context)
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: _errorText == null ? () => _submit(context) : null,
                  child: Text(widget.primaryLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _validateLive(String value) {
    final error = widget.validator?.call(value);
    if (error != _errorText) setState(() => _errorText = error);
  }

  void _submit(BuildContext context) {
    final error = widget.validator?.call(_controller.text);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }
}

Future<void> _showShotlyInfoDialog({
  required BuildContext context,
  required String title,
  required String body,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF424754)),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool?> _showShotlyConfirmDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String primaryLabel,
  bool destructive = false,
}) {
  final primaryColor = destructive
      ? const Color(0xFFB42318)
      : const Color(0xFF111111);
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF424754)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(primaryLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ShotlyMenuRow extends StatelessWidget {
  const _ShotlyMenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF424754)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF1A1C1C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMenuTile extends StatelessWidget {
  const _AddMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 24, color: const Color(0xFF111111)),
      title: Text(title, style: Theme.of(context).textTheme.labelLarge),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _SetDateGroup {
  const _SetDateGroup({required this.dateLabel, required this.sets});

  final String dateLabel;
  final List<ScreenshotSet> sets;
}

List<_SetDateGroup> _groupSetsByDate(List<ScreenshotSet> sets) {
  final grouped = <String, List<ScreenshotSet>>{};
  for (final set in sets) {
    if (set.items.isEmpty) continue;
    final dateLabel = _formatSetDate(set.items.first.date);
    grouped.putIfAbsent(dateLabel, () => []).add(set);
  }
  return grouped.entries
      .map((entry) => _SetDateGroup(dateLabel: entry.key, sets: entry.value))
      .toList();
}

const _assignmentSeparator = '\u001F';
const _removeAssignmentPrefix = '__remove_assignment__:';

List<String> _assignmentKeys(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  return raw
      .split(_assignmentSeparator)
      .map((key) => key.trim())
      .where((key) => key.isNotEmpty)
      .toList();
}

bool _assignmentContains(String? raw, String key) =>
    _assignmentKeys(raw).contains(key);

String _addAssignmentKey(String? raw, String key) {
  final keys = _assignmentKeys(raw);
  if (!keys.contains(key)) keys.add(key);
  return keys.join(_assignmentSeparator);
}

String? _removeAssignmentKey(String? raw, String key) {
  final keys = _assignmentKeys(raw)..remove(key);
  if (keys.isEmpty) return null;
  return keys.join(_assignmentSeparator);
}

List<ScreenshotSet> _buildScreenshotSets(
  String stackKey,
  List<ScreenshotItem> items,
  Map<String, String> setMemos,
  Map<String, String> folderNames, [
  Map<String, String> setAssignments = const {},
]) {
  final sorted = [...items]
    ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
  final manualGroups = <String, List<ScreenshotItem>>{};
  final autoItems = <ScreenshotItem>[];
  for (final item in sorted) {
    final manualKeys = _assignmentKeys(setAssignments[item.id]);
    final groupKeys = manualKeys.where(_isFolderSetKey).toList();
    final setKeys = manualKeys.where((key) => !_isFolderSetKey(key)).toList();
    if (manualKeys.isEmpty || groupKeys.isNotEmpty) {
      autoItems.add(item);
    }
    for (final key in [...setKeys, ...groupKeys]) {
      manualGroups.putIfAbsent(key, () => []).add(item);
    }
  }

  for (final entry in folderNames.entries) {
    if (entry.value.trim().isEmpty) continue;
    if (!_isFolderSetKey(entry.key) ||
        !_folderBelongsToStack(entry.key, stackKey)) {
      continue;
    }
    manualGroups.putIfAbsent(entry.key, () => <ScreenshotItem>[]);
  }

  final keyedSets = <MapEntry<String?, List<ScreenshotItem>>>[];
  var current = <ScreenshotItem>[];
  var firstTime = 0;
  const oneHourMillis = 60 * 60 * 1000;

  for (final item in autoItems) {
    if (current.isEmpty) {
      current = [item];
      firstTime = item.dateTakenMillis;
      continue;
    }
    final withinOneHour =
        firstTime > 0 &&
        item.dateTakenMillis > 0 &&
        (firstTime - item.dateTakenMillis).abs() <= oneHourMillis;
    final sameDay = _isSameDay(
      DateTime.fromMillisecondsSinceEpoch(firstTime),
      item.date,
    );
    if (withinOneHour && sameDay) {
      current.add(item);
    } else {
      keyedSets.add(MapEntry(null, current));
      current = [item];
      firstTime = item.dateTakenMillis;
    }
  }
  if (current.isNotEmpty) keyedSets.add(MapEntry(null, current));
  keyedSets.addAll(
    manualGroups.entries.map((entry) => MapEntry(entry.key, entry.value)),
  );

  final sets = keyedSets.map((entry) {
    final setItems = [...entry.value]
      ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
    final key = entry.key ?? _buildSetKey(stackKey, setItems);
    final isFolder = _isFolderSetKey(key);
    final migratedFolderName = isFolder ? setMemos[key]?.trim() : null;
    final folderName = isFolder
        ? (folderNames[key]?.trim().isNotEmpty == true
              ? folderNames[key]!.trim()
              : (migratedFolderName?.isNotEmpty == true
                    ? migratedFolderName
                    : '새 그룹'))
        : null;
    return ScreenshotSet(
      key: key,
      title:
          folderName ??
          (setItems.isEmpty ? 'Set' : _formatSetTitle(setItems.first.date)),
      timeRange: setItems.isEmpty ? '' : _formatTimeRange(setItems),
      items: setItems,
      memo: isFolder ? '' : setMemos[key] ?? '',
      folderName: folderName,
    );
  }).toList();
  sets.sort((a, b) => _setSortTime(b).compareTo(_setSortTime(a)));
  return sets;
}

int _setSortTime(ScreenshotSet set) =>
    set.items.isEmpty ? 0 : set.items.first.dateTakenMillis;

String _buildSetKey(String stackKey, List<ScreenshotItem> items) {
  final first = items.firstOrNull;
  return '$stackKey|${first?.dateTakenMillis ?? 0}|${first?.id ?? ''}';
}

String _buildFolderKey(String stackKey) =>
    '$stackKey::folder::${DateTime.now().millisecondsSinceEpoch}';

bool _isFolderSetKey(String key) => key.contains('::folder::');

bool _folderBelongsToStack(String folderKey, String stackKey) =>
    folderKey.startsWith('$stackKey::folder::');

String _folderName(ScreenshotSet folder) =>
    folder.folderName?.trim().isNotEmpty == true
    ? folder.folderName!.trim()
    : '새 그룹';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatSetTitle(DateTime date) {
  final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]}) ${date.hour.toString().padLeft(2, '0')}시 ${date.minute.toString().padLeft(2, '0')}분';
}

String _formatSetDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

String _formatTimeRange(List<ScreenshotItem> items) {
  final times = items
      .where((item) => item.dateTakenMillis > 0)
      .map((item) => item.date)
      .toList();
  if (times.isEmpty) return '촬영 시간 정보 없음';
  times.sort();
  String format(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  final start = times.first;
  final end = start.add(const Duration(hours: 1));
  return '${format(start)}-${format(end)}';
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.path,
    this.width,
    this.height,
    this.radius = 12,
    this.borderColor = Colors.transparent,
  });

  final String path;
  final double? width;
  final double? height;
  final double radius;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        foregroundDecoration: borderColor == Colors.transparent
            ? null
            : BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: borderColor),
              ),
        child: _buildThumbnail(path, width, height),
      ),
    );
  }
}

Widget _buildThumbnail(String path, double? width, double? height) {
  if (path.startsWith('mock://')) {
    final hash = path.codeUnits.fold<int>(0, (value, unit) => value + unit);
    final colors = [
      const Color(0xFFEFF6FF),
      const Color(0xFFF0FDF4),
      const Color(0xFFFFF7ED),
      const Color(0xFFFAF5FF),
      const Color(0xFFFDF2F8),
      const Color(0xFFF8FAFC),
    ];
    return Container(
      width: width,
      height: height,
      color: colors[hash % colors.length],
      child: Stack(
        children: [
          Positioned(
            left: 10,
            right: 10,
            top: 12,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 22,
            top: 34,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF111111).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 12,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
  if (kIsWeb || path.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF5F5F5),
    );
  }
  return buildLocalImage(
    path,
    width: width,
    height: height,
    fit: BoxFit.cover,
    fallback: Container(
      width: width,
      height: height,
      color: const Color(0xFFF5F5F5),
    ),
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 120),
      child: Center(child: CircularProgressIndicator(color: Color(0xFF111111))),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.hasPermission,
    required this.hiddenStacks,
    required this.excludedImages,
    required this.onOpenPhotoSettings,
    required this.onRestoreStack,
    required this.onRestoreImage,
    required this.onDeleteOriginalImage,
    required this.onDeleteOriginalImages,
  });

  final bool hasPermission;
  final List<StackItem> hiddenStacks;
  final List<ScreenshotItem> excludedImages;
  final Future<void> Function() onOpenPhotoSettings;
  final Future<void> Function(String stackKey) onRestoreStack;
  final Future<void> Function(String imageId) onRestoreImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<bool> Function(List<String> imageIds) onDeleteOriginalImages;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final List<StackItem> _hiddenStacks = [...widget.hiddenStacks];
  late final List<ScreenshotItem> _excludedImages = [...widget.excludedImages];
  late final bool _hasPermission = widget.hasPermission;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF424754),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsSection(
              title: '권한',
              children: [
                _PermissionStatusTile(
                  hasPermission: _hasPermission,
                  onOpenSettings: widget.onOpenPhotoSettings,
                ),
              ],
            ),
            _SettingsSection(
              title: '숨김 복구',
              children: [
                _RecoverySummaryTile(
                  icon: Icons.layers_clear_outlined,
                  title: '숨긴 Stack',
                  count: _hiddenStacks.length,
                  onTap: () => _showHiddenStacks(context),
                ),
                _RecoverySummaryTile(
                  icon: Icons.visibility_off_outlined,
                  title: '숨긴 이미지',
                  count: _excludedImages.length,
                  onTap: () => _showExcludedImages(context),
                ),
              ],
            ),
            _SettingsSection(
              title: '정보',
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: '앱 정보',
                  subtitle: 'Shotly 1.0.0 · 로컬 기반 스크린샷 정리 앱',
                  onTap: () => _showInfoDialog(context),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: '개인정보처리방침',
                  subtitle: '사진 원본은 클라우드에 업로드하지 않아요',
                  onTap: () => _showPolicyDialog(
                    context,
                    '개인정보처리방침',
                    'Shotly는 사진 원본을 서버에 업로드하지 않고, 기기 로컬에서 스크린샷 메타데이터와 정리 이력만 저장하는 방향으로 설계돼요. 정식 출시 전 정책 문서 링크를 연결할 예정이에요.',
                  ),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: '이용약관',
                  subtitle: '정식 출시 전 문서 링크 연결 예정',
                  onTap: () => _showPolicyDialog(
                    context,
                    '이용약관',
                    '정식 출시 전 이용약관 문서 링크를 연결할 예정이에요. 현재 MVP preview에서는 약관 원문을 앱 밖으로 보내지 않아요.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHiddenStacks(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HiddenStacksPage(
          stacks: _hiddenStacks,
          onRestoreStack: (stackKey) async {
            await widget.onRestoreStack(stackKey);
            if (mounted) {
              setState(
                () =>
                    _hiddenStacks.removeWhere((stack) => stack.key == stackKey),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _showExcludedImages(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HiddenImagesPage(
          images: _excludedImages,
          onRestoreImage: (imageId) async {
            await widget.onRestoreImage(imageId);
            if (mounted) {
              setState(
                () => _excludedImages.removeWhere((item) => item.id == imageId),
              );
            }
          },
          onDeleteOriginalImage: (imageId) async {
            final deleted = await widget.onDeleteOriginalImage(imageId);
            if (deleted && mounted) {
              setState(
                () => _excludedImages.removeWhere((item) => item.id == imageId),
              );
            }
            return deleted;
          },
          onDeleteAllOriginalImages: () async {
            final ids = _excludedImages.map((item) => item.id).toList();
            final deleted = await widget.onDeleteOriginalImages(ids);
            if (deleted && mounted) setState(() => _excludedImages.clear());
            return deleted ? ids.length : 0;
          },
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    _showShotlyInfoDialog(
      context: context,
      title: 'Shotly',
      body: 'Shotly 1.0.0\n기획자를 위한 로컬 기반 스크린샷 정리 앱',
    );
  }

  void _showPolicyDialog(BuildContext context, String title, String body) {
    _showShotlyInfoDialog(context: context, title: title, body: body);
  }
}

class HiddenStacksPage extends StatefulWidget {
  const HiddenStacksPage({
    super.key,
    required this.stacks,
    required this.onRestoreStack,
  });

  final List<StackItem> stacks;
  final Future<void> Function(String stackKey) onRestoreStack;

  @override
  State<HiddenStacksPage> createState() => _HiddenStacksPageState();
}

class _HiddenStacksPageState extends State<HiddenStacksPage> {
  late final List<StackItem> _stacks = [...widget.stacks];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _SettingsPageHeader(title: '숨긴 Stack'),
            const SizedBox(height: 20),
            if (_stacks.isEmpty)
              const _EmptyRecoveryMessage(message: '숨긴 Stack이 없어요')
            else
              ..._stacks.map(
                (stack) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  leading: const Icon(
                    Icons.layers_clear_rounded,
                    color: Color(0xFF424754),
                  ),
                  title: Text(
                    stack.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${stack.items.length} images',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF727785),
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () => _restore(stack.key),
                    child: const Text('복구'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(String stackKey) async {
    await widget.onRestoreStack(stackKey);
    if (mounted) {
      setState(() => _stacks.removeWhere((stack) => stack.key == stackKey));
    }
  }
}

class HiddenImagesPage extends StatefulWidget {
  const HiddenImagesPage({
    super.key,
    required this.images,
    required this.onRestoreImage,
    required this.onDeleteOriginalImage,
    required this.onDeleteAllOriginalImages,
  });

  final List<ScreenshotItem> images;
  final Future<void> Function(String imageId) onRestoreImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<int> Function() onDeleteAllOriginalImages;

  @override
  State<HiddenImagesPage> createState() => _HiddenImagesPageState();
}

class _HiddenImagesPageState extends State<HiddenImagesPage> {
  late final List<ScreenshotItem> _images = [...widget.images];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _SettingsPageHeader(
              title: '숨긴 이미지',
              action: _images.isEmpty
                  ? null
                  : TextButton.icon(
                      onPressed: _deleteAll,
                      icon: const Icon(
                        Icons.delete_rounded,
                        size: 18,
                        color: Color(0xFFB42318),
                      ),
                      label: const Text(
                        '전체 삭제',
                        style: TextStyle(color: Color(0xFFB42318)),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            if (_images.isEmpty)
              const _EmptyRecoveryMessage(message: '숨긴 이미지가 없어요')
            else
              ..._images.map(
                (item) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  leading: _Thumb(
                    path: item.thumbnailPath,
                    width: 44,
                    height: 64,
                    radius: 14,
                  ),
                  title: Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item.appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF727785),
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: () => _restore(item.id),
                        child: const Text('복구'),
                      ),
                      IconButton(
                        onPressed: () => _deleteOne(item.id),
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: Color(0xFFB42318),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(String imageId) async {
    await widget.onRestoreImage(imageId);
    if (mounted) {
      setState(() => _images.removeWhere((item) => item.id == imageId));
    }
  }

  Future<void> _deleteOne(String imageId) async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '원본 파일 삭제',
      body: '이 이미지를 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
      primaryLabel: '삭제',
      destructive: true,
    );
    if (confirmed == true &&
        await widget.onDeleteOriginalImage(imageId) &&
        mounted) {
      setState(() => _images.removeWhere((item) => item.id == imageId));
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '숨긴 이미지 전체 삭제',
      body: '숨긴 이미지 ${_images.length}장을 기기 앨범 원본에서도 모두 삭제할까요? 이 작업은 되돌릴 수 없어요.',
      primaryLabel: '전체 삭제',
      destructive: true,
    );
    if (confirmed != true) return;
    final deletedCount = await widget.onDeleteAllOriginalImages();
    if (mounted) {
      setState(() => _images.clear());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$deletedCount개 원본 파일을 삭제했어요.')));
    }
  }
}

class _SettingsPageHeader extends StatelessWidget {
  const _SettingsPageHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF424754)),
        ),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
        ?action,
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: const Color(0xFF727785)),
            ),
          ),
          Column(children: children),
        ],
      ),
    );
  }
}

class _PermissionStatusTile extends StatelessWidget {
  const _PermissionStatusTile({
    required this.hasPermission,
    required this.onOpenSettings,
  });

  final bool hasPermission;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: hasPermission
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded,
      title: '사진 접근 권한',
      subtitle: hasPermission ? '허용됨' : '허용 안 됨',
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF727785),
      ),
      onTap: onOpenSettings,
    );
  }
}

class _RecoverySummaryTile extends StatelessWidget {
  const _RecoverySummaryTile({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: icon,
      title: title,
      subtitle: count == 0 ? '복구할 항목 없음' : '$count개 항목 복구 가능',
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF727785),
      ),
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      minLeadingWidth: 24,
      horizontalTitleGap: 12,
      leading: Icon(icon, color: const Color(0xFF424754)),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: const Color(0xFF727785)),
      ),
      trailing: trailing,
    );
  }
}

class _EmptyRecoveryMessage extends StatelessWidget {
  const _EmptyRecoveryMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF727785)),
        ),
      ),
    );
  }
}

class _PermissionState extends StatelessWidget {
  const _PermissionState({required this.onRequest});

  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      title: '사진 접근 권한이 필요해요',
      body: '사진 원본은 클라우드에 업로드하지 않고, 이 기기 안에서만 읽어요.',
      buttonText: '권한 허용하기',
      onPressed: onRequest,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      title: '문제가 생겼어요',
      body: message,
      buttonText: '다시 시도',
      onPressed: onRetry,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessage(
      title: '스크린샷을 찾지 못했어요',
      body: 'Screenshots 폴더 또는 Screenshot 파일명을 기준으로 먼저 찾아요.',
    );
  }
}

class _NoResultState extends StatelessWidget {
  const _NoResultState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessage(
      title: '검색 결과가 없어요',
      body: '앱 이름이나 파일명을 다르게 입력해봐요.',
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.title,
    required this.body,
    this.buttonText,
    this.onPressed,
  });

  final String title;
  final String body;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Center(
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onPressed, child: Text(buttonText!)),
            ],
          ],
        ),
      ),
    );
  }
}
