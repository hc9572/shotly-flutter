part of 'main.dart';

class _ShotlyTopBarDelegate extends SliverPersistentHeaderDelegate {
  const _ShotlyTopBarDelegate({
    required this.searchController,
    required this.onSearchTap,
    required this.selectedDateRange,
    required this.onPickDate,
    required this.onClearDate,
    required this.favoriteCount,
    required this.onFavorites,
    required this.onAdd,
    required this.onSettings,
  });

  final TextEditingController searchController;
  final VoidCallback onSearchTap;
  final DateTimeRange? selectedDateRange;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final int favoriteCount;
  final VoidCallback onFavorites;
  final VoidCallback onAdd;
  final VoidCallback onSettings;

  @override
  double get minExtent => selectedDateRange == null ? 70 : 104;

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
              selectedDateRange: selectedDateRange,
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
                _TopIconButton(
                  icon: Icons.star_border_rounded,
                  onTap: onFavorites,
                ),
                const SizedBox(width: 2),
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
      selectedDateRange != oldDelegate.selectedDateRange ||
      onPickDate != oldDelegate.onPickDate ||
      onClearDate != oldDelegate.onClearDate ||
      favoriteCount != oldDelegate.favoriteCount ||
      onFavorites != oldDelegate.onFavorites ||
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

class _OcrStatusCard extends StatelessWidget {
  const _OcrStatusCard({
    required this.indexing,
    required this.paused,
    required this.collapsed,
    required this.completed,
    required this.total,
    required this.pending,
    required this.indexed,
    required this.onTogglePaused,
    required this.onToggleCollapsed,
  });

  final bool indexing;
  final bool paused;
  final bool collapsed;
  final int completed;
  final int total;
  final int pending;
  final int indexed;
  final VoidCallback onTogglePaused;
  final VoidCallback onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final remaining = math.max(0, total - completed);
    final title = paused
        ? st('내용 인식 일시정지', 'Text recognition paused')
        : st('이미지 내용 인식 중', 'Reading image text');
    final status = indexing
        ? st('$remaining개 남음', '$remaining left')
        : st('$pending개 대기 중', '$pending waiting');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E9EE)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F3F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.document_scanner_outlined,
                  size: 18,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF111111),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (collapsed) ...[
                      const SizedBox(height: 2),
                      Text(
                        status,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF727785),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _OcrTextButton(
                label: paused ? st('다시 시작', 'Resume') : st('일시정지', 'Pause'),
                onTap: onTogglePaused,
              ),
              const SizedBox(width: 2),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onToggleCollapsed,
                icon: Icon(
                  collapsed
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  color: const Color(0xFF727785),
                ),
              ),
            ],
          ),
          if (!collapsed) ...[
            const SizedBox(height: 12),
            Text(
              st(
                '인식된 텍스트로 바로 검색할 수 있어요',
                'Search by text inside recognized screenshots',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF727785),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: paused && total <= 0 ? null : progress,
                backgroundColor: const Color(0xFFEDEFF3),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF111111)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    total > 0
                        ? st(
                            '$completed/$total 처리됨',
                            '$completed/$total processed',
                          )
                        : st('$indexed개 인식 완료', '$indexed indexed'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF727785),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF424754),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OcrTextButton extends StatelessWidget {
  const _OcrTextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF111111),
            fontWeight: FontWeight.w700,
          ),
        ),
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
                st(
                  '$screenshotCount개 스크린샷 · $stackCount개 앱',
                  '$screenshotCount screenshots · $stackCount apps',
                ),
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
                            color: const Color(0xFF111111),
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
      (StackSortMode.latest, st('최신순', 'Latest')),
      (StackSortMode.name, st('이름 순', 'Name')),
      (StackSortMode.mostImages, st('이미지 많은 순', 'Most images')),
      (StackSortMode.fewestImages, st('이미지 적은 순', 'Fewest images')),
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
                        color: Color(0xFF111111),
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
    required this.initialRange,
    required this.initialMonth,
    required this.firstDate,
    required this.lastDate,
    required this.screenshotDates,
  });

  final DateTimeRange? initialRange;
  final DateTime initialMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final Set<DateTime> screenshotDates;

  @override
  State<_ShotlyCalendarDialog> createState() => _ShotlyCalendarDialogState();
}

class _ShotlyCalendarDialogState extends State<_ShotlyCalendarDialog> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
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
    final initialRange = widget.initialRange;
    _rangeStart = initialRange == null ? null : _dateOnly(initialRange.start);
    _rangeEnd =
        initialRange == null ||
            _isSameDate(initialRange.start, initialRange.end)
        ? null
        : _dateOnly(initialRange.end);
    final initialMonth = _dateOnly(widget.initialMonth);
    _visibleMonth = DateTime(initialMonth.year, initialMonth.month);
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
                          foregroundColor: const Color(0xFF111111),
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
                        child: Text(st('취소', 'Cancel')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _rangeStart == null
                            ? null
                            : () {
                                final start = _rangeStart!;
                                Navigator.of(context).pop(
                                  DateTimeRange(
                                    start: start,
                                    end: _rangeEnd ?? start,
                                  ),
                                );
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF111111),
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
                        child: Text(st('적용', 'Apply')),
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
    final day = _dateOnly(date);
    final rangeStart = _rangeStart;
    final rangeEnd = _rangeEnd;
    final isStart = rangeStart != null && _isSameDate(day, rangeStart);
    final isEnd = rangeEnd != null && _isSameDate(day, rangeEnd);
    final isSelected = isStart || isEnd;
    final hasActiveRange = rangeStart != null && rangeEnd != null;
    final isInActiveRange =
        hasActiveRange && !day.isBefore(rangeStart) && !day.isAfter(rangeEnd);
    final hasScreenshots = widget.screenshotDates.contains(day);
    final enabled =
        isCurrentMonth &&
        !_dateOnly(date).isBefore(_dateOnly(widget.firstDate)) &&
        !_dateOnly(date).isAfter(_dateOnly(widget.lastDate));
    final textColor = !enabled
        ? const Color(0xFF727785)
        : isSelected
        ? Colors.white
        : const Color(0xFF1A1C1C);
    final weekDayIndex = day.weekday % 7;
    final continuesLeft =
        isInActiveRange &&
        weekDayIndex != 0 &&
        !_isSameDate(day, rangeStart) &&
        !_dateOnly(day.subtract(const Duration(days: 1))).isBefore(rangeStart);
    final continuesRight =
        isInActiveRange &&
        weekDayIndex != 6 &&
        !_isSameDate(day, rangeEnd) &&
        !_dateOnly(day.add(const Duration(days: 1))).isAfter(rangeEnd);

    return InkWell(
      onTap: enabled ? () => _selectDate(day) : null,
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isInActiveRange)
            Positioned(
              left: continuesLeft ? 0 : 20,
              right: continuesRight ? 0 : 20,
              height: 40,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F5),
                  borderRadius: BorderRadius.horizontal(
                    left: continuesLeft
                        ? Radius.zero
                        : const Radius.circular(20),
                    right: continuesRight
                        ? Radius.zero
                        : const Radius.circular(20),
                  ),
                ),
              ),
            ),
          if (isSelected)
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF050711),
                shape: BoxShape.circle,
              ),
            ),
          Text(
            '${date.day}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (hasScreenshots)
            Positioned(
              bottom: 8,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
        ],
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
      _visibleMonth = DateTime(picked.year, picked.month);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      final rangeStart = _rangeStart;
      final rangeEnd = _rangeEnd;

      if (rangeStart == null || rangeEnd != null || date.isBefore(rangeStart)) {
        _rangeStart = date;
        _rangeEnd = null;
        return;
      }

      if (date.isAfter(rangeStart)) {
        _rangeEnd = date;
      }
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
          color: selected ? const Color(0xFF111111) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF111111) : const Color(0xFFE5E7EB),
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
