import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/providers/document_provider.dart';
import 'package:my_holidays/providers/holiday_provider.dart';
import 'package:my_holidays/providers/settings_provider.dart';
import 'package:my_holidays/services/backup_service.dart';
import 'package:my_holidays/services/integrity_service.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isChecking = false;

  AutoBackupInfo? _autoBackupInfo;

  @override
  void initState() {
    super.initState();
    _loadAutoBackupInfo();
  }

  Future<void> _loadAutoBackupInfo() async {
    final info = await BackupService.getAutoBackupInfo();
    if (mounted) setState(() => _autoBackupInfo = info);
  }

  // --- Backup ---

  Future<void> _createBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final zipPath = await BackupService.createBackup();

      if (!mounted) return;

      if (Platform.isAndroid || Platform.isIOS) {
        await Share.shareXFiles([XFile(zipPath)]);
      } else {
        // Desktop: copy to Downloads folder
        final downloadsDir = await _getDownloadsDirectory();
        final destPath =
            p.join(downloadsDir.path, p.basename(zipPath));
        await File(zipPath).copy(destPath);

        if (!mounted) return;
        _showResultDialog(
          title: 'Backup Created',
          message: 'Backup saved to:\n$destPath',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        title: 'Backup Failed',
        message: 'Error: $e',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '';
      final dir = Directory(p.join(home, 'Downloads'));
      if (await dir.exists()) return dir;
    }
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      final dir = Directory(p.join(userProfile, 'Downloads'));
      if (await dir.exists()) return dir;
    }
    return await getApplicationDocumentsDirectory();
  }

  // --- Restore ---

  Future<void> _restoreFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) {
      return;
    }

    final filePath = result.files.first.path!;

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'This will replace all current data with the backup contents. '
          'This cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);
    try {
      final success = await BackupService.restoreFromBackup(filePath);

      if (!mounted) return;

      if (success) {
        // Close the old DB connection and reload all providers
        ref.invalidate(databaseProvider);
        ref.invalidate(holidaysProvider);
        ref.invalidate(documentsProvider);
        ref.invalidate(settingsProvider);

        _showResultDialog(
          title: 'Restore Complete',
          message:
              'Your data has been restored successfully. The app will now reload.',
          isSuccess: true,
        );
      } else {
        _showResultDialog(
          title: 'Restore Failed',
          message:
              'The selected file does not appear to be a valid MyHolidays backup.',
          isSuccess: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        title: 'Restore Failed',
        message: 'Error: $e',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _restoreFromAutoBackup() async {
    final backupPath = await BackupService.getAutoBackupPath();
    if (backupPath == null) {
      if (!mounted) return;
      _showResultDialog(
        title: 'No Auto-Backup',
        message: 'No automatic backup file was found.',
        isSuccess: false,
      );
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Auto-Backup?'),
        content: const Text(
          'This will replace all current data with the most recent '
          'auto-backup. This cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);
    try {
      final success = await BackupService.restoreFromBackup(backupPath);

      if (!mounted) return;

      if (success) {
        ref.invalidate(databaseProvider);
        ref.invalidate(holidaysProvider);
        ref.invalidate(documentsProvider);
        ref.invalidate(settingsProvider);

        _showResultDialog(
          title: 'Restore Complete',
          message: 'Data restored from auto-backup successfully.',
          isSuccess: true,
        );
      } else {
        _showResultDialog(
          title: 'Restore Failed',
          message: 'The auto-backup file appears to be invalid.',
          isSuccess: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        title: 'Restore Failed',
        message: 'Error: $e',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  // --- Integrity Check ---

  Future<void> _runIntegrityCheck() async {
    setState(() => _isChecking = true);
    try {
      final db = ref.read(databaseProvider);
      final result = await IntegrityService.runCheck(db);

      if (!mounted) return;

      if (!result.hasIssues) {
        _showResultDialog(
          title: 'All Good',
          message:
              'Checked ${result.totalChecked} record(s). No issues found.',
          isSuccess: true,
        );
      } else {
        final issueText = result.issues
            .map((i) =>
                '${i.recordType}: ${i.recordLabel}\n  ${i.field} - ${i.problem}')
            .join('\n\n');

        _showResultDialog(
          title: 'Issues Found',
          message:
              'Checked ${result.totalChecked} record(s).\n'
              '${result.issues.length} issue(s) found:\n\n$issueText',
          isSuccess: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        title: 'Check Failed',
        message: 'Error: $e',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  // --- Helpers ---

  void _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              color: isSuccess ? AppColors.success : AppColors.warning,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(message, style: AppTextStyles.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      useOverlayNav: true,
      title: 'Settings & Tools',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        children: [
          // --- Backup & Restore ---
          _SectionHeader(title: 'Backup & Restore'),
          const SizedBox(height: 12),

          // Auto-backup info card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.backup_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text('Auto-Backup',
                          style: AppTextStyles.bodyBold),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_autoBackupInfo != null) ...[
                    _InfoRow(
                      label: 'Last backup',
                      value: DateFormat('dd/MM/yyyy HH:mm')
                          .format(_autoBackupInfo!.timestamp),
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      label: 'Size',
                      value: _formatBytes(_autoBackupInfo!.sizeBytes),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isRestoring ? null : _restoreFromAutoBackup,
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: Text(_isRestoring
                            ? 'Restoring...'
                            : 'Restore from Auto-Backup'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primaryLight),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ] else
                    Text(
                      'No auto-backup available yet.',
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Create Backup button
          _ActionTile(
            icon: Icons.archive_rounded,
            iconColor: AppColors.primary,
            title: 'Create Backup',
            subtitle: 'Export data as a ZIP file',
            isLoading: _isBackingUp,
            onTap: _isBackingUp ? null : _createBackup,
          ),
          const SizedBox(height: 8),

          // Restore from File button
          _ActionTile(
            icon: Icons.unarchive_rounded,
            iconColor: AppColors.accent,
            title: 'Restore from File',
            subtitle: 'Import a backup ZIP',
            isLoading: _isRestoring,
            onTap: _isRestoring ? null : _restoreFromFile,
          ),
          const SizedBox(height: 28),

          // --- Data Tools ---
          _SectionHeader(title: 'Data Tools'),
          const SizedBox(height: 12),

          _ActionTile(
            icon: Icons.health_and_safety_rounded,
            iconColor: AppColors.success,
            title: 'Data Integrity Check',
            subtitle: 'Verify documents and file references',
            isLoading: _isChecking,
            onTap: _isChecking ? null : _runIntegrityCheck,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// --- Reusable UI pieces ---

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.subheading),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value, style: AppTextStyles.body.copyWith(fontSize: 13)),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: AppTextStyles.bodyBold),
        subtitle:
            Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textMuted),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
