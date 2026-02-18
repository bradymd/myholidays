import 'package:freezed_annotation/freezed_annotation.dart';

part 'car_hire.freezed.dart';
part 'car_hire.g.dart';

@freezed
class CarHire with _$CarHire {
  const factory CarHire({
    required String id,
    required String holidayId,
    @Default('') String company,
    @Default('') String pickupLocation,
    @Default('') String pickupDate,
    @Default('') String pickupTime,
    @Default('') String dropoffLocation,
    @Default('') String dropoffDate,
    @Default('') String dropoffTime,
    @Default('') String drivers,
    @Default(0) double deposit,
    @Default(0) double totalCost,
    @Default('') String bookingReference,
    @Default('') String notes,
  }) = _CarHire;

  factory CarHire.fromJson(Map<String, dynamic> json) =>
      _$CarHireFromJson(json);
}
