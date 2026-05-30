part of 'main.dart';

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
              ? const Color(0xFF111111)
              : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? const Color(0xFF111111) : const Color(0xFFD5D8DF),
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
    required this.favorite,
    required this.onToggleFavorite,
    required this.onTap,
    required this.onLongPress,
  });

  final ScreenshotItem item;
  final bool selected;
  final bool selecting;
  final bool favorite;
  final VoidCallback onToggleFavorite;
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
                  ? const Color(0xFF111111)
                  : Colors.transparent,
            ),
          ),
          if (!selecting && favorite)
            Positioned(
              right: 5,
              top: 5,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleFavorite,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Stack(
                    alignment: Alignment.center,
                    children: const [
                      Icon(Icons.star_rounded, size: 22, color: Colors.white),
                      Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Color(0xFFFFC940),
                      ),
                    ],
                  ),
                ),
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
                      ? const Color(0xFF111111)
                      : Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF111111)
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
                  label: st('이동', 'Move'),
                  onTap: onMove,
                ),
                if (onFolder != null)
                  _SelectionActionButton(
                    icon: Icons.grid_view_rounded,
                    label: st('폴더', 'Folder'),
                    onTap: onFolder!,
                  ),
                _SelectionActionButton(
                  icon: Icons.share_rounded,
                  label: st('공유', 'Share'),
                  onTap: onShare,
                ),
                _SelectionActionButton(
                  icon: Icons.visibility_off_rounded,
                  label: st('숨기기', 'Hide'),
                  onTap: onHide,
                ),
                _SelectionActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: st('삭제', 'Delete'),
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
