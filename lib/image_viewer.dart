part of 'main.dart';

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.onDeleteOriginalImage,
  });

  final List<ScreenshotItem> items;
  final int initialIndex;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _controlsVisible = true;
  final Map<String, Future<String?>> _previewFutures =
      <String, Future<String?>>{};

  ScreenshotItem get _currentItem => widget.items[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      right: 8,
                      child: Row(
                        children: [
                          _ViewerCircleButton(
                            icon: Icons.share_rounded,
                            onTap: () =>
                                ShotlyNative.shareImages([_currentItem.id]),
                          ),
                          const SizedBox(width: 10),
                          _ViewerCircleButton(
                            icon: Icons.delete_rounded,
                            destructive: true,
                            onTap: () async {
                              final confirmed = await _showShotlyConfirmDialog(
                                context: context,
                                title: '원본 파일 삭제',
                                body:
                                    '이 이미지를 기기 앨범 원본에서도 삭제할까요? 삭제 후 Shotly 목록에서도 사라져요.',
                                primaryLabel: '삭제',
                                destructive: true,
                              );
                              if (confirmed == true) {
                                final deleted = await widget
                                    .onDeleteOriginalImage(_currentItem.id);
                                if (deleted && context.mounted) {
                                  Navigator.of(context).pop(_currentItem.id);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.paddingOf(context).bottom + 20,
                      child: _ViewerInfo(
                        item: _currentItem,
                        index: _currentIndex,
                        total: widget.items.length,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerCircleButton extends StatelessWidget {
  const _ViewerCircleButton({
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.48),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Icon(
            icon,
            color: destructive ? const Color(0xFFFFD0CC) : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ViewerInfo extends StatelessWidget {
  const _ViewerInfo({
    required this.item,
    required this.index,
    required this.total,
  });

  final ScreenshotItem item;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '${index + 1}/$total · ${item.appName} · ${_formatSetDate(item.date)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

Widget _buildViewerImage(String path) {
  if (path.startsWith('mock://') || kIsWeb || path.isEmpty) {
    return _buildThumbnail(path, null, null);
  }
  return buildLocalImage(
    path,
    width: double.infinity,
    height: double.infinity,
    fit: BoxFit.contain,
    fallback: _buildThumbnail(path, null, null),
  );
}
