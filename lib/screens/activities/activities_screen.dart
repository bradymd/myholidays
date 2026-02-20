import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/models/activity.dart';
import 'package:my_holidays/providers/activity_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/currency_helpers.dart';
import 'package:my_holidays/utils/date_helpers.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/empty_state.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key, required this.holidayId});

  final String holidayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider(holidayId));

    return AppScaffold(
      title: 'Activities',
      useOverlayNav: true,
      showBackButton: true,
      overlayFabIcon: Icons.add_rounded,
      overlayFabOnPressed: () => context.push('/add-activity/$holidayId'),
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (activities) {
          if (activities.isEmpty) {
            return EmptyState(
              message: 'No activities yet',
              subtitle: 'Add excursions, tours, and things to do',
              actionLabel: 'Add Activity',
              onAction: () => context.push('/add-activity/$holidayId'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length + 1,
            itemBuilder: (context, index) {
              if (index == activities.length) {
                return const SizedBox(height: 80);
              }
              return _ActivityCard(
                activity: activities[index],
                holidayId: holidayId,
                onDelete: () => _confirmDelete(context, ref, activities[index]),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Activity activity) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Activity?'),
        content: Text(
          'Remove ${activity.name.isNotEmpty ? activity.name : "this activity"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(activitiesProvider(holidayId).notifier)
                  .deleteActivity(activity.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.holidayId,
    required this.onDelete,
  });

  final Activity activity;
  final String holidayId;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const sectionColor = Color(0xFFC62828);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, sectionColor.withValues(alpha: 0.06)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: name + actions
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          sectionColor.withValues(alpha: 0.15),
                          sectionColor.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: sectionColor.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_activity_rounded,
                      color: sectionColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activity.name.isNotEmpty ? activity.name : 'Activity',
                      style: AppTextStyles.subheading.copyWith(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: sectionColor,
                    onPressed: () => context.push(
                      '/edit-activity/$holidayId/${activity.id}',
                    ),
                    tooltip: 'Edit',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: AppColors.danger,
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date & time
              if (activity.date.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatDateUK(activity.date),
                      style: AppTextStyles.caption,
                    ),
                    if (activity.time.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(activity.time, style: AppTextStyles.caption),
                    ],
                  ],
                ),
              if (activity.date.isNotEmpty) const SizedBox(height: 8),

              // Info chips
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (activity.location.isNotEmpty)
                    _infoChip(Icons.location_on_outlined, activity.location),
                  if (activity.cost > 0)
                    _infoChip(
                      Icons.payments_outlined,
                      formatGBP(activity.cost),
                    ),
                  if (activity.bookingReference.isNotEmpty)
                    _infoChip(
                      Icons.confirmation_number_outlined,
                      activity.bookingReference,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
