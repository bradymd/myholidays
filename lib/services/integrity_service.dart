import 'dart:io';

import 'package:my_holidays/database/database.dart';

class IntegrityIssue {
  final String recordType;
  final String recordLabel;
  final String field;
  final String problem;
  final String path;

  const IntegrityIssue({
    required this.recordType,
    required this.recordLabel,
    required this.field,
    required this.problem,
    required this.path,
  });
}

class IntegrityResult {
  final int totalChecked;
  final List<IntegrityIssue> issues;

  const IntegrityResult({required this.totalChecked, required this.issues});

  bool get hasIssues => issues.isNotEmpty;
}

class IntegrityService {
  static Future<IntegrityResult> runCheck(AppDatabase db) async {
    final issues = <IntegrityIssue>[];
    var totalChecked = 0;

    // Check document refs
    final docs = await db.getDocuments();
    for (final d in docs) {
      if (d.localPath.isNotEmpty) {
        totalChecked++;
        final issue = _checkFile(
          recordType: 'Document',
          recordLabel:
              d.filename.isNotEmpty ? d.filename : d.localPath.split('/').last,
          field: 'File',
          path: d.localPath,
        );
        if (issue != null) issues.add(issue);
      }
    }

    return IntegrityResult(totalChecked: totalChecked, issues: issues);
  }

  static IntegrityIssue? _checkFile({
    required String recordType,
    required String recordLabel,
    required String field,
    required String path,
  }) {
    final file = File(path);
    if (!file.existsSync()) {
      return IntegrityIssue(
        recordType: recordType,
        recordLabel: recordLabel,
        field: field,
        problem: 'File missing',
        path: path,
      );
    }
    if (file.lengthSync() == 0) {
      return IntegrityIssue(
        recordType: recordType,
        recordLabel: recordLabel,
        field: field,
        problem: 'File empty',
        path: path,
      );
    }
    return null;
  }
}
