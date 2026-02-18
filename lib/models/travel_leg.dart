import 'package:freezed_annotation/freezed_annotation.dart';

part 'travel_leg.freezed.dart';
part 'travel_leg.g.dart';

@freezed
class TravelLeg with _$TravelLeg {
  const factory TravelLeg({
    required String id,
    required String holidayId,
    @Default('outbound') String type,
    @Default('flight') String mode,
    @Default('') String from,
    @Default('') String to,
    @Default('') String departureDate,
    @Default('') String departureTime,
    @Default('') String arrivalDate,
    @Default('') String arrivalTime,
    @Default('') String carrier,
    @Default('') String bookingReference,
    @Default(0) double cost,
    @Default('') String notes,
  }) = _TravelLeg;

  factory TravelLeg.fromJson(Map<String, dynamic> json) =>
      _$TravelLegFromJson(json);
}
