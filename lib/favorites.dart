part of 'main.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.items,
    required this.allStackKeys,
    required this.stackNames,
    required this.favoriteImageIds,
    required this.onExcludeImage,
    required this.onDeleteOriginalImage,
    required this.onToggleFavoriteImage,
    required this.onMoveImage,
  });

  final List<ScreenshotItem> items;
  final List<String> allStackKeys;
  final Map<String, String> stackNames;
  final Set<String> favoriteImageIds;
  final Future<void> Function(String imageId) onExcludeImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<void> Function(String imageId) onToggleFavoriteImage;
  final Future<void> Function(String imageId, String stackKey) onMoveImage;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Set<String> _hiddenIds = <String>{};

  List<ScreenshotItem> get _favoriteItems =>
      widget.items
          .where(
            (item) =>
                widget.favoriteImageIds.contains(item.id) &&
                !_hiddenIds.contains(item.id),
          )
          .toList()
        ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));

  @override
  Widget build(BuildContext context) {
    final items = _favoriteItems;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        st('즐겨찾기', 'Favorites'),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: const Color(0xFF1A1C1C)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              sliver: SliverToBoxAdapter(
                child: items.isEmpty
                    ? _FavoritesEmptyState()
                    : _ImageGridSection(
                        title: st(
                          '${items.length}개 사진',
                          '${items.length} photos',
                        ),
                        items: items,
                        viewerItems: items,
                        allStackKeys: widget.allStackKeys,
                        stackNames: widget.stackNames,
                        favoriteImageIds: widget.favoriteImageIds,
                        onExcludeImage: _hideImage,
                        onDeleteOriginalImage: _deleteOriginalImage,
                        onToggleFavoriteImage: _toggleFavoriteImage,
                        onMoveImage: widget.onMoveImage,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavoriteImage(String imageId) async {
    await widget.onToggleFavoriteImage(imageId);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _hideImage(String imageId) async {
    await widget.onExcludeImage(imageId);
    if (!mounted) return;
    setState(() => _hiddenIds.add(imageId));
  }

  Future<bool> _deleteOriginalImage(String imageId) async {
    final deleted = await widget.onDeleteOriginalImage(imageId);
    if (deleted && mounted) setState(() => _hiddenIds.add(imageId));
    return deleted;
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 96),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.star_border_rounded,
              color: Color(0xFF727785),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            st('아직 즐겨찾기한 사진이 없어요', 'No favorites yet'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1A1C1C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            st(
              '중요한 스크린샷에 별표를 눌러 모아봐요.',
              'Tap the star on important screenshots to collect them here.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF727785)),
          ),
        ],
      ),
    );
  }
}
