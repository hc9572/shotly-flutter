part of 'main.dart';

enum _SmartCleanCandidateType { duplicates, flow }

class _SmartCleanCandidate {
  const _SmartCleanCandidate({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final _SmartCleanCandidateType type;
  final String title;
  final String subtitle;
  final List<ScreenshotItem> items;
}

class _SmartCleanPanel extends StatelessWidget {
  const _SmartCleanPanel({
    required this.running,
    required this.progress,
    required this.message,
    required this.candidates,
    required this.onAnalyze,
    required this.onCandidateTap,
  });

  final bool running;
  final double? progress;
  final String? message;
  final List<_SmartCleanCandidate> candidates;
  final VoidCallback onAnalyze;
  final Future<void> Function(_SmartCleanCandidate candidate) onCandidateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F3FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: Color(0xFF2170E4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Clean',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF1A1C1C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message ?? '이 앱 안에서만 중복/비슷한 흐름을 찾아요',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF727785),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: running ? null : onAnalyze,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2170E4),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: Text(running ? '분석 중' : '분석하기'),
              ),
            ],
          ),
          if (running) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress == null || progress! <= 0 ? null : progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFEDEFF3),
                color: const Color(0xFF2170E4),
              ),
            ),
          ],
          if (candidates.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final candidate in candidates) ...[
              _SmartCleanCandidateTile(
                candidate: candidate,
                onTap: () => onCandidateTap(candidate),
              ),
              if (candidate != candidates.last) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _SmartCleanCandidateTile extends StatelessWidget {
  const _SmartCleanCandidateTile({
    required this.candidate,
    required this.onTap,
  });

  final _SmartCleanCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = candidate.type == _SmartCleanCandidateType.duplicates
        ? Icons.content_copy_rounded
        : Icons.folder_rounded;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 42,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final entry in candidate.items.take(3).toList().indexed)
                    Positioned(
                      left: entry.$1 * 15,
                      top: entry.$1.isEven ? 0 : 4,
                      child: _Thumb(
                        path: entry.$2.thumbnailPath,
                        width: 28,
                        height: 42,
                        radius: 8,
                        borderColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF1A1C1C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    candidate.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF727785),
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, size: 18, color: const Color(0xFF727785)),
          ],
        ),
      ),
    );
  }
}

class _SmartCleanReviewScreen extends StatefulWidget {
  const _SmartCleanReviewScreen({required this.candidate});

  final _SmartCleanCandidate candidate;

  @override
  State<_SmartCleanReviewScreen> createState() =>
      _SmartCleanReviewScreenState();
}

class _SmartCleanReviewScreenState extends State<_SmartCleanReviewScreen> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    final isDuplicates =
        widget.candidate.type == _SmartCleanCandidateType.duplicates;
    _selectedIds =
        (isDuplicates ? widget.candidate.items.skip(1) : widget.candidate.items)
            .map((item) => item.id)
            .toSet();
  }

  List<ScreenshotItem> get _selectedItems => [
    for (final item in widget.candidate.items)
      if (_selectedIds.contains(item.id)) item,
  ];

  @override
  Widget build(BuildContext context) {
    final isDuplicates =
        widget.candidate.type == _SmartCleanCandidateType.duplicates;
    final canConfirm = isDuplicates
        ? _selectedIds.isNotEmpty
        : _selectedIds.length >= 2;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF424754),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDuplicates ? '삭제할 화면 확인' : '묶을 사진 확인',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF1A1C1C),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDuplicates
                              ? '${_selectedIds.length}장 삭제 예정 · 남길 사진은 체크 해제'
                              : '${_selectedIds.length}/${widget.candidate.items.length}장 선택됨 · 뺄 사진은 체크 해제',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: const Color(0xFF727785)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 92),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.56,
                ),
                itemCount: widget.candidate.items.length,
                itemBuilder: (context, index) {
                  final item = widget.candidate.items[index];
                  final selected = _selectedIds.contains(item.id);
                  return _SmartCleanReviewTile(
                    item: item,
                    index: index,
                    selected: selected,
                    onToggle: () => setState(() {
                      if (!_selectedIds.add(item.id)) {
                        _selectedIds.remove(item.id);
                      }
                    }),
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ImageViewerScreen(
                          items: widget.candidate.items,
                          initialIndex: index,
                          onDeleteOriginalImage: (_) async => false,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: canConfirm
                ? () => Navigator.of(context).pop(_selectedItems)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2170E4),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E5EA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              isDuplicates
                  ? '선택한 ${_selectedIds.length}장 삭제'
                  : '선택한 ${_selectedIds.length}장 묶기',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmartCleanReviewTile extends StatelessWidget {
  const _SmartCleanReviewTile({
    required this.item,
    required this.index,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
  });

  final ScreenshotItem item;
  final int index;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Thumb(
              path: item.thumbnailPath,
              width: double.infinity,
              height: double.infinity,
              radius: 14,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF2170E4)
                        : const Color(0xFFEDEFF3),
                    width: selected ? 1.5 : 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.04),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 7,
              left: 7,
              child: _SmartCleanIndexBadge(index: index + 1),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF2170E4)
                        : Colors.white.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2170E4)
                          : const Color(0xFFD8DDE6),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    selected ? Icons.check_rounded : Icons.add_rounded,
                    color: selected ? Colors.white : const Color(0xFF727785),
                    size: 14,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: GestureDetector(
                onTap: onOpen,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.open_in_full_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 40,
              bottom: 8,
              child: Text(
                _formatSetDate(item.date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartCleanIndexBadge extends StatelessWidget {
  const _SmartCleanIndexBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$index',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
