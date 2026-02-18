import 'package:freezed_annotation/freezed_annotation.dart';

part 'itinerary_day.freezed.dart';
part 'itinerary_day.g.dart';

@freezed
class ItineraryDay with _$ItineraryDay {
  const factory ItineraryDay({
    required String id,
    required String holidayId,
    @Default('') String date,
    @Default(0) int dayNumber,
    @Default('') String title,
    @Default('') String description,
    @Default('') String notes,
  }) = _ItineraryDay;

  factory ItineraryDay.fromJson(Map<String, dynamic> json) =>
      _$ItineraryDayFromJson(json);
}
