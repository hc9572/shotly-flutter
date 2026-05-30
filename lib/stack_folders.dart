part of 'main.dart';

class _FolderColorOption {
  const _FolderColorOption(this.key, this.color, this.darkColor);

  final String key;
  final Color color;
  final Color darkColor;
}

const List<_FolderColorOption> _folderColorOptions = [
  _FolderColorOption('butter', Color(0xFFFFF4CC), Color(0xFFE9AE2F)),
  _FolderColorOption('peach', Color(0xFFFFE5DA), Color(0xFFE8795F)),
  _FolderColorOption('rose', Color(0xFFFFE1EA), Color(0xFFE85D88)),
  _FolderColorOption('lavender', Color(0xFFEEE7FF), Color(0xFF8B6FE8)),
  _FolderColorOption('sky', Color(0xFFE3F3FF), Color(0xFF4C9DD8)),
  _FolderColorOption('mint', Color(0xFFDCF8EA), Color(0xFF4CB783)),
  _FolderColorOption('sand', Color(0xFFF3E8D6), Color(0xFFC29055)),
  _FolderColorOption('slate', Color(0xFFEEF1F5), Color(0xFF8C98A8)),
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
    required this.favoriteImageIds,
    required this.selectedIds,
    required this.onAddSelectedToFolder,
    required this.onDeleteFolder,
    required this.onRenameFolder,
    required this.onChangeFolderColor,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onToggleFavoriteImage,
    required this.onMoveImage,
    required this.onSaveSetMemo,
    required this.onAssignImageToSet,
    required this.onCreateFolderFromSelected,
  });

  final StackItem stack;
  final List<ScreenshotSet> folders;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Map<String, String> folderColors;
  final Set<String> favoriteImageIds;
  final Set<String> selectedIds;
  final Future<void> Function(ScreenshotSet folder) onAddSelectedToFolder;
  final Future<void> Function(ScreenshotSet folder) onDeleteFolder;
  final Future<void> Function(ScreenshotSet folder, String name) onRenameFolder;
  final Future<void> Function(String folderKey, String colorKey)
  onChangeFolderColor;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId) onToggleFavoriteImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;
  final Future<void> Function(String name, List<String> imageIds)
  onCreateFolderFromSelected;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: [
            for (final folder in folders)
              SizedBox(
                width: cardWidth,
                child: _FolderCard(
                  stack: stack,
                  folder: folder,
                  colorKey: folderColors[folder.key],
                  allStackKeys: allStackKeys,
                  stackNames: stackNames,
                  folderMoveDestinations: folders,
                  favoriteImageIds: favoriteImageIds,
                  selectedIds: selectedIds,
                  onAddSelected: () => onAddSelectedToFolder(folder),
                  onDelete: () => onDeleteFolder(folder),
                  onRename: (name) => onRenameFolder(folder, name),
                  onChangeColor: (colorKey) =>
                      onChangeFolderColor(folder.key, colorKey),
                  onExcludeImage: onExcludeImage,
                  onDeleteOriginalImage: onDeleteOriginalImage,
                  onToggleFavoriteImage: onToggleFavoriteImage,
                  onMoveImage: onMoveImage,
                  onSaveSetMemo: onSaveSetMemo,
                  onAssignImageToSet: onAssignImageToSet,
                  onCreateFolderFromSelected: onCreateFolderFromSelected,
                ),
              ),
          ],
        );
      },
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
    required this.folderMoveDestinations,
    required this.favoriteImageIds,
    required this.selectedIds,
    required this.onAddSelected,
    required this.onDelete,
    required this.onRename,
    required this.onChangeColor,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onToggleFavoriteImage,
    required this.onMoveImage,
    required this.onSaveSetMemo,
    required this.onAssignImageToSet,
    required this.onCreateFolderFromSelected,
  });

  final StackItem stack;
  final ScreenshotSet folder;
  final String? colorKey;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final List<ScreenshotSet> folderMoveDestinations;
  final Set<String> favoriteImageIds;
  final Set<String> selectedIds;
  final Future<void> Function() onAddSelected;
  final Future<void> Function() onDelete;
  final Future<void> Function(String name) onRename;
  final Future<void> Function(String colorKey) onChangeColor;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId) onToggleFavoriteImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;
  final Future<void> Function(String setKey, String memo) onSaveSetMemo;
  final Future<void> Function(String imageId, String setKey) onAssignImageToSet;
  final Future<void> Function(String name, List<String> imageIds)
  onCreateFolderFromSelected;

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
                  favoriteImageIds: favoriteImageIds,
                  onExcludeImage: onExcludeImage,
                  onDeleteOriginalImage: onDeleteOriginalImage,
                  onToggleFavoriteImage: onToggleFavoriteImage,
                  onMoveImage: onMoveImage,
                  onSaveSetMemo: onSaveSetMemo,
                  onAssignImageToSet: onAssignImageToSet,
                  onDeleteFolder: onDelete,
                  onRenameFolder: (name) => onRename(name),
                  onChangeFolderColor: onChangeColor,
                  folderColorKey: colorKey,
                  onCreateFolderFromSelected: onCreateFolderFromSelected,
                  folderMoveDestinations: folderMoveDestinations,
                ),
              ),
            ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 142,
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEDEFF3), width: 1),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 5,
              child: Icon(
                Icons.folder_rounded,
                size: 17,
                color: option.darkColor,
              ),
            ),
            Positioned(
              left: 22,
              top: 6,
              right: 0,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF1A1C1C),
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 38,
              child: _FolderPreviewStack(items: previews),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: option.color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  st(
                    '${folder.items.length}장',
                    '${folder.items.length} photos',
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: option.darkColor,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
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
                title: Text(st('폴더 이름 변경', 'Rename folder')),
                onTap: () => Navigator.pop(context, 'rename'),
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(st('폴더 색상 변경', 'Change folder color')),
                onTap: () => Navigator.pop(context, 'color'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE05656),
                ),
                title: Text(
                  st('폴더 삭제', 'Delete folder'),
                  style: const TextStyle(color: Color(0xFFE05656)),
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
        title: st('폴더 이름 변경', 'Rename folder'),
        initialValue: _folderName(folder),
        hintText: st('폴더 이름', 'Folder name'),
        primaryLabel: st('저장', 'Save'),
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
                st('폴더 색상', 'Folder color'),
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
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.64),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEFF3), width: 1),
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          size: 19,
          color: Color(0xFF727785),
        ),
      );
    }
    final previewItems = items.take(3).toList();
    return SizedBox(
      height: 62,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const thumbWidth = 38.0;
          const thumbHeight = 56.0;
          final center = (constraints.maxWidth - thumbWidth) / 2;
          final configs = <({double dx, double dy, double angle})>[
            (dx: -26, dy: 4, angle: -0.10),
            (dx: 0, dy: 0, angle: 0),
            (dx: 26, dy: 4, angle: 0.10),
          ];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = previewItems.length - 1; i >= 0; i--)
                Positioned(
                  left: center + configs[i].dx,
                  top: configs[i].dy,
                  child: Transform.rotate(
                    angle: configs[i].angle,
                    child: _FolderPreviewThumb(
                      item: previewItems[i],
                      width: thumbWidth,
                      height: thumbHeight,
                      radius: 11,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FolderPreviewThumb extends StatelessWidget {
  const _FolderPreviewThumb({
    required this.item,
    required this.width,
    required this.height,
    required this.radius,
  });

  final ScreenshotItem item;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: _Thumb(path: item.thumbnailPath, radius: radius - 1),
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
          color: option.darkColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF1A1C1C) : Colors.white,
            width: selected ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: option.darkColor.withValues(alpha: 0.22),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
            : null,
      ),
    );
  }
}
