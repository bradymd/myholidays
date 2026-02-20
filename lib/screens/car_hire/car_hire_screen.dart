import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/models/car_hire.dart';
import 'package:my_holidays/providers/car_hire_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/currency_helpers.dart';
import 'package:my_holidays/utils/date_helpers.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/empty_state.dart';

class CarHireScreen extends ConsumerWidget {
  const CarHireScreen({super.key, required this.holidayId});

  final String holidayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carHireAsync = ref.watch(carHiresProvider(holidayId));

    return AppScaffold(
      title: 'Car Hire',
      useOverlayNav: true,
      showBackButton: true,
      overlayFabIcon: Icons.add_rounded,
      overlayFabOnPressed: () => context.push('/add-car-hire/$holidayId'),
      body: carHireAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (hires) {
          if (hires.isEmpty) {
            return EmptyState(
              message: 'No car hire yet',
              subtitle: 'Add rental car details for your trip',
              actionLabel: 'Add Car Hire',
              onAction: () => context.push('/add-car-hire/$holidayId'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hires.length + 1,
            itemBuilder: (context, index) {
              if (index == hires.length) return const SizedBox(height: 80);
              return _CarHireCard(
                carHire: hires[index],
                holidayId: holidayId,
                onDelete: () => _confirmDelete(context, ref, hires[index]),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CarHire carHire) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Car Hire?'),
        content: Text(
          'Remove ${carHire.company.isNotEmpty ? carHire.company : "this car hire"}?',
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
                  .read(carHiresProvider(holidayId).notifier)
                  .deleteCarHire(carHire.id);
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

class _CarHireCard extends StatelessWidget {
  const _CarHireCard({
    required this.carHire,
    required this.holidayId,
    required this.onDelete,
  });

  final CarHire carHire;
  final String holidayId;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const sectionColor = Color(0xFFE65100);
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
              // Header: company + actions
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
                      Icons.directions_car_rounded,
                      color: sectionColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      carHire.company.isNotEmpty ? carHire.company : 'Car Hire',
                      style: AppTextStyles.subheading.copyWith(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: sectionColor,
                    onPressed: () =>
                        context.push('/edit-car-hire/$holidayId/${carHire.id}'),
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

              // Pickup
              if (carHire.pickupLocation.isNotEmpty ||
                  carHire.pickupDate.isNotEmpty)
                _locationRow(
                  label: 'Pickup',
                  location: carHire.pickupLocation,
                  date: carHire.pickupDate,
                  time: carHire.pickupTime,
                  icon: Icons.flight_land_rounded,
                ),

              if (carHire.pickupDate.isNotEmpty &&
                  carHire.dropoffDate.isNotEmpty)
                const SizedBox(height: 8),

              // Dropoff
              if (carHire.dropoffLocation.isNotEmpty ||
                  carHire.dropoffDate.isNotEmpty)
                _locationRow(
                  label: 'Dropoff',
                  location: carHire.dropoffLocation,
                  date: carHire.dropoffDate,
                  time: carHire.dropoffTime,
                  icon: Icons.flight_takeoff_rounded,
                ),
              const SizedBox(height: 8),

              // Info chips
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (carHire.drivers.isNotEmpty)
                    _infoChip(Icons.person_rounded, carHire.drivers),
                  if (carHire.bookingReference.isNotEmpty)
                    _infoChip(
                      Icons.confirmation_number_outlined,
                      carHire.bookingReference,
                    ),
                  if (carHire.deposit > 0)
                    _infoChip(
                      Icons.account_balance_wallet_outlined,
                      'Deposit: ${formatGBP(carHire.deposit)}',
                    ),
                  if (carHire.totalCost > 0)
                    _infoChip(
                      Icons.payments_outlined,
                      'Total: ${formatGBP(carHire.totalCost)}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationRow({
    required String label,
    required String location,
    required String date,
    required String time,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label${location.isNotEmpty ? ": $location" : ""}',
                style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
              ),
              if (date.isNotEmpty)
                Text(
                  '${formatDateUK(date)}${time.isNotEmpty ? " at $time" : ""}',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
        ),
      ],
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
