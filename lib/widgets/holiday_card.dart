import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/models/holiday_plan.dart';
import 'package:my_holidays/providers/traveler_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/date_helpers.dart';

class HolidayCard extends ConsumerWidget {
  const HolidayCard({super.key, required this.holiday, required this.onTap});

  final HolidayPlan holiday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travelerCount =
        ref.watch(travelersProvider(holiday.id)).valueOrNull?.length ?? 0;
    final daysAway = daysUntil(holiday.startDate);
    final isPast = isPastDate(
      holiday.endDate.isNotEmpty ? holiday.endDate : holiday.startDate,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.85),
              isPast
                  ? AppColors.textMuted.withValues(alpha: 0.06)
                  : AppColors.primary.withValues(alpha: 0.10),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPast
                              ? [AppColors.softLilac, AppColors.softLilac]
                              : [
                                  AppColors.primary.withValues(alpha: 0.15),
                                  AppColors.primary.withValues(alpha: 0.08),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isPast
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Icon(
                        isPast
                            ? Icons.beach_access_rounded
                            : Icons.flight_takeoff_rounded,
                        color: isPast ? AppColors.textMuted : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holiday.name.isNotEmpty
                                ? holiday.name
                                : 'Untitled Holiday',
                            style: AppTextStyles.subheading,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (holiday.startDate.isNotEmpty)
                            Text(_dateRange(), style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    if (!isPast && daysAway >= 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: daysAway <= 7
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.softPurple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          daysAway == 0
                              ? 'Today!'
                              : daysAway == 1
                              ? 'Tomorrow'
                              : '$daysAway days',
                          style: AppTextStyles.caption.copyWith(
                            color: daysAway <= 7
                                ? AppColors.accentDark
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    if (isPast)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softLilac,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Past',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                if (travelerCount > 0 || holiday.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (travelerCount > 0) ...[
                        Icon(
                          Icons.people_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$travelerCount traveller${travelerCount == 1 ? '' : 's'}',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: 16),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dateRange() {
    final start = formatDateUK(holiday.startDate);
    final end = formatDateUK(holiday.endDate);
    if (holiday.endDate.isEmpty) return start;
    return '$start - $end';
  }
}
