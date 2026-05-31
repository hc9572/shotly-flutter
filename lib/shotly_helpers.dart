part of 'main.dart';

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
    if (groupKeys.isEmpty) {
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

  final dateGroups = <String, List<ScreenshotItem>>{};
  for (final item in autoItems) {
    final key = _buildDateSetKey(stackKey, item.date);
    dateGroups.putIfAbsent(key, () => <ScreenshotItem>[]).add(item);
  }

  final keyedSets = <MapEntry<String, List<ScreenshotItem>>>[
    ...dateGroups.entries,
    ...manualGroups.entries,
  ];

  final sets = keyedSets.map((entry) {
    final setItems = [...entry.value]
      ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
    final key = entry.key;
    final isFolder = _isFolderSetKey(key);
    final migratedFolderName = isFolder ? setMemos[key]?.trim() : null;
    final folderName = isFolder
        ? (folderNames[key]?.trim().isNotEmpty == true
              ? folderNames[key]!.trim()
              : (migratedFolderName?.isNotEmpty == true
                    ? migratedFolderName
                    : st('새 폴더', 'New folder')))
        : null;
    return ScreenshotSet(
      key: key,
      title:
          folderName ??
          (setItems.isEmpty ? 'Set' : _formatSetTitle(setItems.first.date)),
      timeRange: '',
      items: setItems,
      memo: isFolder ? '' : setMemos[key] ?? _legacyMemoFor(setItems, setMemos),
      folderName: folderName,
    );
  }).toList();
  sets.sort((a, b) => _setSortTime(b).compareTo(_setSortTime(a)));
  return sets;
}

int _setSortTime(ScreenshotSet set) =>
    set.items.isEmpty ? 0 : set.items.first.dateTakenMillis;

String _buildDateSetKey(String stackKey, DateTime date) =>
    '$stackKey|date|${_formatSetDate(date)}';

String _buildSetKey(String stackKey, List<ScreenshotItem> items) {
  final first = items.firstOrNull;
  return '$stackKey|${first?.dateTakenMillis ?? 0}|${first?.id ?? ''}';
}

String _legacyMemoFor(
  List<ScreenshotItem> items,
  Map<String, String> setMemos,
) {
  for (final item in items) {
    final legacyKey = _buildSetKey('', [item]);
    final matchingMemo = setMemos.entries
        .where(
          (entry) =>
              entry.key.endsWith(legacyKey) && entry.value.trim().isNotEmpty,
        )
        .map((entry) => entry.value.trim())
        .firstOrNull;
    if (matchingMemo != null) return matchingMemo;
  }
  return '';
}

String _buildFolderKey(String stackKey) =>
    '$stackKey::folder::${DateTime.now().millisecondsSinceEpoch}';

bool _isFolderSetKey(String key) => key.contains('::folder::');

bool _folderBelongsToStack(String folderKey, String stackKey) =>
    folderKey.startsWith('$stackKey::folder::');

String _folderName(ScreenshotSet folder) =>
    folder.folderName?.trim().isNotEmpty == true
    ? folder.folderName!.trim()
    : st('새 폴더', 'New folder');

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatSetTitle(DateTime date) => stDate(date);

String _formatSetDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
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
