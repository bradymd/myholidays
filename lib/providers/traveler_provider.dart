import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/models/traveler.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/utils/id_generator.dart';

final travelersProvider = AsyncNotifierProvider.family<
    TravelersNotifier, List<Traveler>, String>(
  TravelersNotifier.new,
);

class TravelersNotifier
    extends FamilyAsyncNotifier<List<Traveler>, String> {
  @override
  Future<List<Traveler>> build(String arg) async {
    final db = ref.watch(databaseProvider);
    return db.getTravelers(arg);
  }

  Future<void> addTraveler(Traveler traveler) async {
    final db = ref.read(databaseProvider);
    final id = traveler.id.isEmpty ? generateId() : traveler.id;
    await db.upsertTraveler(traveler.copyWith(id: id));
    ref.invalidateSelf();
  }

  Future<void> updateTraveler(Traveler traveler) async {
    final db = ref.read(databaseProvider);
    await db.upsertTraveler(traveler);
    ref.invalidateSelf();
  }

  Future<void> deleteTraveler(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteTraveler(id);
    ref.invalidateSelf();
  }
}
