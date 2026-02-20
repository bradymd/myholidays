import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/models/accommodation.dart';
import 'package:my_holidays/models/activity.dart';
import 'package:my_holidays/models/car_hire.dart';
import 'package:my_holidays/models/travel_leg.dart';
import 'package:my_holidays/providers/accommodation_provider.dart';
import 'package:my_holidays/providers/activity_provider.dart';
import 'package:my_holidays/providers/car_hire_provider.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/providers/document_provider.dart';
import 'package:my_holidays/providers/holiday_provider.dart';
import 'package:my_holidays/providers/itinerary_provider.dart';
import 'package:my_holidays/providers/travel_provider.dart';
import 'package:my_holidays/providers/traveler_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/currency_helpers.dart';
import 'package:my_holidays/utils/date_helpers.dart';
import 'package:my_holidays/models/document_ref.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/doc_count_badge.dart';
import 'package:my_holidays/widgets/shimmer_loading.dart';

class HolidayDetailScreen extends ConsumerStatefulWidget {
  const HolidayDetailScreen({super.key, required this.holidayId});

  final String holidayId;

  @override
  ConsumerState<HolidayDetailScreen> createState() =>
      _HolidayDetailScreenState();
}

class _HolidayDetailScreenState extends ConsumerState<HolidayDetailScreen> {
  static const _allSections = [
    'travelers',
    'accommodation',
    'travel',
    'car_hire',
    'activities',
    'itinerary',
    'documents',
  ];

  Set<String> _enabledSections = _allSections.toSet();
  bool _sectionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSectionPrefs();
  }

  Future<void> _loadSectionPrefs() async {
    final db = ref.read(databaseProvider);
    final value = await db.getSetting('holiday_sections_${widget.holidayId}');
    if (mounted) {
      setState(() {
        if (value != null && value.isNotEmpty) {
          _enabledSections = value.split(',').toSet();
        }
        _sectionsLoaded = true;
      });
    }
  }

  Future<void> _toggleSection(String key) async {
    final updated = Set<String>.from(_enabledSections);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    setState(() => _enabledSections = updated);
    final db = ref.read(databaseProvider);
    await db.setSetting(
      'holiday_sections_${widget.holidayId}',
      updated.join(','),
    );
  }

  double _totalCost(
    List<Accommodation> accommodations,
    List<TravelLeg> travelLegs,
    List<CarHire> carHires,
    List<Activity> activities,
  ) {
    double total = 0;
    for (final a in accommodations) {
      total += a.cost;
    }
    for (final t in travelLegs) {
      total += t.cost;
    }
    for (final c in carHires) {
      total += c.totalCost;
    }
    for (final a in activities) {
      total += a.cost;
    }
    return total;
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Holiday?'),
        content: const Text(
          'This will permanently delete this holiday and all its travellers, '
          'accommodation, travel, car hire, activities, itinerary and documents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(holidaysProvider.notifier)
                  .deleteHoliday(widget.holidayId);
              Navigator.pop(ctx);
              context.go('/');
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

  Widget _sectionChip(String key, String label, IconData icon) {
    final enabled = _enabledSections.contains(key);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: enabled ? Colors.white : AppColors.textMuted,
        ),
      ),
      avatar: Icon(
        icon,
        size: 14,
        color: enabled ? Colors.white : AppColors.textMuted,
      ),
      selected: enabled,
      onSelected: (_) => _toggleSection(key),
      selectedColor: AppColors.primaryLight,
      backgroundColor: AppColors.softLilac,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      side: BorderSide.none,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.75),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white, size: 20),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final holidaysAsync = ref.watch(holidaysProvider);
    final hId = widget.holidayId;

    // Watch all sub-entity providers so counts update automatically
    final travelers = ref.watch(travelersProvider(hId)).valueOrNull ?? [];
    final accommodations =
        ref.watch(accommodationsProvider(hId)).valueOrNull ?? [];
    final travelLegs = ref.watch(travelLegsProvider(hId)).valueOrNull ?? [];
    final carHires = ref.watch(carHiresProvider(hId)).valueOrNull ?? [];
    final activities = ref.watch(activitiesProvider(hId)).valueOrNull ?? [];
    final itineraryDays =
        ref.watch(itineraryDaysProvider(hId)).valueOrNull ?? [];

    // Watch all documents and compute per-entity counts
    final allDocs = ref.watch(documentsProvider).valueOrNull ?? [];
    final allParentIds = <String>{
      hId,
      ...accommodations.map((a) => a.id),
      ...travelLegs.map((l) => l.id),
      ...carHires.map((c) => c.id),
      ...activities.map((a) => a.id),
      ...travelers.map((t) => t.id),
      ...itineraryDays.map((d) => d.id),
    };
    final holidayDocs =
        allDocs.where((d) => allParentIds.contains(d.parentId)).toList();
    final docsById = <String, List<DocumentRef>>{};
    for (final doc in holidayDocs) {
      docsById.putIfAbsent(doc.parentId, () => []).add(doc);
    }
    final holidayLevelDocs =
        holidayDocs.where((d) => d.parentId == hId).toList();

    final totalCost = _totalCost(
      accommodations,
      travelLegs,
      carHires,
      activities,
    );

    return holidaysAsync.when(
      loading: () =>
          const Scaffold(body: ShimmerList()),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (holidays) {
        final holiday = holidays
            .where((h) => h.id == widget.holidayId)
            .firstOrNull;
        final holidayColour = holiday != null
            ? AppColors.holidayColour(holiday.colour)
            : AppColors.primary;
        if (holiday == null) {
          return AppScaffold(
            title: '',
            showBackButton: true,
            body: const Center(child: Text('Holiday not found')),
          );
        }

        return AppScaffold(
          useOverlayNav: true,
          showBackButton: true,
          title: holiday.name.isNotEmpty ? holiday.name : 'Holiday Details',
          actions: [
            _buildActionButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          ],
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Holiday info card — tappable like other panels
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          holidayColour.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: InkWell(
                      onTap: () =>
                          context.push('/edit-holiday/${widget.holidayId}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (holiday.icon.isNotEmpty)
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          holidayColour.withValues(
                                            alpha: 0.15,
                                          ),
                                          holidayColour.withValues(
                                            alpha: 0.08,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: holidayColour.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Image.asset(
                                          AppColors.holidayIconAsset(holiday.icon),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (holiday.icon.isNotEmpty)
                                  const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        holiday.name.isNotEmpty
                                            ? holiday.name
                                            : 'Untitled Holiday',
                                        style: AppTextStyles.bodyBold,
                                      ),
                                      if (holiday.startDate.isNotEmpty)
                                        Text(
                                          _dateRange(
                                            holiday.startDate,
                                            holiday.endDate,
                                          ),
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                  size: 22,
                                ),
                              ],
                            ),
                            if (holiday.startDate.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 48),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatDateRelative(holiday.startDate),
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _countdownColor(
                                          holiday.startDate,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (holiday.notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 48),
                                child: Text(
                                  holiday.notes,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Section toggle chips
                if (_sectionsLoaded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _sectionChip(
                          'travelers',
                          'Travellers',
                          Icons.people_rounded,
                        ),
                        _sectionChip(
                          'accommodation',
                          'Accommodation',
                          Icons.hotel_rounded,
                        ),
                        _sectionChip('travel', 'Travel', Icons.flight_rounded),
                        _sectionChip(
                          'car_hire',
                          'Car Hire',
                          Icons.directions_car_rounded,
                        ),
                        _sectionChip(
                          'activities',
                          'Activities',
                          Icons.local_activity_rounded,
                        ),
                        _sectionChip(
                          'itinerary',
                          'Itinerary',
                          Icons.calendar_today_rounded,
                        ),
                        _sectionChip(
                          'documents',
                          'Documents',
                          Icons.attach_file_rounded,
                        ),
                      ],
                    ),
                  ),
                // Sub-entity sections
                if (_enabledSections.contains('travelers'))
                  _SectionPanel(
                    icon: Icons.people_rounded,
                    iconColor: const Color(0xFF283593),
                    title: 'Travellers',
                    count: travelers.length,
                    onTap: () => context.push('/travelers/${widget.holidayId}'),
                    children: travelers
                        .map((t) => t.name.isNotEmpty ? t.name : 'Unnamed')
                        .toList(),
                    childDocs: travelers
                        .map((t) => docsById[t.id] ?? <DocumentRef>[])
                        .toList(),
                  ),
                if (_enabledSections.contains('accommodation'))
                  _SectionPanel(
                    icon: Icons.hotel_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    title: 'Accommodation',
                    count: accommodations.length,
                    onTap: () =>
                        context.push('/accommodations/${widget.holidayId}'),
                    children: accommodations
                        .map((a) => a.name.isNotEmpty ? a.name : 'Unnamed')
                        .toList(),
                    childDocs: accommodations
                        .map((a) => docsById[a.id] ?? <DocumentRef>[])
                        .toList(),
                  ),
                if (_enabledSections.contains('travel'))
                  _SectionPanel(
                    icon: Icons.flight_rounded,
                    iconColor: const Color(0xFF1565C0),
                    title: 'Travel',
                    count: travelLegs.length,
                    onTap: () => context.push('/travel/${widget.holidayId}'),
                    children: travelLegs.map((t) {
                      final route = [
                        if (t.from.isNotEmpty) t.from,
                        if (t.to.isNotEmpty) t.to,
                      ].join(' \u2192 ');
                      return route.isNotEmpty ? route : 'Unnamed';
                    }).toList(),
                    childDocs: travelLegs
                        .map((t) => docsById[t.id] ?? <DocumentRef>[])
                        .toList(),
                  ),
                if (_enabledSections.contains('car_hire'))
                  _SectionPanel(
                    icon: Icons.directions_car_rounded,
                    iconColor: const Color(0xFFE65100),
                    title: 'Car Hire',
                    count: carHires.length,
                    onTap: () => context.push('/car-hire/${widget.holidayId}'),
                    children: carHires
                        .map(
                          (c) => c.company.isNotEmpty ? c.company : 'Unnamed',
                        )
                        .toList(),
                    childDocs: carHires
                        .map((c) => docsById[c.id] ?? <DocumentRef>[])
                        .toList(),
                  ),
                if (_enabledSections.contains('activities'))
                  _SectionPanel(
                    icon: Icons.local_activity_rounded,
                    iconColor: const Color(0xFFC62828),
                    title: 'Activities',
                    count: activities.length,
                    onTap: () =>
                        context.push('/activities/${widget.holidayId}'),
                    children: activities
                        .map((a) => a.name.isNotEmpty ? a.name : 'Unnamed')
                        .toList(),
                    childDocs: activities
                        .map((a) => docsById[a.id] ?? <DocumentRef>[])
                        .toList(),
                  ),
                if (_enabledSections.contains('itinerary'))
                  _SectionPanel(
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFF00695C),
                    title: 'Itinerary',
                    count: itineraryDays.length,
                    onTap: () => context.push('/itinerary/${widget.holidayId}'),
                    children: itineraryDays
                        .map(
                          (d) => d.title.isNotEmpty
                              ? 'Day ${d.dayNumber}: ${d.title}'
                              : 'Day ${d.dayNumber}',
                        )
                        .toList(),
                    childDocs: itineraryDays
                        .map((d) => docsById[d.id] ?? <DocumentRef>[])
                        .toList(),
                  ),
                if (_enabledSections.contains('documents'))
                  _SectionPanel(
                    icon: Icons.attach_file_rounded,
                    iconColor: const Color(0xFF5D4037),
                    title: 'Documents',
                    count: holidayLevelDocs.length,
                    onTap: () =>
                        context.push('/documents/holiday/${widget.holidayId}'),
                    children: holidayLevelDocs
                        .map(
                          (d) => d.filename.isNotEmpty ? d.filename : 'Unnamed',
                        )
                        .toList(),
                  ),
                const SizedBox(height: 16),

                // Total cost summary
                if (totalCost > 0)
                  Card(
                    color: holidayColour.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: holidayColour.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: holidayColour,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Total Cost',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatGBP(totalCost),
                                  style: AppTextStyles.heading.copyWith(
                                    color: holidayColour,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Cost breakdown
                if (totalCost > 0) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cost Breakdown', style: AppTextStyles.bodyBold),
                          const SizedBox(height: 12),
                          _CostRow(
                            label: 'Accommodation',
                            amount: accommodations.fold(
                              0.0,
                              (sum, a) => sum + a.cost,
                            ),
                          ),
                          _CostRow(
                            label: 'Travel',
                            amount: travelLegs.fold(
                              0.0,
                              (sum, t) => sum + t.cost,
                            ),
                          ),
                          _CostRow(
                            label: 'Car Hire',
                            amount: carHires.fold(
                              0.0,
                              (sum, c) => sum + c.totalCost,
                            ),
                          ),
                          _CostRow(
                            label: 'Activities',
                            amount: activities.fold(
                              0.0,
                              (sum, a) => sum + a.cost,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 64),
              ],
            ),
          ),
        );
      },
    );
  }

  String _dateRange(String start, String end) {
    final s = formatDateUK(start);
    final e = formatDateUK(end);
    if (end.isEmpty) return s;
    return '$s - $e';
  }

  Color _countdownColor(String dateStr) {
    final days = daysUntil(dateStr);
    if (days < 0) return AppColors.textMuted;
    if (days <= 7) return AppColors.accentDark;
    if (days <= 30) return AppColors.warning;
    return AppColors.success;
  }
}

// ---------------------------------------------------------------------------
// Section panel — expanded with items when data exists, tappable to navigate
// ---------------------------------------------------------------------------

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.onTap,
    required this.children,
    this.childDocs = const [],
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final VoidCallback onTap;
  final List<String> children;
  final List<List<DocumentRef>> childDocs;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, iconColor.withValues(alpha: 0.06)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            iconColor.withValues(alpha: 0.15),
                            iconColor.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(title, style: AppTextStyles.bodyBold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: count > 0
                            ? iconColor.withValues(alpha: 0.12)
                            : AppColors.softLilac,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: count > 0 ? iconColor : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ],
                ),
                if (children.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...List.generate(children.length, (i) {
                    final item = children[i];
                    final docs = i < childDocs.length
                        ? childDocs[i]
                        : <DocumentRef>[];
                    return Padding(
                      padding: const EdgeInsets.only(left: 48, bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 5,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (docs.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 13),
                              child: DocChips(documents: docs),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cost breakdown row
// ---------------------------------------------------------------------------

class _CostRow extends StatelessWidget {
  const _CostRow({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    if (amount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(
            formatGBP(amount),
            style: AppTextStyles.bodyBold.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
