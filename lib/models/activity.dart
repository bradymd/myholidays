import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity.freezed.dart';
part 'activity.g.dart';

@freezed
class Activity with _$Activity {
  const factory Activity({
    required String id,
    required String holidayId,
    @Default('') String name,
    @Default('') String date,
    @Default('') String time,
    @Default('') String location,
    @Default(0) double cost,
    @Default('') String bookingReference,
    @Default('') String notes,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}
