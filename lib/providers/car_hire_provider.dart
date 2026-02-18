import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/models/car_hire.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/utils/id_generator.dart';

final carHiresProvider = AsyncNotifierProvider.family<
    CarHiresNotifier, List<CarHire>, String>(
  CarHiresNotifier.new,
);

class CarHiresNotifier
    extends FamilyAsyncNotifier<List<CarHire>, String> {
  @override
  Future<List<CarHire>> build(String arg) async {
    final db = ref.watch(databaseProvider);
    return db.getCarHires(arg);
  }

  Future<void> addCarHire(CarHire carHire) async {
    final db = ref.read(databaseProvider);
    final id = carHire.id.isEmpty ? generateId() : carHire.id;
    await db.upsertCarHire(carHire.copyWith(id: id));
    ref.invalidateSelf();
  }

  Future<void> updateCarHire(CarHire carHire) async {
    final db = ref.read(databaseProvider);
    await db.upsertCarHire(carHire);
    ref.invalidateSelf();
  }

  Future<void> deleteCarHire(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteCarHire(id);
    ref.invalidateSelf();
  }
}
