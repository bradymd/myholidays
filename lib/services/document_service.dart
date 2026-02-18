import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DocumentService {
  static Future<String> get _docsDir async {
    final dir = await getApplicationDocumentsDirectory();
    final docsPath = p.join(dir.path, 'my_holidays_docs');
    await Directory(docsPath).create(recursive: true);
    return docsPath;
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
