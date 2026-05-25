part of 'main.dart';

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
  bool _smartCleanRunning = false;
  double? _smartCleanProgress;
  String? _smartCleanMessage;
  List<_SmartCleanCandidate> _smartCleanCandidates = const [];
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
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints.tightFor(
                                width: 32,
                                height: 40,
                              ),
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
                        const SizedBox(height: 16),
                        _SmartCleanPanel(
                          running: _smartCleanRunning,
                          progress: _smartCleanProgress,
                          message: _smartCleanMessage,
                          candidates: _smartCleanCandidates,
                          onAnalyze: () => _runSmartClean(visibleItems),
                          onCandidateTap: _handleSmartCleanCandidate,
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
                            onCreateFolderFromSelected: _createFolderFromIds,
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
                          message: '아직 이미지가 없는 앱이에요',
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

  Future<void> _runSmartClean(List<ScreenshotItem> visibleItems) async {
    if (_smartCleanRunning) return;
    final allTargetItems =
        visibleItems.where((item) => item.thumbnailPath.isNotEmpty).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final targetItems = allTargetItems.take(80).toList();
    if (targetItems.length < 2) {
      setState(() {
        _smartCleanCandidates = const [];
        _smartCleanMessage = '분석할 이미지가 부족해요';
      });
      return;
    }

    setState(() {
      _smartCleanRunning = true;
      _smartCleanProgress = null;
      _smartCleanMessage = allTargetItems.length > targetItems.length
          ? '최근 ${targetItems.length}장을 가볍게 훑는 중'
          : '${targetItems.length}장을 가볍게 훑는 중';
      _smartCleanCandidates = const [];
    });

    await Future<void>.delayed(const Duration(milliseconds: 80));
    List<VisualSmartCleanResult> rawCandidates;
    try {
      rawCandidates = await analyzeVisualSmartClean([
        for (final item in targetItems)
          VisualSmartCleanInput(
            id: item.id,
            path: item.thumbnailPath,
            dateMillis: item.date.millisecondsSinceEpoch,
          ),
      ]).timeout(const Duration(seconds: 18));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _smartCleanRunning = false;
        _smartCleanProgress = 1;
        _smartCleanCandidates = const [];
        _smartCleanMessage = '분석 시간이 길어졌어요. 잠시 후 다시 시도해봐요';
      });
      return;
    }
    final itemById = {for (final item in targetItems) item.id: item};
    final candidates = [
      for (final candidate in rawCandidates)
        _SmartCleanCandidate(
          type: candidate.type == 'duplicates'
              ? _SmartCleanCandidateType.duplicates
              : _SmartCleanCandidateType.flow,
          title: candidate.title,
          subtitle: candidate.subtitle,
          items: [
            for (final id in candidate.imageIds)
              if (itemById[id] != null) itemById[id]!,
          ],
        ),
    ].where((candidate) => candidate.items.length >= 2).toList();
    if (!mounted) return;
    setState(() {
      _smartCleanRunning = false;
      _smartCleanProgress = 1;
      _smartCleanCandidates = candidates;
      _smartCleanMessage = candidates.isEmpty
          ? '정리할 만한 후보가 아직 없어요'
          : '${candidates.length}개 후보를 찾았어요';
    });
  }

  Future<void> _handleSmartCleanCandidate(
    _SmartCleanCandidate candidate,
  ) async {
    final reviewedItems = await Navigator.of(context)
        .push<List<ScreenshotItem>>(
          MaterialPageRoute(
            builder: (_) => _SmartCleanReviewScreen(candidate: candidate),
          ),
        );
    if (!mounted || reviewedItems == null || reviewedItems.length < 2) return;

    if (candidate.type == _SmartCleanCandidateType.duplicates) {
      final ids = reviewedItems.map((item) => item.id).toList();
      final confirmed = await _showShotlyConfirmDialog(
        context: context,
        title: '중복 화면 삭제',
        body: '선택한 ${ids.length}장을 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
        primaryLabel: '삭제',
        destructive: true,
      );
      if (confirmed == true &&
          await widget.onDeleteOriginalImages(ids) &&
          mounted) {
        setState(() {
          _deletedImageIds.addAll(ids);
          _smartCleanCandidates = const [];
        });
      }
      return;
    }

    final name = await _showShotlyTextDialog(
      context: context,
      title: '폴더 만들기',
      hintText: '폴더 이름',
      primaryLabel: '묶기',
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await _createFolderFromIds(
      trimmed,
      reviewedItems.map((item) => item.id).toList(),
    );
  }

  Future<void> _hideSelected() async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '선택한 사진 숨기기',
      body:
          '선택한 ${_selectedImageIds.length}장을 Shotly 목록에서 숨길까요? 숨긴 항목은 설정에서 다시 확인할 수 있어요.',
      primaryLabel: '숨기기',
    );
    if (confirmed != true) return;
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
      title: '이동할 폴더',
      items: [
        const _ShotlyActionItem(
          value: '__new_folder__',
          icon: Icons.grid_view_rounded,
          title: '새 폴더 만들기',
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
        title: '폴더 만들기',
        hintText: '폴더 이름',
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
      title: '폴더 만들기',
      hintText: '폴더 이름',
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

  Future<void> _createFolderFromIds(String name, List<String> ids) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || ids.isEmpty) return;
    final folderKey = await _createFolderWithName(trimmed);
    final nextAssignments = <String, String>{};
    for (final id in ids) {
      nextAssignments[id] = _addAssignmentKey(
        _detailSetAssignments[id],
        folderKey,
      );
    }
    if (mounted) setState(() => _detailSetAssignments.addAll(nextAssignments));
    for (final id in ids) {
      await widget.onAssignImageToSet(id, folderKey);
    }
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
      title: '폴더 삭제',
      body: '폴더만 삭제하고 사진은 미정리 화면으로 되돌릴까요?',
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
      title: '이동할 앱',
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
      title: '앱 이름 수정',
      initialValue: _stackName,
      hintText: '앱 이름',
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
                title: _selectedImageIds.isEmpty ? '폴더 추가' : '선택 이미지로 폴더 추가',
                onTap: () => Navigator.of(context).pop('folder'),
              ),
              _AddMenuTile(
                icon: Icons.edit_rounded,
                title: '앱 이름 수정',
                onTap: () => Navigator.of(context).pop('rename'),
              ),
              _AddMenuTile(
                icon: Icons.visibility_off_rounded,
                title: '앱 숨기기',
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
