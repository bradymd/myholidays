import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/models/holiday_plan.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/utils/id_generator.dart';

final holidaysProvider =
    AsyncNotifierProvider<HolidaysNotifier, List<HolidayPlan>>(
        HolidaysNotifier.new);

class HolidaysNotifier extends AsyncNotifier<List<HolidayPlan>> {
  @override
  Future<List<HolidayPlan>> build() async {
    final db = ref.watch(databaseProvider);
    return db.getAllHolidays();
  }

  Future<String> addHoliday(HolidayPlan holiday) async {
    final db = ref.read(databaseProvider);
    final id = holiday.id.isEmpty ? generateId() : holiday.id;
    final h = holiday.copyWith(id: id);
    await db.upsertHoliday(h);
    ref.invalidateSelf();
    return id;
  }

  Future<void> updateHoliday(HolidayPlan holiday) async {
    final db = ref.read(databaseProvider);
    await db.upsertHoliday(holiday);
    ref.invalidateSelf();
  }

  Future<void> deleteHoliday(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteHoliday(id);
    ref.invalidateSelf();
  }
}
