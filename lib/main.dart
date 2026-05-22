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
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF111111),
          brightness: Brightness.light,
          primary: const Color(0xFF111111),
          surface: const Color(0xFFFFFFFF),
          surfaceContainerHighest: const Color(0xFFF5F5F5),
          outline: const Color(0xFFE5E7EB),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 36, height: 1.14, fontWeight: FontWeight.w700, letterSpacing: -1.0),
          headlineMedium: TextStyle(fontSize: 28, height: 1.18, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge: TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: 18, height: 1.3, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w400),
        ).apply(
          bodyColor: const Color(0xFF111111),
          displayColor: const Color(0xFF111111),
          fontFamily: defaultTargetPlatform == TargetPlatform.iOS ? '.SF Pro Text' : 'sans-serif',
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
  bool _showCalendar = false;
  DateTime? _selectedDate;
  String _query = '';
  String? _error;

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
    if (_selectedDate != null) {
      items = items.where((item) => _sameDay(item.date, _selectedDate!));
    }
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
    stacks.sort((a, b) => b.items.first.dateTakenMillis.compareTo(a.items.first.dateTakenMillis));
    return stacks;
  }

  Map<DateTime, int> get _dateCounts {
    final counts = <DateTime, int>{};
    for (final item in _screenshots) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      counts[date] = (counts[date] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final stacks = _stacks;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: const Color(0xFF111111),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(onRefresh: _load),
                      const SizedBox(height: 22),
                      if (_isLoading) const _LoadingState()
                      else if (!_hasPermission) _PermissionState(onRequest: _load)
                      else if (_error != null) _ErrorState(message: _error!, onRetry: _load)
                      else ...[
                        _SummaryRow(screenshotCount: _filteredScreenshots.length, stackCount: stacks.length),
                        const SizedBox(height: 14),
                        _SearchField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: 12),
                        _DateFilterRow(
                          selectedDate: _selectedDate,
                          showCalendar: _showCalendar,
                          onToggleCalendar: () => setState(() => _showCalendar = !_showCalendar),
                          onReset: () => setState(() => _selectedDate = null),
                        ),
                        if (_showCalendar) ...[
                          const SizedBox(height: 8),
                          _CalendarPanel(
                            dateCounts: _dateCounts,
                            selectedDate: _selectedDate,
                            onSelect: (date) => setState(() {
                              _selectedDate = _sameNullableDay(_selectedDate, date) ? null : date;
                              _showCalendar = false;
                            }),
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          const SizedBox(height: 12),
                          Text(
                            _query.isEmpty
                                ? (_selectedDate == null ? '전체 Stack' : '${_formatDate(_selectedDate!)} Stack')
                                : '검색 결과: ${_filteredScreenshots.length}개 이미지 · ${stacks.length}개 Stack',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 16),
                          if (_screenshots.isEmpty) const _EmptyState()
                          else if (stacks.isEmpty) const _NoResultState()
                          else ...stacks.map((stack) => Padding(
                                padding: const EdgeInsets.only(bottom: 22),
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shotly', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text(
                '로컬 스크린샷을 Stack으로 정리해요.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF111111),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            minimumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
          ),
          onPressed: () {},
          child: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.screenshotCount, required this.stackCount});

  final int screenshotCount;
  final int stackCount;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$screenshotCount개 스크린샷 · $stackCount개 Stack',
      style: Theme.of(context).textTheme.titleMedium,
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
      decoration: InputDecoration(
        hintText: '앱 이름, 파일명, 경로 검색',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF111111), width: 1),
        ),
      ),
    );
  }
}

class _DateFilterRow extends StatelessWidget {
  const _DateFilterRow({
    required this.selectedDate,
    required this.showCalendar,
    required this.onToggleCalendar,
    required this.onReset,
  });

  final DateTime? selectedDate;
  final bool showCalendar;
  final VoidCallback onToggleCalendar;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            selectedDate == null ? '전체 날짜' : _formatDate(selectedDate!),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
          ),
        ),
        if (selectedDate != null) TextButton(onPressed: onReset, child: const Text('초기화')),
        OutlinedButton.icon(
          onPressed: onToggleCalendar,
          icon: Icon(showCalendar ? Icons.close_rounded : Icons.calendar_month_outlined, size: 18),
          label: Text(showCalendar ? '닫기' : '달력'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF111111),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}

class _CalendarPanel extends StatefulWidget {
  const _CalendarPanel({required this.dateCounts, required this.selectedDate, required this.onSelect});

  final Map<DateTime, int> dateCounts;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelect;

  @override
  State<_CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<_CalendarPanel> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    final initial = widget.selectedDate ?? (widget.dateCounts.keys.toList()..sort((a, b) => b.compareTo(a))).firstOrNull ?? DateTime.now();
    _month = DateTime(initial.year, initial.month);
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = firstDay.weekday - 1;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(leading, null),
      ...List.generate(daysInMonth, (i) => DateTime(_month.year, _month.month, i + 1)),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${_month.year}년 ${_month.month}월', style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(Icons.chevron_left_rounded)),
              TextButton(onPressed: () => setState(() => _month = DateTime(DateTime.now().year, DateTime.now().month)), child: const Text('오늘')),
              IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)), icon: const Icon(Icons.chevron_right_rounded)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: ['월', '화', '수', '목', '금', '토', '일']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(day, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          ...cells.slices(7).map((week) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: week
                      .map((date) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: _CalendarCell(
                                date: date,
                                count: date == null ? 0 : widget.dateCounts[DateTime(date.year, date.month, date.day)] ?? 0,
                                selected: date != null && _sameNullableDay(widget.selectedDate, date),
                                onTap: date == null ? null : () => widget.onSelect(date),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              )),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({required this.date, required this.count, required this.selected, required this.onTap});

  final DateTime? date;
  final int count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasItems = count > 0;
    return InkWell(
      onTap: hasItems ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111111) : (hasItems ? const Color(0xFFF5F5F5) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.all(6),
        child: date == null
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${date!.day}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: selected ? Colors.white : const Color(0xFF111111),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (hasItems)
                    Text(
                      '$count장',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: selected ? Colors.white70 : const Color(0xFF6B7280), fontSize: 11),
                    ),
                ],
              ),
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stack.name, style: Theme.of(context).textTheme.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${stack.items.length}개 이미지', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stack.items.take(8).length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _Thumb(path: stack.items[index].thumbnailPath, width: 78, height: 132),
              ),
            ),
          ],
        ),
      ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
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

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
bool _sameNullableDay(DateTime? a, DateTime b) => a != null && _sameDay(a, b);
String _formatDate(DateTime date) => '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

extension _ListSlices<T> on List<T> {
  Iterable<List<T>> slices(int size) sync* {
    for (var i = 0; i < length; i += size) {
      yield sublist(i, i + size > length ? length : i + size);
    }
  }
}
