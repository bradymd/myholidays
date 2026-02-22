import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

class DocumentService {
  static const _docsFolder = 'my_holidays_docs';
  static const _dbFilename = 'my_holidays.sqlite';

  static Future<String> get _docsDir async {
    final dir = await getApplicationDocumentsDirectory();
    final docsPath = p.join(dir.path, _docsFolder);
    await Directory(docsPath).create(recursive: true);
    return docsPath;
  }

  /// Rewrites stale absolute document paths in the DB to match the current
  /// app documents directory. Needed on iOS where the sandbox UUID changes
  /// after app updates.
  static Future<void> repairPaths() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, _dbFilename);
    if (!File(dbPath).existsSync()) return;

    final db = sql.sqlite3.open(dbPath);
    try {
      final rows = db.select(
        "SELECT id, local_path FROM document_refs WHERE local_path != ''",
      );
      for (final row in rows) {
        final id = row['id'] as String;
        final oldPath = row['local_path'] as String;

        final folderIndex = oldPath.indexOf('$_docsFolder/');
        if (folderIndex < 0) continue;

        final relativePart = oldPath.substring(folderIndex);
        final newPath = p.join(appDir.path, relativePart);
        if (newPath == oldPath) continue;

        db.execute(
          'UPDATE document_refs SET local_path = ? WHERE id = ?',
          [newPath, id],
        );
      }
    } finally {
      db.dispose();
    }
  }

  static Future<String> saveFile(String sourcePath, String filename) async {
    final dir = await _docsDir;
    final ext = p.extension(sourcePath);
    final safeName = filename.isNotEmpty
        ? filename
        : 'doc_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(dir, safeName);

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      debugPrint('DocumentService: source file not found: $sourcePath');
      return destPath;
    }
    await sourceFile.copy(destPath);
    return destPath;
  }

  static Future<bool> deleteFile(String localPath) async {
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  static Future<void> openFile(String localPath) async {
    await OpenFile.open(localPath);
  }

  static String getFileType(String path) {
    final ext = p.extension(path).toLowerCase();
    return switch (ext) {
      '.pdf' => 'PDF',
      '.jpg' || '.jpeg' => 'Image',
      '.png' => 'Image',
      '.doc' || '.docx' => 'Document',
      '.xls' || '.xlsx' => 'Spreadsheet',
      _ => 'File',
    };
  }
}
