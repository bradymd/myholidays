import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:my_holidays/database/database.dart';
import 'package:my_holidays/models/accommodation.dart';
import 'package:my_holidays/models/activity.dart';
import 'package:my_holidays/models/car_hire.dart';
import 'package:my_holidays/models/document_ref.dart';
import 'package:my_holidays/models/holiday_plan.dart';
import 'package:my_holidays/models/itinerary_day.dart';
import 'package:my_holidays/models/travel_leg.dart';
import 'package:my_holidays/models/traveler.dart';
import 'package:my_holidays/services/document_service.dart';
import 'package:my_holidays/utils/id_generator.dart';

/// Preview info shown in the import confirmation dialog.
class ShareFilePreview {
  final String holidayName;
  final String startDate;
  final String endDate;
  final int travelers;
  final int accommodations;
  final int travelLegs;
  final int carHires;
  final int activities;
  final int itineraryDays;
  final int documents;

  const ShareFilePreview({
    required this.holidayName,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.accommodations,
    required this.travelLegs,
    required this.carHires,
    required this.activities,
    required this.itineraryDays,
    required this.documents,
  });
}

class HolidayShareService {
  static const _currentVersion = 1;
  static const _jsonFilename = 'holiday.json';

  // --- Export ---

  /// Builds a .myholiday file (ZIP with JSON + document files) and returns
  /// the temp file path.
  static Future<String> exportHoliday({
    required HolidayPlan holiday,
    required List<Traveler> travelers,
    required List<Accommodation> accommodations,
    required List<TravelLeg> travelLegs,
    required List<CarHire> carHires,
    required List<Activity> activities,
    required List<ItineraryDay> itineraryDays,
    required List<DocumentRef> documents,
  }) async {
    final archive = Archive();

    // Build document list with archive paths, and add files to ZIP
    final docJsonList = <Map<String, dynamic>>[];
    for (final doc in documents) {
      final json = doc.toJson();
      if (doc.localPath.isNotEmpty) {
        final absPath = DocumentService.resolvePathSync(doc.localPath);
        final file = File(absPath);
        if (file.existsSync()) {
          final archivePath = 'docs/${doc.filename}';
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
          json['localPath'] = archivePath;
        }
      }
      docJsonList.add(json);
    }

    // Build JSON envelope
    final envelope = {
      'version': _currentVersion,
      'holiday': holiday.toJson(),
      'travelers': travelers.map((t) => t.toJson()).toList(),
      'accommodations': accommodations.map((a) => a.toJson()).toList(),
      'travelLegs': travelLegs.map((l) => l.toJson()).toList(),
      'carHires': carHires.map((c) => c.toJson()).toList(),
      'activities': activities.map((a) => a.toJson()).toList(),
      'itineraryDays': itineraryDays.map((d) => d.toJson()).toList(),
      'documents': docJsonList,
    };

    final jsonBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(envelope));
    archive.addFile(ArchiveFile(_jsonFilename, jsonBytes.length, jsonBytes));

    // Encode and write
    final zipData = ZipEncoder().encode(archive);
    final tempDir = await getTemporaryDirectory();
    final safeName = holiday.name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final filePath = p.join(tempDir.path, '$safeName.myholiday');
    await File(filePath).writeAsBytes(zipData);
    return filePath;
  }

  // --- Import ---

  /// Parses a .myholiday file and returns a preview for the confirmation
  /// dialog. Throws on invalid files.
  static Future<ShareFilePreview> parseFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final jsonEntry = archive.findFile(_jsonFilename);
    if (jsonEntry == null) {
      throw const FormatException('Not a valid MyHoliday share file.');
    }

    final json = jsonDecode(utf8.decode(jsonEntry.content as List<int>))
        as Map<String, dynamic>;

    final version = json['version'] as int? ?? 0;
    if (version > _currentVersion) {
      throw const FormatException(
        'This file was created with a newer version of the app. '
        'Please update MyHolidays to import it.',
      );
    }

    final holiday = json['holiday'] as Map<String, dynamic>? ?? {};
    final travelers = json['travelers'] as List? ?? [];
    final accommodations = json['accommodations'] as List? ?? [];
    final travelLegs = json['travelLegs'] as List? ?? [];
    final carHires = json['carHires'] as List? ?? [];
    final activities = json['activities'] as List? ?? [];
    final itineraryDays = json['itineraryDays'] as List? ?? [];
    final documents = json['documents'] as List? ?? [];

    return ShareFilePreview(
      holidayName: holiday['name'] as String? ?? 'Unknown',
      startDate: holiday['startDate'] as String? ?? '',
      endDate: holiday['endDate'] as String? ?? '',
      travelers: travelers.length,
      accommodations: accommodations.length,
      travelLegs: travelLegs.length,
      carHires: carHires.length,
      activities: activities.length,
      itineraryDays: itineraryDays.length,
      documents: documents.length,
    );
  }

  /// Imports a .myholiday file into the database. Returns the new holiday ID.
  static Future<String> importHoliday(
    AppDatabase db,
    String filePath,
  ) async {
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final jsonEntry = archive.findFile(_jsonFilename);
    if (jsonEntry == null) {
      throw const FormatException('Not a valid MyHoliday share file.');
    }

    final json = jsonDecode(utf8.decode(jsonEntry.content as List<int>))
        as Map<String, dynamic>;

    // Parse all entities
    final holiday = HolidayPlan.fromJson(json['holiday'] as Map<String, dynamic>);
    final travelers = (json['travelers'] as List)
        .map((e) => Traveler.fromJson(e as Map<String, dynamic>))
        .toList();
    final accommodations = (json['accommodations'] as List)
        .map((e) => Accommodation.fromJson(e as Map<String, dynamic>))
        .toList();
    final travelLegs = (json['travelLegs'] as List)
        .map((e) => TravelLeg.fromJson(e as Map<String, dynamic>))
        .toList();
    final carHires = (json['carHires'] as List)
        .map((e) => CarHire.fromJson(e as Map<String, dynamic>))
        .toList();
    final activities = (json['activities'] as List)
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList();
    final itineraryDays = (json['itineraryDays'] as List)
        .map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>))
        .toList();
    final documents = (json['documents'] as List)
        .map((e) => DocumentRef.fromJson(e as Map<String, dynamic>))
        .toList();

    // Build old → new ID map
    final idMap = <String, String>{};

    String remap(String oldId) {
      return idMap.putIfAbsent(oldId, () => generateId());
    }

    // Remap holiday
    final newHolidayId = remap(holiday.id);
    final newHoliday = holiday.copyWith(id: newHolidayId);

    // Remap child entities
    final newTravelers = travelers
        .map((t) => t.copyWith(id: remap(t.id), holidayId: newHolidayId))
        .toList();
    final newAccommodations = accommodations
        .map((a) => a.copyWith(id: remap(a.id), holidayId: newHolidayId))
        .toList();
    final newTravelLegs = travelLegs
        .map((l) => l.copyWith(id: remap(l.id), holidayId: newHolidayId))
        .toList();
    final newCarHires = carHires
        .map((c) => c.copyWith(id: remap(c.id), holidayId: newHolidayId))
        .toList();
    final newActivities = activities
        .map((a) => a.copyWith(id: remap(a.id), holidayId: newHolidayId))
        .toList();
    final newItineraryDays = itineraryDays
        .map((d) => d.copyWith(id: remap(d.id), holidayId: newHolidayId))
        .toList();

    // Remap documents — also extract files from archive
    final newDocuments = <DocumentRef>[];
    for (final doc in documents) {
      var newLocalPath = '';
      if (doc.localPath.isNotEmpty) {
        final archiveFile = archive.findFile(doc.localPath);
        if (archiveFile != null) {
          // Write to a temp file, then save via DocumentService
          final tempDir = await getTemporaryDirectory();
          final tempPath = p.join(tempDir.path, doc.filename);
          await File(tempPath).writeAsBytes(archiveFile.content as List<int>);
          newLocalPath = await DocumentService.saveFile(tempPath, doc.filename);
          // Clean up temp
          try {
            await File(tempPath).delete();
          } catch (_) {}
        }
      }

      final newParentId = idMap[doc.parentId] ?? doc.parentId;
      newDocuments.add(doc.copyWith(
        id: remap(doc.id),
        parentId: newParentId,
        localPath: newLocalPath,
      ));
    }

    // Insert everything
    await db.upsertHoliday(newHoliday);
    for (final t in newTravelers) {
      await db.upsertTraveler(t);
    }
    for (final a in newAccommodations) {
      await db.upsertAccommodation(a);
    }
    for (final l in newTravelLegs) {
      await db.upsertTravelLeg(l);
    }
    for (final c in newCarHires) {
      await db.upsertCarHire(c);
    }
    for (final a in newActivities) {
      await db.upsertActivity(a);
    }
    for (final d in newItineraryDays) {
      await db.upsertItineraryDay(d);
    }
    for (final d in newDocuments) {
      await db.upsertDocument(d);
    }

    return newHolidayId;
  }
}
