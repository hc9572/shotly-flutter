part of 'main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.photoPermissionStatus,
    required this.hiddenStacks,
    required this.excludedImages,
    required this.onOpenPhotoSettings,
    required this.onRestoreStack,
    required this.onRestoreImage,
    required this.onDeleteOriginalImage,
    required this.onDeleteOriginalImages,
    required this.onExportBackup,
    required this.onImportBackup,
    required this.onStartPhoneTransfer,
    required this.onReceivePhoneTransfer,
    required this.testerNoAppInfoMode,
    required this.onSetTesterNoAppInfoMode,
    required this.onResetOrganizationData,
  });

  final PhotoPermissionStatus photoPermissionStatus;
  final List<StackItem> hiddenStacks;
  final List<ScreenshotItem> excludedImages;
  final Future<void> Function() onOpenPhotoSettings;
  final Future<void> Function(String stackKey) onRestoreStack;
  final Future<void> Function(String imageId) onRestoreImage;
  final Future<bool> Function(String imageId) onDeleteOriginalImage;
  final Future<bool> Function(List<String> imageIds) onDeleteOriginalImages;
  final Future<void> Function() onExportBackup;
  final Future<void> Function() onImportBackup;
  final Future<void> Function() onStartPhoneTransfer;
  final Future<void> Function() onReceivePhoneTransfer;
  final bool testerNoAppInfoMode;
  final Future<void> Function(bool enabled) onSetTesterNoAppInfoMode;
  final Future<void> Function() onResetOrganizationData;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  late final List<StackItem> _hiddenStacks = [...widget.hiddenStacks];
  late final List<ScreenshotItem> _excludedImages = [...widget.excludedImages];
  late PhotoPermissionStatus _photoPermissionStatus =
      widget.photoPermissionStatus;
  var _appInfoDialogTapCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPhotoPermissionStatus());
    }
  }

  Future<void> _refreshPhotoPermissionStatus() async {
    final status = await ShotlyNative.photoPermissionStatus();
    if (!mounted || status == _photoPermissionStatus) return;
    setState(() => _photoPermissionStatus = status);
  }

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
              title: st('권한', 'Permissions'),
              children: [
                _PermissionStatusTile(
                  permissionStatus: _photoPermissionStatus,
                  onOpenSettings: widget.onOpenPhotoSettings,
                ),
              ],
            ),
            _SettingsSection(
              title: st('숨김 복구', 'Restore hidden items'),
              children: [
                _RecoverySummaryTile(
                  icon: Icons.layers_clear_outlined,
                  title: st('숨긴 앱', 'Hidden apps'),
                  count: _hiddenStacks.length,
                  onTap: () => _showHiddenStacks(context),
                ),
                _RecoverySummaryTile(
                  icon: Icons.visibility_off_outlined,
                  title: st('숨긴 이미지', 'Hidden images'),
                  count: _excludedImages.length,
                  onTap: () => _showExcludedImages(context),
                ),
              ],
            ),
            _SettingsSection(
              title: st('데이터 이전', 'Data transfer'),
              children: [
                _SettingsTile(
                  icon: Icons.sync_alt_rounded,
                  title: st('백업 및 불러오기', 'Backup and import'),
                  subtitle: st(
                    '정리 데이터만 간편하게 옮겨요',
                    'Move organization data easily',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF727785),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BackupAndImportScreen(
                        onStartPhoneTransfer: widget.onStartPhoneTransfer,
                        onReceivePhoneTransfer: widget.onReceivePhoneTransfer,
                        onExportBackup: widget.onExportBackup,
                        onImportBackup: widget.onImportBackup,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _SettingsSection(
              title: st('도움말', 'Help'),
              children: [
                _SettingsTile(
                  icon: Icons.mail_outline_rounded,
                  title: st('의견 보내기', 'Send feedback'),
                  subtitle: st(
                    '불편한 점이나 아이디어를 메일로 보내요',
                    'Share bugs, ideas, or feedback by email',
                  ),
                  onTap: () => _sendFeedbackEmail(context),
                ),
              ],
            ),
            _SettingsSection(
              title: st('정보', 'Information'),
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: st('앱 정보', 'App info'),
                  subtitle: 'Shotly 1.0.0',
                  onTap: () => _handleAppInfoTap(context),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: _ShotlyLegal.isKoreanRegion
                      ? st('개인정보처리방침', 'Privacy Policy')
                      : 'Privacy Policy',
                  subtitle: null,
                  onTap: () => _openShotlyLegalUrl(
                    context,
                    _ShotlyLegal.links.privacyUrl,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: _ShotlyLegal.isKoreanRegion
                      ? st('이용약관', 'Terms of Use')
                      : 'Terms of Use',
                  subtitle: null,
                  onTap: () =>
                      _openShotlyLegalUrl(context, _ShotlyLegal.links.termsUrl),
                ),
                _SettingsTile(
                  icon: Icons.article_outlined,
                  title: st('오픈소스 라이선스', 'Open source licenses'),
                  subtitle: null,
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF727785),
                  ),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Shotly',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026 Shotly',
                  ),
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

  void _handleAppInfoTap(BuildContext context) {
    _showInfoDialog(context);
  }

  Future<void> _unlockTesterMode(BuildContext context) async {
    final password = await _showShotlyTextDialog(
      context: context,
      title: st('테스터 모드', 'Tester mode'),
      hintText: st('테스트 비밀번호', 'Test password'),
      primaryLabel: st('확인', 'OK'),
      validator: (value) => value.trim() == 'hannachung'
          ? null
          : st('비밀번호가 맞지 않아요.', 'Incorrect password.'),
    );
    if (password?.trim() != 'hannachung' || !context.mounted) return;
    await _showTesterModeSheet(context);
  }

  Future<void> _showTesterModeSheet(BuildContext context) {
    var noAppInfoMode = widget.testerNoAppInfoMode;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  st('테스터 모드', 'Tester mode'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF1A1C1C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  st(
                    '앱 정보가 없는 기기(iOS/non-Galaxy) 플로우를 테스트해요.',
                    'Test the no-app-info device flow (iOS/non-Galaxy).',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF727785),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    st('iOS/non-Galaxy mode', 'iOS/non-Galaxy mode'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    st(
                      '켜면 스크린샷 앱 정보가 없는 것처럼 표시돼요. 앱을 다시 열어 확인해보세요.',
                      'When on, screenshots behave as if app info is unavailable. Reopen the app to verify.',
                    ),
                  ),
                  value: noAppInfoMode,
                  onChanged: (value) async {
                    await widget.onSetTesterNoAppInfoMode(value);
                    setSheetState(() => noAppInfoMode = value);
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB42318),
                      side: const BorderSide(color: Color(0xFFF1B6B0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(st('정리 데이터 초기화', 'Reset organization data')),
                    onPressed: () async {
                      final confirmed = await _showShotlyConfirmDialog(
                        context: context,
                        title: st('정리 데이터 초기화', 'Reset organization data'),
                        body: st(
                          '앱 생성, 분류, 폴더, 메모, 즐겨찾기, 숨김, 고정 정보가 모두 삭제돼요. 원본 사진은 삭제되지 않아요.',
                          'This clears apps, sorting, folders, notes, favorites, hidden items, and pins. Original photos will not be deleted.',
                        ),
                        primaryLabel: st('초기화', 'Reset'),
                        destructive: true,
                      );
                      if (confirmed != true) return;
                      await widget.onResetOrganizationData();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendFeedbackEmail(BuildContext context) async {
    final subject = st('[Shotly] 의견 보내기', '[Shotly] Feedback');
    final body = st(
      '안녕하세요, Shotly를 사용하다가 의견을 남깁니다.\n\n- 불편했던 점:\n- 좋았던 점:\n- 있으면 좋을 기능:\n\n',
      'Hi Shotly team, I’d like to share feedback.\n\n- What felt inconvenient:\n- What worked well:\n- Feature ideas:\n\n',
    );
    final mailtoUrl =
        'mailto:nadool.life@gmail.com?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    final opened = await ShotlyNative.openUrl(mailtoUrl);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            st(
              '메일 앱을 열 수 없어요. nadool.life@gmail.com 으로 보내주세요.',
              'Couldn’t open your email app. Please email nadool.life@gmail.com.',
            ),
          ),
        ),
      );
    }
  }

  void _showInfoDialog(BuildContext context) {
    _appInfoDialogTapCount = 0;
    _showShotlyInfoDialog(
      context: context,
      title: 'Shotly',
      body: st(
        'Shotly 1.0.0\n기획자를 위한 로컬 기반 스크린샷 정리 앱',
        'Shotly 1.0.0\nA local-first screenshot organizer for product planners',
      ),
      onContentTap: () {
        _appInfoDialogTapCount += 1;
        if (_appInfoDialogTapCount < 10) return;
        _appInfoDialogTapCount = 0;
        Navigator.of(context).pop();
        unawaited(_unlockTesterMode(context));
      },
    );
  }
}

class BackupAndImportScreen extends StatelessWidget {
  const BackupAndImportScreen({
    super.key,
    required this.onStartPhoneTransfer,
    required this.onReceivePhoneTransfer,
    required this.onExportBackup,
    required this.onImportBackup,
  });

  final Future<void> Function() onStartPhoneTransfer;
  final Future<void> Function() onReceivePhoneTransfer;
  final Future<void> Function() onExportBackup;
  final Future<void> Function() onImportBackup;

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
            Text(
              st('백업 및 불러오기', 'Backup and import'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF22252D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              st(
                '원본 이미지는 옮기지 않고\nShotly 정리 데이터만 옮겨요.',
                'Original images are not moved.\nOnly Shotly organization data is moved.',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: const Color(0xFF727785),
              ),
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: st('QR코드 이전', 'QR transfer'),
              children: [
                _SettingsTile(
                  icon: Icons.qr_code_2_rounded,
                  title: st('QR코드로 옮기기', 'Transfer with QR code'),
                  subtitle: st(
                    '이전 폰에서 QR코드를 만들어요',
                    'Create a QR code on your old phone',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF727785),
                  ),
                  onTap: onStartPhoneTransfer,
                ),
                _SettingsTile(
                  icon: Icons.qr_code_scanner_rounded,
                  title: st('QR코드로 가져오기', 'Import with QR code'),
                  subtitle: st(
                    '새 폰에서 이전 폰의 QR코드를 스캔해요',
                    'Scan the QR code from your old phone',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF727785),
                  ),
                  onTap: onReceivePhoneTransfer,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                foregroundColor: const Color(0xFF727785),
                textStyle: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              onPressed: () => _showFileBackupOptions(context),
              child: Text(st('QR이 잘 되지 않는다면?', 'If QR does not work?')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFileBackupOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E7EC),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.ios_share_rounded,
                title: st('파일로 백업하기', 'Export backup file'),
                subtitle: st(
                  '정리 데이터를 파일로 저장해요',
                  'Save organization data as a file',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onExportBackup();
                },
              ),
              _SettingsTile(
                icon: Icons.restore_rounded,
                title: st('파일에서 복원하기', 'Import backup file'),
                subtitle: st(
                  '백업 파일로 현재 정리 데이터를 교체해요',
                  'Replace current organization data with a backup file',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onImportBackup();
                },
              ),
            ],
          ),
        ),
      ),
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
            _SettingsPageHeader(title: st('숨긴 앱', 'Hidden apps')),
            const SizedBox(height: 20),
            if (_stacks.isEmpty)
              _EmptyRecoveryMessage(message: st('숨긴 앱이 없어요', 'No hidden apps'))
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
                    st(
                      '${stack.items.length}장 숨김',
                      '${stack.items.length} hidden',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF727785),
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () => _restore(stack.key),
                    child: Text(st('복구', 'Restore')),
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
              title: st('숨긴 이미지', 'Hidden images'),
              action: _images.isEmpty
                  ? null
                  : TextButton.icon(
                      onPressed: _deleteAll,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFB42318),
                      ),
                      label: Text(
                        st('전체 삭제', 'Delete all'),
                        style: const TextStyle(color: Color(0xFFB42318)),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            if (_images.isEmpty)
              _EmptyRecoveryMessage(
                message: st('숨긴 이미지가 없어요', 'No hidden images'),
              )
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
                        child: Text(st('복구', 'Restore')),
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
      title: st('기기 앨범에서도 삭제', 'Delete from device gallery'),
      body: st(
        '숨김 목록에서만 지우는 게 아니라, 이 이미지 원본을 기기 앨범에서도 삭제해요. 이 작업은 되돌릴 수 없어요.',
        'This deletes the original image from your device gallery, not just the hidden list. This can’t be undone.',
      ),
      primaryLabel: st('원본 삭제', 'Delete original'),
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
      title: st('숨긴 이미지 원본 전체 삭제', 'Delete all hidden originals'),
      body: st(
        '숨긴 이미지 ${_images.length}장의 원본을 기기 앨범에서도 모두 삭제해요. Android 시스템 확인창이 한 번 더 뜰 수 있고, 삭제 후에는 되돌릴 수 없어요.',
        'Delete originals for all ${_images.length} hidden images from your device gallery. Android may show one more confirmation dialog, and this can’t be undone.',
      ),
      primaryLabel: st('원본 전체 삭제', 'Delete all originals'),
      destructive: true,
    );
    if (confirmed != true) return;
    final deletedCount = await widget.onDeleteAllOriginalImages();
    if (mounted) {
      setState(() => _images.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            st(
              '$deletedCount개 원본 파일을 삭제했어요.',
              'Deleted $deletedCount original files.',
            ),
          ),
        ),
      );
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
    required this.permissionStatus,
    required this.onOpenSettings,
  });

  final PhotoPermissionStatus permissionStatus;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final hasPermission = permissionStatus != PhotoPermissionStatus.denied;
    final subtitle = switch (permissionStatus) {
      PhotoPermissionStatus.full => st('전체 접근 허용', 'Full access allowed'),
      PhotoPermissionStatus.limited => st(
        '제한된 접근 허용',
        'Limited access allowed',
      ),
      PhotoPermissionStatus.denied => st(
        '설정에서 다시 허용할 수 있어요',
        'You can allow access again in Settings',
      ),
    };
    return _SettingsTile(
      icon: hasPermission
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded,
      title: st('사진 접근 권한', 'Photo access'),
      subtitle: subtitle,
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
      subtitle: count == 0
          ? st('복구할 항목 없음', 'No items to restore')
          : st('$count개 항목 복구 가능', '$count items can be restored'),
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
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
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
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
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
      title: st('사진 접근 권한이 필요해요', 'Photo access is required'),
      body: st(
        '스크린샷을 앱별로 정리하려면 사진 접근 권한이 필요해요. 원본은 클라우드에 업로드하지 않고, 이 기기 안에서만 읽어요.',
        'Photo access is required to organize screenshots by app. Originals are not uploaded to the cloud and are read only on this device.',
      ),
      buttonText: st('권한 허용하기', 'Allow access'),
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
      title: st('문제가 생겼어요', 'Something went wrong'),
      body: message,
      buttonText: st('다시 시도', 'Try again'),
      onPressed: onRetry,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      title: st('스크린샷을 찾지 못했어요', 'No screenshots found'),
      body: st(
        'Screenshots 폴더 또는 Screenshot 파일명을 기준으로 먼저 찾아요.',
        'Shotly first looks for the Screenshots folder or Screenshot file names.',
      ),
    );
  }
}

class _NoResultState extends StatelessWidget {
  const _NoResultState();

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      title: st('검색 결과가 없어요', 'No search results'),
      body: st(
        '앱 이름이나 파일명을 다르게 입력해봐요.',
        'Try a different app name or file name.',
      ),
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
