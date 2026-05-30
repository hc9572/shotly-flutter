part of 'main.dart';

class _SetDateSection extends StatelessWidget {
  const _SetDateSection({
    required this.dateLabel,
    required this.sets,
    required this.allStackKeys,
    required this.stackNames,
    required this.favoriteImageIds,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onToggleFavoriteImage,
    required this.onMoveImage,
    required this.selectedIds,
    required this.selectionMode,
    required this.onToggleSelection,
    required this.onToggleDateSelection,
    required this.showLocalActionBar,
    required this.onSaveMemo,
    required this.onAssignImageToSet,
    required this.viewerItems,
  });

  final String dateLabel;
  final List<ScreenshotSet> sets;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Set<String> favoriteImageIds;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId) onToggleFavoriteImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Set<String> selectedIds;
  final bool selectionMode;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<List<String>> onToggleDateSelection;
  final bool showLocalActionBar;
  final Future<void> Function(String setKey, String memo) onSaveMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;
  final List<ScreenshotItem> viewerItems;

  @override
  Widget build(BuildContext context) {
    final dateImageIds = sets
        .expand((set) => set.items.map((item) => item.id))
        .toList();
    final selectedCount = dateImageIds
        .where((id) => selectedIds.contains(id))
        .length;
    final dateCheckValue =
        selectedCount == dateImageIds.length && dateImageIds.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sets.indexed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SetSection(
              set: entry.$2,
              allStackKeys: allStackKeys,
              stackNames: stackNames,
              favoriteImageIds: favoriteImageIds,
              onExcludeImage: onExcludeImage,
              onDeleteOriginalImage: onDeleteOriginalImage,
              onToggleFavoriteImage: onToggleFavoriteImage,
              onMoveImage: onMoveImage,
              selectedIds: selectedIds,
              selectionMode: selectionMode,
              onToggleSelection: onToggleSelection,
              showLocalActionBar: showLocalActionBar,
              onSaveMemo: onSaveMemo,
              onAssignImageToSet: onAssignImageToSet,
              showTitle: false,
              headerLabel: entry.$1 == 0 ? dateLabel : '',
              onHeaderTap: entry.$1 == 0
                  ? () => onToggleDateSelection(dateImageIds)
                  : null,
              headerCheckValue: entry.$1 == 0 ? dateCheckValue : null,
              showHeaderCheckbox: entry.$1 == 0 && selectionMode,
              viewerItems: viewerItems,
            ),
          ),
        ),
      ],
    );
  }
}

class _SetSection extends StatefulWidget {
  const _SetSection({
    required this.set,
    required this.allStackKeys,
    required this.stackNames,
    required this.favoriteImageIds,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onToggleFavoriteImage,
    required this.onMoveImage,
    required this.selectedIds,
    required this.selectionMode,
    required this.onToggleSelection,
    required this.showLocalActionBar,
    required this.onSaveMemo,
    required this.onAssignImageToSet,
    this.onAddSelectedToFolder,
    this.showTitle = true,
    this.suppressHeader = false,
    this.headerLabel,
    this.onHeaderTap,
    this.headerCheckValue,
    this.showHeaderCheckbox = false,
    this.viewerItems,
    this.folderMoveDestinations = const [],
    this.currentFolderKey,
    this.onMoveImagesToFolder,
    this.onClearSelection,
  });

  final ScreenshotSet set;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Set<String> favoriteImageIds;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId) onToggleFavoriteImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Set<String> selectedIds;
  final bool selectionMode;
  final ValueChanged<String> onToggleSelection;
  final bool showLocalActionBar;
  final Future<void> Function(String setKey, String memo) onSaveMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;
  final Future<void> Function(List<String> imageIds)? onAddSelectedToFolder;
  final bool showTitle;
  final bool suppressHeader;
  final String? headerLabel;
  final VoidCallback? onHeaderTap;
  final bool? headerCheckValue;
  final bool showHeaderCheckbox;
  final List<ScreenshotItem>? viewerItems;
  final List<ScreenshotSet> folderMoveDestinations;
  final String? currentFolderKey;
  final Future<void> Function(String folderKey, List<String> imageIds)?
  onMoveImagesToFolder;
  final VoidCallback? onClearSelection;
  @override
  State<_SetSection> createState() => _SetSectionState();
}

class _SetSectionState extends State<_SetSection> {
  late final TextEditingController _memoController;
  late String _memoText;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: widget.set.memo);
    _memoText = widget.set.memo;
  }

  @override
  void didUpdateWidget(covariant _SetSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set.memo != widget.set.memo && widget.set.memo != _memoText) {
      _memoText = widget.set.memo;
      _memoController.text = widget.set.memo;
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ImageGridSection(
      title: widget.suppressHeader
          ? ''
          : widget.headerLabel ??
                (widget.showTitle ? widget.set.timeRange : ''),
      titleOnTap: widget.onHeaderTap,
      headerCheckValue: widget.headerCheckValue,
      showHeaderCheckbox: widget.showHeaderCheckbox,
      memoText: widget.suppressHeader || _memoText.trim().isEmpty
          ? null
          : _memoText.trim(),
      items: widget.set.items,
      viewerItems: widget.viewerItems,
      allStackKeys: widget.allStackKeys,
      stackNames: widget.stackNames,
      favoriteImageIds: widget.favoriteImageIds,
      onExcludeImage: widget.onExcludeImage,
      onDeleteOriginalImage: widget.onDeleteOriginalImage,
      onToggleFavoriteImage: widget.onToggleFavoriteImage,
      onMoveImage: widget.onMoveImage,
      selectedIds: widget.selectedIds,
      selectionMode: widget.selectionMode,
      onToggleSelection: widget.onToggleSelection,
      showLocalActionBar: widget.showLocalActionBar,
      onSetAction: widget.suppressHeader
          ? null
          : () => _showSetActions(context),
      onEditMemo: widget.suppressHeader
          ? null
          : () async {
              final memo = await _editMemo(context);
              if (memo != null) await _saveMemo(memo);
            },
      onAddSelectedToFolder: widget.onAddSelectedToFolder,
      folderMoveDestinations: widget.folderMoveDestinations,
      currentFolderKey: widget.currentFolderKey,
      onMoveImagesToFolder: widget.onMoveImagesToFolder,
      onClearSelection: widget.onClearSelection,
    );
  }

  Future<void> _showSetActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
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
              const SizedBox(height: 12),
              _AddMenuTile(
                icon: Icons.edit_note_rounded,
                title: _memoText.trim().isEmpty
                    ? st('메모 추가', 'Add note')
                    : st('메모 수정', 'Edit note'),
                onTap: () => Navigator.of(context).pop('memo'),
              ),
              if (_memoText.trim().isNotEmpty)
                _AddMenuTile(
                  icon: Icons.notes_rounded,
                  title: st('메모 삭제', 'Delete note'),
                  onTap: () => Navigator.of(context).pop('clear_memo'),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == 'memo' && context.mounted) {
      final memo = await _editMemo(context);
      if (memo != null) await _saveMemo(memo);
    }
    if (action == 'clear_memo') {
      await _saveMemo('');
    }
  }

  Future<void> _saveMemo(String memo) async {
    if (!mounted) return;
    final previous = _memoText;
    final trimmed = memo.trim();
    setState(() {
      _memoText = trimmed;
      _memoController.text = trimmed;
    });
    try {
      await widget.onSaveMemo(widget.set.key, trimmed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _memoText = previous;
        _memoController.text = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(st('메모를 저장하지 못했습니다: $e', 'Couldn’t save note: $e')),
        ),
      );
    }
  }

  Future<String?> _editMemo(BuildContext context) async {
    final value = await _showShotlyTextDialog(
      context: context,
      title: st('Set 메모', 'Set note'),
      initialValue: _memoText,
      hintText: st('예: 온보딩 플로우', 'e.g. Onboarding flow'),
      primaryLabel: st('저장', 'Save'),
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
    required this.items,
    required this.allStackKeys,
    this.memoText,
    this.titleOnTap,
    this.headerCheckValue,
    this.showHeaderCheckbox = false,
    this.viewerItems,
    required this.stackNames,
    required this.favoriteImageIds,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onToggleFavoriteImage,
    required this.onMoveImage,
    this.selectedIds,
    this.selectionMode,
    this.onToggleSelection,
    this.showLocalActionBar = true,
    this.onSetAction,
    this.onEditMemo,
    this.onAddSelectedToFolder,
    this.folderMoveDestinations = const [],
    this.currentFolderKey,
    this.onMoveImagesToFolder,
    this.onClearSelection,
  });

  final String title;
  final List<ScreenshotItem> items;
  final String? memoText;
  final VoidCallback? titleOnTap;
  final bool? headerCheckValue;
  final bool showHeaderCheckbox;
  final List<ScreenshotItem>? viewerItems;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Set<String> favoriteImageIds;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId) onToggleFavoriteImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Set<String>? selectedIds;
  final bool? selectionMode;
  final ValueChanged<String>? onToggleSelection;
  final bool showLocalActionBar;
  final VoidCallback? onSetAction;
  final VoidCallback? onEditMemo;
  final Future<void> Function(List<String> imageIds)? onAddSelectedToFolder;
  final List<ScreenshotSet> folderMoveDestinations;
  final String? currentFolderKey;
  final Future<void> Function(String folderKey, List<String> imageIds)?
  onMoveImagesToFolder;
  final VoidCallback? onClearSelection;

  @override
  State<_ImageGridSection> createState() => _ImageGridSectionState();
}

class _ImageGridSectionState extends State<_ImageGridSection> {
  final Set<String> _selectedIds = <String>{};
  final Set<String> _locallyHiddenIds = <String>{};

  Set<String> get _effectiveSelectedIds => widget.selectedIds ?? _selectedIds;
  bool get _isSelecting =>
      widget.selectionMode ?? _effectiveSelectedIds.isNotEmpty;
  List<ScreenshotItem> get _visibleItems => widget.items
      .where((item) => !_locallyHiddenIds.contains(item.id))
      .toList();

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    final hasHeader =
        widget.title.isNotEmpty ||
        widget.showHeaderCheckbox ||
        widget.memoText != null ||
        (widget.onSetAction != null && !_isSelecting);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasHeader) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title.isNotEmpty ||
                    widget.showHeaderCheckbox ||
                    (widget.onSetAction != null && !_isSelecting))
                  Row(
                    children: [
                      if (widget.showHeaderCheckbox) ...[
                        _HeaderSelectionCircle(
                          value: widget.headerCheckValue,
                          onTap: () => widget.titleOnTap?.call(),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: InkWell(
                          onTap: widget.titleOnTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              widget.title,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: const Color(0xFF1A1C1C)),
                            ),
                          ),
                        ),
                      ),
                      if (widget.onSetAction != null && !_isSelecting)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: Color(0xFF727785),
                          ),
                          onPressed: widget.onSetAction,
                        ),
                    ],
                  ),
                if (widget.memoText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.memoText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF424754),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: widget.showHeaderCheckbox ? 11 : 8),
        ],
        GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 3 / 4,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _SelectableThumb(
              item: item,
              selected: _effectiveSelectedIds.contains(item.id),
              selecting: _isSelecting,
              favorite: widget.favoriteImageIds.contains(item.id),
              onToggleFavorite: () async {
                await widget.onToggleFavoriteImage(item.id);
                if (mounted) setState(() {});
              },
              onTap: () => _isSelecting
                  ? _toggleSelection(item.id)
                  : _openImageViewer(context, item),
              onLongPress: () => _toggleSelection(item.id),
            );
          },
        ),
        if (_isSelecting && widget.showLocalActionBar) ...[
          const SizedBox(height: 12),
          _SelectionActionBar(
            onCancel: _clearSelection,
            onShare: _shareSelected,
            onDelete: () => _deleteSelected(context),
            onMove: () => _moveSelected(context),
            onHide: _hideSelected,
            onFolder:
                widget.onAddSelectedToFolder == null &&
                    (widget.folderMoveDestinations.isEmpty ||
                        widget.onMoveImagesToFolder == null)
                ? null
                : () => _addSelectedToFolder(context),
          ),
        ],
      ],
    );
  }

  void _clearSelection() {
    if (widget.onClearSelection != null) {
      widget.onClearSelection!();
      return;
    }
    setState(_selectedIds.clear);
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

  Future<void> _openImageViewer(
    BuildContext context,
    ScreenshotItem item,
  ) async {
    final viewerItems = (widget.viewerItems ?? widget.items)
        .where((candidate) => !_locallyHiddenIds.contains(candidate.id))
        .toList();
    final index = viewerItems.indexWhere(
      (candidate) => candidate.id == item.id,
    );
    final deletedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(
          items: viewerItems,
          initialIndex: index < 0 ? 0 : index,
          favoriteImageIds: widget.favoriteImageIds,
          onToggleFavoriteImage: widget.onToggleFavoriteImage,
          onDeleteOriginalImage: widget.onDeleteOriginalImage,
        ),
      ),
    );
    if (deletedId != null && mounted) {
      setState(() => _locallyHiddenIds.add(deletedId));
    }
  }

  Future<void> _shareSelected() async {
    await ShotlyNative.shareImages(_effectiveSelectedIds.toList());
  }

  Future<void> _hideSelected() async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: st('선택한 사진 숨기기', 'Hide selected photos'),
      body: st(
        '선택한 ${_effectiveSelectedIds.length}장을 Shotly 목록에서 숨길까요? 숨긴 항목은 설정에서 다시 확인할 수 있어요.',
        'Hide ${_effectiveSelectedIds.length} selected photos from Shotly? Hidden items can be restored in Settings.',
      ),
      primaryLabel: st('숨기기', 'Hide'),
    );
    if (confirmed != true) return;
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
      title: st('이동할 앱', 'Move to app'),
      items: widget.allStackKeys
          .map(
            (key) => _ShotlyActionItem(
              value: key,
              icon: Icons.layers_rounded,
              title: widget.stackNames[key] ?? key,
            ),
          )
          .toList(),
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
    widget.onClearSelection?.call();
  }

  Future<void> _addSelectedToFolder(BuildContext context) async {
    final selected = _effectiveSelectedIds.toList();
    if (selected.isEmpty) return;
    final folderItems = widget.folderMoveDestinations
        .where((folder) => folder.key != widget.currentFolderKey)
        .map(
          (folder) => _ShotlyActionItem(
            value: folder.key,
            icon: Icons.grid_view_rounded,
            title: _folderName(folder),
          ),
        )
        .toList();
    final target = await _showShotlyActionSheet<String>(
      context,
      title: st('이동할 폴더', 'Move to folder'),
      items: [
        if (widget.onAddSelectedToFolder != null)
          _ShotlyActionItem(
            value: '__new_folder__',
            icon: Icons.create_new_folder_rounded,
            title: st('새 폴더 만들기', 'Create new folder'),
          ),
        ...folderItems,
      ],
    );
    if (target == null) return;
    if (target == '__new_folder__') {
      await widget.onAddSelectedToFolder?.call(selected);
    } else {
      await widget.onMoveImagesToFolder?.call(target, selected);
    }
    if (mounted) {
      setState(() {
        _locallyHiddenIds.addAll(selected);
        _selectedIds.clear();
      });
    }
    widget.onClearSelection?.call();
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: st('원본 파일 삭제', 'Delete original file'),
      body: st(
        '선택한 ${_effectiveSelectedIds.length}장을 Shotly뿐 아니라 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
        'Delete ${_effectiveSelectedIds.length} selected originals from both Shotly and your device gallery? This can’t be undone.',
      ),
      primaryLabel: st('삭제', 'Delete'),
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
    widget.onClearSelection?.call();
  }
}
