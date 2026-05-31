part of 'main.dart';

const _legalAcceptedPreferenceKey = 'shotly.legalAccepted.v1';

class _ShotlyLegalLinks {
  const _ShotlyLegalLinks({required this.privacyUrl, required this.termsUrl});

  final String privacyUrl;
  final String termsUrl;
}

class _ShotlyLegal {
  static const _ko = _ShotlyLegalLinks(
    privacyUrl:
        'https://www.notion.so/Shotly-36d96944ffd380a1b3fdd5d8b3c2f70b?source=copy_link',
    termsUrl:
        'https://www.notion.so/Shotly-36d96944ffd380dfaf6dd75a0f049c34?source=copy_link',
  );

  static const _global = _ShotlyLegalLinks(
    privacyUrl:
        'https://www.notion.so/Shotly-Privacy-Policy-36d96944ffd38014b405c203fd00dc10?source=copy_link',
    termsUrl:
        'https://www.notion.so/Shotly-Terms-of-Use-36d96944ffd38014bde1e55d2de6fe59?source=copy_link',
  );

  static bool get isKoreanRegion {
    final region = PlatformDispatcher.instance.locale.countryCode;
    return region?.toUpperCase() == 'KR';
  }

  static _ShotlyLegalLinks get links => isKoreanRegion ? _ko : _global;
}

class _ShotlyLaunchGate extends StatefulWidget {
  const _ShotlyLaunchGate();

  @override
  State<_ShotlyLaunchGate> createState() => _ShotlyLaunchGateState();
}

class _ShotlyLaunchGateState extends State<_ShotlyLaunchGate> {
  bool? _accepted;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAcceptance());
  }

  Future<void> _loadAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _accepted = prefs.getBool(_legalAcceptedPreferenceKey) ?? false;
    });
  }

  Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_legalAcceptedPreferenceKey, true);
    if (!mounted) return;
    setState(() => _accepted = true);
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _accepted;
    if (accepted == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (accepted) return const ShotlyHomeScreen();
    return _ShotlyOnboardingScreen(onStart: _accept);
  }
}

class _ShotlyOnboardingScreen extends StatelessWidget {
  const _ShotlyOnboardingScreen({required this.onStart});

  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    final links = _ShotlyLegal.links;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEDEFF3)),
                ),
                child: Image.asset('assets/images/shotly_logo.png'),
              ),
              const SizedBox(height: 28),
              Text(
                st(
                  '흩어진 스크린샷을\n간편하게 정리해요',
                  'Quickly organize\nscattered screenshots',
                ),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFF1A1C1C),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                st(
                  'Shotly는 사진 원본을 서버로 업로드하지 않고, 기기 안에서 스크린샷을 분석하고 정리해요.',
                  'Shotly analyzes and organizes screenshots locally on your device. Your original screenshots are not uploaded to Shotly servers.',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF727785),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              _OnboardingPoint(
                icon: Icons.folder_copy_outlined,
                title: st('앱/폴더 기반 정리', 'App & folder organization'),
                body: st(
                  '어디서 왜 찍었는지 정리해보세요.',
                  'Keep track of where and why you captured each screen.',
                ),
              ),
              const SizedBox(height: 14),
              _OnboardingPoint(
                icon: Icons.lock_outline_rounded,
                title: st('로컬 기반 처리', 'Local-first processing'),
                body: st(
                  '스크린샷과 정리 정보는 기기 안에서 처리돼요.',
                  'Screenshots and organization data stay on your device.',
                ),
              ),
              const SizedBox(height: 14),
              _OnboardingPoint(
                icon: Icons.cleaning_services_outlined,
                title: st('비슷한 화면 찾기', 'Find similar screens'),
                body: st(
                  '삭제 또는 이동해서 정리해보세요.',
                  'Review, delete, or move similar screens to organize them.',
                ),
              ),
              const Spacer(),
              Text(
                st(
                  '시작하면 Shotly의 이용약관에 동의하고 개인정보처리방침을 확인한 것으로 간주돼요.',
                  'By starting, you agree to Shotly’s Terms of Use and acknowledge the Privacy Policy.',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF727785),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  _LegalTextButton(
                    label: st('이용약관', 'Terms of Use'),
                    url: links.termsUrl,
                  ),
                  _LegalTextButton(
                    label: st('개인정보처리방침', 'Privacy Policy'),
                    url: links.privacyUrl,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: onStart,
                  child: Text(st('시작하기', 'Start')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPoint extends StatelessWidget {
  const _OnboardingPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEFF2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF424754)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF1A1C1C),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF727785),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegalTextButton extends StatelessWidget {
  const _LegalTextButton({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _openShotlyLegalUrl(context, url),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF111111),
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFF111111),
          ),
        ),
      ),
    );
  }
}

Future<void> _openShotlyLegalUrl(BuildContext context, String url) async {
  final opened = await ShotlyNative.openUrl(url);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          st(
            '링크를 열 수 없어요. 잠시 후 다시 시도해 주세요.',
            'Couldn’t open the link. Please try again later.',
          ),
        ),
      ),
    );
  }
}
