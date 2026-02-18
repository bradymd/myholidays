import 'package:freezed_annotation/freezed_annotation.dart';

part 'traveler.freezed.dart';
part 'traveler.g.dart';

@freezed
class Traveler with _$Traveler {
  const factory Traveler({
    required String id,
    required String holidayId,
    @Default('') String name,
    @Default('') String notes,
  }) = _Traveler;

  factory Traveler.fromJson(Map<String, dynamic> json) =>
      _$TravelerFromJson(json);
}
