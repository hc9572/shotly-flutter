part of 'main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.hasPermission,
    required this.hiddenStacks,
    required this.excludedImages,
    required this.onOpenPhotoSettings,
    required this.onRestoreStack,
    required this.onRestoreImage,
    required this.onDeleteOriginalImage,
    required this.onDeleteOriginalImages,
  });

  final bool hasPermission;
  final List<StackItem> hiddenStacks;
  final List<ScreenshotItem> excludedImages;
  final Future<void> Function() onOpenPhotoSettings;
  final Future<void> Function(String stackKey) onRestoreStack;
  final Future<void> Function(String imageId) onRestoreImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<bool> Function(List<String> imageIds) onDeleteOriginalImages;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final List<StackItem> _hiddenStacks = [...widget.hiddenStacks];
  late final List<ScreenshotItem> _excludedImages = [...widget.excludedImages];
  late final bool _hasPermission = widget.hasPermission;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF424754),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsSection(
              title: '권한',
              children: [
                _PermissionStatusTile(
                  hasPermission: _hasPermission,
                  onOpenSettings: widget.onOpenPhotoSettings,
                ),
              ],
            ),
            _SettingsSection(
              title: '숨김 복구',
              children: [
                _RecoverySummaryTile(
                  icon: Icons.layers_clear_outlined,
                  title: '숨긴 앱',
                  count: _hiddenStacks.length,
                  onTap: () => _showHiddenStacks(context),
                ),
                _RecoverySummaryTile(
                  icon: Icons.visibility_off_outlined,
                  title: '숨긴 이미지',
                  count: _excludedImages.length,
                  onTap: () => _showExcludedImages(context),
                ),
              ],
            ),
            _SettingsSection(
              title: '정보',
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: '앱 정보',
                  subtitle: 'Shotly 1.0.0 · 로컬 기반 스크린샷 정리 앱',
                  onTap: () => _showInfoDialog(context),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: _ShotlyLegal.isKoreanRegion
                      ? '개인정보처리방침'
                      : 'Privacy Policy',
                  subtitle: _ShotlyLegal.isKoreanRegion
                      ? '사진 원본은 클라우드에 업로드하지 않아요'
                      : 'Original screenshots are not uploaded to Shotly servers',
                  onTap: () => _openShotlyLegalUrl(
                    context,
                    _ShotlyLegal.links.privacyUrl,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: _ShotlyLegal.isKoreanRegion ? '이용약관' : 'Terms of Use',
                  subtitle: _ShotlyLegal.isKoreanRegion
                      ? 'Shotly 이용 조건 확인'
                      : 'Review Shotly’s terms',
                  onTap: () =>
                      _openShotlyLegalUrl(context, _ShotlyLegal.links.termsUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHiddenStacks(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HiddenStacksPage(
          stacks: _hiddenStacks,
          onRestoreStack: (stackKey) async {
            await widget.onRestoreStack(stackKey);
            if (mounted) {
              setState(
                () =>
                    _hiddenStacks.removeWhere((stack) => stack.key == stackKey),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _showExcludedImages(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HiddenImagesPage(
          images: _excludedImages,
          onRestoreImage: (imageId) async {
            await widget.onRestoreImage(imageId);
            if (mounted) {
              setState(
                () => _excludedImages.removeWhere((item) => item.id == imageId),
              );
            }
          },
          onDeleteOriginalImage: (imageId) async {
            final deleted = await widget.onDeleteOriginalImage(imageId);
            if (deleted && mounted) {
              setState(
                () => _excludedImages.removeWhere((item) => item.id == imageId),
              );
            }
            return deleted;
          },
          onDeleteAllOriginalImages: () async {
            final ids = _excludedImages.map((item) => item.id).toList();
            final deleted = await widget.onDeleteOriginalImages(ids);
            if (deleted && mounted) setState(() => _excludedImages.clear());
            return deleted ? ids.length : 0;
          },
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    _showShotlyInfoDialog(
      context: context,
      title: 'Shotly',
      body: 'Shotly 1.0.0\n기획자를 위한 로컬 기반 스크린샷 정리 앱',
    );
  }
}

class HiddenStacksPage extends StatefulWidget {
  const HiddenStacksPage({
    super.key,
    required this.stacks,
    required this.onRestoreStack,
  });

  final List<StackItem> stacks;
  final Future<void> Function(String stackKey) onRestoreStack;

  @override
  State<HiddenStacksPage> createState() => _HiddenStacksPageState();
}

class _HiddenStacksPageState extends State<HiddenStacksPage> {
  late final List<StackItem> _stacks = [...widget.stacks];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _SettingsPageHeader(title: '숨긴 앱'),
            const SizedBox(height: 20),
            if (_stacks.isEmpty)
              const _EmptyRecoveryMessage(message: '숨긴 앱이 없어요')
            else
              ..._stacks.map(
                (stack) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  leading: const Icon(
                    Icons.layers_clear_rounded,
                    color: Color(0xFF424754),
                  ),
                  title: Text(
                    stack.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${stack.items.length}장 숨김',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF727785),
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () => _restore(stack.key),
                    child: const Text('복구'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(String stackKey) async {
    await widget.onRestoreStack(stackKey);
    if (mounted) {
      setState(() => _stacks.removeWhere((stack) => stack.key == stackKey));
    }
  }
}

class HiddenImagesPage extends StatefulWidget {
  const HiddenImagesPage({
    super.key,
    required this.images,
    required this.onRestoreImage,
    required this.onDeleteOriginalImage,
    required this.onDeleteAllOriginalImages,
  });

  final List<ScreenshotItem> images;
  final Future<void> Function(String imageId) onRestoreImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<int> Function() onDeleteAllOriginalImages;

  @override
  State<HiddenImagesPage> createState() => _HiddenImagesPageState();
}

class _HiddenImagesPageState extends State<HiddenImagesPage> {
  late final List<ScreenshotItem> _images = [...widget.images];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _SettingsPageHeader(
              title: '숨긴 이미지',
              action: _images.isEmpty
                  ? null
                  : TextButton.icon(
                      onPressed: _deleteAll,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFB42318),
                      ),
                      label: const Text(
                        '전체 삭제',
                        style: TextStyle(color: Color(0xFFB42318)),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            if (_images.isEmpty)
              const _EmptyRecoveryMessage(message: '숨긴 이미지가 없어요')
            else
              ..._images.map(
                (item) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  leading: _Thumb(
                    path: item.thumbnailPath,
                    width: 44,
                    height: 64,
                    radius: 14,
                  ),
                  title: Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item.appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF727785),
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: () => _restore(item.id),
                        child: const Text('복구'),
                      ),
                      IconButton(
                        onPressed: () => _deleteOne(item.id),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFB42318),
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

  Future<void> _restore(String imageId) async {
    await widget.onRestoreImage(imageId);
    if (mounted) {
      setState(() => _images.removeWhere((item) => item.id == imageId));
    }
  }

  Future<void> _deleteOne(String imageId) async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '기기 앨범에서도 삭제',
      body: '숨김 목록에서만 지우는 게 아니라, 이 이미지 원본을 기기 앨범에서도 삭제해요. 이 작업은 되돌릴 수 없어요.',
      primaryLabel: '원본 삭제',
      destructive: true,
    );
    if (confirmed == true &&
        await widget.onDeleteOriginalImage(imageId) &&
        mounted) {
      setState(() => _images.removeWhere((item) => item.id == imageId));
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: '숨긴 이미지 원본 전체 삭제',
      body:
          '숨긴 이미지 ${_images.length}장의 원본을 기기 앨범에서도 모두 삭제해요. Android 시스템 확인창이 한 번 더 뜰 수 있고, 삭제 후에는 되돌릴 수 없어요.',
      primaryLabel: '원본 전체 삭제',
      destructive: true,
    );
    if (confirmed != true) return;
    final deletedCount = await widget.onDeleteAllOriginalImages();
    if (mounted) {
      setState(() => _images.clear());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$deletedCount개 원본 파일을 삭제했어요.')));
    }
  }
}

class _SettingsPageHeader extends StatelessWidget {
  const _SettingsPageHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF424754)),
        ),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
        ?action,
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: const Color(0xFF727785)),
            ),
          ),
          Column(children: children),
        ],
      ),
    );
  }
}

class _PermissionStatusTile extends StatelessWidget {
  const _PermissionStatusTile({
    required this.hasPermission,
    required this.onOpenSettings,
  });

  final bool hasPermission;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: hasPermission
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded,
      title: '사진 접근 권한',
      subtitle: hasPermission ? '허용됨' : '설정에서 다시 허용할 수 있어요',
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF727785),
      ),
      onTap: onOpenSettings,
    );
  }
}

class _RecoverySummaryTile extends StatelessWidget {
  const _RecoverySummaryTile({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: icon,
      title: title,
      subtitle: count == 0 ? '복구할 항목 없음' : '$count개 항목 복구 가능',
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF727785),
      ),
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      minLeadingWidth: 24,
      horizontalTitleGap: 12,
      leading: Icon(icon, color: const Color(0xFF424754)),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: const Color(0xFF727785)),
      ),
      trailing: trailing,
    );
  }
}

class _EmptyRecoveryMessage extends StatelessWidget {
  const _EmptyRecoveryMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
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

class _PermissionState extends StatelessWidget {
  const _PermissionState({required this.onRequest});

  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      title: '사진 접근 권한이 필요해요',
      body:
          '스크린샷을 앱별로 정리하려면 사진 접근 권한이 필요해요. 원본은 클라우드에 업로드하지 않고, 이 기기 안에서만 읽어요.',
      buttonText: '권한 허용하기',
      onPressed: onRequest,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      title: '문제가 생겼어요',
      body: message,
      buttonText: '다시 시도',
      onPressed: onRetry,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessage(
      title: '스크린샷을 찾지 못했어요',
      body: 'Screenshots 폴더 또는 Screenshot 파일명을 기준으로 먼저 찾아요.',
    );
  }
}

class _NoResultState extends StatelessWidget {
  const _NoResultState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessage(
      title: '검색 결과가 없어요',
      body: '앱 이름이나 파일명을 다르게 입력해봐요.',
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.title,
    required this.body,
    this.buttonText,
    this.onPressed,
  });

  final String title;
  final String body;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 180, 36, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              if (buttonText != null && onPressed != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: onPressed, child: Text(buttonText!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
