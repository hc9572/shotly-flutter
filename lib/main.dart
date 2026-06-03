import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_image.dart';
import 'local_store.dart';
import 'mock_data.dart';
import 'shotly_analytics.dart';
import 'visual_features.dart';

part 'models_native.dart';
part 'home_widgets_calendar.dart';
part 'search.dart';
part 'stack_card.dart';
part 'stack_detail.dart';
part 'stack_smart_clean.dart';
part 'stack_folders.dart';
part 'stack_sections.dart';
part 'stack_selection_widgets.dart';
part 'image_viewer.dart';
part 'favorites.dart';
part 'dialogs.dart';
part 'shotly_helpers.dart';
part 'settings.dart';
part 'onboarding.dart';
part 'phone_transfer.dart';

bool get _shotlyUsesKorean =>
    PlatformDispatcher.instance.locale.languageCode.toLowerCase() == 'ko';

String st(String ko, String en) => _shotlyUsesKorean ? ko : en;

String stCount(
  int count,
  String koSuffix,
  String enSingular,
  String enPlural,
) => _shotlyUsesKorean
    ? '$count$koSuffix'
    : '$count ${count == 1 ? enSingular : enPlural}';

String stDate(DateTime date) {
  if (_shotlyUsesKorean) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]}) ${date.hour.toString().padLeft(2, '0')}시 ${date.minute.toString().padLeft(2, '0')}분';
  }
  final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${weekdays[date.weekday - 1]}, ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} $hour:$minute';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  _registerShotlyLicenses();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Shotly runtime error: $error');
    debugPrintStack(stackTrace: stack);
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  ErrorWidget.builder = (details) {
    FlutterError.presentError(details);
    return const _ShotlyRuntimeErrorView();
  };
  runApp(const ShotlyApp());
}

void _registerShotlyLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Inter',
    ], await rootBundle.loadString('assets/licenses/inter_ofl.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'Pretendard',
    ], await rootBundle.loadString('assets/licenses/pretendard_ofl.txt'));
  });
}

class _ShotlyRuntimeErrorView extends StatelessWidget {
  const _ShotlyRuntimeErrorView();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFF727785),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                st('화면을 불러오지 못했어요', 'Couldn’t load this screen'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1A1C1C),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                st(
                  '뒤로 갔다가 다시 열어봐요. 오류 내용은 개발 로그에 남겨둘게요.',
                  'Go back and open it again. The error was saved to developer logs.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF727785),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnsortedHeader extends StatelessWidget {
  const _UnsortedHeader({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final countLabel = stCount(count, '장', 'screenshot', 'screenshots');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                st('미분류 스크린샷 $countLabel', 'Unsorted $countLabel'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF1A1C1C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: const Color(0xFF727785),
            ),
          ],
        ),
      ),
    );
  }
}

class ShotlyApp extends StatelessWidget {
  const ShotlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shotly',
      debugShowCheckedModeBanner: false,
      supportedLocales: const [Locale('en'), Locale('ko')],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale?.languageCode.toLowerCase() == 'ko') {
          return const Locale('ko');
        }
        return const Locale('en');
      },
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF111111),
          brightness: Brightness.light,
          primary: const Color(0xFF111111),
          surface: const Color(0xFFF8F9FA),
          surfaceContainerHighest: const Color(0xFFE2E2E2),
          outline: const Color(0xFF727785),
        ),
        textTheme:
            const TextTheme(
              headlineLarge: TextStyle(
                fontSize: 28,
                height: 34 / 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.56,
              ),
              headlineMedium: TextStyle(
                fontSize: 22,
                height: 28 / 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.22,
              ),
              headlineSmall: TextStyle(
                fontSize: 18,
                height: 24 / 18,
                fontWeight: FontWeight.w600,
              ),
              titleLarge: TextStyle(
                fontSize: 22,
                height: 28 / 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.22,
              ),
              titleMedium: TextStyle(
                fontSize: 18,
                height: 24 / 18,
                fontWeight: FontWeight.w600,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w400,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w400,
              ),
              bodySmall: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
              ),
              labelLarge: TextStyle(
                fontSize: 14,
                height: 18 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.14,
              ),
              labelMedium: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
              ),
              labelSmall: TextStyle(
                fontSize: 11,
                height: 14 / 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.33,
              ),
            ).apply(
              bodyColor: const Color(0xFF1A1C1C),
              displayColor: const Color(0xFF1A1C1C),
              fontFamily: 'Inter',
              fontFamilyFallback: ['Pretendard'],
            ),
      ),
      home: const _ShotlyLaunchGate(),
    );
  }
}

class ShotlyHomeScreen extends StatefulWidget {
  const ShotlyHomeScreen({super.key});

  @override
  State<ShotlyHomeScreen> createState() => _ShotlyHomeScreenState();
}

class _ShotlyHomeScreenState extends State<ShotlyHomeScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _localStore = ShotlyLocalStore();
  List<ScreenshotItem> _screenshots = const [];
  final List<String> _manualStackNames = [];
  final Map<String, String> _stackNames = {};
  final Map<String, String> _imageAssignments = {};
  final Map<String, String> _setMemos = {};
  final Map<String, String> _folderNames = {};
  final Map<String, String> _folderColors = {};
  final Map<String, String> _setAssignments = {};
  final Map<String, VisualFeature> _visualFeatures = {};
  final Set<String> _hiddenStackKeys = {};
  final Set<String> _excludedImageIds = {};
  final Set<String> _favoriteImageIds = {};
  final Set<String> _homeSelectedImageIds = {};
  bool _isHomeSelectionMode = false;
  final List<String> _pinnedStackKeys = [];
  bool _isLoading = true;
  PhotoPermissionStatus _photoPermissionStatus = PhotoPermissionStatus.denied;

  bool get _hasPermission =>
      _photoPermissionStatus != PhotoPermissionStatus.denied;
  DateTimeRange? _selectedDateRange;
  bool _reloadAfterCurrentLoad = false;
  String _query = '';
  String? _error;
  bool _showSortMenu = false;
  bool _testerNoAppInfoMode = false;
  bool? _unsortedExpandedOverride;
  StackSortMode _sortMode = StackSortMode.latest;

  static const _testerNoAppInfoModePrefsKey = 'shotly.tester.noAppInfoMode';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(ShotlyAnalytics.log('app_open'));
    unawaited(_restoreLocalState());
    unawaited(_load(requestPermission: false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAfterResume());
    }
  }

  Future<void> _refreshAfterResume() async {
    if (_isLoading) {
      _reloadAfterCurrentLoad = true;
      return;
    }
    await _load(requestPermission: false, showLoading: false);
  }

  Future<void> _restoreLocalState() async {
    final state = await _localStore.load();
    if (!mounted) return;
    setState(() {
      _manualStackNames
        ..clear()
        ..addAll(state.manualStackNames);
      _stackNames
        ..clear()
        ..addAll(state.stackNames);
      _imageAssignments
        ..clear()
        ..addAll(state.imageAssignments);
      _setMemos
        ..clear()
        ..addAll(state.setMemos);
      _folderNames
        ..clear()
        ..addAll(state.folderNames);
      _folderColors
        ..clear()
        ..addAll(state.folderColors);
      _setAssignments
        ..clear()
        ..addAll(state.setAssignments);
      _hiddenStackKeys
        ..clear()
        ..addAll(state.hiddenStackKeys);
      _excludedImageIds
        ..clear()
        ..addAll(state.excludedImageIds);
      _favoriteImageIds
        ..clear()
        ..addAll(state.favoriteImageIds);
      _pinnedStackKeys
        ..clear()
        ..addAll(state.pinnedStackKeys);
      _sortMode = _sortModeFromName(state.sortModeName) ?? _sortMode;
    });
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(
      () => _testerNoAppInfoMode =
          prefs.getBool(_testerNoAppInfoModePrefsKey) ?? false,
    );
  }

  Future<void> _load({
    bool requestPermission = true,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      _error = null;
    }
    try {
      _photoPermissionStatus = requestPermission
          ? await ShotlyNative.requestPhotoPermissionStatus()
          : await ShotlyNative.photoPermissionStatus();
      unawaited(
        ShotlyAnalytics.log(
          _hasPermission
              ? 'photo_permission_granted'
              : 'photo_permission_denied',
        ),
      );
      if (_hasPermission) {
        final screenshots = await ShotlyNative.getScreenshots();
        screenshots.sort(
          (a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis),
        );
        _screenshots = screenshots;
        _visualFeatures.clear();
      } else {
        _screenshots = const [];
      }
    } on PlatformException catch (e) {
      _error = e.message ?? e.code;
    } catch (e) {
      _error = '$e';
    } finally {
      final shouldReload = _reloadAfterCurrentLoad;
      _reloadAfterCurrentLoad = false;
      if (mounted) setState(() => _isLoading = false);
      if (shouldReload && mounted) {
        unawaited(_load(requestPermission: false, showLoading: false));
      }
    }
  }

  Future<void> _exportBackup() async {
    try {
      final state = await _localStore.load();
      final backup = ShotlyBackupDocument.current(state);
      final content = const JsonEncoder.withIndent(
        '  ',
      ).convert(backup.toJson());
      final date = DateTime.now();
      final filename =
          'shotly-backup-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.json';
      final saved = await ShotlyNative.saveBackupFile(filename, content);
      if (!mounted) return;
      if (saved) {
        unawaited(ShotlyAnalytics.log('backup_exported'));
        _showSnack(st('백업 파일을 저장했어요.', 'Backup file saved.'));
      }
    } on PlatformException catch (e) {
      if (mounted) _showSnack(e.message ?? e.code);
    } catch (e) {
      if (mounted) {
        _showSnack(st('백업 파일을 저장하지 못했어요.', 'Couldn’t save backup file.'));
      }
    }
  }

  Future<String> _currentBackupContent() async {
    final state = await _localStore.load();
    final backup = ShotlyBackupDocument.current(state);
    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }

  Future<void> _startPhoneTransfer() async {
    try {
      final content = await _currentBackupContent();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PhoneTransferSendScreen(backupContent: content),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showSnack(st('폰 이전을 시작하지 못했어요.', 'Couldn’t start phone transfer.'));
      }
    }
  }

  Future<void> _receivePhoneTransfer() async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: st('QR로 가져오기', 'Scan QR to import'),
      body: st(
        '이전 폰의 정리 데이터로 현재 Shotly 정리 데이터를 교체할까요? 원본 이미지는 건드리지 않아요.',
        'Replace current Shotly organization data with data from your old phone? Original images will not be changed.',
      ),
      primaryLabel: st('스캔하기', 'Scan'),
    );
    if (confirmed != true || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhoneTransferReceiveScreen(
          onBackupContentReceived: _importBackupContent,
        ),
      ),
    );
  }

  Future<void> _importBackupContent(String content) async {
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw const FormatException('Invalid Shotly backup file');
    }
    final backup = ShotlyBackupDocument.fromJson(
      decoded.cast<String, Object?>(),
    );
    await _localStore.replaceAll(backup.state);
    await _restoreLocalState();
    await _load(requestPermission: false);
    unawaited(ShotlyAnalytics.log('backup_imported'));
    if (mounted) {
      _showSnack(st('정리 데이터를 가져왔어요.', 'Organization data imported.'));
    }
  }

  Future<void> _importBackup() async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: st('백업 불러오기', 'Import backup'),
      body: st(
        '백업 파일의 정리 데이터로 현재 Shotly 정리 데이터를 교체할까요? 원본 이미지는 건드리지 않아요.',
        'Replace current Shotly organization data with the selected backup? Original images will not be changed.',
      ),
      primaryLabel: st('불러오기', 'Import'),
    );
    if (confirmed != true) return;

    try {
      final content = await ShotlyNative.openBackupFile();
      if (content == null || content.trim().isEmpty) return;
      await _importBackupContent(content);
    } on PlatformException catch (e) {
      if (mounted) _showSnack(e.message ?? e.code);
    } on FormatException catch (_) {
      if (mounted) {
        _showSnack(
          st('Shotly 백업 파일이 아니에요.', 'This is not a Shotly backup file.'),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(st('백업을 불러오지 못했어요.', 'Couldn’t import backup.'));
      }
    }
  }

  List<ScreenshotItem> get _effectiveScreenshots => _testerNoAppInfoMode
      ? _screenshots
            .map(
              (item) => ScreenshotItem(
                id: item.id,
                displayName: item.displayName,
                relativePath: item.relativePath,
                dateTakenMillis: item.dateTakenMillis,
                appName: '',
                thumbnailPath: item.thumbnailPath,
              ),
            )
            .toList()
      : _screenshots;

  List<ScreenshotItem> get _calendarScreenshots {
    Iterable<ScreenshotItem> items = _effectiveScreenshots.where(
      (item) => !_excludedImageIds.contains(item.id),
    );
    final selectedRange = _selectedDateRange;
    if (selectedRange != null) {
      items = items.where((item) => _isDateInRange(item.date, selectedRange));
    }
    if (_query.trim().isNotEmpty) {
      items = items.where((item) => item.matches(_query.trim()));
    }
    return items.toList();
  }

  List<ScreenshotItem> get _filteredScreenshots => _calendarScreenshots;

  List<ScreenshotSet> get _unclassifiedHomeSets => _buildScreenshotSets(
    'Unknown',
    _filteredScreenshots
        .where((item) => _stackKeyFor(item) == 'Unknown')
        .toList(),
    _setMemos,
    _folderNames,
    _setAssignments,
  ).where((set) => !_isFolderSetKey(set.key)).toList();

  List<StackItem> get _availableStackTargets => _stacks
      .where((stack) => stack.key != 'Unknown' && stack.name != 'Unknown')
      .toList();

  List<StackItem> get _searchSourceStacks {
    final grouped = <String, List<ScreenshotItem>>{};
    for (final item in _effectiveScreenshots.where(
      (item) => !_excludedImageIds.contains(item.id),
    )) {
      final selectedRange = _selectedDateRange;
      if (selectedRange != null && !_isDateInRange(item.date, selectedRange)) {
        continue;
      }
      final stackKey = _stackKeyFor(item);
      if (stackKey == 'Unknown') continue;
      if (_hiddenStackKeys.contains(stackKey)) continue;
      grouped.putIfAbsent(stackKey, () => []).add(item);
    }
    final stacks = grouped.entries
        .map(
          (entry) => StackItem(
            key: entry.key,
            name: _stackNames[entry.key] ?? entry.key,
            items: entry.value
              ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis)),
          ),
        )
        .toList();
    for (final name in _manualStackNames) {
      if (name == 'Unknown') continue;
      if (_selectedDateRange == null &&
          !grouped.containsKey(name) &&
          !_hiddenStackKeys.contains(name)) {
        stacks.add(
          StackItem(
            key: name,
            name: _stackNames[name] ?? name,
            items: const [],
          ),
        );
      }
    }
    return stacks;
  }

  List<StackItem> get _stacks {
    final q = _query.trim();
    final grouped = <String, List<ScreenshotItem>>{};
    for (final item in _calendarScreenshots) {
      final stackKey = _stackKeyFor(item);
      if (stackKey == 'Unknown') continue;
      if (_hiddenStackKeys.contains(stackKey)) continue;
      grouped.putIfAbsent(stackKey, () => []).add(item);
    }
    final stacks = grouped.entries
        .map(
          (entry) => StackItem(
            key: entry.key,
            name: _stackNames[entry.key] ?? entry.key,
            items: entry.value
              ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis)),
          ),
        )
        .where((stack) => q.isEmpty || _stackMatchesQuery(stack, q))
        .toList();
    for (final name in _manualStackNames) {
      if (name == 'Unknown') continue;
      final matchesQuery =
          q.isEmpty ||
          _textMatches(name, q) ||
          _textMatches(_stackNames[name] ?? '', q);
      if (_selectedDateRange == null &&
          matchesQuery &&
          !grouped.containsKey(name) &&
          !_hiddenStackKeys.contains(name)) {
        stacks.add(
          StackItem(
            key: name,
            name: _stackNames[name] ?? name,
            items: const [],
          ),
        );
      }
    }
    void sortByMode(List<StackItem> target) {
      switch (_sortMode) {
        case StackSortMode.latest:
          target.sort(
            (a, b) => (b.items.isEmpty ? 0 : b.items.first.dateTakenMillis)
                .compareTo(a.items.isEmpty ? 0 : a.items.first.dateTakenMillis),
          );
        case StackSortMode.name:
          target.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        case StackSortMode.mostImages:
          target.sort((a, b) => b.items.length.compareTo(a.items.length));
        case StackSortMode.fewestImages:
          target.sort((a, b) => a.items.length.compareTo(b.items.length));
      }
    }

    final stackByKey = {for (final stack in stacks) stack.key: stack};
    final pinned = _pinnedStackKeys
        .where(stackByKey.containsKey)
        .map((key) => stackByKey[key]!)
        .toList();
    final unpinned = stacks
        .where((stack) => !_pinnedStackKeys.contains(stack.key))
        .toList();
    sortByMode(unpinned);
    return [...pinned, ...unpinned];
  }

  List<StackItem> get _hiddenStacks {
    final grouped = <String, List<ScreenshotItem>>{};
    for (final item in _effectiveScreenshots.where(
      (item) => !_excludedImageIds.contains(item.id),
    )) {
      final stackKey = _stackKeyFor(item);
      if (stackKey == 'Unknown') continue;
      if (_hiddenStackKeys.contains(stackKey)) {
        grouped.putIfAbsent(stackKey, () => []).add(item);
      }
    }
    final stacks = grouped.entries
        .map(
          (entry) => StackItem(
            key: entry.key,
            name: _stackNames[entry.key] ?? entry.key,
            items: entry.value
              ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis)),
          ),
        )
        .toList();
    for (final name in _manualStackNames) {
      if (name == 'Unknown') continue;
      if (_hiddenStackKeys.contains(name) && !grouped.containsKey(name)) {
        stacks.add(
          StackItem(
            key: name,
            name: _stackNames[name] ?? name,
            items: const [],
          ),
        );
      }
    }
    stacks.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return stacks;
  }

  List<ScreenshotItem> get _excludedImages {
    return _effectiveScreenshots
        .where((item) => _excludedImageIds.contains(item.id))
        .toList()
      ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
  }

  String _stackKeyFor(ScreenshotItem item) =>
      _imageAssignments[item.id] ??
      (item.appName.isEmpty ? 'Unknown' : item.appName);

  Future<void> _showCreateStackDialog() async {
    final name = await _showShotlyTextDialog(
      context: context,
      title: st('앱 추가', 'Add app'),
      hintText: st('앱 이름', 'App name'),
      primaryLabel: st('추가', 'Add'),
      validator: (value) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return null;
        final exists =
            _manualStackNames.any(
              (name) => name.toLowerCase() == trimmed.toLowerCase(),
            ) ||
            _stacks.any(
              (stack) =>
                  stack.name.toLowerCase() == trimmed.toLowerCase() ||
                  stack.key.toLowerCase() == trimmed.toLowerCase(),
            );
        return exists
            ? st('이미 같은 이름의 앱이 있어요.', 'An app with this name already exists.')
            : null;
      },
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    setState(() {
      if (!_manualStackNames.contains(trimmed)) _manualStackNames.add(trimmed);
    });
    await _localStore.upsertManualStack(trimmed);
  }

  Future<void> _pickImageFromAlbum() async {
    try {
      final image = await ShotlyNative.pickImage();
      if (image == null) return;
      if (_screenshots.any(
        (item) =>
            item.id == image.id || item.thumbnailPath == image.thumbnailPath,
      )) {
        if (mounted) {
          _showSnack(
            st(
              '이미 추가된 이미지예요. 중복 추가하지 않았어.',
              'This image was already added. Duplicates are skipped.',
            ),
          );
        }
        return;
      }
      setState(() {
        _screenshots = [image, ..._screenshots]
          ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
      });
    } on PlatformException catch (e) {
      if (mounted) _showSnack(e.message ?? e.code);
    }
  }

  Future<ScreenshotItem?> _pickAndAddImageToStack(String stackKey) async {
    try {
      final image = await ShotlyNative.pickImage();
      if (image == null) return null;
      if (_screenshots.any(
        (item) =>
            item.id == image.id || item.thumbnailPath == image.thumbnailPath,
      )) {
        await _moveImage(image.id, stackKey);
        return image;
      }
      setState(() {
        _screenshots = [image, ..._screenshots]
          ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
      });
      await _moveImage(image.id, stackKey);
      return image;
    } on PlatformException catch (e) {
      if (mounted) _showSnack(e.message ?? e.code);
      return null;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPhotoSettings() async {
    try {
      await ShotlyNative.openPhotoSettings();
    } on PlatformException catch (e) {
      if (mounted) _showSnack(e.message ?? e.code);
    }
  }

  Future<void> _setTesterNoAppInfoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_testerNoAppInfoModePrefsKey, enabled);
    if (!mounted) return;
    setState(() => _testerNoAppInfoMode = enabled);
  }

  Future<void> _resetOrganizationData() async {
    await _localStore.replaceAll(const LocalShotlyState());
    if (!mounted) return;
    setState(() {
      _manualStackNames.clear();
      _stackNames.clear();
      _imageAssignments.clear();
      _setMemos.clear();
      _folderNames.clear();
      _folderColors.clear();
      _setAssignments.clear();
      _hiddenStackKeys.clear();
      _excludedImageIds.clear();
      _favoriteImageIds.clear();
      _homeSelectedImageIds.clear();
      _isHomeSelectionMode = false;
      _pinnedStackKeys.clear();
      _selectedDateRange = null;
      _query = '';
      _searchController.clear();
      _showSortMenu = false;
      _unsortedExpandedOverride = null;
      _sortMode = StackSortMode.latest;
      _visualFeatures.clear();
    });
    _showSnack(
      st(
        '정리 데이터를 초기화했어요. 원본 사진은 그대로예요.',
        'Organization data reset. Original photos were not changed.',
      ),
    );
  }

  Future<void> _renameStack(String stackKey, String name) async {
    final trimmed = name.trim().isEmpty ? stackKey : name.trim();
    setState(() => _stackNames[stackKey] = trimmed);
    await _localStore.renameStack(stackKey, trimmed);
  }

  Future<void> _hideStack(String stackKey) async {
    setState(() => _hiddenStackKeys.add(stackKey));
    await _localStore.hideStack(stackKey);
  }

  Future<void> _deleteStack(StackItem stack) async {
    final stackKey = stack.key;
    final imageIds = stack.items.map((item) => item.id).toSet();
    final folderKeys = _folderNames.keys
        .where((key) => _folderBelongsToStack(key, stackKey))
        .toSet();
    final setMemoKeys = _setMemos.keys
        .where(
          (key) =>
              key.startsWith('$stackKey|') ||
              _folderBelongsToStack(key, stackKey),
        )
        .toSet();

    setState(() {
      _manualStackNames.remove(stackKey);
      _stackNames.remove(stackKey);
      _hiddenStackKeys.remove(stackKey);
      _pinnedStackKeys.remove(stackKey);
      for (final id in imageIds) {
        _imageAssignments[id] = 'Unknown';
        _setAssignments.remove(id);
      }
      for (final key in folderKeys) {
        _folderNames.remove(key);
        _folderColors.remove(key);
      }
      for (final key in setMemoKeys) {
        _setMemos.remove(key);
      }
    });

    await _localStore.replaceAll(
      LocalShotlyState(
        manualStackNames: _manualStackNames,
        stackNames: _stackNames,
        hiddenStackKeys: _hiddenStackKeys,
        excludedImageIds: _excludedImageIds,
        favoriteImageIds: _favoriteImageIds,
        imageAssignments: _imageAssignments,
        setMemos: _setMemos,
        folderNames: _folderNames,
        folderColors: _folderColors,
        setAssignments: _setAssignments,
        pinnedStackKeys: _pinnedStackKeys,
        sortModeName: _sortMode.name,
      ),
    );
    if (mounted) {
      _showSnack(
        st(
          '앱 묶음을 해제하고 스크린샷을 미분류로 돌렸어요.',
          'Ungrouped the app and moved screenshots to Unsorted.',
        ),
      );
    }
  }

  Future<void> _togglePinStack(String stackKey) async {
    final shouldPin = !_pinnedStackKeys.contains(stackKey);
    setState(() {
      if (shouldPin) {
        _pinnedStackKeys.add(stackKey);
      } else {
        _pinnedStackKeys.remove(stackKey);
      }
    });
    if (shouldPin) {
      await _localStore.pinStack(stackKey);
    } else {
      await _localStore.unpinStack(stackKey);
    }
  }

  Future<void> _restoreStack(String stackKey) async {
    setState(() => _hiddenStackKeys.remove(stackKey));
    await _localStore.restoreStack(stackKey);
  }

  Future<void> _excludeImage(String imageId) async {
    setState(() => _excludedImageIds.add(imageId));
    await _localStore.excludeImage(imageId);
  }

  Future<void> _toggleFavoriteImage(String imageId) async {
    final shouldFavorite = !_favoriteImageIds.contains(imageId);
    setState(() {
      if (shouldFavorite) {
        _favoriteImageIds.add(imageId);
      } else {
        _favoriteImageIds.remove(imageId);
      }
    });
    if (shouldFavorite) {
      await _localStore.favoriteImage(imageId);
    } else {
      await _localStore.unfavoriteImage(imageId);
    }
  }

  Future<bool> _deleteOriginalImage(String imageId) async {
    try {
      unawaited(ShotlyAnalytics.log('delete_original_requested'));
      final deleted = await ShotlyNative.deleteOriginalImage(imageId);
      if (!deleted) {
        unawaited(ShotlyAnalytics.log('delete_original_failed'));
        if (mounted) {
          _showSnack(
            st(
              '원본 파일을 삭제하지 못했어요. 시스템 권한을 확인해줘.',
              'Couldn’t delete the original file. Check system permissions.',
            ),
          );
        }
        return false;
      }
      setState(() {
        _screenshots = _screenshots
            .where((item) => item.id != imageId)
            .toList();
        _excludedImageIds.remove(imageId);
        _favoriteImageIds.remove(imageId);
        _imageAssignments.remove(imageId);
        _setAssignments.remove(imageId);
        _visualFeatures.remove(imageId);
      });
      await _localStore.excludeImage(imageId);
      unawaited(ShotlyAnalytics.log('delete_original_succeeded'));
      if (mounted) {
        _showSnack(st('원본 파일을 삭제했어요.', 'Deleted the original file.'));
      }
      return true;
    } on PlatformException catch (e) {
      unawaited(ShotlyAnalytics.log('delete_original_failed'));
      if (mounted) _showSnack(e.message ?? e.code);
      return false;
    }
  }

  Future<bool> _deleteOriginalImages(List<String> imageIds) async {
    if (imageIds.isEmpty) return false;
    try {
      unawaited(ShotlyAnalytics.log('delete_original_requested'));
      final deleted = await ShotlyNative.deleteOriginalImages(imageIds);
      if (!deleted) {
        unawaited(ShotlyAnalytics.log('delete_original_failed'));
        if (mounted) {
          _showSnack(
            st(
              '선택한 원본 파일을 삭제하지 못했어요. 시스템 권한을 확인해줘.',
              'Couldn’t delete the selected originals. Check system permissions.',
            ),
          );
        }
        return false;
      }
      setState(() {
        final ids = imageIds.toSet();
        _screenshots = _screenshots
            .where((item) => !ids.contains(item.id))
            .toList();
        _excludedImageIds.removeAll(ids);
        for (final id in ids) {
          _imageAssignments.remove(id);
          _favoriteImageIds.remove(id);
          _setAssignments.remove(id);
          _visualFeatures.remove(id);
        }
      });
      for (final id in imageIds) {
        await _localStore.excludeImage(id);
      }
      unawaited(ShotlyAnalytics.log('delete_original_succeeded'));
      if (mounted) {
        _showSnack(
          st(
            '${imageIds.length}개 원본 파일을 삭제했어요.',
            'Deleted ${imageIds.length} original files.',
          ),
        );
      }
      return true;
    } on PlatformException catch (e) {
      unawaited(ShotlyAnalytics.log('delete_original_failed'));
      if (mounted) _showSnack(e.message ?? e.code);
      return false;
    }
  }

  Future<void> _pickDateFilter() async {
    final activeScreenshots = _effectiveScreenshots
        .where((item) => !_excludedImageIds.contains(item.id))
        .toList();
    final earliest = activeScreenshots.isEmpty
        ? DateTime(DateTime.now().year - 5)
        : activeScreenshots
              .map((item) => item.date)
              .reduce((a, b) => a.isBefore(b) ? a : b);
    final today = _dateOnly(DateTime.now());
    final currentRange = _selectedDateRange;
    final picked = await showDialog<DateTimeRange>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.10),
      builder: (context) => _ShotlyCalendarDialog(
        initialRange: currentRange,
        initialMonth: currentRange?.start ?? today,
        firstDate: DateTime(earliest.year, earliest.month, 1),
        lastDate: today,
        screenshotDates: activeScreenshots
            .map(
              (item) =>
                  DateTime(item.date.year, item.date.month, item.date.day),
            )
            .toSet(),
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDateRange = picked);
  }

  Future<void> _openSearchPage() async {
    final query = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _SearchPage(
          initialQuery: _query,
          stacks: _searchSourceStacks,
          allStackKeys: _stacks.map((item) => item.key).toList(),
          stackNames: _stackNames,
          setMemos: _setMemos,
          folderNames: _folderNames,
          folderColors: _folderColors,
          setAssignments: _setAssignments,
          favoriteImageIds: _favoriteImageIds,
          stackMatchesQuery: _stackMatchesQuery,
          onRenameStack: _renameStack,
          onHideStack: _hideStack,
          onDeleteStack: _deleteStack,
          onExcludeImage: _excludeImage,
          onDeleteOriginalImage: _deleteOriginalImage,
          onDeleteOriginalImages: _deleteOriginalImages,
          onToggleFavoriteImage: _toggleFavoriteImage,
          onMoveImage: _moveImage,
          onAddImageToStack: _pickAndAddImageToStack,
          onSaveSetMemo: _saveSetMemo,
          onSaveFolderName: _saveFolderName,
          onSaveFolderColor: _saveFolderColor,
          onAssignImageToSet: _assignImageToSet,
        ),
      ),
    );
    if (query != null && mounted) {
      setState(() => _query = query);
      _searchController.text = query;
    }
  }

  Future<void> _openFavoritesPage() async {
    final items = _effectiveScreenshots
        .where((item) => !_excludedImageIds.contains(item.id))
        .toList();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FavoritesScreen(
          items: items,
          allStackKeys: _searchSourceStacks.map((item) => item.key).toList(),
          stackNames: _stackNames,
          favoriteImageIds: _favoriteImageIds,
          onExcludeImage: _excludeImage,
          onDeleteOriginalImage: _deleteOriginalImage,
          onToggleFavoriteImage: _toggleFavoriteImage,
          onMoveImage: _moveImage,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _restoreImage(String imageId) async {
    setState(() => _excludedImageIds.remove(imageId));
    await _localStore.restoreImage(imageId);
  }

  Future<void> _moveImage(String imageId, String stackKey) async {
    setState(() {
      _imageAssignments[imageId] = stackKey;
      _setAssignments.remove(imageId);
    });
    if (!_manualStackNames.contains(stackKey) &&
        stackKey != 'Unknown' &&
        !_stacks.any((stack) => stack.key == stackKey)) {
      _manualStackNames.add(stackKey);
    }
    await _localStore.moveImage(imageId, stackKey);
    await _localStore.assignImageToSet(imageId, '');
  }

  Future<void> _saveSetMemo(String setKey, String memo) async {
    setState(() => _setMemos[setKey] = memo);
    await _localStore.saveSetMemo(setKey, memo);
  }

  Future<void> _saveFolderName(String folderKey, String name) async {
    setState(() {
      if (name.trim().isEmpty) {
        _folderNames.remove(folderKey);
      } else {
        _folderNames[folderKey] = name;
      }
    });
    await _localStore.saveFolderName(folderKey, name);
  }

  Future<void> _saveFolderColor(String folderKey, String colorKey) async {
    setState(() {
      if (colorKey.trim().isEmpty) {
        _folderColors.remove(folderKey);
      } else {
        _folderColors[folderKey] = colorKey;
      }
    });
    await _localStore.saveFolderColor(folderKey, colorKey);
  }

  Future<void> _saveSortMode(StackSortMode mode) async {
    setState(() {
      _sortMode = mode;
      _showSortMenu = false;
    });
    await _localStore.saveSortMode(mode.name);
  }

  Future<void> _assignImageToSet(String imageId, String setKey) async {
    final current = _setAssignments[imageId];
    final next = setKey.startsWith(_removeAssignmentPrefix)
        ? _removeAssignmentKey(
            current,
            setKey.substring(_removeAssignmentPrefix.length),
          )
        : setKey.isEmpty
        ? null
        : _addAssignmentKey(current, setKey);
    setState(() {
      if (next == null || next.isEmpty) {
        _setAssignments.remove(imageId);
      } else {
        _setAssignments[imageId] = next;
      }
    });
    await _localStore.assignImageToSet(imageId, next ?? '');
  }

  bool _stackMatchesQuery(StackItem stack, String query) {
    if (_textMatches(stack.name, query) || _textMatches(stack.key, query)) {
      return true;
    }
    if (stack.items.any((item) => item.matches(query))) return true;
    final sets = _buildScreenshotSets(
      stack.key,
      stack.items,
      _setMemos,
      _folderNames,
      _setAssignments,
    );
    return sets.any(
      (set) =>
          _textMatches(set.memo, query) ||
          (_isFolderSetKey(set.key) && _textMatches(_folderName(set), query)) ||
          _textMatches(set.timeRange, query) ||
          (set.items.isNotEmpty &&
              _textMatches(_formatSetDate(set.items.first.date), query)),
    );
  }

  bool _textMatches(String text, String query) =>
      text.toLowerCase().contains(query.toLowerCase());

  void _toggleHomeSelection(String imageId) {
    setState(() {
      _isHomeSelectionMode = true;
      if (!_homeSelectedImageIds.add(imageId)) {
        _homeSelectedImageIds.remove(imageId);
      }
      if (_homeSelectedImageIds.isEmpty) _isHomeSelectionMode = false;
    });
  }

  void _toggleHomeDateSelection(List<String> imageIds) {
    setState(() {
      _isHomeSelectionMode = true;
      final allSelected = imageIds.every(_homeSelectedImageIds.contains);
      if (allSelected) {
        _homeSelectedImageIds.removeAll(imageIds);
      } else {
        _homeSelectedImageIds.addAll(imageIds);
      }
      if (_homeSelectedImageIds.isEmpty) _isHomeSelectionMode = false;
    });
  }

  void _clearHomeSelection() {
    setState(() {
      _homeSelectedImageIds.clear();
      _isHomeSelectionMode = false;
    });
  }

  Future<void> _shareHomeSelected() async {
    await ShotlyNative.shareImages(_homeSelectedImageIds.toList());
  }

  Future<void> _hideHomeSelected() async {
    final selected = _homeSelectedImageIds.toList();
    for (final id in selected) {
      await _excludeImage(id);
    }
    _clearHomeSelection();
  }

  Future<void> _deleteHomeSelected(BuildContext context) async {
    final confirmed = await _showShotlyConfirmDialog(
      context: context,
      title: st('선택한 사진 삭제', 'Delete selected photos'),
      body: st(
        '선택한 ${_homeSelectedImageIds.length}장을 기기 앨범 원본에서도 삭제할까요? 이 작업은 되돌릴 수 없어요.',
        'Delete ${_homeSelectedImageIds.length} selected originals from your device gallery? This can’t be undone.',
      ),
      primaryLabel: st('삭제', 'Delete'),
      destructive: true,
    );
    if (confirmed != true) return;
    await _deleteOriginalImages(_homeSelectedImageIds.toList());
    _clearHomeSelection();
  }

  Future<void> _moveHomeSelectedToStack(BuildContext context) async {
    final targets = _availableStackTargets;
    final target = await _showShotlyActionSheet<String>(
      context,
      title: st('이동할 앱', 'Move to app'),
      items: [
        _ShotlyActionItem(
          value: '__new_stack__',
          icon: Icons.layers_rounded,
          title: st('새 앱 만들기', 'Create new app'),
        ),
        ...targets.map(
          (stack) => _ShotlyActionItem(
            value: stack.key,
            icon: Icons.layers_rounded,
            title: stack.name,
          ),
        ),
      ],
    );
    if (target == null || !context.mounted) return;
    var stackKey = target;
    if (target == '__new_stack__') {
      final name = await _showShotlyTextDialog(
        context: context,
        title: st('앱 만들기', 'Create app'),
        hintText: st('앱 이름', 'App name'),
        primaryLabel: st('만들기', 'Create'),
      );
      final trimmed = name?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      stackKey = trimmed;
      setState(() {
        _manualStackNames.add(stackKey);
        _stackNames[stackKey] = trimmed;
      });
      await _localStore.renameStack(stackKey, trimmed);
    }
    final selected = _homeSelectedImageIds.toList();
    for (final id in selected) {
      await _moveImage(id, stackKey);
    }
    _clearHomeSelection();
  }

  Future<void> _showAddMenu() async {
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
                icon: Icons.layers_rounded,
                title: st('앱 추가', 'Add app'),
                onTap: () => Navigator.of(context).pop('stack'),
              ),
              _AddMenuTile(
                icon: Icons.photo_library_rounded,
                title: st('이미지 추가', 'Add image'),
                onTap: () => Navigator.of(context).pop('image'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == 'stack') await _showCreateStackDialog();
    if (action == 'image') await _pickImageFromAlbum();
  }

  @override
  Widget build(BuildContext context) {
    final filteredScreenshots = _filteredScreenshots
      ..sort((a, b) => b.dateTakenMillis.compareTo(a.dateTakenMillis));
    final stacks = _stacks;
    final unclassifiedDateGroups = _groupSetsByDate(_unclassifiedHomeSets);
    final hasUnsorted = unclassifiedDateGroups.isNotEmpty;
    final showUnsortedHeader = hasUnsorted && stacks.isNotEmpty;
    final unsortedExpanded = showUnsortedHeader
        ? (_unsortedExpandedOverride ?? false)
        : hasUnsorted;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF111111),
              child: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _ShotlyTopBarDelegate(
                      searchController: _searchController,
                      onSearchTap: _openSearchPage,
                      selectedDateRange: _selectedDateRange,
                      onPickDate: _pickDateFilter,
                      onClearDate: () =>
                          setState(() => _selectedDateRange = null),
                      favoriteCount: _favoriteImageIds.length,
                      onFavorites: _openFavoritesPage,
                      onAdd: _showAddMenu,
                      onSettings: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            photoPermissionStatus: _photoPermissionStatus,
                            hiddenStacks: _hiddenStacks,
                            excludedImages: _excludedImages,
                            onOpenPhotoSettings: _openPhotoSettings,
                            onRestoreStack: _restoreStack,
                            onRestoreImage: _restoreImage,
                            onDeleteOriginalImage: _deleteOriginalImage,
                            onDeleteOriginalImages: _deleteOriginalImages,
                            onExportBackup: _exportBackup,
                            onImportBackup: _importBackup,
                            onStartPhoneTransfer: _startPhoneTransfer,
                            onReceivePhoneTransfer: _receivePhoneTransfer,
                            testerNoAppInfoMode: _testerNoAppInfoMode,
                            onSetTesterNoAppInfoMode: _setTesterNoAppInfoMode,
                            onResetOrganizationData: _resetOrganizationData,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isLoading)
                            const _LoadingState()
                          else if (!_hasPermission)
                            _PermissionState(onRequest: _load)
                          else if (_error != null)
                            _ErrorState(message: _error!, onRetry: _load)
                          else ...[
                            _SummarySortRow(
                              screenshotCount: filteredScreenshots.length,
                              stackCount: stacks.length,
                              sortMode: _sortMode,
                              showSortMenu: _showSortMenu,
                              onToggleSort: () => setState(
                                () => _showSortMenu = !_showSortMenu,
                              ),
                              onSelectSort: _saveSortMode,
                            ),
                            const SizedBox(height: 26),
                            if (_effectiveScreenshots.isEmpty &&
                                stacks.isEmpty &&
                                !hasUnsorted)
                              const _EmptyState()
                            else ...[
                              ...stacks.map(
                                (stack) => Padding(
                                  padding: const EdgeInsets.only(bottom: 26),
                                  child: _StackCard(
                                    stack: stack,
                                    allStackKeys: _stacks
                                        .map((item) => item.key)
                                        .toList(),
                                    stackNames: _stackNames,
                                    setMemos: _setMemos,
                                    folderNames: _folderNames,
                                    folderColors: _folderColors,
                                    setAssignments: _setAssignments,
                                    favoriteImageIds: _favoriteImageIds,
                                    visualFeatures: _visualFeatures,
                                    onRenameStack: _renameStack,
                                    onHideStack: _hideStack,
                                    onDeleteStack: _deleteStack,
                                    onTogglePinStack: _togglePinStack,
                                    pinned: _pinnedStackKeys.contains(
                                      stack.key,
                                    ),
                                    onExcludeImage: _excludeImage,
                                    onDeleteOriginalImage: _deleteOriginalImage,
                                    onDeleteOriginalImages:
                                        _deleteOriginalImages,
                                    onToggleFavoriteImage: _toggleFavoriteImage,
                                    onMoveImage: _moveImage,
                                    onAddImageToStack: _pickAndAddImageToStack,
                                    onSaveSetMemo: _saveSetMemo,
                                    onSaveFolderName: _saveFolderName,
                                    onSaveFolderColor: _saveFolderColor,
                                    onAssignImageToSet: _assignImageToSet,
                                  ),
                                ),
                              ),
                              if (hasUnsorted) ...[
                                if (showUnsortedHeader)
                                  _UnsortedHeader(
                                    count: _unclassifiedHomeSets.fold<int>(
                                      0,
                                      (sum, set) => sum + set.items.length,
                                    ),
                                    expanded: unsortedExpanded,
                                    onTap: () => setState(
                                      () => _unsortedExpandedOverride =
                                          !unsortedExpanded,
                                    ),
                                  ),
                                if (unsortedExpanded) ...[
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: showUnsortedHeader ? 10 : 0,
                                      bottom: 18,
                                    ),
                                    child: Text(
                                      st(
                                        '같은 앱에서 찍은 사진들을 골라서 앱별로 정리해보세요.',
                                        'Select screenshots from the same app and organize them together.',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFF727785),
                                            height: 1.35,
                                          ),
                                    ),
                                  ),
                                  ...unclassifiedDateGroups.map(
                                    (dateGroup) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 22,
                                      ),
                                      child: _SetDateSection(
                                        dateLabel: dateGroup.dateLabel,
                                        sets: dateGroup.sets,
                                        allStackKeys: _availableStackTargets
                                            .map((stack) => stack.key)
                                            .toList(),
                                        stackNames: _stackNames,
                                        favoriteImageIds: _favoriteImageIds,
                                        onExcludeImage: _excludeImage,
                                        onDeleteOriginalImage:
                                            _deleteOriginalImage,
                                        onToggleFavoriteImage:
                                            _toggleFavoriteImage,
                                        onMoveImage: _moveImage,
                                        selectedIds: _homeSelectedImageIds,
                                        selectionMode: _isHomeSelectionMode,
                                        onToggleSelection: _toggleHomeSelection,
                                        onToggleDateSelection:
                                            _toggleHomeDateSelection,
                                        showLocalActionBar: false,
                                        onSaveMemo: _saveSetMemo,
                                        onAssignImageToSet: _assignImageToSet,
                                        viewerItems: filteredScreenshots,
                                      ),
                                    ),
                                  ),
                                ] else
                                  const SizedBox(height: 22),
                              ] else if (stacks.isEmpty)
                                const _NoResultState(),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showSortMenu)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => setState(() => _showSortMenu = false),
                ),
              ),
            if (_showSortMenu)
              Positioned(
                top: 138,
                right: 20,
                child: _SortDropdown(
                  selected: _sortMode,
                  onSelect: _saveSortMode,
                ),
              ),
            if (hasUnsorted && _isHomeSelectionMode)
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: _SelectionActionBar(
                  onCancel: _clearHomeSelection,
                  onShare: _shareHomeSelected,
                  onDelete: () => _deleteHomeSelected(context),
                  onMove: () => _moveHomeSelectedToStack(context),
                  onHide: _hideHomeSelected,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
