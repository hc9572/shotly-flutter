part of 'main.dart';

class _ShotlyPhoneTransferSession {
  _ShotlyPhoneTransferSession._({
    required this.server,
    required this.qrPayload,
    required this.onDownloaded,
  });

  final HttpServer server;
  final String qrPayload;
  final ValueNotifier<bool> onDownloaded;

  Future<void> close() => server.close(force: true);

  static Future<_ShotlyPhoneTransferSession> start(String backupContent) async {
    final token = _randomTransferToken();
    final host = await _localIpv4Address();
    if (host == null) {
      throw StateError('No local Wi-Fi address found');
    }
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final downloaded = ValueNotifier(false);
    final url = Uri(
      scheme: 'http',
      host: host,
      port: server.port,
      path: '/shotly-backup',
      queryParameters: {'token': token},
    );
    final qrPayload = jsonEncode({
      'app': 'Shotly',
      'type': 'phone_transfer',
      'version': 1,
      'url': url.toString(),
    });

    unawaited(
      server.forEach((request) async {
        final validPath = request.uri.path == '/shotly-backup';
        final validToken = request.uri.queryParameters['token'] == token;
        if (!validPath || !validToken) {
          request.response.statusCode = HttpStatus.forbidden;
          await request.response.close();
          return;
        }
        request.response.headers.contentType = ContentType.json;
        request.response.headers.set('Cache-Control', 'no-store');
        request.response.write(backupContent);
        await request.response.close();
        downloaded.value = true;
      }),
    );

    return _ShotlyPhoneTransferSession._(
      server: server,
      qrPayload: qrPayload,
      onDownloaded: downloaded,
    );
  }
}

String _randomTransferToken() {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = math.Random.secure();
  return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
}

Future<String?> _localIpv4Address() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
    includeLinkLocal: false,
  );
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      final value = address.address;
      if (value.startsWith('10.') ||
          value.startsWith('192.168.') ||
          RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(value)) {
        return value;
      }
    }
  }
  for (final interface in interfaces) {
    if (interface.addresses.isNotEmpty) {
      return interface.addresses.first.address;
    }
  }
  return null;
}

class PhoneTransferSendScreen extends StatefulWidget {
  const PhoneTransferSendScreen({super.key, required this.backupContent});

  final String backupContent;

  @override
  State<PhoneTransferSendScreen> createState() =>
      _PhoneTransferSendScreenState();
}

class _PhoneTransferSendScreenState extends State<PhoneTransferSendScreen> {
  late final Future<_ShotlyPhoneTransferSession> _sessionFuture;
  _ShotlyPhoneTransferSession? _session;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _ShotlyPhoneTransferSession.start(widget.backupContent);
  }

  @override
  void dispose() {
    unawaited(_session?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        foregroundColor: const Color(0xFF22252D),
        title: Text(st('새 폰으로 옮기기', 'Transfer to new phone')),
      ),
      body: FutureBuilder<_ShotlyPhoneTransferSession>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _PhoneTransferMessage(
              icon: Icons.wifi_off_rounded,
              title: st('전송을 시작할 수 없어요', 'Can’t start transfer'),
              message: st(
                '두 폰이 같은 Wi‑Fi에 연결되어 있는지 확인해줘.',
                'Make sure both phones are connected to the same Wi‑Fi.',
              ),
            );
          }
          _session = snapshot.data;
          return ValueListenableBuilder<bool>(
            valueListenable: _session!.onDownloaded,
            builder: (context, downloaded, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE4E7EC)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE4E7EC)),
                          ),
                          child: QrImageView(
                            data: _session!.qrPayload,
                            version: QrVersions.auto,
                            size: 190,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          downloaded
                              ? st('전송 완료', 'Transfer complete')
                              : st(
                                  '새 폰에서 이 QR을 스캔해주세요',
                                  'Please scan this QR on your new phone',
                                ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF22252D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          st(
                            '원본 이미지는 옮기지 않고 Shotly 정리 데이터만 전송해요. 이 화면을 닫으면 전송이 종료돼요.',
                            'Only Shotly organization data is transferred. Original images are not included. Closing this screen stops the transfer.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            height: 1.45,
                            color: Color(0xFF727785),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PhoneTransferStepList(
                    steps: [
                      st(
                        '두 폰을 같은 Wi‑Fi에 연결해주세요',
                        'Connect both phones to the same Wi‑Fi',
                      ),
                      st(
                        '새 폰에서 “QR코드로 가져오기”를 선택해주세요',
                        'On the new phone, choose “Scan QR to import”',
                      ),
                      st(
                        '이 QR을 스캔하면 자동으로 복원돼요',
                        'Scan this QR to restore automatically',
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class PhoneTransferReceiveScreen extends StatefulWidget {
  const PhoneTransferReceiveScreen({
    super.key,
    required this.onBackupContentReceived,
  });

  final Future<void> Function(String content) onBackupContentReceived;

  @override
  State<PhoneTransferReceiveScreen> createState() =>
      _PhoneTransferReceiveScreenState();
}

class _PhoneTransferReceiveScreenState
    extends State<PhoneTransferReceiveScreen> {
  final _controller = MobileScannerController();
  bool _handling = false;
  String? _error;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_handling) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;
    setState(() {
      _handling = true;
      _error = null;
    });
    try {
      final url = _transferUrlFromQr(value);
      if (url == null) {
        throw const FormatException('Invalid Shotly transfer QR');
      }
      final content = await _downloadTransferBackup(url);
      await widget.onBackupContentReceived(content);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _handling = false;
        _error = st(
          'Shotly 이전 QR을 읽지 못했어요. 같은 Wi‑Fi인지 확인하고 다시 스캔해줘.',
          'Couldn’t read this Shotly transfer QR. Check Wi‑Fi and scan again.',
        );
      });
    }
  }

  Uri? _transferUrlFromQr(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map ||
        decoded['app'] != 'Shotly' ||
        decoded['type'] != 'phone_transfer') {
      return null;
    }
    final rawUrl = decoded['url']?.toString();
    if (rawUrl == null) return null;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme != 'http' || uri.host.isEmpty) return null;
    return uri;
  }

  Future<String> _downloadTransferBackup(Uri url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(url);
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Transfer failed: ${response.statusCode}');
      }
      return response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(st('QR로 가져오기', 'Scan QR to import')),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleBarcode),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_handling) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _handling
                        ? st('백업을 가져오는 중...', 'Importing backup...')
                        : st(
                            '이전 폰의 Shotly QR을 비춰주세요',
                            'Please point at the Shotly QR on your old phone',
                          ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF22252D),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFE5484D)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneTransferStepList extends StatelessWidget {
  const _PhoneTransferStepList({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: const Color(0xFF111111),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: const TextStyle(
                        color: Color(0xFF424754),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PhoneTransferMessage extends StatelessWidget {
  const _PhoneTransferMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF727785)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF22252D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.45, color: Color(0xFF727785)),
            ),
          ],
        ),
      ),
    );
  }
}
