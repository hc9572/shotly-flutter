import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'local_store.dart';
import 'mock_data.dart';

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
  final Set<String> _hiddenStackKeys = {};
  final Set<String> _excludedImageIds = {};
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
        _screenshots = screenshots;
      }
    } on PlatformException catch (e) {
      _error = e.message ?? e.code;
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ScreenshotItem> get _filteredScreenshots {
    Iterable<ScreenshotItem> items = _screenshots.where((item) => !_excludedImageIds.contains(item.id));
    if (_query.trim().isNotEmpty) {
      items = items.where((item) => item.matches(_query.trim()));
    }
    return items.toList();
  }

  List<StackItem> get _stacks {
    final grouped = <String, List<ScreenshotItem>>{};
    for (final item in _filteredScreenshots) {
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
        .toList();
    for (final name in _manualStackNames) {
      final matchesQuery = _query.trim().isEmpty || name.toLowerCase().contains(_query.trim().toLowerCase());
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
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Stack 추가'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Stack 이름'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('추가')),
        ],
      ),
    );
    controller.dispose();
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

  Future<void> _showAddMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 16),
              _AddMenuTile(icon: Icons.layers_rounded, title: 'Stack 추가', onTap: () => Navigator.of(context).pop('stack')),
              _AddMenuTile(icon: Icons.photo_library_outlined, title: '이미지 추가', onTap: () => Navigator.of(context).pop('image')),
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
    final filteredScreenshots = _filteredScreenshots..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
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
                          onRequestPermission: _load,
                          onRestoreStack: _restoreStack,
                          onRestoreImage: _restoreImage,
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
                              else _CalendarTimelineView(items: filteredScreenshots),
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
                                      onRenameStack: _renameStack,
                                      onHideStack: _hideStack,
                                      onExcludeImage: _excludeImage,
                                      onMoveImage: _moveImage,
                                      onSaveSetMemo: _saveSetMemo,
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
            _BottomNavBar(
              calendarSelected: _isCalendarView,
              onStacksTap: () => setState(() => _isCalendarView = false),
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
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF424754)),
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
    required this.onRenameStack,
    required this.onHideStack,
    required this.onExcludeImage,
    required this.onMoveImage,
    required this.onSaveSetMemo,
  });

  final StackItem stack;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> setMemos;
  final Future<void> Function(String stackKey, String name) onRenameStack;
  final Future<void> Function(String stackKey) onHideStack;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => StackDetailScreen(
          stack: stack,
          allStackKeys: allStackKeys,
          stackNames: stackNames,
          setMemos: setMemos,
          onRenameStack: onRenameStack,
          onHideStack: onHideStack,
          onExcludeImage: onExcludeImage,
          onMoveImage: onMoveImage,
          onSaveSetMemo: onSaveSetMemo,
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
                itemBuilder: (context, index) => _Thumb(path: stack.items[index].thumbnailPath, width: 96, height: 160),
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
              _BottomNavItem(icon: Icons.layers_rounded, label: 'Stacks', selected: !calendarSelected, onTap: onStacksTap),
              const SizedBox(width: 34),
              _BottomNavItem(icon: Icons.calendar_today_outlined, label: 'Calendar', selected: calendarSelected, onTap: onCalendarTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
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
            Icon(icon, color: color, size: 24),
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
  const _CalendarTimelineView({required this.items});

  final List<ScreenshotItem> items;

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
              final item = grouped[date]![index];
              return InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: _Thumb(path: item.thumbnailPath),
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
    required this.onRenameStack,
    required this.onHideStack,
    required this.onExcludeImage,
    required this.onMoveImage,
    required this.onSaveSetMemo,
  });

  final StackItem stack;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> setMemos;
  final Future<void> Function(String stackKey, String name) onRenameStack;
  final Future<void> Function(String stackKey) onHideStack;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;

  @override
  State<StackDetailScreen> createState() => _StackDetailScreenState();
}

class _StackDetailScreenState extends State<StackDetailScreen> {
  bool _showSimilar = false;

  @override
  Widget build(BuildContext context) {
    final sets = _buildScreenshotSets(widget.stack.key, widget.stack.items, widget.setMemos);
    final similarGroups = _buildSimilarGroups(widget.stack.items);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF424754))),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF424754)),
                          onSelected: (value) async {
                            if (value == 'rename') await _renameStack(context);
                            if (value == 'hide') {
                              await widget.onHideStack(widget.stack.key);
                              if (context.mounted) Navigator.of(context).pop();
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'rename', child: Text('Stack 이름 수정')),
                            PopupMenuItem(value: 'hide', child: Text('Stack 숨기기')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(widget.stack.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: const Color(0xFF1A1C1C), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${widget.stack.items.length}개 이미지 · ${sets.length}개 Set', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF424754))),
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
                itemCount: _showSimilar ? (similarGroups.isEmpty ? 1 : similarGroups.length) : (sets.isEmpty ? 1 : sets.length),
                separatorBuilder: (context, index) => const SizedBox(height: 28),
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
                      onMoveImage: widget.onMoveImage,
                    );
                  }
                  if (sets.isEmpty) return const _EmptyStackDetail(message: '아직 이미지가 없는 Stack이에요');
                  return _SetSection(
                    set: sets[index],
                    allStackKeys: widget.allStackKeys,
                    stackNames: widget.stackNames,
                    onExcludeImage: widget.onExcludeImage,
                    onMoveImage: widget.onMoveImage,
                    onSaveMemo: widget.onSaveSetMemo,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameStack(BuildContext context) async {
    final controller = TextEditingController(text: widget.stack.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Stack 이름 수정'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('저장')),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    await widget.onRenameStack(widget.stack.key, name);
    if (mounted) setState(() {});
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

class _SetSection extends StatefulWidget {
  const _SetSection({
    required this.set,
    required this.allStackKeys,
    required this.stackNames,
    required this.onExcludeImage,
    required this.onMoveImage,
    required this.onSaveMemo,
  });

  final ScreenshotSet set;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveMemo;

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
      subtitle: _formatSetDate(widget.set.items.first.date),
      memoText: widget.set.memo.trim().isEmpty ? '여기에 메모를 추가하세요...' : widget.set.memo.trim(),
      items: widget.set.items,
      allStackKeys: widget.allStackKeys,
      stackNames: widget.stackNames,
      onExcludeImage: widget.onExcludeImage,
      onMoveImage: widget.onMoveImage,
      onEditMemo: () async {
        final memo = await _editMemo(context);
        if (memo != null) await widget.onSaveMemo(widget.set.key, memo.trim());
      },
    );
  }

  Future<String?> _editMemo(BuildContext context) async {
    _memoController.text = widget.set.memo;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Set 메모'),
        content: TextField(
          controller: _memoController,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(hintText: '예: 인스타그램 홈 피드 UI 리서치'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(_memoController.text), child: const Text('저장')),
        ],
      ),
    );
  }
}

class _ImageGridSection extends StatelessWidget {
  const _ImageGridSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.allStackKeys,
    this.memoText,
    required this.stackNames,
    required this.onExcludeImage,
    required this.onMoveImage,
    this.onEditMemo,
  });

  final String title;
  final String subtitle;
  final List<ScreenshotItem> items;
  final String? memoText;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final VoidCallback? onEditMemo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF1A1C1C))),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: const Color(0xFF727785))),
              if (memoText != null) ...[
                const SizedBox(height: 4),
                InkWell(
                  onTap: onEditMemo,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            memoText!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: memoText == '여기에 메모를 추가하세요...' ? const Color(0xFF727785) : const Color(0xFF424754),
                                  fontStyle: memoText == '여기에 메모를 추가하세요...' ? FontStyle.italic : FontStyle.normal,
                                ),
                          ),
                        ),
                        if (onEditMemo != null) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF727785)),
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
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 9 / 16,
          ),
          itemBuilder: (context, index) => _ActionableThumb(
            item: items[index],
            allStackKeys: allStackKeys,
            stackNames: stackNames,
            onExcludeImage: onExcludeImage,
            onMoveImage: onMoveImage,
          ),
        ),
      ],
    );
  }
}

class _ActionableThumb extends StatelessWidget {
  const _ActionableThumb({required this.item, required this.allStackKeys, required this.stackNames, required this.onExcludeImage, required this.onMoveImage});

  final ScreenshotItem item;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () => _showActions(context),
      borderRadius: BorderRadius.circular(16),
      child: _Thumb(path: item.thumbnailPath, radius: 8, borderColor: Colors.transparent),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 12),
              _AddMenuTile(icon: Icons.visibility_off_outlined, title: '이미지 숨기기', onTap: () => Navigator.of(context).pop('exclude')),
              _AddMenuTile(icon: Icons.drive_file_move_outline, title: '다른 Stack으로 이동', onTap: () => Navigator.of(context).pop('move')),
            ],
          ),
        ),
      ),
    );
    if (action == 'exclude') await onExcludeImage(item.id);
    if (action == 'move' && context.mounted) await _pickTargetStack(context);
  }

  Future<void> _pickTargetStack(BuildContext context) async {
    final target = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: Colors.white,
        title: const Text('이동할 Stack'),
        children: allStackKeys.map((key) => SimpleDialogOption(onPressed: () => Navigator.of(context).pop(key), child: Text(stackNames[key] ?? key))).toList(),
      ),
    );
    if (target != null) await onMoveImage(item.id, target);
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

List<ScreenshotSet> _buildScreenshotSets(String stackKey, List<ScreenshotItem> items, Map<String, String> setMemos) {
  if (items.isEmpty) return const [];
  final sorted = [...items]..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
  final sets = <List<ScreenshotItem>>[];
  var current = <ScreenshotItem>[];
  var firstTime = 0;
  const oneHourMillis = 60 * 60 * 1000;

  for (final item in sorted) {
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
      sets.add(current);
      current = [item];
      firstTime = item.dateTakenMillis;
    }
  }
  if (current.isNotEmpty) sets.add(current);

  return sets.map((setItems) {
    final key = _buildSetKey(stackKey, setItems);
    return ScreenshotSet(key: key, title: _formatSetTitle(setItems.first.date), timeRange: _formatTimeRange(setItems), items: setItems, memo: setMemos[key] ?? '');
  }).toList();
}


String _buildSetKey(String stackKey, List<ScreenshotItem> items) {
  final first = items.firstOrNull;
  return '$stackKey|${first?.dateTakenMillis ?? 0}|${first?.id ?? ''}';
}

List<List<ScreenshotItem>> _buildSimilarGroups(List<ScreenshotItem> items) {
  final sorted = [...items]..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
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
  const _Thumb({required this.path, this.width, this.height, this.radius = 8, this.borderColor = const Color(0xFFC2C6D6)});

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
    required this.onRequestPermission,
    required this.onRestoreStack,
    required this.onRestoreImage,
  });

  final bool hasPermission;
  final List<StackItem> hiddenStacks;
  final List<ScreenshotItem> excludedImages;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function(String stackKey) onRestoreStack;
  final Future<void> Function(String imageId) onRestoreImage;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final List<StackItem> _hiddenStacks = [...widget.hiddenStacks];
  late final List<ScreenshotItem> _excludedImages = [...widget.excludedImages];
  late bool _hasPermission = widget.hasPermission;

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
                  onRequest: () async {
                    await widget.onRequestPermission();
                    if (mounted) setState(() => _hasPermission = true);
                  },
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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 18),
              Text('숨긴 Stack', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              if (_hiddenStacks.isEmpty)
                _EmptyRecoveryMessage(message: '숨긴 Stack이 없어요')
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _hiddenStacks.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (context, index) {
                      final stack = _hiddenStacks[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(stack.name, style: Theme.of(context).textTheme.bodyLarge),
                        subtitle: Text('${stack.items.length} images', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF727785))),
                        trailing: TextButton(onPressed: () => _restoreStack(index), child: const Text('복구')),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showExcludedImages(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 18),
              Text('숨긴 이미지', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              if (_excludedImages.isEmpty)
                _EmptyRecoveryMessage(message: '숨긴 이미지가 없어요')
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _excludedImages.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (context, index) {
                      final item = _excludedImages[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _Thumb(path: item.thumbnailPath, width: 44, height: 64, radius: 8),
                        title: Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                        subtitle: Text(item.appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF727785))),
                        trailing: TextButton(onPressed: () => _restoreImage(index), child: const Text('복구')),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restoreStack(int index) async {
    final stack = _hiddenStacks[index];
    await widget.onRestoreStack(stack.key);
    if (mounted) setState(() => _hiddenStacks.removeAt(index));
  }

  Future<void> _restoreImage(int index) async {
    final item = _excludedImages[index];
    await widget.onRestoreImage(item.id);
    if (mounted) setState(() => _excludedImages.removeAt(index));
  }

  void _showInfoDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Shotly',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.layers_rounded, size: 32),
      children: const [Text('기획자를 위한 로컬 기반 스크린샷 정리 앱')],
    );
  }

  void _showPolicyDialog(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title),
        content: Text(body),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
      ),
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _PermissionStatusTile extends StatelessWidget {
  const _PermissionStatusTile({required this.hasPermission, required this.onRequest});

  final bool hasPermission;
  final Future<void> Function() onRequest;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: hasPermission ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
      title: '사진 접근 권한',
      subtitle: hasPermission ? '허용됨 · 사진 원본은 기기 밖으로 나가지 않아요' : '권한 필요 · 스크린샷 정리를 위해 허용해주세요',
      trailing: hasPermission ? null : TextButton(onPressed: onRequest, child: const Text('허용')),
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
