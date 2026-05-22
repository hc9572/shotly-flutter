import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          headlineLarge: TextStyle(fontSize: 28, height: 1.21, fontWeight: FontWeight.w700, letterSpacing: -0.56),
          headlineMedium: TextStyle(fontSize: 22, height: 1.27, fontWeight: FontWeight.w600, letterSpacing: -0.22),
          titleLarge: TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: 18, height: 1.3, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w400),
        ).apply(
          bodyColor: const Color(0xFF1A1C1C),
          displayColor: const Color(0xFF1A1C1C),
          fontFamily: 'Pretendard',
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
  const StackItem({required this.name, required this.items});

  final String name;
  final List<ScreenshotItem> items;
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
}

class ShotlyHomeScreen extends StatefulWidget {
  const ShotlyHomeScreen({super.key});

  @override
  State<ShotlyHomeScreen> createState() => _ShotlyHomeScreenState();
}

class _ShotlyHomeScreenState extends State<ShotlyHomeScreen> {
  final _searchController = TextEditingController();
  List<ScreenshotItem> _screenshots = const [];
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
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    Iterable<ScreenshotItem> items = _screenshots;
    if (_query.trim().isNotEmpty) {
      items = items.where((item) => item.matches(_query.trim()));
    }
    return items.toList();
  }

  List<StackItem> get _stacks {
    final grouped = <String, List<ScreenshotItem>>{};
    for (final item in _filteredScreenshots) {
      grouped.putIfAbsent(item.appName.isEmpty ? 'Unknown' : item.appName, () => []).add(item);
    }
    final stacks = grouped.entries
        .map((entry) => StackItem(name: entry.key, items: entry.value..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis))))
        .toList();
    switch (_sortMode) {
      case StackSortMode.latest:
        stacks.sort((a, b) => b.items.first.dateTakenMillis.compareTo(a.items.first.dateTakenMillis));
      case StackSortMode.name:
        stacks.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case StackSortMode.mostImages:
        stacks.sort((a, b) => b.items.length.compareTo(a.items.length));
      case StackSortMode.fewestImages:
        stacks.sort((a, b) => a.items.length.compareTo(b.items.length));
    }
    return stacks;
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
                    delegate: _ShotlyTopBarDelegate(onRefresh: _load),
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
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF727785), fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0.05),
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
                                    child: _StackCard(stack: stack),
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
  const _ShotlyTopBarDelegate({required this.onRefresh});

  final VoidCallback onRefresh;

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
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF424754)),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, color: Color(0xFF111111)),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ShotlyTopBarDelegate oldDelegate) => false;
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '$screenshotCount개 스크린샷 · $stackCount개 Stack',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF727785), fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0.05),
          ),
        ),
        SizedBox(
          width: 112,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topRight,
            children: [
              TextButton.icon(
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
                  textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ],
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
                    Expanded(child: Text(item.$2, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF111111), fontSize: 14, fontWeight: FontWeight.w500))),
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
  const _StackCard({required this.stack});

  final StackItem stack;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StackDetailScreen(stack: stack))),
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
                              fontSize: 20,
                              height: 25 / 20,
                              color: const Color(0xFF1A1C1C),
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stack.items.length} images',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF424754),
                              fontSize: 13,
                              height: 16 / 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.05,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontSize: 11,
                    height: 14 / 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.33,
                  ),
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
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${grouped[date]!.length} images',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF424754), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.05),
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

class StackDetailScreen extends StatelessWidget {
  const StackDetailScreen({super.key, required this.stack});

  final StackItem stack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded)),
                    const SizedBox(height: 8),
                    Text(stack.name, style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text('${stack.items.length}개 이미지', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280))),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid.builder(
                itemCount: stack.items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.56),
                itemBuilder: (context, index) => _Thumb(path: stack.items[index].thumbnailPath),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, this.width, this.height});

  final String path;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC2C6D6)),
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
