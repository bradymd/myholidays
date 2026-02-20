import 'dart:io';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

class AutoBackupInfo {
  final DateTime timestamp;
  final int sizeBytes;

  const AutoBackupInfo({required this.timestamp, required this.sizeBytes});
}

class BackupService {
  static const _dbFilename = 'my_holidays.sqlite';
  static const _docsFolder = 'my_holidays_docs';
  static const _autoBackupFilename = 'my_holidays_autobackup.zip';

  /// Creates a backup ZIP and returns the temp file path.
  static Future<String> createBackup() async {
    final appDir = await getApplicationDocumentsDirectory();
    final archive = await _buildArchive(appDir.path);

    final zipData = ZipEncoder().encode(archive);

    final timestamp = DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());
    final tempDir = await getTemporaryDirectory();
    final zipPath =
        p.join(tempDir.path, 'backup-myholidays-$timestamp.zip');
    await File(zipPath).writeAsBytes(zipData);
    return zipPath;
  }

  /// Creates/overwrites the rolling auto-backup. Silently skips if no DB.
  static Future<void> createAutoBackup() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(appDir.path, _dbFilename));

    // Nothing to back up on first launch
    if (!await dbFile.exists()) return;

    final archive = await _buildArchive(appDir.path);
    final zipData = ZipEncoder().encode(archive);

    final zipPath = p.join(appDir.path, _autoBackupFilename);
    await File(zipPath).writeAsBytes(zipData);
  }

  /// Returns info about the auto-backup, or null if none exists.
  static Future<AutoBackupInfo?> getAutoBackupInfo() async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(appDir.path, _autoBackupFilename));

    if (!await file.exists()) return null;

    final stat = await file.stat();
    return AutoBackupInfo(timestamp: stat.modified, sizeBytes: stat.size);
  }

  /// Returns the auto-backup file path, or null.
  static Future<String?> getAutoBackupPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(appDir.path, _autoBackupFilename));
    if (await file.exists()) return file.path;
    return null;
  }

  /// Restores data from a backup ZIP. Returns true on success.
  static Future<bool> restoreFromBackup(String zipPath) async {
    final zipFile = File(zipPath);
    if (!await zipFile.exists()) return false;

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Basic validation — must contain the database file
    final hasDb = archive.any((f) => f.name == _dbFilename);
    if (!hasDb) return false;

    final appDir = await getApplicationDocumentsDirectory();

    // Remove existing docs folder before extracting
    final dir = Directory(p.join(appDir.path, _docsFolder));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    // Delete WAL and SHM journal files so the old Drift connection
    // cannot checkpoint stale data over the restored database.
    for (final suffix in ['-wal', '-shm']) {
      final journal = File(p.join(appDir.path, '$_dbFilename$suffix'));
      if (await journal.exists()) {
        await journal.delete();
      }
    }

    // Extract all files
    for (final entry in archive) {
      final outPath = p.join(appDir.path, entry.name);
      if (entry.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(entry.content as List<int>);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    // Rewrite document paths to match this device's app directory
    await _rewriteDocumentPaths(appDir.path);

    return true;
  }

  /// After restore, rewrite absolute file paths in the DB to match
  /// this device's app documents directory.
  static Future<void> _rewriteDocumentPaths(String appDirPath) async {
    final dbPath = p.join(appDirPath, _dbFilename);

    final db = sql.sqlite3.open(dbPath);
    try {
      _rewriteColumn(db, 'document_refs', 'local_path', appDirPath);
    } finally {
      db.dispose();
    }
  }

  static void _rewriteColumn(
    sql.Database db,
    String table,
    String column,
    String appDirPath,
  ) {
    final knownFolders = [_docsFolder];
    final rows = db.select(
      "SELECT id, $column FROM $table WHERE $column != ''",
    );
    for (final row in rows) {
      final id = row['id'] as String;
      final oldPath = row[column] as String;

      String? newPath;
      for (final folder in knownFolders) {
        final folderIndex = oldPath.indexOf('$folder/');
        if (folderIndex >= 0) {
          final relativePart = oldPath.substring(folderIndex);
          newPath = p.join(appDirPath, relativePart);
          break;
        }
      }

      newPath ??= p.join(appDirPath, _docsFolder, p.basename(oldPath));

      db.execute(
        'UPDATE $table SET $column = ? WHERE id = ?',
        [newPath, id],
      );
    }
  }

  // --- Private helpers ---

  static Future<Archive> _buildArchive(String appDirPath) async {
    final archive = Archive();

    // Add database file
    final dbFile = File(p.join(appDirPath, _dbFilename));
    if (await dbFile.exists()) {
      final bytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile(_dbFilename, bytes.length, bytes));
    }

    // Add docs folder to the archive
    final dir = Directory(p.join(appDirPath, _docsFolder));
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = p.join(
            _docsFolder,
            p.relative(entity.path, from: dir.path),
          );
          final bytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
        }
      }
    }

    return archive;
  }
}
