import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/models/itinerary_day.dart';
import 'package:my_holidays/providers/document_provider.dart';
import 'package:my_holidays/providers/itinerary_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/date_helpers.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/models/document_ref.dart';
import 'package:my_holidays/widgets/doc_count_badge.dart';
import 'package:my_holidays/widgets/empty_state.dart';
import 'package:my_holidays/widgets/shimmer_loading.dart';
import 'package:my_holidays/widgets/staggered_list.dart';

class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key, required this.holidayId});

  final String holidayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(itineraryDaysProvider(holidayId));
    final allDocs = ref.watch(documentsProvider).valueOrNull ?? [];

    return AppScaffold(
      useOverlayNav: true,
      showBackButton: true,
      title: 'Itinerary',
      overlayFabIcon: Icons.add_rounded,
      overlayFabOnPressed: () => context.push('/add-itinerary-day/$holidayId'),
      body: daysAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error loading itinerary: $e',
              style: AppTextStyles.body.copyWith(color: AppColors.danger),
            ),
          ),
        ),
        data: (days) {
          if (days.isEmpty) {
            return EmptyState(
              message: 'No itinerary yet',
              subtitle: 'Plan your trip day by day',
              actionLabel: 'Add Day',
              onAction: () => context.push('/add-itinerary-day/$holidayId'),
            );
          }

          final sorted = List<ItineraryDay>.from(days)
            ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final day = sorted[index];
              final docs = allDocs
                  .where((d) => d.parentId == day.id)
                  .toList();
              return StaggeredListItem(
                index: index,
                child: _DayCard(
                  day: day,
                  holidayId: holidayId,
                  documents: docs,
                  onEdit: () =>
                      context.push('/edit-itinerary-day/$holidayId/${day.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.holidayId,
    required this.onEdit,
    this.documents = const [],
  });

  final ItineraryDay day;
  final String holidayId;
  final VoidCallback onEdit;
  final List<DocumentRef> documents;

  @override
  Widget build(BuildContext context) {
    const sectionColor = Color(0xFF00695C);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: AppColors.cardShadow,
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
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: sectionColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${day.dayNumber}',
                        style: AppTextStyles.subheading.copyWith(
                          color: sectionColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${day.dayNumber}${day.title.isNotEmpty ? ' - ${day.title}' : ''}',
                          style: AppTextStyles.subheading.copyWith(
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (day.date.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            formatDateUK(day.date),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: sectionColor,
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                ],
              ),
              if (day.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  day.description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (documents.isNotEmpty) ...[
                const SizedBox(height: 8),
                DocChips(documents: documents),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
