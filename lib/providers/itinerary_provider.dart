import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/models/itinerary_day.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/utils/id_generator.dart';

final itineraryDaysProvider = AsyncNotifierProvider.family<
    ItineraryDaysNotifier, List<ItineraryDay>, String>(
  ItineraryDaysNotifier.new,
);

class ItineraryDaysNotifier
    extends FamilyAsyncNotifier<List<ItineraryDay>, String> {
  @override
  Future<List<ItineraryDay>> build(String arg) async {
    final db = ref.watch(databaseProvider);
    return db.getItineraryDays(arg);
  }

  Future<void> addItineraryDay(ItineraryDay day) async {
    final db = ref.read(databaseProvider);
    final id = day.id.isEmpty ? generateId() : day.id;
    await db.upsertItineraryDay(day.copyWith(id: id));
    ref.invalidateSelf();
  }

  Future<void> updateItineraryDay(ItineraryDay day) async {
    final db = ref.read(databaseProvider);
    await db.upsertItineraryDay(day);
    ref.invalidateSelf();
  }

  Future<void> deleteItineraryDay(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteItineraryDay(id);
    ref.invalidateSelf();
  }
}
