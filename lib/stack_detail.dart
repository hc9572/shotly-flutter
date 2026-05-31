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
    required this.favoriteImageIds,
    required this.visualFeatures,
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

  final StackItem stack;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> setMemos;
  final Map<String, String> folderNames;
  final Map<String, String> folderColors;
  final Map<String, String> setAssignments;
  final Set<String> favoriteImageIds;
  final Map<String, VisualFeature> visualFeatures;
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
  State<StackDetailScreen> createState() => _StackDetailScreenState();
}

class _SmartCleanSessionCache {
  const _SmartCleanSessionCache({
    required this.candidates,
    required this.message,
    required this.analyzed,
    required this.expanded,
  });

  final List<_SmartCleanCandidate> candidates;
  final String? message;
  final bool analyzed;
  final bool expanded;
}

final Map<String, _SmartCleanSessionCache> _smartCleanSessionCache =
    <String, _SmartCleanSessionCache>{};

class _StackDetailScreenState extends State<StackDetailScreen> {
  final Set<String> _deletedImageIds = <String>{};
  final Set<String> _selectedImageIds = <String>{};
  bool _isSelectionMode = false;
  bool _smartCleanRunning = false;
  bool _smartCleanAnalyzed = false;
  bool _smartCleanExpanded = true;
  double? _smartCleanProgress;
  String? _smartCleanMessage;
  List<_SmartCleanCandidate> _smartCleanCandidates = const [];
  final Map<String, VisualFeature> _smartFeatureCache = {};
  final List<ScreenshotItem> _addedItems = <ScreenshotItem>[];
  late Map<String, String> _detailFolderNames;
  late Map<String, String> _detailFolderColors;
  late Map<String, String> _detailSetAssignments;

  String get _stackName =>
      widget.stackNames[widget.stack.key] ?? widget.stack.name;

  List<ScreenshotItem> get _visibleItems => [
    ..._addedItems,
    ...widget.stack.items,
  ].where((item) => !_deletedImageIds.contains(item.id)).toList();

  List<ScreenshotSet> get _currentFolderSets => _buildScreenshotSets(
    widget.stack.key,
    _visibleItems,
    widget.setMemos,
    _detailFolderNames,
    _detailSetAssignments,
  ).where((set) => _isFolderSetKey(set.key)).toList();

  @override
  void initState() {
    super.initState();
    _detailFolderNames = {...widget.folderNames};
    _detailFolderColors = {...widget.folderColors};
    _detailSetAssignments = {...widget.setAssignments};
    _smartFeatureCache.addAll(widget.visualFeatures);
    final cached = _smartCleanSessionCache[widget.stack.key];
    if (cached != null) {
      _smartCleanCandidates = cached.candidates;
      _smartCleanMessage = cached.message;
      _smartCleanAnalyzed = cached.analyzed;
      _smartCleanExpanded = cached.expanded;
    }
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
    final visibleItems = _visibleItems;
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
                                onPressed: () => _showStackAddActions(context),
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
                              ? st(
                                  '${_selectedImageIds.length}개 선택',
                                  '${_selectedImageIds.length} selected',
                                )
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
                          analyzed: _smartCleanAnalyzed,
                          expanded: _smartCleanExpanded,
                          progress: _smartCleanProgress,
                          message: _smartCleanMessage,
                          candidates: _smartCleanCandidates,
                          onAnalyze: () => _runSmartClean(visibleItems),
                          onToggleExpanded: _toggleSmartCleanExpanded,
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
                            favoriteImageIds: widget.favoriteImageIds,
                            onToggleFavoriteImage: widget.onToggleFavoriteImage,
                            onMoveImage: widget.onMoveImage,
                            onSaveSetMemo: widget.onSaveSetMemo,
                            onAssignImageToSet: _assignImageToSetFromFolder,
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
                        return _EmptyStackDetail(
                          message: st(
                            '아직 이미지가 없는 앱이에요',
                            'This app has no images yet',
                          ),
                        );
                      }
                      return _SetDateSection(
                        dateLabel: dateGroups[index].dateLabel,
                        sets: dateGroups[index].sets,
                        allStackKeys: widget.allStackKeys,
                        stackNames: widget.stackNames,
                        favoriteImageIds: widget.favoriteImageIds,
                        onExcludeImage: widget.onExcludeImage,
                        onDeleteOriginalImage: _deleteOriginalImage,
                        onToggleFavoriteImage: widget.onToggleFavoriteImage,
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

  void _toggleSmartCleanExpanded() {
    setState(() => _smartCleanExpanded = !_smartCleanExpanded);
    _saveSmartCleanSessionCache();
  }

  void _saveSmartCleanSessionCache() {
    _smartCleanSessionCache[widget.stack.key] = _SmartCleanSessionCache(
      candidates: _smartCleanCandidates,
      message: _smartCleanMessage,
      analyzed: _smartCleanAnalyzed,
      expanded: _smartCleanExpanded,
    );
  }

  void _removeSmartCleanCandidate(_SmartCleanCandidate candidate) {
    setState(() {
      _smartCleanCandidates = _smartCleanCandidates
          .where((item) => !identical(item, candidate))
          .toList();
      _smartCleanMessage = _smartCleanCandidates.isEmpty
          ? st(
              '남은 후보가 없어요. 필요하면 다시 분석해요',
              'No candidates left. Analyze again if needed.',
            )
          : st(
              '${_smartCleanCandidates.length}개 후보가 남았어요',
              '${_smartCleanCandidates.length} candidates left',
            );
      _smartCleanExpanded = _smartCleanCandidates.isNotEmpty;
    });
    _saveSmartCleanSessionCache();
  }

  Future<void> _runSmartClean(List<ScreenshotItem> visibleItems) async {
    if (_smartCleanRunning) return;
    final targetItems =
        visibleItems.where((item) => item.thumbnailPath.isNotEmpty).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    if (targetItems.length < 2) {
      setState(() {
        _smartCleanCandidates = const [];
        _smartCleanMessage = st(
          '분석할 이미지가 부족해요',
          'Not enough images to analyze',
        );
      });
      return;
    }

    final featureItems = _smartCleanFeatureItems(targetItems);
    final missingFeatureCount = featureItems
        .where((item) => !_smartFeatureCache.containsKey(item.id))
        .length;

    setState(() {
      _smartCleanRunning = true;
      _smartCleanAnalyzed = true;
      _smartCleanExpanded = true;
      _smartCleanProgress = null;
      _smartCleanMessage = missingFeatureCount > 0
          ? st(
              '이미지 분석 중...(0/$missingFeatureCount)',
              'Analyzing images...(0/$missingFeatureCount)',
            )
          : st('이미지 분석 중...', 'Analyzing images...');
      _smartCleanCandidates = const [];
    });

    await Future<void>.delayed(const Duration(milliseconds: 80));
    unawaited(ShotlyAnalytics.log('screen_analysis_started'));
    debugPrint('SmartClean start: target=${targetItems.length}');
    final startedAt = DateTime.now();
    final inputs = [
      for (final item in targetItems)
        VisualSmartCleanInput(
          id: item.id,
          path: item.thumbnailPath,
          dateMillis: item.date.millisecondsSinceEpoch,
          assignmentRaw: _detailSetAssignments[item.id] ?? '',
          folderName: _folderNameForAssignedItem(item.id),
        ),
    ];
    List<VisualSmartCleanResult> rawCandidates;
    try {
      await _ensureSmartCleanFeatures(featureItems);
      rawCandidates = await analyzeVisualSmartCleanFromFeatures(
        inputs,
        _smartFeatureCache,
      );
      debugPrint(
        'SmartClean done: candidates=${rawCandidates.length} features=${_smartFeatureCache.length} elapsed=${DateTime.now().difference(startedAt).inMilliseconds}ms',
      );
    } catch (error, stackTrace) {
      unawaited(ShotlyAnalytics.log('screen_analysis_failed'));
      debugPrint('SmartClean failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _smartCleanRunning = false;
        _smartCleanProgress = 1;
        _smartCleanAnalyzed = true;
        _smartCleanCandidates = const [];
        _smartCleanMessage = st(
          '분석 중 문제가 생겼어요',
          'Something went wrong during analysis',
        );
      });
      _saveSmartCleanSessionCache();
      return;
    }
    final itemById = {for (final item in targetItems) item.id: item};
    final candidates = [
      for (final candidate in rawCandidates)
        _SmartCleanCandidate(
          type: switch (candidate.type) {
            'duplicates' => _SmartCleanCandidateType.duplicates,
            'existingFolder' => _SmartCleanCandidateType.existingFolder,
            _ => _SmartCleanCandidateType.flow,
          },
          title: _smartCleanTitleFor(candidate),
          subtitle: _smartCleanSubtitleFor(candidate),
          items: [
            for (final id in candidate.imageIds)
              if (itemById[id] != null) itemById[id]!,
          ],
          targetFolderKey: candidate.targetFolderKey,
          targetFolderName: candidate.targetFolderName,
          selectableImageIds: candidate.selectableImageIds.toSet(),
        ),
    ].where((candidate) => candidate.items.length >= 2).toList();
    if (!mounted) return;
    unawaited(ShotlyAnalytics.log('screen_analysis_completed'));
    setState(() {
      _smartCleanRunning = false;
      _smartCleanProgress = 1;
      _smartCleanAnalyzed = true;
      _smartCleanExpanded = candidates.isNotEmpty;
      _smartCleanCandidates = candidates;
      _smartCleanMessage = candidates.isEmpty
          ? st('정리할 후보가 없어요', 'No cleanup candidates found')
          : st(
              '${candidates.length}개 후보를 찾았어요',
              'Found ${candidates.length} candidates',
            );
    });
    _saveSmartCleanSessionCache();
  }

  String _smartCleanTitleFor(VisualSmartCleanResult candidate) =>
      switch (candidate.type) {
        'existingFolder' => st(
          '비슷한 화면 ${candidate.imageIds.length}장',
          '${candidate.imageIds.length} similar screens',
        ),
        'duplicates' => st(
          '비슷한 화면 ${candidate.imageIds.length}장',
          '${candidate.imageIds.length} similar screens',
        ),
        _ => st(
          '비슷한 화면 ${candidate.imageIds.length}장',
          '${candidate.imageIds.length} similar screens',
        ),
      };

  String _smartCleanSubtitleFor(VisualSmartCleanResult candidate) {
    if (candidate.type == 'existingFolder') {
      final folderName =
          candidate.targetFolderName ?? st('기존 폴더', 'Existing folder');
      return st(
        '$folderName 폴더와 비슷한 화면이에요',
        'Similar to the $folderName folder',
      );
    }
    return st(
      '삭제하거나 폴더로 묶을 수 있는 화면이에요',
      'Screens you can delete or make into a folder',
    );
  }

  List<ScreenshotItem> _smartCleanFeatureItems(
    List<ScreenshotItem> sortedItems,
  ) {
    final itemsById = <String, ScreenshotItem>{};
    final seenFolderKeys = <String>{};
    for (final item in sortedItems) {
      final folderKeys = _assignmentKeys(
        _detailSetAssignments[item.id],
      ).where(_isFolderSetKey).toList();
      if (folderKeys.isEmpty) {
        itemsById[item.id] = item;
        continue;
      }
      for (final folderKey in folderKeys) {
        if (seenFolderKeys.add(folderKey)) {
          itemsById[item.id] = item;
        }
      }
    }
    return itemsById.values.toList();
  }

  Future<void> _ensureSmartCleanFeatures(List<ScreenshotItem> items) async {
    const batchSize = 10;
    final candidates = items
        .where((item) => !_smartFeatureCache.containsKey(item.id))
        .toList();
    if (candidates.isEmpty) {
      if (mounted) setState(() => _smartCleanProgress = 1);
      return;
    }

    var processed = 0;
    for (var start = 0; start < candidates.length; start += batchSize) {
      final end = math.min(start + batchSize, candidates.length);
      final batch = candidates.sublist(start, end);
      final features = await extractVisualFeatures({
        for (final item in batch) item.id: item.thumbnailPath,
      });
      _smartFeatureCache.addAll(features);
      widget.visualFeatures.addAll(features);
      processed = end;
      debugPrint(
        'SmartClean feature batch: $processed/${candidates.length} +${features.length}',
      );
      if (!mounted) return;
      setState(() {
        _smartCleanProgress = processed / candidates.length;
        _smartCleanMessage = st(
          '이미지 분석 중...($processed/${candidates.length})',
          'Analyzing images...($processed/${candidates.length})',
        );
      });
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> _handleSmartCleanCandidate(
    _SmartCleanCandidate candidate,
  ) async {
    final reviewResult = await Navigator.of(context)
        .push<_SmartCleanReviewResult>(
          MaterialPageRoute(
            builder: (_) => _SmartCleanReviewScreen(candidate: candidate),
          ),
        );
    if (!mounted || reviewResult == null || reviewResult.items.isEmpty) return;

    final ids = reviewResult.items.map((item) => item.id).toList();
    if (reviewResult.action == _SmartCleanReviewAction.delete) {
      final confirmed = await _showShotlyConfirmDialog(
        context: context,
        title: st('선택한 화면 삭제', 'Delete selected screens'),
        body: st(
          '선택한 ${ids.length}장을 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
          'Delete ${ids.length} selected originals from your device gallery? This can’t be undone.',
        ),
        primaryLabel: st('삭제', 'Delete'),
        destructive: true,
      );
      if (confirmed == true &&
          await widget.onDeleteOriginalImages(ids) &&
          mounted) {
        setState(() {
          _deletedImageIds.addAll(ids);
          _smartCleanMessage = st(
            '${ids.length}장을 삭제했어요',
            'Deleted ${ids.length} originals',
          );
        });
        _removeSmartCleanCandidate(candidate);
      }
      return;
    }

    if (ids.length < 2 &&
        candidate.type != _SmartCleanCandidateType.existingFolder) {
      return;
    }
    final moved = await _showSmartCleanFolderPicker(ids);
    if (moved) _removeSmartCleanCandidate(candidate);
  }

  String _folderNameForAssignedItem(String imageId) {
    for (final key in _assignmentKeys(_detailSetAssignments[imageId])) {
      if (_isFolderSetKey(key)) {
        return _detailFolderNames[key] ?? st('기존 폴더', 'Existing folder');
      }
    }
    return '';
  }

  Future<bool> _showSmartCleanFolderPicker(List<String> ids) async {
    if (ids.isEmpty) return false;
    final folders = _currentFolderSets;
    final target = await _showShotlyActionSheet<String>(
      context,
      title: st('폴더로 묶기', 'Make folder'),
      items: [
        _ShotlyActionItem(
          value: '__new_folder__',
          icon: Icons.create_new_folder_rounded,
          title: st('새 폴더로 묶기', 'Create new folder'),
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
    if (target == null || !mounted) return false;
    var message = '';
    if (target == '__new_folder__') {
      final config = await _showCreateFolderFlow(context);
      if (config == null) return false;
      await _createFolderFromIds(config.name, ids, colorKey: config.colorKey);
      message = st(
        '${ids.length}장을 새 폴더로 묶었어요',
        'Grouped ${ids.length} photos into a new folder',
      );
    } else {
      await _addIdsToExistingFolder(target, ids);
      final folderName = folders
          .where((folder) => folder.key == target)
          .map(_folderName)
          .firstOrNull;
      final targetFolderName = folderName ?? st('기존 폴더', 'Existing folder');
      message = st(
        '${ids.length}장을 $targetFolderName에 묶었어요',
        'Grouped ${ids.length} photos into $targetFolderName',
      );
    }
    if (mounted) {
      setState(() {
        _smartCleanCandidates = const [];
        _smartCleanMessage = message;
      });
    }
    return true;
  }

  Future<void> _addIdsToExistingFolder(
    String folderKey,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return;
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

  Future<void> _hideSelected() async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: st('선택한 사진 숨기기', 'Hide selected photos'),
      body: st(
        '선택한 ${_selectedImageIds.length}장을 Shotly 목록에서 숨길까요? 숨긴 항목은 설정에서 다시 확인할 수 있어요.',
        'Hide ${_selectedImageIds.length} selected photos from Shotly? Hidden items can be restored in Settings.',
      ),
      primaryLabel: st('숨기기', 'Hide'),
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

  Future<void> _showStackAddActions(BuildContext context) async {
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
                icon: Icons.add_photo_alternate_rounded,
                title: st('사진 추가', 'Add photo'),
                onTap: () => Navigator.of(context).pop('photo'),
              ),
              _AddMenuTile(
                icon: Icons.create_new_folder_rounded,
                title: st('폴더 추가', 'Add folder'),
                onTap: () => Navigator.of(context).pop('folder'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'photo') {
      await _addImageToCurrentStack();
    } else if (action == 'folder') {
      await _createFolder(context);
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
      title: st('폴더 선택', 'Choose folder'),
      items: [
        _ShotlyActionItem(
          value: '__new_folder__',
          icon: Icons.create_new_folder_rounded,
          title: st('새 폴더 만들기', 'Create new folder'),
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
      final config = await _showCreateFolderFlow(context);
      if (config == null) return;
      folderKey = await _createFolderWithName(
        config.name,
        colorKey: config.colorKey,
      );
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
    final config = await _showCreateFolderFlow(context);
    if (config == null) return null;
    return _createFolderWithName(config.name, colorKey: config.colorKey);
  }

  Future<({String name, String colorKey})?> _showCreateFolderFlow(
    BuildContext context,
  ) async {
    final name = await _showShotlyTextDialog(
      context: context,
      title: st('폴더 만들기', 'Create folder'),
      hintText: st('폴더 이름', 'Folder name'),
      primaryLabel: st('다음', 'Next'),
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty || !context.mounted) return null;
    final colorKey = await _showFolderColorPicker(
      context,
      initialColorKey: _folderColorOptions.first.key,
      title: st('폴더 색상 선택', 'Choose folder color'),
      primaryLabel: st('완료', 'Done'),
    );
    if (colorKey == null) return null;
    return (name: trimmed, colorKey: colorKey);
  }

  Future<String?> _showFolderColorPicker(
    BuildContext context, {
    required String initialColorKey,
    required String title,
    required String primaryLabel,
  }) async {
    var selected = _folderColorFor(initialColorKey).key;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
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
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final option in _folderColorOptions)
                      _FolderColorDot(
                        option: option,
                        selected: option.key == selected,
                        onTap: () => setModalState(() => selected = option.key),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF111111),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      primaryLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _createFolderWithName(String name, {String? colorKey}) async {
    final folderKey = _buildFolderKey(widget.stack.key);
    setState(() {
      _detailFolderNames[folderKey] = name;
      if (colorKey != null && colorKey.trim().isNotEmpty) {
        _detailFolderColors[folderKey] = colorKey;
      }
    });
    await widget.onSaveFolderName(folderKey, name);
    if (colorKey != null && colorKey.trim().isNotEmpty) {
      await widget.onSaveFolderColor(folderKey, colorKey);
    }
    return folderKey;
  }

  Future<void> _assignImageToSetFromFolder(
    String imageId,
    String setKey,
  ) async {
    final next = setKey.startsWith(_removeAssignmentPrefix)
        ? _removeAssignmentKey(
            _detailSetAssignments[imageId],
            setKey.substring(_removeAssignmentPrefix.length),
          )
        : setKey.isEmpty
        ? null
        : _addAssignmentKey(_detailSetAssignments[imageId], setKey);
    if (mounted) {
      setState(() {
        if (next == null || next.isEmpty) {
          _detailSetAssignments.remove(imageId);
        } else {
          _detailSetAssignments[imageId] = next;
        }
      });
    }
    await widget.onAssignImageToSet(imageId, setKey);
  }

  Future<void> _createFolderFromIds(
    String name,
    List<String> ids, {
    String? colorKey,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || ids.isEmpty) return;
    final folderKey = await _createFolderWithName(trimmed, colorKey: colorKey);
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
      title: st('폴더 삭제', 'Delete folder'),
      body: st(
        '폴더만 삭제하고 사진은 미정리 화면으로 되돌릴까요?',
        'Delete only the folder and return photos to uncategorized screens?',
      ),
      primaryLabel: st('삭제', 'Delete'),
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
      title: st('이동할 앱', 'Move to app'),
      items: [
        _ShotlyActionItem(
          value: _createMoveTargetKey,
          icon: Icons.add_rounded,
          title: st('새 앱 만들기', 'Create new app'),
        ),
        ...widget.allStackKeys
            .where((key) => key != widget.stack.key)
            .map(
              (key) => _ShotlyActionItem(
                value: key,
                icon: Icons.layers_rounded,
                title: widget.stackNames[key] ?? key,
              ),
            ),
      ],
    );
    if (target == null) return;
    if (target == _createMoveTargetKey && !context.mounted) return;
    final targetStack = target == _createMoveTargetKey
        ? await _showShotlyTextDialog(
            context: context,
            title: st('새 앱 만들기', 'Create new app'),
            hintText: st('앱 이름', 'App name'),
            primaryLabel: st('만들기', 'Create'),
            validator: (value) {
              final trimmed = value.trim();
              if (trimmed.isEmpty) return null;
              final exists =
                  widget.allStackKeys.any(
                    (key) => key.toLowerCase() == trimmed.toLowerCase(),
                  ) ||
                  widget.stackNames.values.any(
                    (name) => name.toLowerCase() == trimmed.toLowerCase(),
                  );
              return exists
                  ? st(
                      '이미 같은 이름의 앱이 있어요.',
                      'An app with this name already exists.',
                    )
                  : null;
            },
          )
        : target;
    final trimmedTarget = targetStack?.trim();
    if (trimmedTarget == null || trimmedTarget.isEmpty) return;
    final selected = _selectedImageIds.toList();
    for (final id in selected) {
      await widget.onMoveImage(id, trimmedTarget);
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
      title: st('원본 파일 삭제', 'Delete original file'),
      body: st(
        '선택한 ${_selectedImageIds.length}장을 Shotly뿐 아니라 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
        'Delete ${_selectedImageIds.length} selected originals from both Shotly and your device gallery? This can’t be undone.',
      ),
      primaryLabel: st('삭제', 'Delete'),
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
      title: st('앱 이름 수정', 'Rename app'),
      initialValue: _stackName,
      hintText: st('앱 이름', 'App name'),
      primaryLabel: st('저장', 'Save'),
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
                title: _selectedImageIds.isEmpty
                    ? st('폴더 추가', 'Add folder')
                    : st('선택 이미지로 폴더 추가', 'Create folder from selection'),
                onTap: () => Navigator.of(context).pop('folder'),
              ),
              _AddMenuTile(
                icon: Icons.edit_rounded,
                title: st('앱 이름 수정', 'Rename app'),
                onTap: () => Navigator.of(context).pop('rename'),
              ),
              _AddMenuTile(
                icon: Icons.visibility_off_rounded,
                title: st('앱 숨기기', 'Hide app'),
                onTap: () => Navigator.of(context).pop('hide'),
              ),
              _AddMenuTile(
                icon: Icons.delete_outline_rounded,
                title: st('앱 묶음 해제', 'Ungroup app'),
                onTap: () => Navigator.of(context).pop('delete'),
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
    if (action == 'rename') {
      await _renameStack(context);
      return;
    }
    if (action == 'hide') {
      await widget.onHideStack(widget.stack.key);
      if (context.mounted) Navigator.of(context).pop();
      return;
    }
    if (action == 'delete') {
      final confirmed = await _showShotlyConfirmDialog(
        context: context,
        title: st('앱 묶음 해제', 'Ungroup app'),
        body: st(
          '앱 묶음을 해제하면 포함된 스크린샷은 미분류로 돌아가요. 원본 사진은 삭제되지 않아요.',
          'Ungrouping this app moves its screenshots back to Unsorted. Original photos will not be deleted.',
        ),
        primaryLabel: st('해제', 'Ungroup'),
        destructive: true,
      );
      if (confirmed == true) {
        await widget.onDeleteStack(widget.stack);
        if (context.mounted) Navigator.of(context).pop();
      }
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
