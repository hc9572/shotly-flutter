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
    required this.favoriteImageIds,
    required this.visualFeatures,
    required this.onRenameStack,
    required this.onHideStack,
    required this.onTogglePinStack,
    required this.pinned,
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
  final Future<void> Function(String stackKey) onTogglePinStack;
  final bool pinned;
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
            favoriteImageIds: favoriteImageIds,
            visualFeatures: visualFeatures,
            onRenameStack: onRenameStack,
            onHideStack: onHideStack,
            onExcludeImage: onExcludeImage,
            onDeleteOriginalImage: onDeleteOriginalImage,
            onDeleteOriginalImages: onDeleteOriginalImages,
            onToggleFavoriteImage: onToggleFavoriteImage,
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
          title: pinned ? st('고정 해제', 'Unpin') : st('고정 하기', 'Pin'),
        ),
        _ShotlyActionItem(
          value: 'rename',
          icon: Icons.edit_rounded,
          title: st('앱 이름 수정', 'Rename app'),
        ),
        _ShotlyActionItem(
          value: 'hide',
          icon: Icons.visibility_off_rounded,
          title: st('앱 숨기기', 'Hide app'),
        ),
      ],
    );
    if (action == 'pin') await onTogglePinStack(stack.key);
    if (action == 'rename' && context.mounted) {
      final name = await _showShotlyTextDialog(
        context: context,
        title: st('앱 이름 수정', 'Rename app'),
        initialValue: stack.name,
        hintText: st('앱 이름', 'App name'),
        primaryLabel: st('저장', 'Save'),
      );
      if (name != null) await onRenameStack(stack.key, name);
    }
    if (action == 'hide') await onHideStack(stack.key);
  }
}
