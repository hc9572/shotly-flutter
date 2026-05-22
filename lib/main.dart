import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0058BE),
          brightness: Brightness.light,
          primary: const Color(0xFF0058BE),
          surface: const Color(0xFFFAFAFA),
          surfaceContainerHighest: const Color(0xFFE2E2E2),
          outline: const Color(0xFF727785),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w700, letterSpacing: -0.56),
          headlineMedium: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w600, letterSpacing: -0.22),
          headlineSmall: TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w600, letterSpacing: -0.22),
          titleMedium: TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500),
          labelLarge: TextStyle(fontSize: 14, height: 18 / 14, fontWeight: FontWeight.w600, letterSpacing: 0.14),
          labelMedium: TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w500, letterSpacing: 0.33),
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
    if (n.contains('karrot') || n.contains('carrot')) return ['당근', '당근마켓', 'Karrot'];
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

class StackItem {
  const StackItem({required this.key, required this.name, required this.items});

  final String key;
  final String name;
  final List<ScreenshotItem> items;
}

class ScreenshotSet {
  const ScreenshotSet({required this.key, required this.title, required this.timeRange, required this.items, this.memo = ''});

  final String key;
  final String title;
  final String timeRange;
  final List<ScreenshotItem> items;
  final String memo;
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
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickImage');
    if (result == null) return null;
    return ScreenshotItem.fromMap(result);
  }

  static Future<String?> getImagePreview(String imageId, String fallbackPath) async {
    if (kIsWeb) return fallbackPath;
    final result = await _channel.invokeMethod<String>('getImagePreview', {'imageId': imageId});
    return result?.isEmpty == true ? fallbackPath : result ?? fallbackPath;
  }

  static Future<bool> deleteOriginalImage(String imageId) async {
    if (kIsWeb) return false;
    final result = await _channel.invokeMethod<bool>('deleteOriginalImage', {'imageId': imageId});
    return result ?? false;
  }

  static Future<bool> deleteOriginalImages(List<String> imageIds) async {
    if (kIsWeb || imageIds.isEmpty) return false;
    final result = await _channel.invokeMethod<bool>('deleteOriginalImages', {'imageIds': imageIds});
    return result ?? false;
  }

  static Future<bool> shareImages(List<String> imageIds) async {
    if (kIsWeb || imageIds.isEmpty) return false;
    final result = await _channel.invokeMethod<bool>('shareImages', {'imageIds': imageIds});
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
  final Map<String, String> _setAssignments = {};
  final Map<String, VisualFeature> _visualFeatures = {};
  final Set<String> _hiddenStackKeys = {};
  final Set<String> _excludedImageIds = {};
  final Set<String> _selectedCalendarImageIds = <String>{};
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _isCalendarView = false;
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
      _setAssignments
        ..clear()
        ..addAll(state.setAssignments);
      _hiddenStackKeys
        ..clear()
        ..addAll(state.hiddenStackKeys);
      _excludedImageIds
        ..clear()
        ..addAll(state.excludedImageIds);
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
        screenshots.sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
        final features = await extractVisualFeatures({for (final item in screenshots) item.id: item.thumbnailPath});
        _screenshots = screenshots;
        _visualFeatures
          ..clear()
          ..addAll(features);
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
    Iterable<ScreenshotItem> items = _screenshots.where((item) => !_excludedImageIds.contains(item.id));
    if (_query.trim().isNotEmpty) {
      items = items.where((item) => item.matches(_query.trim()));
    }
    return items.toList();
  }

  List<ScreenshotItem> get _filteredScreenshots => _calendarScreenshots;

  List<StackItem> get _stacks {
    final q = _query.trim();
    final grouped = <String, List<ScreenshotItem>>{};
    for (final item in _screenshots.where((item) => !_excludedImageIds.contains(item.id))) {
      final stackKey = _stackKeyFor(item);
      if (_hiddenStackKeys.contains(stackKey)) continue;
      grouped.putIfAbsent(stackKey, () => []).add(item);
    }
    final stacks = grouped.entries
        .map((entry) => StackItem(
              key: entry.key,
              name: _stackNames[entry.key] ?? entry.key,
              items: entry.value..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis)),
            ))
        .where((stack) => q.isEmpty || _stackMatchesQuery(stack, q))
        .toList();
    for (final name in _manualStackNames) {
      final matchesQuery = q.isEmpty || _textMatches(name, q) || _textMatches(_stackNames[name] ?? '', q);
      if (matchesQuery && !grouped.containsKey(name) && !_hiddenStackKeys.contains(name)) {
        stacks.add(StackItem(key: name, name: _stackNames[name] ?? name, items: const []));
      }
    }
    switch (_sortMode) {
      case StackSortMode.latest:
        stacks.sort((a, b) => (b.items.isEmpty ? 0 : b.items.first.dateTakenMillis).compareTo(a.items.isEmpty ? 0 : a.items.first.dateTakenMillis));
      case StackSortMode.name:
        stacks.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case StackSortMode.mostImages:
        stacks.sort((a, b) => b.items.length.compareTo(a.items.length));
      case StackSortMode.fewestImages:
        stacks.sort((a, b) => a.items.length.compareTo(b.items.length));
    }
    return stacks;
  }

  List<StackItem> get _hiddenStacks {
    final grouped = <String, List<ScreenshotItem>>{};
    for (final item in _screenshots.where((item) => !_excludedImageIds.contains(item.id))) {
      final stackKey = _stackKeyFor(item);
      if (_hiddenStackKeys.contains(stackKey)) grouped.putIfAbsent(stackKey, () => []).add(item);
    }
    final stacks = grouped.entries
        .map((entry) => StackItem(
              key: entry.key,
              name: _stackNames[entry.key] ?? entry.key,
              items: entry.value..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis)),
            ))
        .toList();
    for (final name in _manualStackNames) {
      if (_hiddenStackKeys.contains(name) && !grouped.containsKey(name)) {
        stacks.add(StackItem(key: name, name: _stackNames[name] ?? name, items: const []));
      }
    }
    stacks.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return stacks;
  }

  List<ScreenshotItem> get _excludedImages {
    return _screenshots.where((item) => _excludedImageIds.contains(item.id)).toList()
      ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
  }

  String _stackKeyFor(ScreenshotItem item) => _imageAssignments[item.id] ?? (item.appName.isEmpty ? 'Unknown' : item.appName);


  Future<void> _showCreateStackDialog() async {
    final name = await _showShotlyTextDialog(context: context, title: 'Stack 추가', hintText: 'Stack 이름', primaryLabel: '추가');
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
      if (image == null) {
        if (mounted) _showSnack('웹 미리보기에서는 앨범 열기를 지원하지 않아요. Android 앱에서 동작해.');
        return;
      }
      if (_screenshots.any((item) => item.id == image.id || item.thumbnailPath == image.thumbnailPath)) {
        if (mounted) _showSnack('이미 추가된 이미지예요. 중복 추가하지 않았어.');
        return;
      }
      setState(() {
        _screenshots = [image, ..._screenshots]..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
      });
    } on PlatformException catch (e) {
      if (mounted) _showSnack(e.message ?? e.code);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPhotoSettings() async {
    try {
      final opened = await ShotlyNative.openPhotoSettings();
      if (!opened && mounted) _showSnack('웹 미리보기에서는 시스템 설정을 열 수 없어요.');
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
        _screenshots = _screenshots.where((item) => item.id != imageId).toList();
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
        _screenshots = _screenshots.where((item) => !ids.contains(item.id)).toList();
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

  void _toggleCalendarSelection(String imageId) {
    setState(() {
      if (!_selectedCalendarImageIds.add(imageId)) _selectedCalendarImageIds.remove(imageId);
    });
  }

  Future<void> _openCalendarImageViewer(List<ScreenshotItem> items, int index) async {
    final deletedId = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => ImageViewerScreen(
        items: items,
        initialIndex: index,
        onDeleteOriginalImage: _deleteOriginalImage,
      ),
    ));
    if (deletedId != null && mounted) setState(() => _selectedCalendarImageIds.remove(deletedId));
  }

  Future<void> _shareSelectedCalendarImages() async {
    await ShotlyNative.shareImages(_selectedCalendarImageIds.toList());
  }

  Future<void> _hideSelectedCalendarImages() async {
    final selected = _selectedCalendarImageIds.toList();
    for (final id in selected) {
      await _excludeImage(id);
    }
    if (mounted) setState(_selectedCalendarImageIds.clear);
  }

  Future<void> _moveSelectedCalendarImages() async {
    final target = await _showShotlyActionSheet<String>(
      context,
      title: '이동할 Stack',
      items: _stacks.map((stack) => _ShotlyActionItem(value: stack.key, icon: Icons.layers_rounded, title: stack.name)).toList(),
    );
    if (target == null) return;
    final selected = _selectedCalendarImageIds.toList();
    for (final id in selected) {
      await _moveImage(id, target);
    }
    if (mounted) setState(_selectedCalendarImageIds.clear);
  }

  Future<void> _deleteSelectedCalendarImages() async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '원본 파일 삭제',
      body: '선택한 ${_selectedCalendarImageIds.length}장을 Shotly뿐 아니라 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
      primaryLabel: '삭제',
      destructive: true,
    );
    if (confirmed != true) return;
    final selected = _selectedCalendarImageIds.toList();
    if (await _deleteOriginalImages(selected) && mounted) setState(_selectedCalendarImageIds.clear);
  }

  Future<void> _restoreImage(String imageId) async {
    setState(() => _excludedImageIds.remove(imageId));
    await _localStore.restoreImage(imageId);
  }

  Future<void> _moveImage(String imageId, String stackKey) async {
    setState(() => _imageAssignments[imageId] = stackKey);
    if (!_manualStackNames.contains(stackKey) && !_stacks.any((stack) => stack.key == stackKey)) {
      _manualStackNames.add(stackKey);
    }
    await _localStore.moveImage(imageId, stackKey);
  }

  Future<void> _saveSetMemo(String setKey, String memo) async {
    setState(() => _setMemos[setKey] = memo);
    await _localStore.saveSetMemo(setKey, memo);
  }

  Future<void> _assignImageToSet(String imageId, String setKey) async {
    setState(() => _setAssignments[imageId] = setKey);
    await _localStore.assignImageToSet(imageId, setKey);
  }

  bool _stackMatchesQuery(StackItem stack, String query) {
    if (_textMatches(stack.name, query) || _textMatches(stack.key, query)) return true;
    if (stack.items.any((item) => item.matches(query))) return true;
    final sets = _buildScreenshotSets(stack.key, stack.items, _setMemos, _setAssignments);
    return sets.any((set) => _textMatches(set.memo, query) || _textMatches(set.timeRange, query) || _textMatches(_formatSetDate(set.items.first.date), query));
  }

  bool _textMatches(String text, String query) => text.toLowerCase().contains(query.toLowerCase());

  Future<void> _showAddMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 16),
              _AddMenuTile(icon: Icons.layers_rounded, title: 'Stack 추가', onTap: () => Navigator.of(context).pop('stack')),
              _AddMenuTile(icon: Icons.photo_library_rounded, title: '이미지 추가', onTap: () => Navigator.of(context).pop('image')),
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
    final filteredScreenshots = (_isCalendarView ? _calendarScreenshots : _filteredScreenshots)..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
    final stacks = _stacks;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
                      onAdd: _showAddMenu,
                      onSettings: () => Navigator.of(context).push(MaterialPageRoute(
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
                      )),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 118),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isLoading) const _LoadingState()
                          else if (!_hasPermission) _PermissionState(onRequest: _load)
                          else if (_error != null) _ErrorState(message: _error!, onRetry: _load)
                          else ...[
                            _SearchField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _query = value),
                            ),
                            const SizedBox(height: 16),
                            if (_isCalendarView) ...[
                              Text(
                                '${filteredScreenshots.length}개 스크린샷 · 최신순',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF727785)),
                              ),
                              const SizedBox(height: 18),
                              if (_screenshots.isEmpty) const _EmptyState()
                              else if (filteredScreenshots.isEmpty) const _NoResultState()
                              else _CalendarTimelineView(
                            items: filteredScreenshots,
                            selectedIds: _selectedCalendarImageIds,
                            onToggleSelection: _toggleCalendarSelection,
                            onOpenImage: _openCalendarImageViewer,
                          ),
                            ] else ...[
                              _SummarySortRow(
                                screenshotCount: filteredScreenshots.length,
                                stackCount: stacks.length,
                                sortMode: _sortMode,
                                showSortMenu: _showSortMenu,
                                onToggleSort: () => setState(() => _showSortMenu = !_showSortMenu),
                                onSelectSort: (mode) => setState(() {
                                  _sortMode = mode;
                                  _showSortMenu = false;
                                }),
                              ),
                              const SizedBox(height: 26),
                              if (_screenshots.isEmpty) const _EmptyState()
                              else if (stacks.isEmpty) const _NoResultState()
                              else ...stacks.map((stack) => Padding(
                                    padding: const EdgeInsets.only(bottom: 26),
                                    child: _StackCard(
                                      stack: stack,
                                      allStackKeys: _stacks.map((item) => item.key).toList(),
                                      stackNames: _stackNames,
                                      setMemos: _setMemos,
                                      setAssignments: _setAssignments,
                                      visualFeatures: _visualFeatures,
                                      onRenameStack: _renameStack,
                                      onHideStack: _hideStack,
                                      onExcludeImage: _excludeImage,
                                      onDeleteOriginalImage: _deleteOriginalImage,
                                      onDeleteOriginalImages: _deleteOriginalImages,
                                      onMoveImage: _moveImage,
                                      onSaveSetMemo: _saveSetMemo,
                                      onAssignImageToSet: _assignImageToSet,
                                    ),
                                  )),
                            ],
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
                  onSelect: (mode) => setState(() {
                    _sortMode = mode;
                    _showSortMenu = false;
                  }),
                ),
              ),
            if (_isCalendarView && _selectedCalendarImageIds.isNotEmpty)
              Positioned(
                left: 20,
                right: 20,
                bottom: 96,
                child: _SelectionActionBar(
                  count: _selectedCalendarImageIds.length,
                  onCancel: () => setState(_selectedCalendarImageIds.clear),
                  onShare: _shareSelectedCalendarImages,
                  onDelete: _deleteSelectedCalendarImages,
                  onMove: _moveSelectedCalendarImages,
                  onHide: _hideSelectedCalendarImages,
                ),
              ),
            _BottomNavBar(
              calendarSelected: _isCalendarView,
              onStacksTap: () => setState(() {
                _isCalendarView = false;
                _selectedCalendarImageIds.clear();
              }),
              onCalendarTap: () => setState(() => _isCalendarView = true),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShotlyTopBarDelegate extends SliverPersistentHeaderDelegate {
  const _ShotlyTopBarDelegate({required this.onAdd, required this.onSettings});

  final VoidCallback onAdd;
  final VoidCallback onSettings;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 64,
      color: const Color(0xFFFAFAFA).withValues(alpha: 0.96),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Shotly',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: const Color(0xFF1A1C1C)),
            ),
          ),
          IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF424754)),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, color: Color(0xFF111111)),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ShotlyTopBarDelegate oldDelegate) => onAdd != oldDelegate.onAdd || onSettings != oldDelegate.onSettings;
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
    return SizedBox(
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            right: 116,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$screenshotCount개 스크린샷 · $stackCount개 Stack',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF727785)),
              ),
            ),
          ),
          Positioned(
            top: -1,
            right: 0,
            child: TextButton.icon(
              onPressed: onToggleSort,
              icon: const Icon(Icons.sort_rounded, size: 18),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sort'),
                  const SizedBox(width: 2),
                  Icon(showSortMenu ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18),
                ],
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF111111),
                textStyle: Theme.of(context).textTheme.labelLarge,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 22),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 24, offset: Offset(0, 10))],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(child: Text(item.$2, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF111111)))),
                    if (isSelected) const Icon(Icons.check_rounded, color: Color(0xFF0058BE), size: 18),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: '앱 이름, 파일명, 날짜 검색',
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF727785)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF727785)),
        prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 40),
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        border: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC2C6D6))),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC2C6D6))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0058BE), width: 1.2)),
      ),
    );
  }
}

class _StackCard extends StatelessWidget {
  const _StackCard({
    required this.stack,
    required this.allStackKeys,
    required this.stackNames,
    required this.setMemos,
    required this.setAssignments,
    required this.visualFeatures,
    required this.onRenameStack,
    required this.onHideStack,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onDeleteOriginalImages,
    required this.onMoveImage,
    required this.onSaveSetMemo,
    required this.onAssignImageToSet,
  });

  final StackItem stack;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> setMemos;
  final Map<String, String> setAssignments;
  final Map<String, VisualFeature> visualFeatures;
  final Future<void> Function(String stackKey, String name) onRenameStack;
  final Future<void> Function(String stackKey) onHideStack;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<bool> Function(List<String> imageIds) onDeleteOriginalImages;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => StackDetailScreen(
          stack: stack,
          allStackKeys: allStackKeys,
          stackNames: stackNames,
          setMemos: setMemos,
          setAssignments: setAssignments,
          visualFeatures: visualFeatures,
          onRenameStack: onRenameStack,
          onHideStack: onHideStack,
          onExcludeImage: onExcludeImage,
          onDeleteOriginalImage: onDeleteOriginalImage,
          onDeleteOriginalImages: onDeleteOriginalImages,
          onMoveImage: onMoveImage,
          onSaveSetMemo: onSaveSetMemo,
          onAssignImageToSet: onAssignImageToSet,
        ),
      )),
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
                      Text(
                        stack.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              height: 24 / 18,
                              color: const Color(0xFF1A1C1C),
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF727785)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stack.items.take(8).length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _Thumb(path: stack.items[index].thumbnailPath, width: 96, height: 160, radius: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.calendarSelected, required this.onStacksTap, required this.onCalendarTap});

  final bool calendarSelected;
  final VoidCallback onStacksTap;
  final VoidCallback onCalendarTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x4DC2C6D6)),
            boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 12))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BottomNavItem(icon: Icons.layers_outlined, selectedIcon: Icons.layers_rounded, label: 'Stacks', selected: !calendarSelected, onTap: onStacksTap),
              const SizedBox(width: 34),
              _BottomNavItem(icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_month_rounded, label: 'Calendar', selected: calendarSelected, onTap: onCalendarTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({required this.icon, required this.selectedIcon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF0058BE) : const Color(0xFF424754);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarTimelineView extends StatelessWidget {
  const _CalendarTimelineView({required this.items, required this.selectedIds, required this.onToggleSelection, required this.onOpenImage});

  final List<ScreenshotItem> items;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelection;
  final Future<void> Function(List<ScreenshotItem> items, int index) onOpenImage;

  bool get _isSelecting => selectedIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final grouped = <DateTime, List<ScreenshotItem>>{};
    for (final item in items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      grouped.putIfAbsent(date, () => []).add(item);
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final date in dates) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: Row(
              children: [
                Text(
                  _formatTimelineDate(date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1A1C1C),
                        fontSize: 18,
                        height: 24 / 18,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${grouped[date]!.length} images',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: const Color(0xFF424754)),
                ),
              ],
            ),
          ),
          GridView.builder(
            itemCount: grouped[date]!.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.6,
            ),
            itemBuilder: (context, index) {
              final dateItems = grouped[date]!;
              final item = dateItems[index];
              return _SelectableThumb(
                item: item,
                selected: selectedIds.contains(item.id),
                selecting: _isSelecting,
                onTap: () => _isSelecting ? onToggleSelection(item.id) : onOpenImage(items, items.indexWhere((candidate) => candidate.id == item.id)),
                onLongPress: () => onToggleSelection(item.id),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class StackDetailScreen extends StatefulWidget {
  const StackDetailScreen({
    super.key,
    required this.stack,
    required this.allStackKeys,
    required this.stackNames,
    required this.setMemos,
    required this.setAssignments,
    required this.visualFeatures,
    required this.onRenameStack,
    required this.onHideStack,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onDeleteOriginalImages,
    required this.onMoveImage,
    required this.onSaveSetMemo,
    required this.onAssignImageToSet,
  });

  final StackItem stack;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> setMemos;
  final Map<String, String> setAssignments;
  final Map<String, VisualFeature> visualFeatures;
  final Future<void> Function(String stackKey, String name) onRenameStack;
  final Future<void> Function(String stackKey) onHideStack;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<bool> Function(List<String> imageIds) onDeleteOriginalImages;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;

  @override
  State<StackDetailScreen> createState() => _StackDetailScreenState();
}

class _StackDetailScreenState extends State<StackDetailScreen> {
  bool _showSimilar = false;
  final Set<String> _deletedImageIds = <String>{};
  final Set<String> _selectedImageIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.stack.items.where((item) => !_deletedImageIds.contains(item.id)).toList();
    final sets = _buildScreenshotSets(widget.stack.key, visibleItems, widget.setMemos, widget.setAssignments);
    final similarGroups = _buildSimilarGroups(visibleItems, widget.visualFeatures);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(-12, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF424754)),
                          ),
                          const Spacer(),
                          Transform.translate(
                            offset: const Offset(24, 0),
                            child: IconButton(
                              onPressed: () => _showStackActions(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                              icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF424754)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(widget.stack.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: const Color(0xFF1A1C1C), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${visibleItems.length}개 이미지 · ${sets.length}개 Set', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF424754))),
                    const SizedBox(height: 18),
                    _DetailModeSwitch(
                      showSimilar: _showSimilar,
                      onChanged: (value) => setState(() => _showSimilar = value),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList.separated(
                itemCount: _showSimilar ? (similarGroups.isEmpty ? 1 : similarGroups.length) : (_groupSetsByDate(sets).isEmpty ? 1 : _groupSetsByDate(sets).length),
                separatorBuilder: (context, index) => const SizedBox(height: 32),
                itemBuilder: (context, index) {
                  if (_showSimilar) {
                    if (similarGroups.isEmpty) return const _EmptyStackDetail(message: '유사 화면 후보가 없어요');
                    final group = similarGroups[index];
                    return _ImageGridSection(
                      title: _formatTimeRange(group),
                      subtitle: _formatSetDate(group.first.date),
                      items: group,
                      allStackKeys: widget.allStackKeys,
                      stackNames: widget.stackNames,
                      onExcludeImage: widget.onExcludeImage,
                      onDeleteOriginalImage: _deleteOriginalImage,
                      onMoveImage: widget.onMoveImage,
                      selectedIds: _selectedImageIds,
                      onToggleSelection: _toggleSelection,
                      showLocalActionBar: false,
                    );
                  }
                  final dateGroups = _groupSetsByDate(sets);
                  if (dateGroups.isEmpty) return const _EmptyStackDetail(message: '아직 이미지가 없는 Stack이에요');
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
                    showLocalActionBar: false,
                    onSaveMemo: widget.onSaveSetMemo,
                    onAssignImageToSet: widget.onAssignImageToSet,
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
                  count: _selectedImageIds.length,
                  onCancel: () => setState(_selectedImageIds.clear),
                  onShare: _shareSelected,
                  onDelete: () => _deleteSelected(context),
                  onMove: () => _moveSelected(context),
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

  Future<void> _moveSelected(BuildContext context) async {
    final target = await _showShotlyActionSheet<String>(
      context,
      title: '이동할 Stack',
      items: widget.allStackKeys.map((key) => _ShotlyActionItem(value: key, icon: Icons.layers_rounded, title: widget.stackNames[key] ?? key)).toList(),
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
      body: '선택한 ${_selectedImageIds.length}장을 Shotly뿐 아니라 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
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
    final name = await _showShotlyTextDialog(context: context, title: 'Stack 이름 수정', initialValue: widget.stack.name, hintText: 'Stack 이름', primaryLabel: '저장');
    if (name == null) return;
    await widget.onRenameStack(widget.stack.key, name);
    if (mounted) setState(() {});
  }

  Future<void> _showStackActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 16),
              _AddMenuTile(icon: Icons.edit_rounded, title: 'Stack 이름 수정', onTap: () => Navigator.of(context).pop('rename')),
              _AddMenuTile(icon: Icons.visibility_off_rounded, title: 'Stack 숨기기', onTap: () => Navigator.of(context).pop('hide')),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'rename') await _renameStack(context);
    if (action == 'hide') {
      await widget.onHideStack(widget.stack.key);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<bool> _deleteOriginalImage(String imageId) async {
    final deleted = await widget.onDeleteOriginalImage(imageId);
    if (deleted && mounted) {
      setState(() => _deletedImageIds.add(imageId));
    }
    return deleted;
  }
}

class _DetailModeSwitch extends StatelessWidget {
  const _DetailModeSwitch({required this.showSimilar, required this.onChanged});

  final bool showSimilar;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ModeChip(label: '시간대별', selected: !showSimilar, onTap: () => onChanged(false)),
          const SizedBox(width: 8),
          _ModeChip(label: '유사 화면', selected: showSimilar, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2170E4) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: selected ? Colors.white : const Color(0xFF424754)),
        ),
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
    required this.showLocalActionBar,
    required this.onSaveMemo,
    required this.onAssignImageToSet,
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
  final bool showLocalActionBar;
  final Future<void> Function(String setKey, String memo) onSaveMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            dateLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF424754),
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
          ),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < sets.length; index++) ...[
          _SetSection(
            set: sets[index],
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
            mergeTarget: index < sets.length - 1 ? sets[index + 1] : null,
          ),
          if (index != sets.length - 1) const SizedBox(height: 28),
        ],
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
    this.mergeTarget,
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
  final ScreenshotSet? mergeTarget;

  @override
  State<_SetSection> createState() => _SetSectionState();
}

class _SetSectionState extends State<_SetSection> {
  late final TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: widget.set.memo);
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ImageGridSection(
      title: widget.set.timeRange,
      memoText: widget.set.memo.trim().isEmpty ? '메모 추가' : widget.set.memo.trim(),
      items: widget.set.items,
      allStackKeys: widget.allStackKeys,
      stackNames: widget.stackNames,
      onExcludeImage: widget.onExcludeImage,
      onDeleteOriginalImage: widget.onDeleteOriginalImage,
      onMoveImage: widget.onMoveImage,
      selectedIds: widget.selectedIds,
      onToggleSelection: widget.onToggleSelection,
      showLocalActionBar: widget.showLocalActionBar,
      onSetAction: () => _showSetActions(context),
      onEditMemo: () async {
        final memo = await _editMemo(context);
        if (memo != null) await widget.onSaveMemo(widget.set.key, memo.trim());
      },
    );
  }

  Future<void> _showSetActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 12),
              if (widget.mergeTarget != null) _AddMenuTile(icon: Icons.call_merge_rounded, title: '아래 Set과 합치기', onTap: () => Navigator.of(context).pop('merge')),
              if (widget.set.items.length > 1) _AddMenuTile(icon: Icons.call_split_rounded, title: '이미지 하나를 새 Set으로 분리', onTap: () => Navigator.of(context).pop('split')),
            ],
          ),
        ),
      ),
    );
    if (action == 'merge' && widget.mergeTarget != null) {
      for (final item in widget.mergeTarget!.items) {
        await widget.onAssignImageToSet(item.id, widget.set.key);
      }
    }
    if (action == 'split' && context.mounted) await _splitOneImage(context);
  }

  Future<void> _splitOneImage(BuildContext context) async {
    final image = await showModalBottomSheet<ScreenshotItem>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 16),
              Text('새 Set으로 분리할 이미지', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.set.items.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = widget.set.items[index];
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(item),
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(width: 72, child: _Thumb(path: item.thumbnailPath, radius: 18, borderColor: Colors.transparent)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (image != null) await widget.onAssignImageToSet(image.id, '${widget.set.key}::split::${image.id}');
  }

  Future<String?> _editMemo(BuildContext context) async {
    final value = await _showShotlyTextDialog(
      context: context,
      title: 'Set 메모',
      initialValue: widget.set.memo,
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
    this.subtitle,
    required this.items,
    required this.allStackKeys,
    this.memoText,
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
  final String? subtitle;
  final List<ScreenshotItem> items;
  final String? memoText;
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
  List<ScreenshotItem> get _visibleItems => widget.items.where((item) => !_locallyHiddenIds.contains(item.id)).toList();

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.subtitle != null) ...[
                Text(widget.subtitle!, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: const Color(0xFF727785))),
                const SizedBox(height: 2),
              ],
              Row(
                children: [
                  Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF1A1C1C)))),
                  if (widget.onSetAction != null && !_isSelecting)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.more_horiz_rounded, size: 18, color: Color(0xFF727785)),
                      onPressed: widget.onSetAction,
                    ),
                ],
              ),
              if (widget.memoText != null) ...[
                const SizedBox(height: 4),
                InkWell(
                  onTap: _isSelecting ? null : widget.onEditMemo,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.memoText!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: widget.memoText == '메모 추가' ? const Color(0xFF727785) : const Color(0xFF424754),
                                fontStyle: widget.memoText == '메모 추가' ? FontStyle.italic : FontStyle.normal,
                              ),
                        ),
                        if (widget.onEditMemo != null && !_isSelecting) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF727785)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3 / 4,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _SelectableThumb(
              item: item,
              selected: _effectiveSelectedIds.contains(item.id),
              selecting: _isSelecting,
              onTap: () => _isSelecting ? _toggleSelection(item.id) : _openImageViewer(context, items, index),
              onLongPress: () => _toggleSelection(item.id),
            );
          },
        ),
        if (_isSelecting && widget.showLocalActionBar) ...[
          const SizedBox(height: 12),
          _SelectionActionBar(
            count: _effectiveSelectedIds.length,
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

  Future<void> _openImageViewer(BuildContext context, List<ScreenshotItem> items, int index) async {
    final deletedId = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => ImageViewerScreen(
        items: items,
        initialIndex: index,
        onDeleteOriginalImage: widget.onDeleteOriginalImage,
      ),
    ));
    if (deletedId != null && mounted) setState(() => _locallyHiddenIds.add(deletedId));
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
      items: widget.allStackKeys.map((key) => _ShotlyActionItem(value: key, icon: Icons.layers_rounded, title: widget.stackNames[key] ?? key)).toList(),
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
      body: '선택한 ${_effectiveSelectedIds.length}장을 Shotly뿐 아니라 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
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
  const _SelectableThumb({required this.item, required this.selected, required this.selecting, required this.onTap, required this.onLongPress});

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
          Positioned.fill(child: _Thumb(path: item.thumbnailPath, radius: 18, borderColor: selected ? const Color(0xFF2170E4) : Colors.transparent)),
          if (selecting)
            Positioned(
              right: 7,
              top: 7,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF2170E4) : Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: selected ? const Color(0xFF2170E4) : const Color(0xFFD5D8DF)),
                ),
                child: selected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({required this.count, required this.onCancel, required this.onShare, required this.onDelete, required this.onMove, required this.onHide});

  final int count;
  final VoidCallback onCancel;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onMove;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Text('$count개 선택', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF1A1C1C))),
          const Spacer(),
          _SelectionActionButton(icon: Icons.share_rounded, label: '공유', onTap: onShare),
          _SelectionActionButton(icon: Icons.delete_rounded, label: '삭제', onTap: onDelete, destructive: true),
          _SelectionActionButton(icon: Icons.drive_file_move_rounded, label: '이동', onTap: onMove),
          _SelectionActionButton(icon: Icons.visibility_off_outlined, label: '숨기기', onTap: onHide),
          IconButton(onPressed: onCancel, icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF727785))),
        ],
      ),
    );
  }
}

class _SelectionActionButton extends StatelessWidget {
  const _SelectionActionButton({required this.icon, required this.label, required this.onTap, this.destructive = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFB42318) : const Color(0xFF424754);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
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
        child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF727785))),
      ),
    );
  }
}

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key, required this.items, required this.initialIndex, required this.onDeleteOriginalImage});

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
  final Map<String, Future<String?>> _previewFutures = <String, Future<String?>>{};

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
    return _previewFutures.putIfAbsent(item.id, () => ShotlyNative.getImagePreview(item.id, item.thumbnailPath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
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
                      return Center(
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4,
                          child: _buildViewerImage(imagePath),
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
                        top: 8,
                        left: 8,
                        child: _ViewerCircleButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            _ViewerCircleButton(
                              icon: Icons.share_rounded,
                              onTap: () => ShotlyNative.shareImages([_currentItem.id]),
                            ),
                            const SizedBox(width: 10),
                            _ViewerCircleButton(
                              icon: Icons.delete_rounded,
                              destructive: true,
                              onTap: () async {
                                final confirmed = await _showShotlyConfirmDialog(
                                  context: context,
                                  title: '원본 파일 삭제',
                                  body: '이 이미지를 기기 앨범 원본에서도 삭제할까요? 삭제 후 Shotly 목록에서도 사라져요.',
                                  primaryLabel: '삭제',
                                  destructive: true,
                                );
                                if (confirmed == true) {
                                  final deleted = await widget.onDeleteOriginalImage(_currentItem.id);
                                  if (deleted && context.mounted) Navigator.of(context).pop(_currentItem.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: _ViewerInfo(item: _currentItem, index: _currentIndex, total: widget.items.length),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerCircleButton extends StatelessWidget {
  const _ViewerCircleButton({required this.icon, required this.onTap, this.destructive = false});

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
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.16))),
          child: Icon(icon, color: destructive ? const Color(0xFFFFD0CC) : Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _ViewerInfo extends StatelessWidget {
  const _ViewerInfo({required this.item, required this.index, required this.total});

  final ScreenshotItem item;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.42), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text('${index + 1}/$total · ${item.appName} · ${_formatSetDate(item.date)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

Widget _buildViewerImage(String path) {
  if (path.startsWith('mock://') || kIsWeb || path.isEmpty) {
    return _buildThumbnail(path, null, null);
  }
  return Image.network(
    Uri.file(path).toString(),
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => _buildThumbnail(path, null, null),
  );
}

class _ShotlyActionItem<T> {
  const _ShotlyActionItem({required this.value, required this.icon, required this.title});

  final T value;
  final IconData icon;
  final String title;
}

Future<T?> _showShotlyActionSheet<T>(BuildContext context, {String? title, required List<_ShotlyActionItem<T>> items}) {
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: const Color(0xFF727785))),
                ),
              ],
              ...items.map((item) => _ShotlyMenuRow(icon: item.icon, title: item.title, onTap: () => Navigator.of(context).pop(item.value))),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<String?> _showShotlyTextDialog({required BuildContext context, required String title, String initialValue = '', required String hintText, required String primaryLabel, int minLines = 1, int maxLines = 1}) async {
  final controller = TextEditingController(text: initialValue);
  final result = await showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 12))],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFF1A1C1C))),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: minLines,
              maxLines: maxLines,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF727785)),
                filled: true,
                fillColor: const Color(0xFFF7F7F8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1A1C1C), width: 1)),
              ),
              onSubmitted: maxLines == 1 ? (value) => Navigator.of(context).pop(value) : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF111111), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                  onPressed: () => Navigator.of(context).pop(controller.text),
                  child: Text(primaryLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  controller.dispose();
  return result;
}

Future<void> _showShotlyInfoDialog({required BuildContext context, required String title, required String body}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 12))]),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF424754))),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF111111), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
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

Future<bool?> _showShotlyConfirmDialog({required BuildContext context, required String title, required String body, required String primaryLabel, bool destructive = false}) {
  final primaryColor = destructive ? const Color(0xFFB42318) : const Color(0xFF111111);
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 12))]),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF424754))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
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
  const _ShotlyMenuRow({required this.icon, required this.title, required this.onTap});

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
            Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF1A1C1C)))),
          ],
        ),
      ),
    );
  }
}

class _AddMenuTile extends StatelessWidget {
  const _AddMenuTile({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF111111)),
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
  return grouped.entries.map((entry) => _SetDateGroup(dateLabel: entry.key, sets: entry.value)).toList();
}

List<ScreenshotSet> _buildScreenshotSets(String stackKey, List<ScreenshotItem> items, Map<String, String> setMemos, [Map<String, String> setAssignments = const {}]) {
  if (items.isEmpty) return const [];
  final sorted = [...items]..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
  final manualGroups = <String, List<ScreenshotItem>>{};
  final autoItems = <ScreenshotItem>[];
  for (final item in sorted) {
    final manualKey = setAssignments[item.id];
    if (manualKey == null) {
      autoItems.add(item);
    } else {
      manualGroups.putIfAbsent(manualKey, () => []).add(item);
    }
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
    final withinOneHour = firstTime > 0 && item.dateTakenMillis > 0 && (firstTime - item.dateTakenMillis).abs() <= oneHourMillis;
    final sameDay = _isSameDay(DateTime.fromMillisecondsSinceEpoch(firstTime), item.date);
    if (withinOneHour && sameDay) {
      current.add(item);
    } else {
      keyedSets.add(MapEntry(null, current));
      current = [item];
      firstTime = item.dateTakenMillis;
    }
  }
  if (current.isNotEmpty) keyedSets.add(MapEntry(null, current));
  keyedSets.addAll(manualGroups.entries.map((entry) => MapEntry(entry.key, entry.value)));

  final sets = keyedSets.map((entry) {
    final setItems = [...entry.value]..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
    final key = entry.key ?? _buildSetKey(stackKey, setItems);
    return ScreenshotSet(key: key, title: _formatSetTitle(setItems.first.date), timeRange: _formatTimeRange(setItems), items: setItems, memo: setMemos[key] ?? '');
  }).toList();
  sets.sort((a, b) => b.items.first.dateTakenMillis.compareTo(a.items.first.dateTakenMillis));
  return sets;
}


String _buildSetKey(String stackKey, List<ScreenshotItem> items) {
  final first = items.firstOrNull;
  return '$stackKey|${first?.dateTakenMillis ?? 0}|${first?.id ?? ''}';
}

List<List<ScreenshotItem>> _buildSimilarGroups(List<ScreenshotItem> items, Map<String, VisualFeature> features) {
  final sorted = [...items]..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
  if (sorted.length < 2) return const [];

  const threshold = 0.86;
  final edges = <String, Set<String>>{for (final item in sorted) item.id: <String>{}};
  var featurePairCount = 0;

  for (var i = 0; i < sorted.length; i++) {
    for (var j = i + 1; j < sorted.length; j++) {
      final a = sorted[i];
      final b = sorted[j];
      final aFeature = features[a.id];
      final bFeature = features[b.id];
      if (aFeature == null || bFeature == null) continue;
      featurePairCount++;
      final score = visualSimilarity(aFeature, bFeature);
      if (score >= threshold) {
        edges[a.id]!.add(b.id);
        edges[b.id]!.add(a.id);
      }
    }
  }

  final groups = _connectedSimilarGroups(sorted, edges);
  if (groups.isNotEmpty) return groups;

  // Web/mock fallback until MediaPipe/native features are available there.
  if (featurePairCount == 0) return _filenameSimilarGroups(sorted);
  return const [];
}

List<List<ScreenshotItem>> _connectedSimilarGroups(List<ScreenshotItem> sorted, Map<String, Set<String>> edges) {
  final byId = {for (final item in sorted) item.id: item};
  final visited = <String>{};
  final groups = <List<ScreenshotItem>>[];

  for (final item in sorted) {
    if (visited.contains(item.id)) continue;
    final queue = <String>[item.id];
    final component = <ScreenshotItem>[];
    visited.add(item.id);

    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      final node = byId[id];
      if (node != null) component.add(node);
      for (final next in edges[id] ?? const <String>{}) {
        if (visited.add(next)) queue.add(next);
      }
    }

    if (component.length >= 2) {
      component.sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
      groups.add(component);
    }
  }
  groups.sort((a, b) => b.length.compareTo(a.length));
  return groups;
}

List<List<ScreenshotItem>> _filenameSimilarGroups(List<ScreenshotItem> sorted) {
  final groups = <List<ScreenshotItem>>[];
  final used = <String>{};
  for (final item in sorted) {
    if (used.contains(item.id)) continue;
    final baseToken = _similarToken(item.displayName);
    final group = sorted.where((other) => !used.contains(other.id) && _similarToken(other.displayName) == baseToken).toList();
    if (group.length >= 2) {
      groups.add(group);
      used.addAll(group.map((item) => item.id));
    }
  }
  if (groups.isEmpty && sorted.length >= 2) {
    return _buildScreenshotSets('similar', sorted, const {}).map((set) => set.items.where((item) => item.id.isNotEmpty).toList()).where((group) => group.length >= 2).toList();
  }
  return groups;
}

String _similarToken(String value) {
  final normalized = value.toLowerCase().replaceAll(RegExp(r'\d+'), '').replaceAll(RegExp(r'[_\-\s]+'), ' ').trim();
  return normalized.isEmpty ? value.toLowerCase() : normalized;
}

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String _formatSetTitle(DateTime date) {
  final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]}) ${date.hour.toString().padLeft(2, '0')}시 ${date.minute.toString().padLeft(2, '0')}분';
}

String _formatSetDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

String _formatTimeRange(List<ScreenshotItem> items) {
  final times = items.where((item) => item.dateTakenMillis > 0).map((item) => item.date).toList();
  if (times.isEmpty) return '촬영 시간 정보 없음';
  times.sort();
  String format(DateTime date) => '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  final start = times.first;
  final end = start.add(const Duration(hours: 1));
  return '${format(start)}-${format(end)}';
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, this.width, this.height, this.radius = 16, this.borderColor = const Color(0xFFC2C6D6)});

  final String path;
  final double? width;
  final double? height;
  final double radius;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildThumbnail(path, width, height),
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
            child: Container(height: 12, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(99))),
          ),
          Positioned(
            left: 10,
            right: 22,
            top: 34,
            child: Container(height: 8, decoration: BoxDecoration(color: const Color(0xFF111111).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99))),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 12,
            child: Container(height: 42, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }
  if (kIsWeb || path.isEmpty) {
    return Container(width: width, height: height, color: const Color(0xFFF5F5F5));
  }
  return Image.network(
    Uri.file(path).toString(),
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => Container(width: width, height: height, color: const Color(0xFFF5F5F5)),
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
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF424754))),
                Expanded(child: Text('Settings', style: Theme.of(context).textTheme.headlineMedium)),
              ],
            ),
            const SizedBox(height: 20),
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
                  onTap: () => _showPolicyDialog(context, '개인정보처리방침', 'Shotly는 사진 원본을 서버에 업로드하지 않고, 기기 로컬에서 스크린샷 메타데이터와 정리 이력만 저장하는 방향으로 설계돼요. 정식 출시 전 정책 문서 링크를 연결할 예정이에요.'),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: '이용약관',
                  subtitle: '정식 출시 전 문서 링크 연결 예정',
                  onTap: () => _showPolicyDialog(context, '이용약관', '정식 출시 전 이용약관 문서 링크를 연결할 예정이에요. 현재 MVP preview에서는 약관 원문을 앱 밖으로 보내지 않아요.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHiddenStacks(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HiddenStacksPage(
        stacks: _hiddenStacks,
        onRestoreStack: (stackKey) async {
          await widget.onRestoreStack(stackKey);
          if (mounted) setState(() => _hiddenStacks.removeWhere((stack) => stack.key == stackKey));
        },
      ),
    ));
  }

  Future<void> _showExcludedImages(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HiddenImagesPage(
        images: _excludedImages,
        onRestoreImage: (imageId) async {
          await widget.onRestoreImage(imageId);
          if (mounted) setState(() => _excludedImages.removeWhere((item) => item.id == imageId));
        },
        onDeleteOriginalImage: (imageId) async {
          final deleted = await widget.onDeleteOriginalImage(imageId);
          if (deleted && mounted) setState(() => _excludedImages.removeWhere((item) => item.id == imageId));
          return deleted;
        },
        onDeleteAllOriginalImages: () async {
          final ids = _excludedImages.map((item) => item.id).toList();
          final deleted = await widget.onDeleteOriginalImages(ids);
          if (deleted && mounted) setState(() => _excludedImages.clear());
          return deleted ? ids.length : 0;
        },
      ),
    ));
  }

  void _showInfoDialog(BuildContext context) {
    _showShotlyInfoDialog(
      context: context,
      title: 'Shotly',
      body: 'Shotly 1.0.0\n기획자를 위한 로컬 기반 스크린샷 정리 앱',
    );
  }

  void _showPolicyDialog(BuildContext context, String title, String body) {
    _showShotlyInfoDialog(
      context: context,
      title: title,
      body: body,
    );
  }
}

class HiddenStacksPage extends StatefulWidget {
  const HiddenStacksPage({super.key, required this.stacks, required this.onRestoreStack});

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
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _SettingsPageHeader(title: '숨긴 Stack'),
            const SizedBox(height: 20),
            if (_stacks.isEmpty)
              const _EmptyRecoveryMessage(message: '숨긴 Stack이 없어요')
            else
              ..._stacks.map((stack) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: const Icon(Icons.layers_clear_rounded, color: Color(0xFF424754)),
                    title: Text(stack.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('${stack.items.length} images', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF727785))),
                    trailing: TextButton(onPressed: () => _restore(stack.key), child: const Text('복구')),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(String stackKey) async {
    await widget.onRestoreStack(stackKey);
    if (mounted) setState(() => _stacks.removeWhere((stack) => stack.key == stackKey));
  }
}

class HiddenImagesPage extends StatefulWidget {
  const HiddenImagesPage({super.key, required this.images, required this.onRestoreImage, required this.onDeleteOriginalImage, required this.onDeleteAllOriginalImages});

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
      backgroundColor: const Color(0xFFFAFAFA),
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
                      icon: const Icon(Icons.delete_rounded, size: 18, color: Color(0xFFB42318)),
                      label: const Text('전체 삭제', style: TextStyle(color: Color(0xFFB42318))),
                    ),
            ),
            const SizedBox(height: 20),
            if (_images.isEmpty)
              const _EmptyRecoveryMessage(message: '숨긴 이미지가 없어요')
            else
              ..._images.map((item) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: _Thumb(path: item.thumbnailPath, width: 44, height: 64, radius: 14),
                    title: Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(item.appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF727785))),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        TextButton(onPressed: () => _restore(item.id), child: const Text('복구')),
                        IconButton(onPressed: () => _deleteOne(item.id), icon: const Icon(Icons.delete_rounded, color: Color(0xFFB42318))),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(String imageId) async {
    await widget.onRestoreImage(imageId);
    if (mounted) setState(() => _images.removeWhere((item) => item.id == imageId));
  }

  Future<void> _deleteOne(String imageId) async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '원본 파일 삭제',
      body: '이 이미지를 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
      primaryLabel: '삭제',
      destructive: true,
    );
    if (confirmed == true && await widget.onDeleteOriginalImage(imageId) && mounted) {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$deletedCount개 원본 파일을 삭제했어요.')));
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
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF424754))),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
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
            child: Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: const Color(0xFF727785))),
          ),
          Column(children: children),
        ],
      ),
    );
  }
}

class _PermissionStatusTile extends StatelessWidget {
  const _PermissionStatusTile({required this.hasPermission, required this.onOpenSettings});

  final bool hasPermission;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: hasPermission ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
      title: '사진 접근 권한',
      subtitle: hasPermission ? '허용됨' : '허용 안 됨',
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF727785)),
      onTap: onOpenSettings,
    );
  }
}

class _RecoverySummaryTile extends StatelessWidget {
  const _RecoverySummaryTile({required this.icon, required this.title, required this.count, required this.onTap});

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
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF727785)),
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.trailing, this.onTap});

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
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF727785))),
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
      child: Center(child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF727785)))),
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
    return _CenteredMessage(title: '문제가 생겼어요', body: message, buttonText: '다시 시도', onPressed: onRetry);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessage(title: '스크린샷을 찾지 못했어요', body: 'Screenshots 폴더 또는 Screenshot 파일명을 기준으로 먼저 찾아요.');
  }
}

class _NoResultState extends StatelessWidget {
  const _NoResultState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessage(title: '검색 결과가 없어요', body: '앱 이름이나 파일명을 다르게 입력해봐요.');
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.title, required this.body, this.buttonText, this.onPressed});

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
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)), textAlign: TextAlign.center),
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

String _formatTimelineDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  if (target == today) return '오늘';
  if (target == today.subtract(const Duration(days: 1))) return '어제';
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}
