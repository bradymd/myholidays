import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/models/activity.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/utils/id_generator.dart';

final activitiesProvider = AsyncNotifierProvider.family<
    ActivitiesNotifier, List<Activity>, String>(
  ActivitiesNotifier.new,
);

class ActivitiesNotifier
    extends FamilyAsyncNotifier<List<Activity>, String> {
  @override
  Future<List<Activity>> build(String arg) async {
    final db = ref.watch(databaseProvider);
    return db.getActivities(arg);
  }

  Future<void> addActivity(Activity activity) async {
    final db = ref.read(databaseProvider);
    final id = activity.id.isEmpty ? generateId() : activity.id;
    await db.upsertActivity(activity.copyWith(id: id));
    ref.invalidateSelf();
  }

  Future<void> updateActivity(Activity activity) async {
    final db = ref.read(databaseProvider);
    await db.upsertActivity(activity);
    ref.invalidateSelf();
  }

  Future<void> deleteActivity(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteActivity(id);
    ref.invalidateSelf();
  }
}
