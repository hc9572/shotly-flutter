part of 'main.dart';

enum _SmartCleanCandidateType { duplicates, flow, existingFolder }

enum _SmartCleanReviewAction { delete, folder }

class _SmartCleanReviewResult {
  const _SmartCleanReviewResult({required this.action, required this.items});

  final _SmartCleanReviewAction action;
  final List<ScreenshotItem> items;
}

class _SmartCleanCandidate {
  const _SmartCleanCandidate({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.items,
    this.targetFolderKey,
    this.targetFolderName,
    this.selectableImageIds = const {},
  });

  final _SmartCleanCandidateType type;
  final String title;
  final String subtitle;
  final List<ScreenshotItem> items;
  final String? targetFolderKey;
  final String? targetFolderName;
  final Set<String> selectableImageIds;
}

class _SmartCleanPanel extends StatelessWidget {
  const _SmartCleanPanel({
    required this.running,
    required this.analyzed,
    required this.expanded,
    required this.progress,
    required this.message,
    required this.candidates,
    required this.onAnalyze,
    required this.onToggleExpanded,
    required this.onCandidateTap,
  });

  final bool running;
  final bool analyzed;
  final bool expanded;
  final double? progress;
  final String? message;
  final List<_SmartCleanCandidate> candidates;
  final VoidCallback onAnalyze;
  final VoidCallback onToggleExpanded;
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
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.collections_rounded,
                  size: 18,
                  color: Color(0xFF424754),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '비슷한 화면 찾기',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF1A1C1C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message ?? '정리할 화면을 찾아보세요.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF727785),
                      ),
                    ),
                  ],
                ),
              ),
              if (candidates.isNotEmpty)
                IconButton(
                  onPressed: running ? null : onToggleExpanded,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF727785),
                  ),
                ),
              IconButton(
                onPressed: running ? null : onAnalyze,
                tooltip: analyzed ? '다시 분석하기' : '분석하기',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  analyzed ? Icons.refresh_rounded : Icons.search_rounded,
                  color: running
                      ? const Color(0xFFADB3BE)
                      : const Color(0xFF2170E4),
                ),
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
          if (candidates.isNotEmpty && expanded) ...[
            const SizedBox(height: 14),
            Text(
              '비슷한 화면',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF1A1C1C),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              padding: EdgeInsets.zero,
              itemCount: candidates.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                return _SmartCleanCandidateTile(
                  candidate: candidate,
                  index: index,
                  onTap: () => onCandidateTap(candidate),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SmartCleanCandidateTile extends StatelessWidget {
  const _SmartCleanCandidateTile({
    required this.candidate,
    required this.index,
    required this.onTap,
  });

  final _SmartCleanCandidate candidate;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEFF3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 58,
                  height: 72,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final entry
                          in candidate.items.take(3).toList().indexed)
                        Positioned(
                          left: entry.$1 * 8,
                          top: entry.$1 * 5,
                          child: Transform.rotate(
                            angle: (entry.$1 - 1) * 0.035,
                            child: _Thumb(
                              path: entry.$2.thumbnailPath,
                              width: 42,
                              height: 64,
                              radius: 10,
                              borderColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '그룹 ${index + 1}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF1A1C1C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${candidate.items.length}장',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF727785),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (candidate.type == _SmartCleanCandidateType.existingFolder &&
                candidate.targetFolderName != null) ...[
              const SizedBox(height: 2),
              Text(
                candidate.targetFolderName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF727785),
                ),
              ),
            ],
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
    _selectedIds = widget.candidate.items.map((item) => item.id).toSet();
  }

  List<ScreenshotItem> get _selectedItems => [
    for (final item in widget.candidate.items)
      if (_selectedIds.contains(item.id)) item,
  ];

  @override
  Widget build(BuildContext context) {
    final canDelete = _selectedIds.isNotEmpty;
    final canFolder =
        _selectedIds.length >= 2 ||
        (widget.candidate.type == _SmartCleanCandidateType.existingFolder &&
            _selectedIds.isNotEmpty);
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
                          '비슷한 화면 확인',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF1A1C1C),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedIds.length}/${widget.candidate.items.length}장 선택됨',
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 104),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.60,
                ),
                itemCount: widget.candidate.items.length,
                itemBuilder: (context, index) {
                  final item = widget.candidate.items[index];
                  return _SmartCleanReviewTile(
                    item: item,
                    index: index,
                    selected: _selectedIds.contains(item.id),
                    onToggle: () => setState(() {
                      if (!_selectedIds.add(item.id)) {
                        _selectedIds.remove(item.id);
                      }
                    }),
                    onOpen: () async {
                      final nextSelected = await Navigator.of(context)
                          .push<Set<String>>(
                            MaterialPageRoute(
                              builder: (_) => _SmartCleanPreviewScreen(
                                items: widget.candidate.items,
                                initialIndex: index,
                                selectedIds: _selectedIds,
                              ),
                            ),
                          );
                      if (nextSelected != null && mounted) {
                        setState(() {
                          _selectedIds
                            ..clear()
                            ..addAll(nextSelected);
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 26),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: canDelete
                      ? () => Navigator.of(context).pop(
                          _SmartCleanReviewResult(
                            action: _SmartCleanReviewAction.delete,
                            items: _selectedItems,
                          ),
                        )
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE8E8),
                    disabledBackgroundColor: const Color(0xFFF0F2F5),
                    foregroundColor: const Color(0xFFD04444),
                    disabledForegroundColor: const Color(0xFFADB3BE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    '삭제 ${_selectedIds.length}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: canFolder
                      ? () => Navigator.of(context).pop(
                          _SmartCleanReviewResult(
                            action: _SmartCleanReviewAction.folder,
                            items: _selectedItems,
                          ),
                        )
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
                    '폴더로 묶기 ${_selectedIds.length}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
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
                    selected ? Icons.check_rounded : null,
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
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFEDEFF3)),
                  ),
                  child: const Icon(
                    Icons.open_in_full_rounded,
                    color: Color(0xFF424754),
                    size: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartCleanPreviewScreen extends StatefulWidget {
  const _SmartCleanPreviewScreen({
    required this.items,
    required this.initialIndex,
    required this.selectedIds,
  });

  final List<ScreenshotItem> items;
  final int initialIndex;
  final Set<String> selectedIds;

  @override
  State<_SmartCleanPreviewScreen> createState() =>
      _SmartCleanPreviewScreenState();
}

class _SmartCleanPreviewScreenState extends State<_SmartCleanPreviewScreen> {
  late final PageController _pageController;
  late final Set<String> _selectedIds;
  late int _currentIndex;
  bool _controlsVisible = true;
  final Map<String, Future<String?>> _previewFutures =
      <String, Future<String?>>{};

  ScreenshotItem get _currentItem => widget.items[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _selectedIds = {...widget.selectedIds};
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

  void _close() => Navigator.of(context).pop(_selectedIds);

  void _toggleCurrent() {
    setState(() {
      if (!_selectedIds.add(_currentItem.id)) {
        _selectedIds.remove(_currentItem.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIds.contains(_currentItem.id);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
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
                          onTap: _close,
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 8,
                        right: 12,
                        child: GestureDetector(
                          onTap: _toggleCurrent,
                          child: _SmartCleanPreviewCheck(selected: selected),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: MediaQuery.paddingOf(context).bottom + 22,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_currentIndex + 1}/${widget.items.length}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
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
        ),
      ),
    );
  }
}

class _SmartCleanPreviewCheck extends StatelessWidget {
  const _SmartCleanPreviewCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2170E4) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? const Color(0xFF2170E4) : const Color(0xFFD8DDE6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        selected ? Icons.check_rounded : null,
        color: Colors.white,
        size: 20,
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
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: Text(
        '$index',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF424754),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
