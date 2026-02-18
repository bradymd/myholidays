import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/models/accommodation.dart';
import 'package:my_holidays/models/activity.dart';
import 'package:my_holidays/models/car_hire.dart';
import 'package:my_holidays/models/document_ref.dart';
import 'package:my_holidays/models/itinerary_day.dart';
import 'package:my_holidays/models/travel_leg.dart';
import 'package:my_holidays/models/traveler.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/providers/holiday_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/currency_helpers.dart';
import 'package:my_holidays/utils/date_helpers.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';

class HolidayDetailScreen extends ConsumerStatefulWidget {
  const HolidayDetailScreen({super.key, required this.holidayId});

  final String holidayId;

  @override
  ConsumerState<HolidayDetailScreen> createState() =>
      _HolidayDetailScreenState();
}

class _HolidayDetailScreenState extends ConsumerState<HolidayDetailScreen> {
  List<Traveler> _travelers = [];
  List<Accommodation> _accommodations = [];
  List<TravelLeg> _travelLegs = [];
  List<CarHire> _carHires = [];
  List<Activity> _activities = [];
  List<ItineraryDay> _itineraryDays = [];
  List<DocumentRef> _documents = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSubEntities();
  }

  Future<void> _loadSubEntities() async {
    final db = ref.read(databaseProvider);
    final hId = widget.holidayId;

    final results = await Future.wait([
      db.getTravelers(hId),
      db.getAccommodations(hId),
      db.getTravelLegs(hId),
      db.getCarHires(hId),
      db.getActivities(hId),
      db.getItineraryDays(hId),
      db.getDocuments(parentType: 'holiday', parentId: hId),
    ]);

    if (mounted) {
      setState(() {
        _travelers = results[0] as List<Traveler>;
        _accommodations = results[1] as List<Accommodation>;
        _travelLegs = results[2] as List<TravelLeg>;
        _carHires = results[3] as List<CarHire>;
        _activities = results[4] as List<Activity>;
        _itineraryDays = results[5] as List<ItineraryDay>;
        _documents = results[6] as List<DocumentRef>;
        _loaded = true;
      });
    }
  }

  double get _totalCost {
    double total = 0;
    for (final a in _accommodations) {
      total += a.cost;
    }
    for (final t in _travelLegs) {
      total += t.cost;
    }
    for (final c in _carHires) {
      total += c.totalCost;
    }
    for (final a in _activities) {
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
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final holidaysAsync = ref.watch(holidaysProvider);

    // Reload sub-entity counts when holiday provider changes
    ref.listen(holidaysProvider, (prev, next) => _loadSubEntities());

    return holidaysAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (holidays) {
        final holiday =
            holidays.where((h) => h.id == widget.holidayId).firstOrNull;
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
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              tooltip: 'Edit',
              onPressed: () =>
                  context.push('/edit-holiday/${widget.holidayId}'),
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
              tooltip: 'Summary',
              onPressed: () =>
                  context.push('/holiday-summary/${widget.holidayId}'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white, size: 20),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          ],
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Holiday info header card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          holiday.name.isNotEmpty
                              ? holiday.name
                              : 'Untitled Holiday',
                          style: AppTextStyles.heading,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              _dateRange(holiday.startDate, holiday.endDate),
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        if (holiday.startDate.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                formatDateRelative(holiday.startDate),
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _countdownColor(holiday.startDate),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (holiday.notes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            holiday.notes,
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sub-entity sections
                if (!_loaded)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  // Travellers
                  _SectionTile(
                    icon: Icons.people_rounded,
                    iconColor: AppColors.primary,
                    title: 'Travellers',
                    count: _travelers.length,
                    onNavigate: () =>
                        context.push('/travelers/${widget.holidayId}'),
                    children: _travelers
                        .take(3)
                        .map((t) => _PreviewRow(
                              label: t.name.isNotEmpty ? t.name : 'Unnamed',
                              detail: t.notes,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Accommodation
                  _SectionTile(
                    icon: Icons.hotel_rounded,
                    iconColor: const Color(0xFF1565C0),
                    title: 'Accommodation',
                    count: _accommodations.length,
                    onNavigate: () =>
                        context.push('/accommodations/${widget.holidayId}'),
                    children: _accommodations
                        .take(3)
                        .map((a) => _PreviewRow(
                              label: a.name.isNotEmpty ? a.name : 'Unnamed',
                              detail: [
                                if (a.checkIn.isNotEmpty)
                                  formatDateUK(a.checkIn),
                                if (a.checkOut.isNotEmpty)
                                  '- ${formatDateUK(a.checkOut)}',
                                if (a.cost > 0) formatGBP(a.cost),
                              ].join(' '),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Travel
                  _SectionTile(
                    icon: Icons.flight_rounded,
                    iconColor: const Color(0xFF00695C),
                    title: 'Travel',
                    count: _travelLegs.length,
                    onNavigate: () =>
                        context.push('/travel/${widget.holidayId}'),
                    children: _travelLegs
                        .take(3)
                        .map((t) => _PreviewRow(
                              label: [
                                if (t.from.isNotEmpty) t.from,
                                if (t.to.isNotEmpty) t.to,
                              ].join(' -> '),
                              detail: [
                                if (t.departureDate.isNotEmpty)
                                  formatDateUK(t.departureDate),
                                if (t.carrier.isNotEmpty) t.carrier,
                                if (t.cost > 0) formatGBP(t.cost),
                              ].join(' | '),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Car Hire
                  _SectionTile(
                    icon: Icons.directions_car_rounded,
                    iconColor: const Color(0xFFFF9800),
                    title: 'Car Hire',
                    count: _carHires.length,
                    onNavigate: () =>
                        context.push('/car-hire/${widget.holidayId}'),
                    children: _carHires
                        .take(3)
                        .map((c) => _PreviewRow(
                              label: c.company.isNotEmpty
                                  ? c.company
                                  : 'Unnamed',
                              detail: [
                                if (c.pickupDate.isNotEmpty)
                                  formatDateUK(c.pickupDate),
                                if (c.dropoffDate.isNotEmpty)
                                  '- ${formatDateUK(c.dropoffDate)}',
                                if (c.totalCost > 0) formatGBP(c.totalCost),
                              ].join(' '),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Activities
                  _SectionTile(
                    icon: Icons.local_activity_rounded,
                    iconColor: const Color(0xFFE53935),
                    title: 'Activities',
                    count: _activities.length,
                    onNavigate: () =>
                        context.push('/activities/${widget.holidayId}'),
                    children: _activities
                        .take(3)
                        .map((a) => _PreviewRow(
                              label: a.name.isNotEmpty ? a.name : 'Unnamed',
                              detail: [
                                if (a.date.isNotEmpty) formatDateUK(a.date),
                                if (a.location.isNotEmpty) a.location,
                                if (a.cost > 0) formatGBP(a.cost),
                              ].join(' | '),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Itinerary
                  _SectionTile(
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFF6A1B9A),
                    title: 'Itinerary',
                    count: _itineraryDays.length,
                    onNavigate: () =>
                        context.push('/itinerary/${widget.holidayId}'),
                    children: _itineraryDays
                        .take(3)
                        .map((d) => _PreviewRow(
                              label: d.title.isNotEmpty
                                  ? 'Day ${d.dayNumber}: ${d.title}'
                                  : 'Day ${d.dayNumber}',
                              detail: d.date.isNotEmpty
                                  ? formatDateUK(d.date)
                                  : '',
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Documents
                  _SectionTile(
                    icon: Icons.attach_file_rounded,
                    iconColor: const Color(0xFF5D4037),
                    title: 'Documents',
                    count: _documents.length,
                    onNavigate: () => context
                        .push('/documents/holiday/${widget.holidayId}'),
                    children: _documents
                        .take(3)
                        .map((d) => _PreviewRow(
                              label: d.filename.isNotEmpty
                                  ? d.filename
                                  : 'Unnamed',
                              detail: d.fileType,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Total cost summary
                  if (_totalCost > 0)
                    Card(
                      color: AppColors.softPurple,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Estimated Total Cost',
                                      style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatGBP(_totalCost),
                                    style: AppTextStyles.heading.copyWith(
                                      color: AppColors.primary,
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
                  if (_totalCost > 0) ...[
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cost Breakdown',
                                style: AppTextStyles.bodyBold),
                            const SizedBox(height: 12),
                            _CostRow(
                              label: 'Accommodation',
                              amount: _accommodations.fold(
                                  0.0, (sum, a) => sum + a.cost),
                            ),
                            _CostRow(
                              label: 'Travel',
                              amount: _travelLegs.fold(
                                  0.0, (sum, t) => sum + t.cost),
                            ),
                            _CostRow(
                              label: 'Car Hire',
                              amount: _carHires.fold(
                                  0.0, (sum, c) => sum + c.totalCost),
                            ),
                            _CostRow(
                              label: 'Activities',
                              amount: _activities.fold(
                                  0.0, (sum, a) => sum + a.cost),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 64),
                ],
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
// Collapsible section tile
// ---------------------------------------------------------------------------

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.onNavigate,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final VoidCallback onNavigate;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(title, style: AppTextStyles.bodyBold),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: count > 0 ? AppColors.softPurple : AppColors.softLilac,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: count > 0
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No items yet',
                style: AppTextStyles.caption,
              ),
            )
          else
            ...children,
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onNavigate,
              icon: Icon(Icons.open_in_new_rounded,
                  size: 16, color: AppColors.primary),
              label: Text(
                'View All',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview row for items inside an expansion tile
// ---------------------------------------------------------------------------

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, this.detail});

  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.body,
                    overflow: TextOverflow.ellipsis),
                if (detail != null && detail!.isNotEmpty)
                  Text(detail!,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
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
          Text(formatGBP(amount),
              style: AppTextStyles.bodyBold
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
