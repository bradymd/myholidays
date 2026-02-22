import 'package:drift/drift.dart';
import 'package:my_holidays/models/holiday_plan.dart' as models;
import 'package:my_holidays/models/traveler.dart' as models;
import 'package:my_holidays/models/accommodation.dart' as models;
import 'package:my_holidays/models/car_hire.dart' as models;
import 'package:my_holidays/models/travel_leg.dart' as models;
import 'package:my_holidays/models/activity.dart' as models;
import 'package:my_holidays/models/itinerary_day.dart' as models;
import 'package:my_holidays/models/document_ref.dart' as models;
import 'package:my_holidays/database/connection.dart';

part 'database.g.dart';

// --- Tables ---

@DataClassName('HolidayPlanRow')
class HolidayPlans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get startDate => text().withDefault(const Constant(''))();
  TextColumn get endDate => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get colour => text().withDefault(const Constant(''))();
  TextColumn get icon => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TravelerRow')
class Travelers extends Table {
  TextColumn get id => text()();
  TextColumn get holidayId => text().references(HolidayPlans, #id)();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AccommodationRow')
class Accommodations extends Table {
  TextColumn get id => text()();
  TextColumn get holidayId => text().references(HolidayPlans, #id)();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get checkIn => text().withDefault(const Constant(''))();
  TextColumn get checkOut => text().withDefault(const Constant(''))();
  RealColumn get cost => real().withDefault(const Constant(0))();
  RealColumn get depositPaid => real().withDefault(const Constant(0))();
  RealColumn get balanceDue => real().withDefault(const Constant(0))();
  TextColumn get balanceDueDate => text().withDefault(const Constant(''))();
  TextColumn get balancePaidDate => text().withDefault(const Constant(''))();
  TextColumn get confirmationNumber => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CarHireRow')
class CarHires extends Table {
  TextColumn get id => text()();
  TextColumn get holidayId => text().references(HolidayPlans, #id)();
  TextColumn get company => text().withDefault(const Constant(''))();
  TextColumn get pickupLocation => text().withDefault(const Constant(''))();
  TextColumn get pickupDate => text().withDefault(const Constant(''))();
  TextColumn get pickupTime => text().withDefault(const Constant(''))();
  TextColumn get dropoffLocation => text().withDefault(const Constant(''))();
  TextColumn get dropoffDate => text().withDefault(const Constant(''))();
  TextColumn get dropoffTime => text().withDefault(const Constant(''))();
  TextColumn get drivers => text().withDefault(const Constant(''))();
  RealColumn get deposit => real().withDefault(const Constant(0))();
  RealColumn get totalCost => real().withDefault(const Constant(0))();
  TextColumn get bookingReference => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TravelLegRow')
class TravelLegs extends Table {
  TextColumn get id => text()();
  TextColumn get holidayId => text().references(HolidayPlans, #id)();
  TextColumn get type => text().withDefault(const Constant('outbound'))();
  TextColumn get mode => text().withDefault(const Constant('flight'))();
  @JsonKey('from_location')
  TextColumn get from => text().named('from_location').withDefault(const Constant(''))();
  @JsonKey('to_location')
  TextColumn get to => text().named('to_location').withDefault(const Constant(''))();
  TextColumn get departureDate => text().withDefault(const Constant(''))();
  TextColumn get departureTime => text().withDefault(const Constant(''))();
  TextColumn get arrivalDate => text().withDefault(const Constant(''))();
  TextColumn get arrivalTime => text().withDefault(const Constant(''))();
  TextColumn get carrier => text().withDefault(const Constant(''))();
  TextColumn get bookingReference => text().withDefault(const Constant(''))();
  RealColumn get cost => real().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ActivityRow')
class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get holidayId => text().references(HolidayPlans, #id)();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get date => text().withDefault(const Constant(''))();
  TextColumn get time => text().withDefault(const Constant(''))();
  TextColumn get location => text().withDefault(const Constant(''))();
  RealColumn get cost => real().withDefault(const Constant(0))();
  TextColumn get bookingReference => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ItineraryDayRow')
class ItineraryDays extends Table {
  TextColumn get id => text()();
  TextColumn get holidayId => text().references(HolidayPlans, #id)();
  TextColumn get date => text().withDefault(const Constant(''))();
  IntColumn get dayNumber => integer().withDefault(const Constant(0))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DocumentRefRow')
class DocumentRefs extends Table {
  TextColumn get id => text()();
  TextColumn get parentType => text().withDefault(const Constant('holiday'))();
  TextColumn get parentId => text().withDefault(const Constant(''))();
  TextColumn get filename => text().withDefault(const Constant(''))();
  TextColumn get localPath => text().withDefault(const Constant(''))();
  TextColumn get fileType => text().withDefault(const Constant(''))();
  TextColumn get addedDate => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  HolidayPlans,
  Travelers,
  Accommodations,
  CarHires,
  TravelLegs,
  Activities,
  ItineraryDays,
  DocumentRefs,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await customStatement(
              "ALTER TABLE holiday_plans ADD COLUMN colour TEXT NOT NULL DEFAULT ''",
            );
          }
          if (from < 3) {
            await customStatement(
              "ALTER TABLE holiday_plans ADD COLUMN icon TEXT NOT NULL DEFAULT ''",
            );
          }
          if (from < 4) {
            // Convert absolute document paths to relative (my_holidays_docs/...).
            const folder = 'my_holidays_docs';
            final rows = await customSelect(
              "SELECT id, local_path FROM document_refs WHERE local_path != ''",
            ).get();
            for (final row in rows) {
              final id = row.read<String>('id');
              final oldPath = row.read<String>('local_path');
              final idx = oldPath.indexOf('$folder/');
              if (idx < 0) continue;
              final relativePath = oldPath.substring(idx);
              if (relativePath == oldPath) continue;
              await customStatement(
                'UPDATE document_refs SET local_path = ? WHERE id = ?',
                [relativePath, id],
              );
            }
          }
        },
      );

  // --- Holiday operations ---

  Future<List<models.HolidayPlan>> getAllHolidays() async {
    final rows = await (select(holidayPlans)
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
    return rows.map(_holidayFromRow).toList();
  }

  Future<models.HolidayPlan?> getHoliday(String id) async {
    final row = await (select(holidayPlans)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _holidayFromRow(row);
  }

  Future<void> upsertHoliday(models.HolidayPlan h) async {
    await into(holidayPlans).insertOnConflictUpdate(
      HolidayPlansCompanion.insert(
        id: h.id,
        name: Value(h.name),
        startDate: Value(h.startDate),
        endDate: Value(h.endDate),
        notes: Value(h.notes),
        colour: Value(h.colour),
        icon: Value(h.icon),
      ),
    );
  }

  Future<void> deleteHoliday(String id) async {
    await (delete(travelers)..where((t) => t.holidayId.equals(id))).go();
    await (delete(accommodations)..where((t) => t.holidayId.equals(id))).go();
    await (delete(carHires)..where((t) => t.holidayId.equals(id))).go();
    await (delete(travelLegs)..where((t) => t.holidayId.equals(id))).go();
    await (delete(activities)..where((t) => t.holidayId.equals(id))).go();
    await (delete(itineraryDays)..where((t) => t.holidayId.equals(id))).go();
    await (delete(documentRefs)..where((t) => t.parentId.equals(id))).go();
    await (delete(holidayPlans)..where((t) => t.id.equals(id))).go();
  }

  // --- Traveler operations ---

  Future<List<models.Traveler>> getTravelers(String holidayId) async {
    final rows = await (select(travelers)
          ..where((t) => t.holidayId.equals(holidayId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map(_travelerFromRow).toList();
  }

  Future<void> upsertTraveler(models.Traveler t) async {
    await into(travelers).insertOnConflictUpdate(
      TravelersCompanion.insert(
        id: t.id,
        holidayId: t.holidayId,
        name: Value(t.name),
        notes: Value(t.notes),
      ),
    );
  }

  Future<void> deleteTraveler(String id) async {
    await (delete(travelers)..where((t) => t.id.equals(id))).go();
  }

  // --- Accommodation operations ---

  Future<List<models.Accommodation>> getAccommodations(String holidayId) async {
    final rows = await (select(accommodations)
          ..where((t) => t.holidayId.equals(holidayId))
          ..orderBy([(t) => OrderingTerm.asc(t.checkIn)]))
        .get();
    return rows.map(_accommodationFromRow).toList();
  }

  Future<void> upsertAccommodation(models.Accommodation a) async {
    await into(accommodations).insertOnConflictUpdate(
      AccommodationsCompanion.insert(
        id: a.id,
        holidayId: a.holidayId,
        name: Value(a.name),
        address: Value(a.address),
        checkIn: Value(a.checkIn),
        checkOut: Value(a.checkOut),
        cost: Value(a.cost),
        depositPaid: Value(a.depositPaid),
        balanceDue: Value(a.balanceDue),
        balanceDueDate: Value(a.balanceDueDate),
        balancePaidDate: Value(a.balancePaidDate),
        confirmationNumber: Value(a.confirmationNumber),
        notes: Value(a.notes),
      ),
    );
  }

  Future<void> deleteAccommodation(String id) async {
    await (delete(documentRefs)..where((t) => t.parentId.equals(id))).go();
    await (delete(accommodations)..where((t) => t.id.equals(id))).go();
  }

  // --- Car hire operations ---

  Future<List<models.CarHire>> getCarHires(String holidayId) async {
    final rows = await (select(carHires)
          ..where((t) => t.holidayId.equals(holidayId))
          ..orderBy([(t) => OrderingTerm.asc(t.pickupDate)]))
        .get();
    return rows.map(_carHireFromRow).toList();
  }

  Future<void> upsertCarHire(models.CarHire c) async {
    await into(carHires).insertOnConflictUpdate(
      CarHiresCompanion.insert(
        id: c.id,
        holidayId: c.holidayId,
        company: Value(c.company),
        pickupLocation: Value(c.pickupLocation),
        pickupDate: Value(c.pickupDate),
        pickupTime: Value(c.pickupTime),
        dropoffLocation: Value(c.dropoffLocation),
        dropoffDate: Value(c.dropoffDate),
        dropoffTime: Value(c.dropoffTime),
        drivers: Value(c.drivers),
        deposit: Value(c.deposit),
        totalCost: Value(c.totalCost),
        bookingReference: Value(c.bookingReference),
        notes: Value(c.notes),
      ),
    );
  }

  Future<void> deleteCarHire(String id) async {
    await (delete(documentRefs)..where((t) => t.parentId.equals(id))).go();
    await (delete(carHires)..where((t) => t.id.equals(id))).go();
  }

  // --- Travel leg operations ---

  Future<List<models.TravelLeg>> getTravelLegs(String holidayId) async {
    final rows = await (select(travelLegs)
          ..where((t) => t.holidayId.equals(holidayId))
          ..orderBy([(t) => OrderingTerm.asc(t.departureDate)]))
        .get();
    return rows.map(_travelLegFromRow).toList();
  }

  Future<void> upsertTravelLeg(models.TravelLeg l) async {
    await into(travelLegs).insertOnConflictUpdate(
      TravelLegsCompanion.insert(
        id: l.id,
        holidayId: l.holidayId,
        type: Value(l.type),
        mode: Value(l.mode),
        from: Value(l.from),
        to: Value(l.to),
        departureDate: Value(l.departureDate),
        departureTime: Value(l.departureTime),
        arrivalDate: Value(l.arrivalDate),
        arrivalTime: Value(l.arrivalTime),
        carrier: Value(l.carrier),
        bookingReference: Value(l.bookingReference),
        cost: Value(l.cost),
        notes: Value(l.notes),
      ),
    );
  }

  Future<void> deleteTravelLeg(String id) async {
    await (delete(documentRefs)..where((t) => t.parentId.equals(id))).go();
    await (delete(travelLegs)..where((t) => t.id.equals(id))).go();
  }

  // --- Activity operations ---

  Future<List<models.Activity>> getActivities(String holidayId) async {
    final rows = await (select(activities)
          ..where((t) => t.holidayId.equals(holidayId))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
    return rows.map(_activityFromRow).toList();
  }

  Future<void> upsertActivity(models.Activity a) async {
    await into(activities).insertOnConflictUpdate(
      ActivitiesCompanion.insert(
        id: a.id,
        holidayId: a.holidayId,
        name: Value(a.name),
        date: Value(a.date),
        time: Value(a.time),
        location: Value(a.location),
        cost: Value(a.cost),
        bookingReference: Value(a.bookingReference),
        notes: Value(a.notes),
      ),
    );
  }

  Future<void> deleteActivity(String id) async {
    await (delete(documentRefs)..where((t) => t.parentId.equals(id))).go();
    await (delete(activities)..where((t) => t.id.equals(id))).go();
  }

  // --- Itinerary day operations ---

  Future<List<models.ItineraryDay>> getItineraryDays(String holidayId) async {
    final rows = await (select(itineraryDays)
          ..where((t) => t.holidayId.equals(holidayId))
          ..orderBy([(t) => OrderingTerm.asc(t.dayNumber)]))
        .get();
    return rows.map(_itineraryDayFromRow).toList();
  }

  Future<void> upsertItineraryDay(models.ItineraryDay d) async {
    await into(itineraryDays).insertOnConflictUpdate(
      ItineraryDaysCompanion.insert(
        id: d.id,
        holidayId: d.holidayId,
        date: Value(d.date),
        dayNumber: Value(d.dayNumber),
        title: Value(d.title),
        description: Value(d.description),
        notes: Value(d.notes),
      ),
    );
  }

  Future<void> deleteItineraryDay(String id) async {
    await (delete(documentRefs)..where((t) => t.parentId.equals(id))).go();
    await (delete(itineraryDays)..where((t) => t.id.equals(id))).go();
  }

  // --- Document operations ---

  Future<List<models.DocumentRef>> getDocuments({
    String? parentType,
    String? parentId,
  }) async {
    var query = select(documentRefs);
    if (parentType != null) {
      query = query..where((t) => t.parentType.equals(parentType));
    }
    if (parentId != null) {
      query = query..where((t) => t.parentId.equals(parentId));
    }
    final rows = await query.get();
    return rows.map(_documentFromRow).toList();
  }

  Future<List<models.DocumentRef>> getDocumentsByParentIds(
      List<String> parentIds) async {
    final query = select(documentRefs)
      ..where((t) => t.parentId.isIn(parentIds));
    final rows = await query.get();
    return rows.map(_documentFromRow).toList();
  }

  Future<void> upsertDocument(models.DocumentRef d) async {
    await into(documentRefs).insertOnConflictUpdate(
      DocumentRefsCompanion.insert(
        id: d.id,
        parentType: Value(d.parentType),
        parentId: Value(d.parentId),
        filename: Value(d.filename),
        localPath: Value(d.localPath),
        fileType: Value(d.fileType),
        addedDate: Value(d.addedDate),
      ),
    );
  }

  Future<void> deleteDocument(String id) async {
    await (delete(documentRefs)..where((t) => t.id.equals(id))).go();
  }

  // --- Settings ---

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }

  // --- Row converters ---

  models.HolidayPlan _holidayFromRow(HolidayPlanRow r) => models.HolidayPlan(
        id: r.id,
        name: r.name,
        startDate: r.startDate,
        endDate: r.endDate,
        notes: r.notes,
        colour: r.colour,
        icon: r.icon,
      );

  models.Traveler _travelerFromRow(TravelerRow r) => models.Traveler(
        id: r.id,
        holidayId: r.holidayId,
        name: r.name,
        notes: r.notes,
      );

  models.Accommodation _accommodationFromRow(AccommodationRow r) =>
      models.Accommodation(
        id: r.id,
        holidayId: r.holidayId,
        name: r.name,
        address: r.address,
        checkIn: r.checkIn,
        checkOut: r.checkOut,
        cost: r.cost,
        depositPaid: r.depositPaid,
        balanceDue: r.balanceDue,
        balanceDueDate: r.balanceDueDate,
        balancePaidDate: r.balancePaidDate,
        confirmationNumber: r.confirmationNumber,
        notes: r.notes,
      );

  models.CarHire _carHireFromRow(CarHireRow r) => models.CarHire(
        id: r.id,
        holidayId: r.holidayId,
        company: r.company,
        pickupLocation: r.pickupLocation,
        pickupDate: r.pickupDate,
        pickupTime: r.pickupTime,
        dropoffLocation: r.dropoffLocation,
        dropoffDate: r.dropoffDate,
        dropoffTime: r.dropoffTime,
        drivers: r.drivers,
        deposit: r.deposit,
        totalCost: r.totalCost,
        bookingReference: r.bookingReference,
        notes: r.notes,
      );

  models.TravelLeg _travelLegFromRow(TravelLegRow r) => models.TravelLeg(
        id: r.id,
        holidayId: r.holidayId,
        type: r.type,
        mode: r.mode,
        from: r.from,
        to: r.to,
        departureDate: r.departureDate,
        departureTime: r.departureTime,
        arrivalDate: r.arrivalDate,
        arrivalTime: r.arrivalTime,
        carrier: r.carrier,
        bookingReference: r.bookingReference,
        cost: r.cost,
        notes: r.notes,
      );

  models.Activity _activityFromRow(ActivityRow r) => models.Activity(
        id: r.id,
        holidayId: r.holidayId,
        name: r.name,
        date: r.date,
        time: r.time,
        location: r.location,
        cost: r.cost,
        bookingReference: r.bookingReference,
        notes: r.notes,
      );

  models.ItineraryDay _itineraryDayFromRow(ItineraryDayRow r) =>
      models.ItineraryDay(
        id: r.id,
        holidayId: r.holidayId,
        date: r.date,
        dayNumber: r.dayNumber,
        title: r.title,
        description: r.description,
        notes: r.notes,
      );

  models.DocumentRef _documentFromRow(DocumentRefRow r) => models.DocumentRef(
        id: r.id,
        parentType: r.parentType,
        parentId: r.parentId,
        filename: r.filename,
        localPath: r.localPath,
        fileType: r.fileType,
        addedDate: r.addedDate,
      );
}
