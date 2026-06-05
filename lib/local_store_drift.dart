import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_store_models.dart';

class ShotlyLocalStore implements LocalStore {
  ShotlyLocalStore() : _db = ShotlyDatabase(_openConnection());

  static const _manualStacksPrefsKey = 'shotly.manualStacks';
  static const _stackNamesPrefsKey = 'shotly.stackNames';
  static const _hiddenStacksPrefsKey = 'shotly.hiddenStacks';
  static const _excludedImagesPrefsKey = 'shotly.excludedImages';
  static const _favoriteImagesPrefsKey = 'shotly.favoriteImages';
  static const _imageAssignmentsPrefsKey = 'shotly.imageAssignments';
  static const _setMemosPrefsKey = 'shotly.setMemos';
  static const _folderNamesPrefsKey = 'shotly.folderNames';
  static const _folderColorsPrefsKey = 'shotly.folderColors';
  static const _setAssignmentsPrefsKey = 'shotly.setAssignments';
  static const _pinnedStacksPrefsKey = 'shotly.pinnedStacks';
  static const _sortModePrefsKey = 'shotly.sortMode';
  static const _migrationPrefsKey = 'shotly.driftMigration.v1';

  final ShotlyDatabase _db;

  @override
  Future<LocalShotlyState> load() async {
    await _db.ensureOpen();
    await _migrateSharedPreferencesIfNeeded();

    final manualStacks = await _db
        .customSelect('SELECT name FROM manual_stacks ORDER BY created_at ASC')
        .get();
    final stackRows = await _db
        .customSelect('SELECT stack_key, name FROM stack_customizations')
        .get();
    final assignmentRows = await _db
        .customSelect('SELECT image_id, stack_key FROM image_assignments')
        .get();
    final memoRows = await _db
        .customSelect('SELECT set_key, memo FROM set_memos')
        .get();
    final folderNameRows = await _db
        .customSelect('SELECT folder_key, name FROM folder_names')
        .get();
    final folderColorRows = await _db
        .customSelect('SELECT folder_key, color_key FROM folder_colors')
        .get();
    final setAssignmentRows = await _db
        .customSelect('SELECT image_id, set_key FROM set_assignments')
        .get();
    final hiddenRows = await _db
        .customSelect('SELECT stack_key FROM hidden_stacks')
        .get();
    final excludedRows = await _db
        .customSelect('SELECT image_id FROM excluded_images')
        .get();
    final favoriteRows = await _db
        .customSelect('SELECT image_id FROM favorite_images')
        .get();
    final pinnedRows = await _db
        .customSelect(
          'SELECT stack_key FROM pinned_stacks ORDER BY created_at ASC',
        )
        .get();
    final settingRows = await _db
        .customSelect("SELECT value FROM settings WHERE key = 'sort_mode'")
        .get();

    return LocalShotlyState(
      manualStackNames: [
        for (final row in manualStacks) row.read<String>('name'),
      ],
      stackNames: {
        for (final row in stackRows)
          row.read<String>('stack_key'): row.read<String>('name'),
      },
      imageAssignments: {
        for (final row in assignmentRows)
          row.read<String>('image_id'): row.read<String>('stack_key'),
      },
      setMemos: {
        for (final row in memoRows)
          row.read<String>('set_key'): row.read<String>('memo'),
      },
      folderNames: {
        for (final row in folderNameRows)
          row.read<String>('folder_key'): row.read<String>('name'),
      },
      folderColors: {
        for (final row in folderColorRows)
          row.read<String>('folder_key'): row.read<String>('color_key'),
      },
      setAssignments: {
        for (final row in setAssignmentRows)
          row.read<String>('image_id'): row.read<String>('set_key'),
      },
      hiddenStackKeys: {
        for (final row in hiddenRows) row.read<String>('stack_key'),
      },
      excludedImageIds: {
        for (final row in excludedRows) row.read<String>('image_id'),
      },
      favoriteImageIds: {
        for (final row in favoriteRows) row.read<String>('image_id'),
      },
      pinnedStackKeys: [
        for (final row in pinnedRows) row.read<String>('stack_key'),
      ],
      sortModeName: settingRows.isEmpty
          ? null
          : settingRows.first.read<String>('value'),
    );
  }

  @override
  Future<void> replaceAll(LocalShotlyState state) async {
    await _db.ensureOpen();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      for (final table in const [
        'manual_stacks',
        'stack_customizations',
        'image_assignments',
        'set_memos',
        'folder_names',
        'folder_colors',
        'set_assignments',
        'hidden_stacks',
        'excluded_images',
        'favorite_images',
        'pinned_stacks',
        'settings',
      ]) {
        await _db.customStatement('DELETE FROM $table');
      }
      for (final name in state.manualStackNames) {
        await _db.customStatement(
          'INSERT OR IGNORE INTO manual_stacks(name, created_at) VALUES (?, ?)',
          [name, now],
        );
      }
      for (final entry in state.stackNames.entries) {
        await _db.customStatement(
          'INSERT OR REPLACE INTO stack_customizations(stack_key, name, updated_at) VALUES (?, ?, ?)',
          [entry.key, entry.value, now],
        );
      }
      for (final entry in state.imageAssignments.entries) {
        await _db.customStatement(
          'INSERT OR REPLACE INTO image_assignments(image_id, stack_key, updated_at) VALUES (?, ?, ?)',
          [entry.key, entry.value, now],
        );
      }
      for (final entry in state.setMemos.entries) {
        await _db.customStatement(
          'INSERT OR REPLACE INTO set_memos(set_key, memo, updated_at) VALUES (?, ?, ?)',
          [entry.key, entry.value, now],
        );
      }
      for (final entry in state.folderNames.entries) {
        await _db.customStatement(
          'INSERT OR REPLACE INTO folder_names(folder_key, name, updated_at) VALUES (?, ?, ?)',
          [entry.key, entry.value, now],
        );
      }
      for (final entry in state.folderColors.entries) {
        await _db.customStatement(
          'INSERT OR REPLACE INTO folder_colors(folder_key, color_key, updated_at) VALUES (?, ?, ?)',
          [entry.key, entry.value, now],
        );
      }
      for (final entry in state.setAssignments.entries) {
        await _db.customStatement(
          'INSERT OR REPLACE INTO set_assignments(image_id, set_key, updated_at) VALUES (?, ?, ?)',
          [entry.key, entry.value, now],
        );
      }
      for (final stackKey in state.hiddenStackKeys) {
        await _db.customStatement(
          'INSERT OR IGNORE INTO hidden_stacks(stack_key, created_at) VALUES (?, ?)',
          [stackKey, now],
        );
      }
      for (final imageId in state.excludedImageIds) {
        await _db.customStatement(
          'INSERT OR IGNORE INTO excluded_images(image_id, created_at) VALUES (?, ?)',
          [imageId, now],
        );
      }
      for (final imageId in state.favoriteImageIds) {
        await _db.customStatement(
          'INSERT OR IGNORE INTO favorite_images(image_id, created_at) VALUES (?, ?)',
          [imageId, now],
        );
      }
      for (final stackKey in state.pinnedStackKeys) {
        await _db.customStatement(
          'INSERT OR IGNORE INTO pinned_stacks(stack_key, created_at) VALUES (?, ?)',
          [stackKey, now],
        );
      }
      if (state.sortModeName != null) {
        await _db.customStatement(
          'INSERT OR REPLACE INTO settings(key, value, updated_at) VALUES (?, ?, ?)',
          ['sort_mode', state.sortModeName!, now],
        );
      }
    });
  }

  @override
  Future<void> upsertManualStack(String name) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'INSERT OR IGNORE INTO manual_stacks(name, created_at) VALUES (?, ?)',
      [name, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<void> renameStack(String stackKey, String name) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'INSERT OR REPLACE INTO stack_customizations(stack_key, name, updated_at) VALUES (?, ?, ?)',
      [stackKey, name, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<void> hideStack(String stackKey) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'INSERT OR IGNORE INTO hidden_stacks(stack_key, created_at) VALUES (?, ?)',
      [stackKey, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<void> restoreStack(String stackKey) async {
    await _db.ensureOpen();
    await _db.customStatement('DELETE FROM hidden_stacks WHERE stack_key = ?', [
      stackKey,
    ]);
  }

  @override
  Future<void> excludeImage(String imageId) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'INSERT OR IGNORE INTO excluded_images(image_id, created_at) VALUES (?, ?)',
      [imageId, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<void> restoreImage(String imageId) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'DELETE FROM excluded_images WHERE image_id = ?',
      [imageId],
    );
  }

  @override
  Future<void> favoriteImage(String imageId) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'INSERT OR IGNORE INTO favorite_images(image_id, created_at) VALUES (?, ?)',
      [imageId, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<void> unfavoriteImage(String imageId) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'DELETE FROM favorite_images WHERE image_id = ?',
      [imageId],
    );
  }

  @override
  Future<void> moveImage(String imageId, String stackKey) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'INSERT OR REPLACE INTO image_assignments(image_id, stack_key, updated_at) VALUES (?, ?, ?)',
      [imageId, stackKey, DateTime.now().millisecondsSinceEpoch],
    );
    await upsertManualStack(stackKey);
  }

  @override
  Future<void> saveSetMemo(String setKey, String memo) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'INSERT OR REPLACE INTO set_memos(set_key, memo, updated_at) VALUES (?, ?, ?)',
      [setKey, memo, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<void> saveFolderName(String folderKey, String name) async {
    await _db.ensureOpen();
    if (name.trim().isEmpty) {
      await _db.customStatement(
        'DELETE FROM folder_names WHERE folder_key = ?',
        [folderKey],
      );
      return;
    }
    await _db.customStatement(
      'INSERT OR REPLACE INTO folder_names(folder_key, name, updated_at) VALUES (?, ?, ?)',
      [folderKey, name, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<void> saveFolderColor(String folderKey, String colorKey) async {
    await _db.ensureOpen();
    if (colorKey.trim().isEmpty) {
      await _db.customStatement(
        'DELETE FROM folder_colors WHERE folder_key = ?',
        [folderKey],
      );
      return;
    }
    await _db.customStatement(
      'INSERT OR REPLACE INTO folder_colors(folder_key, color_key, updated_at) VALUES (?, ?, ?)',
      [folderKey, colorKey, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<void> assignImageToSet(String imageId, String setKey) async {
    await _db.ensureOpen();
    if (setKey.isEmpty) {
      await _db.customStatement(
        'DELETE FROM set_assignments WHERE image_id = ?',
        [imageId],
      );
      return;
    }
    await _db.customStatement(
      'INSERT OR REPLACE INTO set_assignments(image_id, set_key, updated_at) VALUES (?, ?, ?)',
      [imageId, setKey, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<void> pinStack(String stackKey) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'INSERT OR IGNORE INTO pinned_stacks(stack_key, created_at) VALUES (?, ?)',
      [stackKey, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<void> unpinStack(String stackKey) async {
    await _db.ensureOpen();
    await _db.customStatement('DELETE FROM pinned_stacks WHERE stack_key = ?', [
      stackKey,
    ]);
  }

  @override
  Future<void> saveSortMode(String sortModeName) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'INSERT OR REPLACE INTO settings(key, value, updated_at) VALUES (?, ?, ?)',
      ['sort_mode', sortModeName, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<Map<String, OcrIndexEntry>> loadOcrIndex() async {
    await _db.ensureOpen();
    final rows = await _db
        .customSelect(
          'SELECT image_id, status, text, updated_at, error_message FROM screenshot_ocr',
        )
        .get();
    return {
      for (final row in rows)
        row.read<String>('image_id'): OcrIndexEntry(
          imageId: row.read<String>('image_id'),
          status: _ocrStatusFromName(row.read<String>('status')),
          text: row.read<String>('text'),
          updatedAtMillis: row.read<int>('updated_at'),
          errorMessage: row.readNullable<String>('error_message'),
        ),
    };
  }

  @override
  Future<void> saveOcrText(String imageId, String text) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'INSERT OR REPLACE INTO screenshot_ocr(image_id, status, text, updated_at, error_message) VALUES (?, ?, ?, ?, NULL)',
      [
        imageId,
        OcrIndexStatus.done.name,
        text,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  @override
  Future<void> saveOcrFailure(String imageId, String errorMessage) async {
    await _db.ensureOpen();
    await _db.customStatement(
      'INSERT OR REPLACE INTO screenshot_ocr(image_id, status, text, updated_at, error_message) VALUES (?, ?, ?, ?, ?)',
      [
        imageId,
        OcrIndexStatus.failed.name,
        '',
        DateTime.now().millisecondsSinceEpoch,
        errorMessage.takeForShotly(240),
      ],
    );
  }

  Future<void> _migrateSharedPreferencesIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationPrefsKey) ?? false) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final manualStacks = prefs.getStringList(_manualStacksPrefsKey) ?? const [];
    for (final name in manualStacks) {
      await _db.customStatement(
        'INSERT OR IGNORE INTO manual_stacks(name, created_at) VALUES (?, ?)',
        [name, now],
      );
    }

    for (final entry in _decodeStringMap(
      prefs.getString(_stackNamesPrefsKey),
    ).entries) {
      await _db.customStatement(
        'INSERT OR REPLACE INTO stack_customizations(stack_key, name, updated_at) VALUES (?, ?, ?)',
        [entry.key, entry.value, now],
      );
    }
    for (final entry in _decodeStringMap(
      prefs.getString(_imageAssignmentsPrefsKey),
    ).entries) {
      await _db.customStatement(
        'INSERT OR REPLACE INTO image_assignments(image_id, stack_key, updated_at) VALUES (?, ?, ?)',
        [entry.key, entry.value, now],
      );
    }
    for (final entry in _decodeStringMap(
      prefs.getString(_setMemosPrefsKey),
    ).entries) {
      await _db.customStatement(
        'INSERT OR REPLACE INTO set_memos(set_key, memo, updated_at) VALUES (?, ?, ?)',
        [entry.key, entry.value, now],
      );
    }
    for (final entry in _decodeStringMap(
      prefs.getString(_folderNamesPrefsKey),
    ).entries) {
      await _db.customStatement(
        'INSERT OR REPLACE INTO folder_names(folder_key, name, updated_at) VALUES (?, ?, ?)',
        [entry.key, entry.value, now],
      );
    }
    for (final entry in _decodeStringMap(
      prefs.getString(_folderColorsPrefsKey),
    ).entries) {
      await _db.customStatement(
        'INSERT OR REPLACE INTO folder_colors(folder_key, color_key, updated_at) VALUES (?, ?, ?)',
        [entry.key, entry.value, now],
      );
    }
    for (final entry in _decodeStringMap(
      prefs.getString(_setAssignmentsPrefsKey),
    ).entries) {
      await _db.customStatement(
        'INSERT OR REPLACE INTO set_assignments(image_id, set_key, updated_at) VALUES (?, ?, ?)',
        [entry.key, entry.value, now],
      );
    }
    for (final stackKey
        in prefs.getStringList(_hiddenStacksPrefsKey) ?? const <String>[]) {
      await _db.customStatement(
        'INSERT OR IGNORE INTO hidden_stacks(stack_key, created_at) VALUES (?, ?)',
        [stackKey, now],
      );
    }
    for (final imageId
        in prefs.getStringList(_excludedImagesPrefsKey) ?? const <String>[]) {
      await _db.customStatement(
        'INSERT OR IGNORE INTO excluded_images(image_id, created_at) VALUES (?, ?)',
        [imageId, now],
      );
    }
    for (final imageId
        in prefs.getStringList(_favoriteImagesPrefsKey) ?? const <String>[]) {
      await _db.customStatement(
        'INSERT OR IGNORE INTO favorite_images(image_id, created_at) VALUES (?, ?)',
        [imageId, now],
      );
    }
    for (final stackKey
        in prefs.getStringList(_pinnedStacksPrefsKey) ?? const <String>[]) {
      await _db.customStatement(
        'INSERT OR IGNORE INTO pinned_stacks(stack_key, created_at) VALUES (?, ?)',
        [stackKey, now],
      );
    }
    final sortMode = prefs.getString(_sortModePrefsKey);
    if (sortMode != null) {
      await _db.customStatement(
        'INSERT OR REPLACE INTO settings(key, value, updated_at) VALUES (?, ?, ?)',
        ['sort_mode', sortMode, now],
      );
    }

    await prefs.setBool(_migrationPrefsKey, true);
  }

  static Map<String, String> _decodeStringMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, '$value'));
  }
}

class ShotlyDatabase extends GeneratedDatabase {
  ShotlyDatabase(super.e);

  bool _opened = false;

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  Future<void> ensureOpen() async {
    if (_opened) return;
    await customStatement('''
      CREATE TABLE IF NOT EXISTS manual_stacks (
        name TEXT PRIMARY KEY NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS stack_customizations (
        stack_key TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS image_assignments (
        image_id TEXT PRIMARY KEY NOT NULL,
        stack_key TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS set_memos (
        set_key TEXT PRIMARY KEY NOT NULL,
        memo TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS folder_names (
        folder_key TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS folder_colors (
        folder_key TEXT PRIMARY KEY NOT NULL,
        color_key TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS set_assignments (
        image_id TEXT PRIMARY KEY NOT NULL,
        set_key TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS hidden_stacks (
        stack_key TEXT PRIMARY KEY NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS excluded_images (
        image_id TEXT PRIMARY KEY NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS favorite_images (
        image_id TEXT PRIMARY KEY NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS pinned_stacks (
        stack_key TEXT PRIMARY KEY NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS screenshot_ocr (
        image_id TEXT PRIMARY KEY NOT NULL,
        status TEXT NOT NULL,
        text TEXT NOT NULL DEFAULT '',
        updated_at INTEGER NOT NULL,
        error_message TEXT
      )
    ''');
    _opened = true;
  }
}

OcrIndexStatus _ocrStatusFromName(String name) {
  for (final status in OcrIndexStatus.values) {
    if (status.name == name) return status;
  }
  return OcrIndexStatus.pending;
}

extension _ShotlyStringLimit on String {
  String takeForShotly(int maxLength) =>
      length <= maxLength ? this : substring(0, maxLength);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await _databaseDirectory();
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'shotly.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

Future<Directory> _databaseDirectory() async {
  final override = Platform.environment['SHOTLY_DB_DIR'];
  if (override != null && override.isNotEmpty) return Directory(override);
  if (Platform.isAndroid) {
    return getApplicationSupportDirectory();
  }
  final home = Platform.environment['HOME'];
  if (home != null && home.isNotEmpty) {
    return Directory(p.join(home, 'Documents'));
  }
  return Directory.systemTemp;
}
