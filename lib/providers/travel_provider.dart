import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/models/travel_leg.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/utils/id_generator.dart';

final travelLegsProvider = AsyncNotifierProvider.family<
    TravelLegsNotifier, List<TravelLeg>, String>(
  TravelLegsNotifier.new,
);

class TravelLegsNotifier
    extends FamilyAsyncNotifier<List<TravelLeg>, String> {
  @override
  Future<List<TravelLeg>> build(String arg) async {
    final db = ref.watch(databaseProvider);
    return db.getTravelLegs(arg);
  }

  Future<void> addTravelLeg(TravelLeg leg) async {
    final db = ref.read(databaseProvider);
    final id = leg.id.isEmpty ? generateId() : leg.id;
    await db.upsertTravelLeg(leg.copyWith(id: id));
    ref.invalidateSelf();
  }

  Future<void> updateTravelLeg(TravelLeg leg) async {
    final db = ref.read(databaseProvider);
    await db.upsertTravelLeg(leg);
    ref.invalidateSelf();
  }

  Future<void> deleteTravelLeg(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteTravelLeg(id);
    ref.invalidateSelf();
  }
}
