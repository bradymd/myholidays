import 'package:freezed_annotation/freezed_annotation.dart';

part 'accommodation.freezed.dart';
part 'accommodation.g.dart';

@freezed
class Accommodation with _$Accommodation {
  const factory Accommodation({
    required String id,
    required String holidayId,
    @Default('') String name,
    @Default('') String address,
    @Default('') String checkIn,
    @Default('') String checkOut,
    @Default(0) double cost,
    @Default(0) double depositPaid,
    @Default(0) double balanceDue,
    @Default('') String balanceDueDate,
    @Default('') String balancePaidDate,
    @Default('') String confirmationNumber,
    @Default('') String notes,
  }) = _Accommodation;

  factory Accommodation.fromJson(Map<String, dynamic> json) =>
      _$AccommodationFromJson(json);
}
