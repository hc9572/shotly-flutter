import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'local_image.dart';
import 'local_store.dart';
import 'mock_data.dart';
import 'visual_features.dart';

part 'models_native.dart';
part 'home_widgets_calendar.dart';
part 'search.dart';
part 'stack_card.dart';
part 'stack_detail.dart';
part 'stack_smart_clean.dart';
part 'stack_folders.dart';
part 'stack_sections.dart';
part 'stack_selection_widgets.dart';
part 'image_viewer.dart';
part 'dialogs.dart';
part 'shotly_helpers.dart';
part 'settings.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Shotly runtime error: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };
  ErrorWidget.builder = (details) {
    FlutterError.presentError(details);
    return const _ShotlyRuntimeErrorView();
  };
  runApp(const ShotlyApp());
}

class _ShotlyRuntimeErrorView extends StatelessWidget {
  const _ShotlyRuntimeErrorView();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFF727785),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '화면을 불러오지 못했어요',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1A1C1C),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '뒤로 갔다가 다시 열어봐요. 오류 내용은 개발 로그에 남겨둘게요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF727785),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class ShotlyHomeScreen extends StatefulWidget {
  const ShotlyHomeScreen({super.key});

  @override
  State<ShotlyHomeScreen> createState() => _ShotlyHomeScreenState();
}

class _ShotlyHomeScreenState extends State<ShotlyHomeScreen>
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreLocalState());
    unawaited(_load(requestPermission: false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPermissionAfterResume());
    }
  }

  Future<void> _refreshPermissionAfterResume() async {
    final hasPermission = await ShotlyNative.hasPhotoPermission();
    if (!mounted || hasPermission == _hasPermission) return;
    await _load(requestPermission: false);
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

  Future<void> _load({bool requestPermission = true}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _hasPermission = requestPermission
          ? await ShotlyNative.requestPhotoPermission()
          : await ShotlyNative.hasPhotoPermission();
      if (_hasPermission) {
        final screenshots = await ShotlyNative.getScreenshots();
        screenshots.sort(
          (a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis),
        );
        _screenshots = screenshots;
        _visualFeatures.clear();
      } else {
        _screenshots = const [];
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
      title: '앱 추가',
      hintText: '앱 이름',
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
        return exists ? '이미 같은 이름의 앱이 있어요.' : null;
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
                title: '앱 추가',
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
