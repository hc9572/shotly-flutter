part of 'main.dart';

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
                  selectionMode: false,
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
