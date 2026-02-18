import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/models/accommodation.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/utils/id_generator.dart';

final accommodationsProvider = AsyncNotifierProvider.family<
    AccommodationsNotifier, List<Accommodation>, String>(
  AccommodationsNotifier.new,
);

class AccommodationsNotifier
    extends FamilyAsyncNotifier<List<Accommodation>, String> {
  @override
  Future<List<Accommodation>> build(String arg) async {
    final db = ref.watch(databaseProvider);
    return db.getAccommodations(arg);
  }

  Future<void> addAccommodation(Accommodation accommodation) async {
    final db = ref.read(databaseProvider);
    final id = accommodation.id.isEmpty ? generateId() : accommodation.id;
    await db.upsertAccommodation(accommodation.copyWith(id: id));
    ref.invalidateSelf();
  }

  Future<void> updateAccommodation(Accommodation accommodation) async {
    final db = ref.read(databaseProvider);
    await db.upsertAccommodation(accommodation);
    ref.invalidateSelf();
  }

  Future<void> deleteAccommodation(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteAccommodation(id);
    ref.invalidateSelf();
  }
}
