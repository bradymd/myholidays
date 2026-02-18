import 'package:freezed_annotation/freezed_annotation.dart';

part 'holiday_plan.freezed.dart';
part 'holiday_plan.g.dart';

@freezed
class HolidayPlan with _$HolidayPlan {
  const factory HolidayPlan({
    required String id,
    @Default('') String name,
    @Default('') String startDate,
    @Default('') String endDate,
    @Default('') String notes,
  }) = _HolidayPlan;

  factory HolidayPlan.fromJson(Map<String, dynamic> json) =>
      _$HolidayPlanFromJson(json);
}
