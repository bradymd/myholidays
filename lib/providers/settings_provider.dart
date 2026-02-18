import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/providers/database_provider.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, Map<String, String>>(
        SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() async {
    return {};
  }

  Future<String?> get(String key) async {
    final db = ref.read(databaseProvider);
    return db.getSetting(key);
  }

  Future<void> set(String key, String value) async {
    final db = ref.read(databaseProvider);
    await db.setSetting(key, value);
    state = AsyncData({...state.valueOrNull ?? {}, key: value});
  }
}
