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
    required this.favoriteImageIds,
    required this.ocrIndex,
    required this.stackMatchesQuery,
    required this.onRenameStack,
    required this.onHideStack,
    required this.onDeleteStack,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onDeleteOriginalImages,
    required this.onToggleFavoriteImage,
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
  final Set<String> favoriteImageIds;
  final Map<String, OcrIndexEntry> ocrIndex;
  final bool Function(StackItem stack, String query) stackMatchesQuery;
  final Future<void> Function(String stackKey, String name) onRenameStack;
  final Future<void> Function(String stackKey) onHideStack;
  final Future<void> Function(StackItem stack) onDeleteStack;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<bool> Function(List<String> imageIds) onDeleteOriginalImages;
  final Future<void> Function(String imageId) onToggleFavoriteImage;
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
                    onPressed: () => Navigator.of(context).pop(),
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
                        onSubmitted: (value) {
                          final nextQuery = value.trim();
                          if (nextQuery != _query) {
                            setState(() => _query = nextQuery);
                          }
                          FocusScope.of(context).unfocus();
                        },
                        textInputAction: TextInputAction.search,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: st(
                            '앱 이름, 폴더명 등으로 검색하기',
                            'Search apps, folders...',
                          ),
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
                          title: st('앱', 'Apps'),
                          results: stackResults,
                          folderColors: widget.folderColors,
                          expanded: _showAllStacks,
                          onToggleExpanded: () =>
                              setState(() => _showAllStacks = !_showAllStacks),
                          onOpen: _openResult,
                        ),
                        _SearchResultSection(
                          title: st('폴더', 'Folders'),
                          results: setResults,
                          folderColors: widget.folderColors,
                          expanded: _showAllSets,
                          onToggleExpanded: () =>
                              setState(() => _showAllSets = !_showAllSets),
                          onOpen: _openResult,
                        ),
                        _SearchResultSection(
                          title: st('사진', 'Photos'),
                          results: imageResults,
                          folderColors: widget.folderColors,
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
        if (!_isFolderSetKey(set.key)) continue;
        final setMatches =
            _matches(set.memo, query) || _matches(_folderName(set), query);
        if (setMatches && setKeys.add(set.key)) {
          results.add(_SearchResult.set(stack, set));
        }
      }
      for (final image in stack.items) {
        final ocrMatches = widget.ocrIndex[image.id]?.matches(query) ?? false;
        if ((image.matches(query) || ocrMatches) && imageIds.add(image.id)) {
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
                favoriteImageIds: widget.favoriteImageIds,
                visualFeatures: const {},
                initialAnchorImageId: _latestMatchingImageId(result.stack),
                onRenameStack: widget.onRenameStack,
                onHideStack: widget.onHideStack,
                onDeleteStack: widget.onDeleteStack,
                onExcludeImage: widget.onExcludeImage,
                onDeleteOriginalImage: widget.onDeleteOriginalImage,
                onDeleteOriginalImages: widget.onDeleteOriginalImages,
                onToggleFavoriteImage: widget.onToggleFavoriteImage,
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
                favoriteImageIds: widget.favoriteImageIds,
                onExcludeImage: widget.onExcludeImage,
                onDeleteOriginalImage: widget.onDeleteOriginalImage,
                onToggleFavoriteImage: widget.onToggleFavoriteImage,
                onMoveImage: widget.onMoveImage,
                onSaveSetMemo: widget.onSaveSetMemo,
                onAssignImageToSet: widget.onAssignImageToSet,
                onRenameFolder: (name) =>
                    widget.onSaveFolderName(result.set!.key, name),
                onChangeFolderColor: (colorKey) =>
                    widget.onSaveFolderColor(result.set!.key, colorKey),
                folderColorKey: widget.folderColors[result.set!.key],
                onCreateFolderFromSelected: (name, ids) async {
                  final folderKey = _buildFolderKey(result.stack.key);
                  await widget.onSaveFolderName(folderKey, name);
                  for (final id in ids) {
                    await widget.onAssignImageToSet(id, folderKey);
                  }
                },
              );
            case _SearchResultKind.image:
              final images = result.stack.items;
              final index = images.indexWhere(
                (item) => item.id == result.image!.id,
              );
              return ImageViewerScreen(
                items: images,
                initialIndex: index < 0 ? 0 : index,
                favoriteImageIds: widget.favoriteImageIds,
                onToggleFavoriteImage: widget.onToggleFavoriteImage,
                onDeleteOriginalImage: widget.onDeleteOriginalImage,
              );
          }
        },
      ),
    );
  }

  String? _latestMatchingImageId(StackItem stack) {
    final query = _query.trim();
    if (query.isEmpty) return null;
    final matches =
        stack.items
            .where(
              (image) =>
                  image.matches(query) ||
                  (widget.ocrIndex[image.id]?.matches(query) ?? false),
            )
            .toList()
          ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
    return matches.isEmpty ? null : matches.first.id;
  }
}

class _SearchEmptyHint extends StatelessWidget {
  const _SearchEmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        st('앱 이름, 폴더명 등으로 검색해보세요.', 'Search apps, folders, and more.'),
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
        st('검색 결과가 없습니다.', 'No results found.'),
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
    required this.folderColors,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onOpen,
  });

  final String title;
  final List<_SearchResult> results;
  final Map<String, String> folderColors;
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
                  child: Text(
                    expanded ? st('접기', 'Collapse') : st('더보기', 'Show more'),
                  ),
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
                  folderColors: folderColors,
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
  const _SearchResultCard({
    required this.result,
    required this.folderColors,
    required this.onTap,
  });

  final _SearchResult result;
  final Map<String, String> folderColors;
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
      _SearchResultKind.stack => stCount(
        stack.items.length,
        '장',
        'image',
        'images',
      ),
      _SearchResultKind.set =>
        '${stack.name} · ${stCount(set!.items.length, '장', 'image', 'images')}',
      _SearchResultKind.image => stack.name,
    };
    final thumbs = switch (result.kind) {
      _SearchResultKind.stack => stack.items.take(8).toList(),
      _SearchResultKind.set => set!.items.take(8).toList(),
      _SearchResultKind.image => [result.image!],
    };
    final isFolder =
        result.kind == _SearchResultKind.set &&
        set != null &&
        _isFolderSetKey(set.key);
    final folderColor = isFolder
        ? _folderColorFor(folderColors[set.key])
        : null;

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
                if (isFolder) ...[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: folderColor!.color,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      size: 19,
                      color: folderColor.darkColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
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

class _SearchSetResultScreen extends StatefulWidget {
  const _SearchSetResultScreen({
    required this.stack,
    required this.set,
    required this.allStackKeys,
    required this.stackNames,
    required this.favoriteImageIds,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onToggleFavoriteImage,
    required this.onMoveImage,
    required this.onSaveSetMemo,
    required this.onAssignImageToSet,
    this.onDeleteFolder,
    this.onRenameFolder,
    this.onChangeFolderColor,
    this.folderColorKey,
    this.onCreateFolderFromSelected,
    this.folderMoveDestinations = const [],
  });

  final StackItem stack;
  final ScreenshotSet set;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Set<String> favoriteImageIds;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId) onToggleFavoriteImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;
  final Future<void> Function()? onDeleteFolder;
  final Future<void> Function(String name)? onRenameFolder;
  final Future<void> Function(String colorKey)? onChangeFolderColor;
  final String? folderColorKey;
  final Future<void> Function(String name, List<String> imageIds)?
  onCreateFolderFromSelected;
  final List<ScreenshotSet> folderMoveDestinations;

  @override
  State<_SearchSetResultScreen> createState() => _SearchSetResultScreenState();
}

class _SearchSetResultScreenState extends State<_SearchSetResultScreen> {
  String? _folderNameOverride;
  String? _folderColorKeyOverride;
  final Set<String> _selectedIds = <String>{};
  final Set<String> _removedImageIds = <String>{};
  bool _isSelectionMode = false;

  ScreenshotSet get _visibleSet => ScreenshotSet(
    key: widget.set.key,
    title: widget.set.title,
    timeRange: widget.set.timeRange,
    memo: widget.set.memo,
    folderName: widget.set.folderName,
    items: widget.set.items
        .where((item) => !_removedImageIds.contains(item.id))
        .toList(),
  );

  String get _currentFolderName =>
      _folderNameOverride ?? _folderName(widget.set);

  String? get _currentFolderColorKey =>
      _folderColorKeyOverride ?? widget.folderColorKey;

  @override
  Widget build(BuildContext context) {
    final isFolder = _isFolderSetKey(widget.set.key);
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
                            ? _currentFolderName
                            : (widget.set.memo.trim().isEmpty
                                  ? widget.stack.name
                                  : widget.set.memo.trim()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1C1C),
                            ),
                      ),
                    ),
                    if (isFolder &&
                        (widget.onRenameFolder != null ||
                            widget.onChangeFolderColor != null ||
                            widget.onDeleteFolder != null))
                      IconButton(
                        onPressed: () => _showGroupDetailActions(context),
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
                  set: _visibleSet,
                  allStackKeys: widget.allStackKeys,
                  stackNames: widget.stackNames,
                  favoriteImageIds: widget.favoriteImageIds,
                  onExcludeImage: widget.onExcludeImage,
                  onDeleteOriginalImage: widget.onDeleteOriginalImage,
                  onToggleFavoriteImage: widget.onToggleFavoriteImage,
                  onMoveImage: widget.onMoveImage,
                  selectedIds: _selectedIds,
                  selectionMode: _isSelectionMode,
                  onToggleSelection: _toggleSelection,
                  showLocalActionBar: true,
                  onSaveMemo: isFolder ? (_, _) async {} : widget.onSaveSetMemo,
                  onAssignImageToSet: widget.onAssignImageToSet,
                  suppressHeader: isFolder,
                  showTitle: false,
                  onAddSelectedToFolder:
                      widget.onCreateFolderFromSelected == null
                      ? null
                      : _createGroupFromSelected,
                  folderMoveDestinations: widget.folderMoveDestinations,
                  currentFolderKey: isFolder ? widget.set.key : null,
                  onMoveImagesToFolder: _moveImagesToFolder,
                  onClearSelection: _clearSelection,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  void _toggleSelection(String imageId) {
    setState(() {
      _isSelectionMode = true;
      if (!_selectedIds.add(imageId)) _selectedIds.remove(imageId);
      if (_selectedIds.isEmpty) _isSelectionMode = false;
    });
  }

  Future<void> _showGroupDetailActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              if (widget.onRenameFolder != null)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(st('폴더 이름 변경', 'Rename folder')),
                  onTap: () => Navigator.pop(context, 'rename'),
                ),
              if (widget.onChangeFolderColor != null)
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(st('폴더 색상 변경', 'Change folder color')),
                  onTap: () => Navigator.pop(context, 'color'),
                ),
              if (widget.onDeleteFolder != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFE05656),
                  ),
                  title: Text(
                    st('폴더 삭제', 'Delete folder'),
                    style: TextStyle(color: Color(0xFFE05656)),
                  ),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'rename' && widget.onRenameFolder != null) {
      final name = await _showShotlyTextDialog(
        context: context,
        title: st('폴더 이름 변경', 'Rename folder'),
        initialValue: _currentFolderName,
        hintText: st('폴더 이름', 'Folder name'),
        primaryLabel: st('저장', 'Save'),
      );
      final trimmed = name?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      await widget.onRenameFolder!(trimmed);
      if (mounted) setState(() => _folderNameOverride = trimmed);
      return;
    }
    if (action == 'color' && widget.onChangeFolderColor != null) {
      final picked = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _folderColorOptions
                  .map(
                    (option) => _FolderColorDot(
                      option: option,
                      selected: option.key == _currentFolderColorKey,
                      onTap: () => Navigator.pop(context, option.key),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );
      if (picked != null) {
        await widget.onChangeFolderColor!(picked);
        if (mounted) setState(() => _folderColorKeyOverride = picked);
      }
      return;
    }
    if (action == 'delete' && widget.onDeleteFolder != null) {
      await widget.onDeleteFolder!();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _moveImagesToFolder(
    String folderKey,
    List<String> imageIds,
  ) async {
    if (imageIds.isEmpty) return;
    for (final id in imageIds) {
      await widget.onAssignImageToSet(id, folderKey);
      if (_isFolderSetKey(widget.set.key)) {
        await widget.onAssignImageToSet(
          id,
          '$_removeAssignmentPrefix${widget.set.key}',
        );
      }
    }
    if (mounted) {
      setState(() {
        _removedImageIds.addAll(imageIds);
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _createGroupFromSelected(List<String> imageIds) async {
    if (widget.onCreateFolderFromSelected == null || imageIds.isEmpty) return;
    final name = await _showShotlyTextDialog(
      context: context,
      title: st('폴더 만들기', 'Create folder'),
      hintText: st('폴더 이름', 'Folder name'),
      primaryLabel: st('만들기', 'Create'),
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await widget.onCreateFolderFromSelected!(trimmed, imageIds);
    if (_isFolderSetKey(widget.set.key)) {
      for (final id in imageIds) {
        await widget.onAssignImageToSet(
          id,
          '$_removeAssignmentPrefix${widget.set.key}',
        );
      }
    }
    if (mounted) {
      setState(() {
        if (_isFolderSetKey(widget.set.key)) {
          _removedImageIds.addAll(imageIds);
        }
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onTap,
    required this.selectedDateRange,
    required this.onPickDate,
    required this.onClearDate,
  });

  final TextEditingController controller;
  final VoidCallback onTap;
  final DateTimeRange? selectedDateRange;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    final range = selectedDateRange;
    final dateText = range == null ? null : _formatDateRange(range);
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
              hintText: st('검색', 'Search'),
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
                  color: range == null
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

  String _formatDateRange(DateTimeRange range) {
    String format(DateTime date) =>
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    if (_isSameDay(range.start, range.end)) return format(range.start);
    return '${format(range.start)}–${format(range.end)}';
  }
}
