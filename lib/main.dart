import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/app.dart';
import 'package:my_holidays/services/backup_service.dart';
import 'package:my_holidays/services/document_service.dart';
import 'package:my_holidays/services/incoming_file_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DocumentService.init();
  await IncomingFileHandler.init();

  runApp(
    const ProviderScope(child: _AppLifecycleWrapper(child: MyHolidaysApp())),
  );
}

/// Watches app lifecycle and triggers auto-backup on close/background,
/// but no more than once every 4 hours.
class _AppLifecycleWrapper extends StatefulWidget {
  const _AppLifecycleWrapper({required this.child});
  final Widget child;

  @override
  State<_AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<_AppLifecycleWrapper>
    with WidgetsBindingObserver {
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
      setState(() {});
      return;
    }
    // Include `hidden` — on desktop it fires before `paused` and gives the
    // async I/O more time to complete before the engine shuts down.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _backupIfDue();
    }
  }

  Future<void> _backupIfDue() async {
    try {
      final info = await BackupService.getAutoBackupInfo();
      if (info != null) {
        final hoursSince = DateTime.now().difference(info.timestamp).inHours;
        if (hoursSince < 4) return;
      }
      await BackupService.createAutoBackup();
    } catch (_) {
      // Backup is best-effort — never crash the app
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
