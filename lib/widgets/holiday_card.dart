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
    final holidayColour = AppColors.holidayColour(holiday.colour);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: isPast
          ? Colors.black12
          : holidayColour.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: icon picture taking ~1/3 width (hidden when no icon)
              if (holiday.icon.isNotEmpty)
                SizedBox(
                  width: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPast
                            ? [
                                AppColors.softLilac,
                                AppColors.background,
                              ]
                            : [
                                holidayColour.withValues(alpha: 0.15),
                                holidayColour.withValues(alpha: 0.06),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        AppColors.holidayIconAsset(holiday.icon),
                        fit: BoxFit.contain,
                        color: isPast ? AppColors.textMuted : null,
                        colorBlendMode:
                            isPast ? BlendMode.saturation : null,
                      ),
                    ),
                  ),
                ),

              // Right: content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        isPast
                            ? AppColors.background.withValues(alpha: 0.5)
                            : holidayColour.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Holiday name
                        Text(
                          holiday.name.isNotEmpty
                              ? holiday.name
                              : 'Untitled Holiday',
                          style: AppTextStyles.subheading.copyWith(
                            fontSize: 17,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),

                        if (holiday.startDate.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: isPast
                                    ? AppColors.textMuted
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  _dateRange(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: isPast
                                        ? AppColors.textMuted
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Bottom row: travellers + days badge
                        Row(
                          children: [
                            if (travelerCount > 0) ...[
                              Icon(
                                Icons.people_rounded,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$travelerCount',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            const Spacer(),
                            if (!isPast && daysAway >= 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: daysAway <= 7
                                      ? AppColors.accent.withValues(alpha: 0.15)
                                      : AppColors.softLilac,
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
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateRange() {
    final start = formatDateUK(holiday.startDate);
    final end = formatDateUK(holiday.endDate);
    if (holiday.endDate.isEmpty) return start;
    return '$start \u2013 $end';
  }
}
