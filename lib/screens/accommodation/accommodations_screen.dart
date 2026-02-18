import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/models/accommodation.dart';
import 'package:my_holidays/providers/accommodation_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/currency_helpers.dart';
import 'package:my_holidays/utils/date_helpers.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/empty_state.dart';

class AccommodationsScreen extends ConsumerWidget {
  const AccommodationsScreen({super.key, required this.holidayId});

  final String holidayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accommodationsAsync =
        ref.watch(accommodationsProvider(holidayId));

    return AppScaffold(
      title: 'Accommodation',
      useOverlayNav: true,
      showBackButton: true,
      overlayFabIcon: Icons.add_rounded,
      overlayFabOnPressed: () =>
          context.push('/add-accommodation/$holidayId'),
      body: accommodationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accommodations) {
          if (accommodations.isEmpty) {
            return EmptyState(
              message: 'No accommodation yet',
              subtitle: 'Add hotels, villas, or other stays',
              actionLabel: 'Add Accommodation',
              onAction: () =>
                  context.push('/add-accommodation/$holidayId'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accommodations.length + 1,
            itemBuilder: (context, index) {
              if (index == accommodations.length) {
                return const SizedBox(height: 80);
              }
              final accommodation = accommodations[index];
              return _AccommodationCard(
                accommodation: accommodation,
                holidayId: holidayId,
                onDelete: () =>
                    _confirmDelete(context, ref, accommodation),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Accommodation accommodation,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Accommodation?'),
        content: Text(
          'Remove "${accommodation.name.isNotEmpty ? accommodation.name : 'this accommodation'}"? '
          'This cannot be undone.',
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
                  .read(accommodationsProvider(holidayId).notifier)
                  .deleteAccommodation(accommodation.id);
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

class _AccommodationCard extends StatelessWidget {
  const _AccommodationCard({
    required this.accommodation,
    required this.holidayId,
    required this.onDelete,
  });

  final Accommodation accommodation;
  final String holidayId;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasDeposit = accommodation.depositPaid > 0;
    final hasBalance = accommodation.balanceDue > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon, name, action buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.softPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.hotel_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accommodation.name.isNotEmpty
                            ? accommodation.name
                            : 'Unnamed',
                        style: AppTextStyles.bodyBold,
                      ),
                      if (accommodation.address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          accommodation.address,
                          style: AppTextStyles.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  color: AppColors.primary,
                  onPressed: () => context.push(
                    '/edit-accommodation/$holidayId/${accommodation.id}',
                  ),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColors.danger,
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Dates row
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Check-in: ${formatDateUK(accommodation.checkIn)}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(width: 16),
                Text(
                  'Check-out: ${formatDateUK(accommodation.checkOut)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),

            // Cost
            if (accommodation.cost > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.payments_rounded,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Total: ${formatGBP(accommodation.cost)}',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ],

            // Deposit & balance info
            if (hasDeposit || hasBalance) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (hasDeposit)
                    _infoChip(
                      'Deposit: ${formatGBP(accommodation.depositPaid)}',
                      AppColors.softGreen,
                      AppColors.success,
                    ),
                  if (hasBalance)
                    _infoChip(
                      'Balance: ${formatGBP(accommodation.balanceDue)}',
                      accommodation.balancePaidDate.isNotEmpty
                          ? AppColors.softGreen
                          : AppColors.softOrange,
                      accommodation.balancePaidDate.isNotEmpty
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  if (accommodation.balanceDueDate.isNotEmpty &&
                      accommodation.balancePaidDate.isEmpty)
                    _infoChip(
                      'Due: ${formatDateUK(accommodation.balanceDueDate)}',
                      isDueSoon(accommodation.balanceDueDate)
                          ? AppColors.softRed
                          : AppColors.softOrange,
                      isDueSoon(accommodation.balanceDueDate)
                          ? AppColors.danger
                          : AppColors.warning,
                    ),
                  if (accommodation.balancePaidDate.isNotEmpty)
                    _infoChip(
                      'Paid: ${formatDateUK(accommodation.balancePaidDate)}',
                      AppColors.softGreen,
                      AppColors.success,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
