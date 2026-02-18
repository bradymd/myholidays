import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/constants/enums.dart';
import 'package:my_holidays/models/travel_leg.dart';
import 'package:my_holidays/providers/travel_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/currency_helpers.dart';
import 'package:my_holidays/utils/date_helpers.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/empty_state.dart';

class TravelScreen extends ConsumerWidget {
  const TravelScreen({super.key, required this.holidayId});

  final String holidayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travelAsync = ref.watch(travelLegsProvider(holidayId));

    return AppScaffold(
      title: 'Travel',
      useOverlayNav: true,
      showBackButton: true,
      overlayFabIcon: Icons.add_rounded,
      overlayFabOnPressed: () => context.push('/add-travel/$holidayId'),
      body: travelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (legs) {
          if (legs.isEmpty) {
            return EmptyState(
              message: 'No travel legs yet',
              subtitle: 'Add flights, trains, and other transport',
              actionLabel: 'Add Travel',
              onAction: () => context.push('/add-travel/$holidayId'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: legs.length + 1,
            itemBuilder: (context, index) {
              if (index == legs.length) return const SizedBox(height: 80);
              return _TravelLegCard(
                leg: legs[index],
                holidayId: holidayId,
                onDelete: () => _confirmDelete(context, ref, legs[index]),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TravelLeg leg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Travel Leg?'),
        content: Text(
          'Remove ${leg.from} to ${leg.to}?',
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
                  .read(travelLegsProvider(holidayId).notifier)
                  .deleteTravelLeg(leg.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _TravelLegCard extends StatelessWidget {
  const _TravelLegCard({
    required this.leg,
    required this.holidayId,
    required this.onDelete,
  });

  final TravelLeg leg;
  final String holidayId;
  final VoidCallback onDelete;

  IconData _modeIcon(String mode) {
    return switch (mode) {
      'flight' => Icons.flight_rounded,
      'train' => Icons.train_rounded,
      'car' => Icons.directions_car_rounded,
      'bus' => Icons.directions_bus_rounded,
      'ferry' => Icons.directions_boat_rounded,
      _ => Icons.commute_rounded,
    };
  }

  Color _typeBadgeColor(String type) {
    return switch (type) {
      'outbound' => AppColors.primary,
      'returnLeg' => AppColors.accent,
      _ => AppColors.skyBlue,
    };
  }

  String _typeLabel(String type) {
    final matched = TravelLegType.values.where((e) => e.name == type);
    if (matched.isNotEmpty) return matched.first.label;
    return type;
  }

  String _modeLabel(String mode) {
    final matched = TravelMode.values.where((e) => e.name == mode);
    if (matched.isNotEmpty) return matched.first.label;
    return mode;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: type badge + mode icon + actions
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _typeBadgeColor(leg.type).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _typeLabel(leg.type),
                    style: AppTextStyles.caption.copyWith(
                      color: _typeBadgeColor(leg.type),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _modeIcon(leg.mode),
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _modeLabel(leg.mode),
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.primary,
                  onPressed: () =>
                      context.push('/edit-travel/$holidayId/${leg.id}'),
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

            // From -> To
            Row(
              children: [
                Expanded(
                  child: Text(
                    leg.from.isNotEmpty ? leg.from : 'Origin',
                    style: AppTextStyles.bodyBold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18, color: AppColors.primary),
                ),
                Expanded(
                  child: Text(
                    leg.to.isNotEmpty ? leg.to : 'Destination',
                    style: AppTextStyles.bodyBold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Departure date/time
            if (leg.departureDate.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    formatDateUK(leg.departureDate),
                    style: AppTextStyles.caption,
                  ),
                  if (leg.departureTime.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      leg.departureTime,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 8),

            // Carrier, booking ref, cost
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (leg.carrier.isNotEmpty)
                  _infoChip(Icons.business_rounded, leg.carrier),
                if (leg.bookingReference.isNotEmpty)
                  _infoChip(Icons.confirmation_number_outlined,
                      leg.bookingReference),
                if (leg.cost > 0)
                  _infoChip(Icons.payments_outlined, formatGBP(leg.cost)),
              ],
            ),
          ],
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
        Text(text, style: AppTextStyles.caption),
      ],
    );
  }
}
