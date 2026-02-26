import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/models/traveler.dart';
import 'package:my_holidays/providers/document_provider.dart';
import 'package:my_holidays/providers/traveler_provider.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/linkified_text.dart';
import 'package:my_holidays/models/document_ref.dart';
import 'package:my_holidays/widgets/doc_count_badge.dart';
import 'package:my_holidays/widgets/empty_state.dart';
import 'package:my_holidays/widgets/shimmer_loading.dart';
import 'package:my_holidays/widgets/staggered_list.dart';

class TravelersScreen extends ConsumerWidget {
  const TravelersScreen({super.key, required this.holidayId});

  final String holidayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travelersAsync = ref.watch(travelersProvider(holidayId));
    final allDocs = ref.watch(documentsProvider).valueOrNull ?? [];

    return AppScaffold(
      title: 'Travellers',
      useOverlayNav: true,
      showBackButton: true,
      overlayFabIcon: Icons.add_rounded,
      overlayFabOnPressed: () => context.push('/add-traveler/$holidayId'),
      body: travelersAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (travelers) {
          if (travelers.isEmpty) {
            return EmptyState(
              message: 'No travellers yet',
              subtitle: 'Add the people going on this holiday',
              actionLabel: 'Add Traveller',
              onAction: () => context.push('/add-traveler/$holidayId'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: travelers.length + 1,
            itemBuilder: (context, index) {
              if (index == travelers.length) {
                return const SizedBox(height: 80);
              }
              final traveler = travelers[index];
              final docs = allDocs
                  .where((d) => d.parentId == traveler.id)
                  .toList();
              return StaggeredListItem(
                index: index,
                child: _TravelerCard(
                  traveler: traveler,
                  holidayId: holidayId,
                  documents: docs,
                ),
              );
            },
          );
        },
      ),
    );
  }

}

class _TravelerCard extends StatelessWidget {
  const _TravelerCard({
    required this.traveler,
    required this.holidayId,
    this.documents = const [],
  });

  final Traveler traveler;
  final String holidayId;
  final List<DocumentRef> documents;

  @override
  Widget build(BuildContext context) {
    const sectionColor = Color(0xFF283593);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
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
                  Icons.person_rounded,
                  color: sectionColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      traveler.name.isNotEmpty ? traveler.name : 'Unnamed',
                      style: AppTextStyles.bodyBold,
                    ),
                    if (traveler.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      LinkifiedText(
                        traveler.notes,
                        style: AppTextStyles.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (documents.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      DocChips(documents: documents),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                color: sectionColor,
                onPressed: () =>
                    context.push('/edit-traveler/$holidayId/${traveler.id}'),
                tooltip: 'Edit',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
