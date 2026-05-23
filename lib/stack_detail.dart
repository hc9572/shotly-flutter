part of 'main.dart';

class _StackCard extends StatelessWidget {
  const _StackCard({
    required this.stack,
    required this.allStackKeys,
    required this.stackNames,
    required this.setMemos,
    required this.folderNames,
    required this.folderColors,
    required this.setAssignments,
    required this.visualFeatures,
    required this.onRenameStack,
    required this.onHideStack,
    required this.onTogglePinStack,
    required this.pinned,
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

  final StackItem stack;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> setMemos;
  final Map<String, String> folderNames;
  final Map<String, String> folderColors;
  final Map<String, String> setAssignments;
  final Map<String, VisualFeature> visualFeatures;
  final Future<void> Function(String stackKey, String name) onRenameStack;
  final Future<void> Function(String stackKey) onHideStack;
  final Future<void> Function(String stackKey) onTogglePinStack;
  final bool pinned;
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
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () => _showStackQuickActions(context),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StackDetailScreen(
            stack: stack,
            allStackKeys: allStackKeys,
            stackNames: stackNames,
            setMemos: setMemos,
            folderNames: folderNames,
            folderColors: folderColors,
            setAssignments: setAssignments,
            visualFeatures: visualFeatures,
            onRenameStack: onRenameStack,
            onHideStack: onHideStack,
            onExcludeImage: onExcludeImage,
            onDeleteOriginalImage: onDeleteOriginalImage,
            onDeleteOriginalImages: onDeleteOriginalImages,
            onMoveImage: onMoveImage,
            onAddImageToStack: onAddImageToStack,
            onSaveSetMemo: onSaveSetMemo,
            onSaveFolderName: onSaveFolderName,
            onSaveFolderColor: onSaveFolderColor,
            onAssignImageToSet: onAssignImageToSet,
          ),
        ),
      ),
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
                      Row(
                        children: [
                          if (pinned) ...[
                            const Icon(
                              Icons.push_pin_rounded,
                              size: 16,
                              color: Color(0xFF424754),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Expanded(
                            child: Text(
                              stack.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontSize: 18,
                                    height: 24 / 18,
                                    color: const Color(0xFF1A1C1C),
                                    fontWeight: FontWeight.w700,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF727785),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stack.items.take(8).length,
                separatorBuilder: (context, index) => const SizedBox(width: 5),
                itemBuilder: (context, index) => _Thumb(
                  path: stack.items[index].thumbnailPath,
                  width: 96,
                  height: 160,
                  radius: 12,
                  borderColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStackQuickActions(BuildContext context) async {
    final action = await _showShotlyActionSheet<String>(
      context,
      items: [
        _ShotlyActionItem(
          value: 'pin',
          icon: pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          title: pinned ? '고정 해제' : '고정 하기',
        ),
        const _ShotlyActionItem(
          value: 'rename',
          icon: Icons.edit_rounded,
          title: 'Stack 이름 수정',
        ),
        const _ShotlyActionItem(
          value: 'hide',
          icon: Icons.visibility_off_rounded,
          title: 'Stack 숨기기',
        ),
      ],
    );
    if (action == 'pin') await onTogglePinStack(stack.key);
    if (action == 'rename' && context.mounted) {
      final name = await _showShotlyTextDialog(
        context: context,
        title: 'Stack 이름 수정',
        initialValue: stack.name,
        hintText: 'Stack 이름',
        primaryLabel: '저장',
      );
      if (name != null) await onRenameStack(stack.key, name);
    }
    if (action == 'hide') await onHideStack(stack.key);
  }
}

class StackDetailScreen extends StatefulWidget {
  const StackDetailScreen({
    super.key,
    required this.stack,
    required this.allStackKeys,
    required this.stackNames,
    required this.setMemos,
    required this.folderNames,
    required this.folderColors,
    required this.setAssignments,
    required this.visualFeatures,
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

  final StackItem stack;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> setMemos;
  final Map<String, String> folderNames;
  final Map<String, String> folderColors;
  final Map<String, String> setAssignments;
  final Map<String, VisualFeature> visualFeatures;
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
  State<StackDetailScreen> createState() => _StackDetailScreenState();
}

class _StackDetailScreenState extends State<StackDetailScreen> {
  final Set<String> _deletedImageIds = <String>{};
  final Set<String> _selectedImageIds = <String>{};
  bool _isSelectionMode = false;
  final List<ScreenshotItem> _addedItems = <ScreenshotItem>[];
  late Map<String, String> _detailFolderNames;
  late Map<String, String> _detailFolderColors;
  late Map<String, String> _detailSetAssignments;

  String get _stackName =>
      widget.stackNames[widget.stack.key] ?? widget.stack.name;

  @override
  void initState() {
    super.initState();
    _detailFolderNames = {...widget.folderNames};
    _detailFolderColors = {...widget.folderColors};
    _detailSetAssignments = {...widget.setAssignments};
  }

  @override
  void didUpdateWidget(covariant StackDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.folderNames, widget.folderNames)) {
      _detailFolderNames = {...widget.folderNames, ..._detailFolderNames};
    }
    if (!identical(oldWidget.folderColors, widget.folderColors)) {
      _detailFolderColors = {...widget.folderColors, ..._detailFolderColors};
    }
    if (!identical(oldWidget.setAssignments, widget.setAssignments)) {
      _detailSetAssignments = {
        ...widget.setAssignments,
        ..._detailSetAssignments,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = [
      ..._addedItems,
      ...widget.stack.items,
    ].where((item) => !_deletedImageIds.contains(item.id)).toList();
    final sets = _buildScreenshotSets(
      widget.stack.key,
      visibleItems,
      widget.setMemos,
      _detailFolderNames,
      _detailSetAssignments,
    );
    final folderSets = sets.where((set) => _isFolderSetKey(set.key)).toList();
    final dateGroups = _groupSetsByDate(
      sets.where((set) => !_isFolderSetKey(set.key)).toList(),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF424754),
                              ),
                            ),
                            const Spacer(),
                            if (widget.onAddImageToStack != null)
                              IconButton(
                                onPressed: _addImageToCurrentStack,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 36,
                                  height: 40,
                                ),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Color(0xFF424754),
                                ),
                              ),
                            IconButton(
                              onPressed: () => _showStackActions(context),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints.tightFor(
                                width: 36,
                                height: 40,
                              ),
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Color(0xFF424754),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isSelectionMode
                              ? '${_selectedImageIds.length}개 선택'
                              : _stackName,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: const Color(0xFF1A1C1C),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (folderSets.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _FolderStrip(
                            stack: widget.stack,
                            folders: folderSets,
                            allStackKeys: widget.allStackKeys,
                            stackNames: widget.stackNames,
                            folderColors: _detailFolderColors,
                            selectedIds: _selectedImageIds,
                            onAddSelectedToFolder: _addSelectedToExistingFolder,
                            onDeleteFolder: (folder) =>
                                _deleteFolder(context, folder, visibleItems),
                            onRenameFolder: _renameFolder,
                            onChangeFolderColor: _changeFolderColor,
                            onExcludeImage: widget.onExcludeImage,
                            onDeleteOriginalImage: _deleteOriginalImage,
                            onMoveImage: widget.onMoveImage,
                            onSaveSetMemo: widget.onSaveSetMemo,
                            onAssignImageToSet: widget.onAssignImageToSet,
                          ),
                          const SizedBox(height: 24),
                        ] else
                          const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: dateGroups.isEmpty ? 1 : dateGroups.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 32),
                    itemBuilder: (context, index) {
                      if (dateGroups.isEmpty) {
                        return const _EmptyStackDetail(
                          message: '아직 이미지가 없는 Stack이에요',
                        );
                      }
                      return _SetDateSection(
                        dateLabel: dateGroups[index].dateLabel,
                        sets: dateGroups[index].sets,
                        allStackKeys: widget.allStackKeys,
                        stackNames: widget.stackNames,
                        onExcludeImage: widget.onExcludeImage,
                        onDeleteOriginalImage: _deleteOriginalImage,
                        onMoveImage: widget.onMoveImage,
                        selectedIds: _selectedImageIds,
                        selectionMode: _isSelectionMode,
                        onToggleSelection: _toggleSelection,
                        onToggleDateSelection: _toggleDateSelection,
                        showLocalActionBar: false,
                        onSaveMemo: widget.onSaveSetMemo,
                        onAssignImageToSet: widget.onAssignImageToSet,
                        viewerItems: visibleItems,
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_isSelectionMode)
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: _SelectionActionBar(
                  onCancel: () => setState(() {
                    _selectedImageIds.clear();
                    _isSelectionMode = false;
                  }),
                  onShare: _shareSelected,
                  onDelete: () => _deleteSelected(context),
                  onMove: () => _moveSelectedToStack(context),
                  onFolder: () => _addSelectedToFolder(context, folderSets),
                  onHide: _hideSelected,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(String imageId) {
    setState(() {
      _isSelectionMode = true;
      if (!_selectedImageIds.add(imageId)) _selectedImageIds.remove(imageId);
    });
  }

  void _toggleDateSelection(List<String> imageIds) {
    setState(() {
      _isSelectionMode = true;
      final allSelected = imageIds.every(_selectedImageIds.contains);
      if (allSelected) {
        _selectedImageIds.removeAll(imageIds);
      } else {
        _selectedImageIds.addAll(imageIds);
      }
    });
  }

  Future<void> _shareSelected() async {
    await ShotlyNative.shareImages(_selectedImageIds.toList());
  }

  Future<void> _hideSelected() async {
    final selected = _selectedImageIds.toList();
    for (final id in selected) {
      await widget.onExcludeImage(id);
    }
    if (mounted) {
      setState(() {
        _deletedImageIds.addAll(selected);
        _selectedImageIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _addImageToCurrentStack() async {
    final image = await widget.onAddImageToStack?.call(widget.stack.key);
    if (image == null || !mounted) return;
    setState(() {
      if (!_addedItems.any((item) => item.id == image.id) &&
          !widget.stack.items.any((item) => item.id == image.id)) {
        _addedItems.insert(0, image);
      }
    });
  }

  Future<void> _addSelectedToFolder(
    BuildContext context,
    List<ScreenshotSet> folders,
  ) async {
    final target = await _showShotlyActionSheet<String>(
      context,
      title: '추가할 그룹',
      items: [
        const _ShotlyActionItem(
          value: '__new_folder__',
          icon: Icons.grid_view_rounded,
          title: '신규 그룹 만들기',
        ),
        ...folders.map(
          (folder) => _ShotlyActionItem(
            value: folder.key,
            icon: Icons.grid_view_rounded,
            title: _folderName(folder),
          ),
        ),
      ],
    );
    if (target == null) return;
    var folderKey = target;
    if (target == '__new_folder__') {
      if (!context.mounted) return;
      final name = await _showShotlyTextDialog(
        context: context,
        title: '그룹 만들기',
        hintText: '그룹 이름',
        primaryLabel: '만들기',
      );
      final trimmed = name?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      folderKey = await _createFolderWithName(trimmed);
    }
    await _assignSelectedToFolder(folderKey, _selectedImageIds.toList());
  }

  Future<void> _createFolderAndAddSelected(BuildContext context) async {
    final folderKey = await _createFolder(context);
    if (folderKey == null) return;
    await _assignSelectedToFolder(folderKey, _selectedImageIds.toList());
  }

  Future<void> _addSelectedToExistingFolder(ScreenshotSet folder) async {
    await _assignSelectedToFolder(folder.key, _selectedImageIds.toList());
  }

  Future<void> _assignSelectedToFolder(
    String folderKey,
    List<String> selected,
  ) async {
    if (selected.isEmpty) return;
    final nextAssignments = <String, String>{};
    for (final id in selected) {
      final next = _addAssignmentKey(_detailSetAssignments[id], folderKey);
      nextAssignments[id] = next;
    }
    if (mounted) {
      setState(() {
        _detailSetAssignments.addAll(nextAssignments);
        _selectedImageIds.clear();
        _isSelectionMode = false;
      });
    }
    for (final id in selected) {
      await widget.onAssignImageToSet(id, folderKey);
    }
  }

  Future<String?> _createFolder(BuildContext context) async {
    final name = await _showShotlyTextDialog(
      context: context,
      title: '그룹 만들기',
      hintText: '그룹 이름',
      primaryLabel: '만들기',
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return _createFolderWithName(trimmed);
  }

  Future<String> _createFolderWithName(String name) async {
    final folderKey = _buildFolderKey(widget.stack.key);
    setState(() => _detailFolderNames[folderKey] = name);
    await widget.onSaveFolderName(folderKey, name);
    return folderKey;
  }

  Future<void> _renameFolder(ScreenshotSet folder, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    setState(() => _detailFolderNames[folder.key] = trimmed);
    await widget.onSaveFolderName(folder.key, trimmed);
  }

  Future<void> _deleteFolder(
    BuildContext context,
    ScreenshotSet folder,
    List<ScreenshotItem> visibleItems,
  ) async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '그룹 삭제',
      body: '그룹만 삭제하고 사진은 Stack에 그대로 둘까요?',
      primaryLabel: '삭제',
      destructive: true,
    );
    if (confirmed != true) return;
    final assignedIds = visibleItems
        .where(
          (item) =>
              _assignmentContains(_detailSetAssignments[item.id], folder.key),
        )
        .map((item) => item.id)
        .toList();
    for (final id in assignedIds) {
      final next = _removeAssignmentKey(_detailSetAssignments[id], folder.key);
      setState(() {
        if (next == null || next.isEmpty) {
          _detailSetAssignments.remove(id);
        } else {
          _detailSetAssignments[id] = next;
        }
      });
      await widget.onAssignImageToSet(
        id,
        '$_removeAssignmentPrefix${folder.key}',
      );
    }
    setState(() => _detailFolderNames.remove(folder.key));
    await widget.onSaveFolderName(folder.key, '');
    await widget.onSaveSetMemo(folder.key, '');
    if (mounted) setState(() {});
  }

  Future<void> _moveSelectedToStack(BuildContext context) async {
    final target = await _showShotlyActionSheet<String>(
      context,
      title: '이동할 Stack',
      items: widget.allStackKeys
          .where((key) => key != widget.stack.key)
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
    final selected = _selectedImageIds.toList();
    for (final id in selected) {
      await widget.onMoveImage(id, target);
    }
    if (mounted) {
      setState(() {
        _deletedImageIds.addAll(selected);
        _selectedImageIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '원본 파일 삭제',
      body:
          '선택한 ${_selectedImageIds.length}장을 Shotly뿐 아니라 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
      primaryLabel: '삭제',
      destructive: true,
    );
    if (confirmed != true) return;
    final selected = _selectedImageIds.toList();
    if (await widget.onDeleteOriginalImages(selected) && mounted) {
      setState(() {
        _deletedImageIds.addAll(selected);
        _selectedImageIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _renameStack(BuildContext context) async {
    final name = await _showShotlyTextDialog(
      context: context,
      title: 'Stack 이름 수정',
      initialValue: _stackName,
      hintText: 'Stack 이름',
      primaryLabel: '저장',
    );
    if (name == null) return;
    await widget.onRenameStack(widget.stack.key, name);
    if (mounted) setState(() {});
  }

  Future<void> _showStackActions(BuildContext context) async {
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
              const SizedBox(height: 16),
              _AddMenuTile(
                icon: Icons.grid_view_rounded,
                title: _selectedImageIds.isEmpty ? '그룹 추가' : '선택 이미지로 그룹 추가',
                onTap: () => Navigator.of(context).pop('folder'),
              ),
              _AddMenuTile(
                icon: Icons.edit_rounded,
                title: 'Stack 이름 수정',
                onTap: () => Navigator.of(context).pop('rename'),
              ),
              _AddMenuTile(
                icon: Icons.visibility_off_rounded,
                title: 'Stack 숨기기',
                onTap: () => Navigator.of(context).pop('hide'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'folder') {
      if (_selectedImageIds.isEmpty) {
        await _createFolder(context);
      } else {
        await _createFolderAndAddSelected(context);
      }
      return;
    }
    if (action == 'rename') await _renameStack(context);
    if (action == 'hide') {
      await widget.onHideStack(widget.stack.key);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _changeFolderColor(String folderKey, String colorKey) async {
    setState(() {
      if (colorKey.trim().isEmpty) {
        _detailFolderColors.remove(folderKey);
      } else {
        _detailFolderColors[folderKey] = colorKey;
      }
    });
    await widget.onSaveFolderColor(folderKey, colorKey);
  }

  Future<bool> _deleteOriginalImage(String imageId) async {
    final deleted = await widget.onDeleteOriginalImage(imageId);
    if (deleted && mounted) {
      setState(() => _deletedImageIds.add(imageId));
    }
    return deleted;
  }
}

class _FolderColorOption {
  const _FolderColorOption(this.key, this.color, this.darkColor);

  final String key;
  final Color color;
  final Color darkColor;
}

const List<_FolderColorOption> _folderColorOptions = [
  _FolderColorOption('butter', Color(0xFFFFD86B), Color(0xFFE9AE2F)),
  _FolderColorOption('peach', Color(0xFFFFB199), Color(0xFFE8795F)),
  _FolderColorOption('rose', Color(0xFFFF9DB8), Color(0xFFE85D88)),
  _FolderColorOption('lavender', Color(0xFFC9B7FF), Color(0xFF8B6FE8)),
  _FolderColorOption('sky', Color(0xFF9BD4FF), Color(0xFF4C9DD8)),
  _FolderColorOption('mint', Color(0xFF9BE7C1), Color(0xFF4CB783)),
  _FolderColorOption('sand', Color(0xFFE6C79C), Color(0xFFC29055)),
  _FolderColorOption('slate', Color(0xFFC7CFDA), Color(0xFF8C98A8)),
];

_FolderColorOption _folderColorFor(String? key) {
  return _folderColorOptions.firstWhere(
    (option) => option.key == key,
    orElse: () => _folderColorOptions.first,
  );
}

class _FolderStrip extends StatelessWidget {
  const _FolderStrip({
    required this.stack,
    required this.folders,
    required this.allStackKeys,
    required this.stackNames,
    required this.folderColors,
    required this.selectedIds,
    required this.onAddSelectedToFolder,
    required this.onDeleteFolder,
    required this.onRenameFolder,
    required this.onChangeFolderColor,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onMoveImage,
    required this.onSaveSetMemo,
    required this.onAssignImageToSet,
  });

  final StackItem stack;
  final List<ScreenshotSet> folders;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> folderColors;
  final Set<String> selectedIds;
  final Future<void> Function(ScreenshotSet folder) onAddSelectedToFolder;
  final Future<void> Function(ScreenshotSet folder) onDeleteFolder;
  final Future<void> Function(ScreenshotSet folder, String name) onRenameFolder;
  final Future<void> Function(String folderKey, String colorKey)
  onChangeFolderColor;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: folders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final folder = folders[index];
          return _FolderCard(
            stack: stack,
            folder: folder,
            colorKey: folderColors[folder.key],
            allStackKeys: allStackKeys,
            stackNames: stackNames,
            selectedIds: selectedIds,
            onAddSelected: () => onAddSelectedToFolder(folder),
            onDelete: () => onDeleteFolder(folder),
            onRename: (name) => onRenameFolder(folder, name),
            onChangeColor: (colorKey) =>
                onChangeFolderColor(folder.key, colorKey),
            onExcludeImage: onExcludeImage,
            onDeleteOriginalImage: onDeleteOriginalImage,
            onMoveImage: onMoveImage,
            onSaveSetMemo: onSaveSetMemo,
            onAssignImageToSet: onAssignImageToSet,
          );
        },
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.stack,
    required this.folder,
    required this.colorKey,
    required this.allStackKeys,
    required this.stackNames,
    required this.selectedIds,
    required this.onAddSelected,
    required this.onDelete,
    required this.onRename,
    required this.onChangeColor,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onMoveImage,
    required this.onSaveSetMemo,
    required this.onAssignImageToSet,
  });

  final StackItem stack;
  final ScreenshotSet folder;
  final String? colorKey;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Set<String> selectedIds;
  final Future<void> Function() onAddSelected;
  final Future<void> Function() onDelete;
  final Future<void> Function(String name) onRename;
  final Future<void> Function(String colorKey) onChangeColor;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;

  @override
  Widget build(BuildContext context) {
    final option = _folderColorFor(colorKey);
    final title = _folderName(folder);
    final previews = folder.items.take(3).toList();
    return InkWell(
      onLongPress: () => _showFolderActions(context),
      onTap: selectedIds.isNotEmpty
          ? onAddSelected
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _SearchSetResultScreen(
                  stack: stack,
                  set: folder,
                  allStackKeys: allStackKeys,
                  stackNames: stackNames,
                  onExcludeImage: onExcludeImage,
                  onDeleteOriginalImage: onDeleteOriginalImage,
                  onMoveImage: onMoveImage,
                  onSaveSetMemo: onSaveSetMemo,
                  onAssignImageToSet: onAssignImageToSet,
                  onDeleteFolder: onDelete,
                ),
              ),
            ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 112,
        height: 92,
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: option.color.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: option.darkColor.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF1A1C1C),
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: _FolderPreviewStack(items: previews),
            ),
            Positioned(
              right: 0,
              bottom: 1,
              child: Text(
                '${folder.items.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF424754).withValues(alpha: 0.62),
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFolderActions(BuildContext context) async {
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
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('그룹 이름 변경'),
                onTap: () => Navigator.pop(context, 'rename'),
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('폴더 색상 변경'),
                onTap: () => Navigator.pop(context, 'color'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFE05656),
                ),
                title: const Text(
                  '그룹 삭제',
                  style: TextStyle(color: Color(0xFFE05656)),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'delete') {
      await onDelete();
    } else if (action == 'rename') {
      if (!context.mounted) return;
      final name = await _showShotlyTextDialog(
        context: context,
        title: '그룹 이름 변경',
        initialValue: _folderName(folder),
        hintText: '그룹 이름',
        primaryLabel: '저장',
      );
      if (name != null) await onRename(name);
    } else if (action == 'color') {
      await _showColorPicker(context);
    }
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '폴더 색상',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final option in _folderColorOptions)
                    _FolderColorDot(
                      option: option,
                      selected: _folderColorFor(colorKey).key == option.key,
                      onTap: () => Navigator.pop(context, option.key),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await onChangeColor(picked);
  }
}

class _FolderPreviewStack extends StatelessWidget {
  const _FolderPreviewStack({required this.items});

  final List<ScreenshotItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: 28,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          size: 17,
          color: Color(0xFF727785),
        ),
      );
    }
    return SizedBox(
      width: 56,
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final entry in items.indexed)
            Positioned(
              left: entry.$1 * 14,
              bottom: 0,
              child: Container(
                width: 27,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.82),
                    width: 1.4,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _Thumb(path: entry.$2.thumbnailPath, radius: 7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FolderColorDot extends StatelessWidget {
  const _FolderColorDot({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _FolderColorOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: option.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF1A1C1C) : Colors.white,
            width: selected ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: option.darkColor.withValues(alpha: 0.20),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: selected
            ? const Icon(
                Icons.check_rounded,
                size: 20,
                color: Color(0xFF1A1C1C),
              )
            : null,
      ),
    );
  }
}

class _SetDateSection extends StatelessWidget {
  const _SetDateSection({
    required this.dateLabel,
    required this.sets,
    required this.allStackKeys,
    required this.stackNames,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
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
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
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
              onExcludeImage: onExcludeImage,
              onDeleteOriginalImage: onDeleteOriginalImage,
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
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onMoveImage,
    required this.selectedIds,
    required this.selectionMode,
    required this.onToggleSelection,
    required this.showLocalActionBar,
    required this.onSaveMemo,
    required this.onAssignImageToSet,
    this.showTitle = true,
    this.suppressHeader = false,
    this.headerLabel,
    this.onHeaderTap,
    this.headerCheckValue,
    this.showHeaderCheckbox = false,
    this.viewerItems,
  });

  final ScreenshotSet set;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Set<String> selectedIds;
  final bool selectionMode;
  final ValueChanged<String> onToggleSelection;
  final bool showLocalActionBar;
  final Future<void> Function(String setKey, String memo) onSaveMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;
  final bool showTitle;
  final bool suppressHeader;
  final String? headerLabel;
  final VoidCallback? onHeaderTap;
  final bool? headerCheckValue;
  final bool showHeaderCheckbox;
  final List<ScreenshotItem>? viewerItems;
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
      onExcludeImage: widget.onExcludeImage,
      onDeleteOriginalImage: widget.onDeleteOriginalImage,
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
                title: _memoText.trim().isEmpty ? '메모 추가' : '메모 수정',
                onTap: () => Navigator.of(context).pop('memo'),
              ),
              if (_memoText.trim().isNotEmpty)
                _AddMenuTile(
                  icon: Icons.notes_rounded,
                  title: '메모 삭제',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('메모를 저장하지 못했습니다: $e')));
    }
  }

  Future<String?> _editMemo(BuildContext context) async {
    final value = await _showShotlyTextDialog(
      context: context,
      title: 'Set 메모',
      initialValue: _memoText,
      hintText: '예: 온보딩 플로우',
      primaryLabel: '저장',
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
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onMoveImage,
    this.selectedIds,
    this.selectionMode,
    this.onToggleSelection,
    this.showLocalActionBar = true,
    this.onSetAction,
    this.onEditMemo,
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
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Set<String>? selectedIds;
  final bool? selectionMode;
  final ValueChanged<String>? onToggleSelection;
  final bool showLocalActionBar;
  final VoidCallback? onSetAction;
  final VoidCallback? onEditMemo;

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
            onCancel: () => setState(_selectedIds.clear),
            onShare: _shareSelected,
            onDelete: () => _deleteSelected(context),
            onMove: () => _moveSelected(context),
            onHide: _hideSelected,
          ),
        ],
      ],
    );
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
      title: '이동할 Stack',
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
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '원본 파일 삭제',
      body:
          '선택한 ${_effectiveSelectedIds.length}장을 Shotly뿐 아니라 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
      primaryLabel: '삭제',
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
  }
}

class _HeaderSelectionCircle extends StatelessWidget {
  const _HeaderSelectionCircle({required this.value, required this.onTap});

  final bool? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = value == true;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2170E4)
              : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? const Color(0xFF2170E4) : const Color(0xFFD5D8DF),
          ),
        ),
        child: selected
            ? Icon(Icons.check_rounded, size: 13, color: Colors.white)
            : null,
      ),
    );
  }
}

class _SelectableThumb extends StatelessWidget {
  const _SelectableThumb({
    required this.item,
    required this.selected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
  });

  final ScreenshotItem item;
  final bool selected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: _Thumb(
              path: item.thumbnailPath,
              radius: 14,
              borderColor: selected
                  ? const Color(0xFF2170E4)
                  : Colors.transparent,
            ),
          ),
          if (selecting)
            Positioned(
              right: 7,
              top: 7,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF2170E4)
                      : Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF2170E4)
                        : const Color(0xFFD5D8DF),
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.onCancel,
    required this.onShare,
    required this.onDelete,
    required this.onMove,
    required this.onHide,
    this.onFolder,
  });
  final VoidCallback onCancel;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onMove;
  final VoidCallback onHide;
  final VoidCallback? onFolder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SelectionActionButton(
                  icon: Icons.drive_file_move_rounded,
                  label: '이동',
                  onTap: onMove,
                ),
                if (onFolder != null)
                  _SelectionActionButton(
                    icon: Icons.grid_view_rounded,
                    label: '그룹',
                    onTap: onFolder!,
                  ),
                _SelectionActionButton(
                  icon: Icons.share_rounded,
                  label: '공유',
                  onTap: onShare,
                ),
                _SelectionActionButton(
                  icon: Icons.visibility_off_rounded,
                  label: '숨기기',
                  onTap: onHide,
                ),
                _SelectionActionButton(
                  icon: Icons.delete_rounded,
                  label: '삭제',
                  onTap: onDelete,
                  destructive: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(999),
            child: const SizedBox(
              width: 24,
              height: 40,
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: Color(0xFF727785),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionActionButton extends StatelessWidget {
  const _SelectionActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFB42318)
        : const Color(0xFF424754);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
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
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF727785)),
        ),
      ),
    );
  }
}
