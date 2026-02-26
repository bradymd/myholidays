import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:my_holidays/models/accommodation.dart';
import 'package:my_holidays/models/activity.dart';
import 'package:my_holidays/models/car_hire.dart';
import 'package:my_holidays/models/document_ref.dart';
import 'package:my_holidays/models/holiday_plan.dart';
import 'package:my_holidays/models/itinerary_day.dart';
import 'package:my_holidays/models/travel_leg.dart';
import 'package:my_holidays/models/traveler.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/providers/accommodation_provider.dart';
import 'package:my_holidays/providers/activity_provider.dart';
import 'package:my_holidays/providers/car_hire_provider.dart';
import 'package:my_holidays/providers/document_provider.dart';
import 'package:my_holidays/providers/holiday_provider.dart';
import 'package:my_holidays/providers/itinerary_provider.dart';
import 'package:my_holidays/providers/travel_provider.dart';
import 'package:my_holidays/providers/traveler_provider.dart';
import 'package:my_holidays/services/document_service.dart';
import 'package:my_holidays/services/holiday_share_service.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/currency_helpers.dart';
import 'package:my_holidays/utils/date_helpers.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/shimmer_loading.dart';

class HolidaySummaryScreen extends ConsumerStatefulWidget {
  const HolidaySummaryScreen({super.key, required this.holidayId});

  final String holidayId;

  @override
  ConsumerState<HolidaySummaryScreen> createState() =>
      _HolidaySummaryScreenState();
}

class _HolidaySummaryScreenState extends ConsumerState<HolidaySummaryScreen> {
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
      });
    }
  }

  // Reactive data from providers — populated in build()
  HolidayPlan? _holiday;
  List<Traveler> _travelers = [];
  List<Accommodation> _accommodations = [];
  List<TravelLeg> _travelLegs = [];
  List<CarHire> _carHires = [];
  List<Activity> _activities = [];
  List<ItineraryDay> _itineraryDays = [];
  List<DocumentRef> _documents = [];


  bool _isSharing = false;

  Future<void> _shareHoliday() async {
    final h = _holiday;
    if (h == null) return;

    setState(() => _isSharing = true);
    try {
      final filePath = await HolidayShareService.exportHoliday(
        holiday: h,
        travelers: _travelers,
        accommodations: _accommodations,
        travelLegs: _travelLegs,
        carHires: _carHires,
        activities: _activities,
        itineraryDays: _itineraryDays,
        documents: _documents,
      );

      if (!mounted) return;

      if (Platform.isAndroid || Platform.isIOS) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(filePath)],
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : Rect.zero,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _printSummary() {
    final h = _holiday;
    if (h == null) return;

    Printing.layoutPdf(
      name: h.name,
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();

        // Load TTF fonts for full Unicode support (bullets, arrows, dashes)
        final font = await PdfGoogleFonts.nunitoSansRegular();
        final fontBold = await PdfGoogleFonts.nunitoSansBold();
        final fontItalic = await PdfGoogleFonts.nunitoSansItalic();

        // Styles
        const purple = PdfColors.purple;
        final titleStyle = pw.TextStyle(
          font: fontBold,
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: purple,
        );
        final subtitleStyle = pw.TextStyle(
          font: font,
          fontSize: 12,
          color: PdfColors.grey700,
        );
        final sectionHeaderStyle = pw.TextStyle(
          font: fontBold,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: purple,
        );
        final labelStyle = pw.TextStyle(
          font: fontBold,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        );
        final valueStyle = pw.TextStyle(font: font, fontSize: 10);
        final notesStyle = pw.TextStyle(
          font: fontItalic,
          fontSize: 10,
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.grey600,
        );

        // Helper to build a label: value row
        pw.Widget pdfRow(String label, String value) {
          if (value.isEmpty) return pw.SizedBox.shrink();
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 100,
                  child: pw.Text('$label:', style: labelStyle),
                ),
                pw.Expanded(child: pw.Text(value, style: valueStyle)),
              ],
            ),
          );
        }

        // Helper for a card-like container
        pw.Widget pdfCard(List<pw.Widget> children) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: children,
            ),
          );
        }

        // Helper for a section header
        pw.Widget pdfSectionHeader(String title) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: sectionHeaderStyle),
                pw.Divider(color: purple, thickness: 1),
              ],
            ),
          );
        }

        // Build all content widgets
        final content = <pw.Widget>[];

        // Title header
        content.add(
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.purple50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(h.name, style: titleStyle),
                if (h.startDate.isNotEmpty || h.endDate.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '${formatDateUK(h.startDate)} - ${formatDateUK(h.endDate)}',
                    style: subtitleStyle,
                  ),
                ],
                if (h.notes.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(h.notes, style: notesStyle),
                ],
              ],
            ),
          ),
        );

        // Travellers
        if (_travelers.isNotEmpty) {
          content.add(pdfSectionHeader('Travellers'));
          for (final t in _travelers) {
            content.add(
              pdfCard([
                pdfRow('Name', t.name),
                if (t.notes.isNotEmpty) pdfRow('Notes', t.notes),
              ]),
            );
          }
        }

        // Accommodation
        if (_accommodations.isNotEmpty) {
          content.add(pdfSectionHeader('Accommodation'));
          for (final a in _accommodations) {
            content.add(
              pdfCard([
                pdfRow('Name', a.name),
                if (a.address.isNotEmpty) pdfRow('Address', a.address),
                if (a.checkIn.isNotEmpty || a.checkOut.isNotEmpty)
                  pdfRow(
                    'Dates',
                    '${formatDateUK(a.checkIn)} - ${formatDateUK(a.checkOut)}',
                  ),
                if (a.confirmationNumber.isNotEmpty)
                  pdfRow('Confirmation', a.confirmationNumber),
                if (a.cost > 0) pdfRow('Cost', formatGBP(a.cost)),
                if (a.depositPaid > 0)
                  pdfRow('Deposit Paid', formatGBP(a.depositPaid)),
                if (a.balanceDue > 0)
                  pdfRow('Balance Due', formatGBP(a.balanceDue)),
                if (a.balanceDueDate.isNotEmpty)
                  pdfRow('Due Date', formatDateUK(a.balanceDueDate)),
                if (a.balancePaidDate.isNotEmpty)
                  pdfRow('Paid Date', formatDateUK(a.balancePaidDate)),
                if (a.notes.isNotEmpty) pdfRow('Notes', a.notes),
              ]),
            );
          }
        }

        // Travel
        if (_travelLegs.isNotEmpty) {
          content.add(pdfSectionHeader('Travel'));
          for (final leg in _travelLegs) {
            final typeLabel = leg.type.isNotEmpty
                ? '${leg.type[0].toUpperCase()}${leg.type.substring(1)}'
                : '';
            final modeLabel = leg.mode.isNotEmpty
                ? '${leg.mode[0].toUpperCase()}${leg.mode.substring(1)}'
                : '';
            content.add(
              pdfCard([
                pdfRow(
                  'Type',
                  '$typeLabel${modeLabel.isNotEmpty ? ' ($modeLabel)' : ''}',
                ),
                if (leg.from.isNotEmpty || leg.to.isNotEmpty)
                  pdfRow('Route', '${leg.from} -> ${leg.to}'),
                if (leg.departureDate.isNotEmpty)
                  pdfRow(
                    'Depart',
                    '${formatDateUK(leg.departureDate)}${leg.departureTime.isNotEmpty ? ' ${leg.departureTime}' : ''}',
                  ),
                if (leg.arrivalDate.isNotEmpty)
                  pdfRow(
                    'Arrive',
                    '${formatDateUK(leg.arrivalDate)}${leg.arrivalTime.isNotEmpty ? ' ${leg.arrivalTime}' : ''}',
                  ),
                if (leg.carrier.isNotEmpty) pdfRow('Carrier', leg.carrier),
                if (leg.bookingReference.isNotEmpty)
                  pdfRow('Booking Ref', leg.bookingReference),
                if (leg.cost > 0) pdfRow('Cost', formatGBP(leg.cost)),
                if (leg.notes.isNotEmpty) pdfRow('Notes', leg.notes),
              ]),
            );
          }
        }

        // Car Hire
        if (_carHires.isNotEmpty) {
          content.add(pdfSectionHeader('Car Hire'));
          for (final c in _carHires) {
            content.add(
              pdfCard([
                if (c.company.isNotEmpty) pdfRow('Company', c.company),
                if (c.pickupLocation.isNotEmpty || c.pickupDate.isNotEmpty)
                  pdfRow(
                    'Pickup',
                    '${c.pickupLocation}${c.pickupDate.isNotEmpty ? ' on ${formatDateUK(c.pickupDate)}' : ''}${c.pickupTime.isNotEmpty ? ' at ${c.pickupTime}' : ''}',
                  ),
                if (c.dropoffLocation.isNotEmpty || c.dropoffDate.isNotEmpty)
                  pdfRow(
                    'Dropoff',
                    '${c.dropoffLocation}${c.dropoffDate.isNotEmpty ? ' on ${formatDateUK(c.dropoffDate)}' : ''}${c.dropoffTime.isNotEmpty ? ' at ${c.dropoffTime}' : ''}',
                  ),
                if (c.drivers.isNotEmpty) pdfRow('Drivers', c.drivers),
                if (c.bookingReference.isNotEmpty)
                  pdfRow('Booking Ref', c.bookingReference),
                if (c.deposit > 0) pdfRow('Deposit', formatGBP(c.deposit)),
                if (c.totalCost > 0)
                  pdfRow('Total Cost', formatGBP(c.totalCost)),
                if (c.notes.isNotEmpty) pdfRow('Notes', c.notes),
              ]),
            );
          }
        }

        // Activities
        if (_activities.isNotEmpty) {
          content.add(pdfSectionHeader('Activities'));
          for (final a in _activities) {
            content.add(
              pdfCard([
                pdfRow('Name', a.name),
                if (a.date.isNotEmpty)
                  pdfRow(
                    'Date',
                    '${formatDateUK(a.date)}${a.time.isNotEmpty ? ' at ${a.time}' : ''}',
                  ),
                if (a.location.isNotEmpty) pdfRow('Location', a.location),
                if (a.bookingReference.isNotEmpty)
                  pdfRow('Booking Ref', a.bookingReference),
                if (a.cost > 0) pdfRow('Cost', formatGBP(a.cost)),
                if (a.notes.isNotEmpty) pdfRow('Notes', a.notes),
              ]),
            );
          }
        }

        // Itinerary
        if (_itineraryDays.isNotEmpty) {
          content.add(pdfSectionHeader('Itinerary'));
          for (final day in _itineraryDays) {
            content.add(
              pdfCard([
                pdfRow(
                  'Day',
                  '${day.dayNumber}${day.title.isNotEmpty ? ' - ${day.title}' : ''}',
                ),
                if (day.date.isNotEmpty) pdfRow('Date', formatDateUK(day.date)),
                if (day.description.isNotEmpty)
                  pdfRow('Description', day.description),
                if (day.notes.isNotEmpty) pdfRow('Notes', day.notes),
              ]),
            );
          }
        }

        // Documents
        if (_documents.isNotEmpty) {
          content.add(pdfSectionHeader('Documents'));
          final grouped = <String, List<DocumentRef>>{};
          for (final doc in _documents) {
            grouped.putIfAbsent(doc.parentType, () => []).add(doc);
          }
          for (final entry in grouped.entries) {
            final typeLabel = _parentTypeLabel(entry.key);
            content.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4, top: 4),
                child: pw.Text(
                  typeLabel,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
            );
            for (final doc in entry.value) {
              final parentName = _resolveParentName(doc);
              content.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                  child: pw.Row(
                    children: [
                      pw.Text('\u2022 ', style: valueStyle),
                      pw.Expanded(
                        child: pw.Text(
                          '${doc.filename}  ($parentName)',
                          style: valueStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
        }

        // Financial Summary
        final costs = <String, double>{};
        double accomTotal = 0;
        for (final a in _accommodations) {
          accomTotal += a.cost;
        }
        if (accomTotal > 0) costs['Accommodation'] = accomTotal;

        double travelTotal = 0;
        for (final l in _travelLegs) {
          travelTotal += l.cost;
        }
        if (travelTotal > 0) costs['Travel'] = travelTotal;

        double carTotal = 0;
        for (final c in _carHires) {
          carTotal += c.totalCost;
        }
        if (carTotal > 0) costs['Car Hire'] = carTotal;

        double activityTotal = 0;
        for (final a in _activities) {
          activityTotal += a.cost;
        }
        if (activityTotal > 0) costs['Activities'] = activityTotal;

        if (costs.isNotEmpty) {
          double grandTotal = 0;
          for (final v in costs.values) {
            grandTotal += v;
          }

          content.add(pdfSectionHeader('Financial Summary'));
          content.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  ...costs.entries.map(
                    (entry) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(entry.key, style: valueStyle),
                          pw.Text(
                            formatGBP(entry.value),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Divider(color: PdfColors.grey400),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: purple,
                          ),
                        ),
                        pw.Text(
                          formatGBP(grandTotal),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Build PDF pages with multi-page support
        pdf.addPage(
          pw.MultiPage(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(32),
            build: (context) => content,
          ),
        );

        return pdf.save();
      },
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final hId = widget.holidayId;
    final holidaysAsync = ref.watch(holidaysProvider);

    // Watch all sub-entity providers for reactive updates
    _travelers = ref.watch(travelersProvider(hId)).valueOrNull ?? [];
    _accommodations = ref.watch(accommodationsProvider(hId)).valueOrNull ?? [];
    _travelLegs = ref.watch(travelLegsProvider(hId)).valueOrNull ?? [];
    _carHires = ref.watch(carHiresProvider(hId)).valueOrNull ?? [];
    _activities = ref.watch(activitiesProvider(hId)).valueOrNull ?? [];
    final rawDays = ref.watch(itineraryDaysProvider(hId)).valueOrNull ?? [];
    _itineraryDays = List<ItineraryDay>.from(rawDays)
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    // Collect all parent IDs and filter documents
    final allParentIds = <String>{
      hId,
      ..._accommodations.map((a) => a.id),
      ..._travelLegs.map((l) => l.id),
      ..._carHires.map((c) => c.id),
      ..._activities.map((a) => a.id),
      ..._travelers.map((t) => t.id),
      ..._itineraryDays.map((d) => d.id),
    };
    final allDocs = ref.watch(documentsProvider).valueOrNull ?? [];
    _documents =
        allDocs.where((d) => allParentIds.contains(d.parentId)).toList();

    return holidaysAsync.when(
      loading: () => const AppScaffold(
        title: 'Trip Summary',
        body: ShimmerList(),
      ),
      error: (e, _) => AppScaffold(
        title: 'Trip Summary',
        body: Center(child: Text('Error: $e')),
      ),
      data: (holidays) {
        _holiday = holidays.where((h) => h.id == hId).firstOrNull;

        final isEmpty = _travelers.isEmpty &&
            _accommodations.isEmpty &&
            _travelLegs.isEmpty &&
            _carHires.isEmpty &&
            _activities.isEmpty &&
            _itineraryDays.isEmpty;

        return AppScaffold(
          useOverlayNav: true,
          showBackButton: true,
          showHomeButton: false,
          title: '',
          overlayFabIcon: Icons.edit_rounded,
          overlayFabPulse: isEmpty,
          overlayFabOnPressed: () => context.push(
            '/holiday-manage/${widget.holidayId}',
          ),
          extraMenuItems: _holiday != null
              ? [
                  PopupMenuItem<String>(
                    value: 'share',
                    enabled: !_isSharing,
                    child: Row(
                      children: [
                        Icon(Icons.share_rounded, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Text(_isSharing ? 'Sharing...' : 'Share Holiday',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'print',
                    child: Row(
                      children: [
                        Icon(Icons.print_rounded, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        const Text('Print / Save PDF',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ]
              : null,
          onExtraMenuSelected: (value) {
            if (value == 'share') _shareHoliday();
            if (value == 'print') _printSummary();
          },
          body: _holiday == null
              ? Center(
                  child: Text(
                    'Holiday not found.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      if (_travelers.isNotEmpty &&
                          _enabledSections.contains('travelers'))
                        _buildTravellersSection(),
                      if (_accommodations.isNotEmpty &&
                          _enabledSections.contains('accommodation'))
                        _buildAccommodationSection(),
                      if (_travelLegs.isNotEmpty &&
                          _enabledSections.contains('travel'))
                        _buildTravelSection(),
                      if (_carHires.isNotEmpty &&
                          _enabledSections.contains('car_hire'))
                        _buildCarHireSection(),
                      if (_activities.isNotEmpty &&
                          _enabledSections.contains('activities'))
                        _buildActivitiesSection(),
                      if (_itineraryDays.isNotEmpty &&
                          _enabledSections.contains('itinerary'))
                        _buildItinerarySection(),
                      if (_documents.isNotEmpty &&
                          _enabledSections.contains('documents'))
                        _buildDocumentsSection(),
                      _buildFinancialSection(),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final h = _holiday!;
    final holidayColour = AppColors.holidayColour(h.colour);
    return Hero(
      tag: 'holiday-${widget.holidayId}',
      child: Material(
        type: MaterialType.transparency,
        child: Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      child: InkWell(
        onTap: () => context.push('/edit-holiday/${widget.holidayId}'),
        child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              holidayColour.withValues(alpha: 0.12),
              holidayColour.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (h.icon.isNotEmpty) ...[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: holidayColour.withValues(alpha: 0.15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          AppColors.holidayIconAsset(h.icon),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    h.name,
                    style: AppTextStyles.heading.copyWith(fontSize: 22),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: holidayColour.withValues(alpha: 0.5),
                  size: 24,
                ),
              ],
            ),
            if (h.startDate.isNotEmpty || h.endDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${formatDateUK(h.startDate)} - ${formatDateUK(h.endDate)}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (h.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                h.notes,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    ),
    ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    VoidCallback? onTap,
  }) {
    final header = Row(
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
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.subheading.copyWith(fontSize: 17),
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right_rounded,
            color: iconColor.withValues(alpha: 0.5),
            size: 24,
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                onTap != null
                    ? InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(8),
                        child: header,
                      )
                    : header,
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTravellersSection() {
    return _buildSection(
      title: 'Travellers',
      icon: Icons.people_rounded,
      iconColor: const Color(0xFF283593),
      onTap: () => context.push('/travelers/${widget.holidayId}'),
      children: _travelers
          .map(
            (t) => _SummaryCard(
              children: [
                _SummaryRow(label: 'Name', value: t.name),
                if (t.notes.isNotEmpty)
                  _SummaryRow(label: 'Notes', value: t.notes),
                ..._buildInlineDocuments(t.id),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildAccommodationSection() {
    return _buildSection(
      title: 'Accommodation',
      icon: Icons.hotel_rounded,
      iconColor: const Color(0xFF2E7D32),
      onTap: () => context.push('/accommodations/${widget.holidayId}'),
      children: _accommodations
          .map(
            (a) => _SummaryCard(
              children: [
                _SummaryRow(label: 'Name', value: a.name),
                if (a.address.isNotEmpty)
                  _SummaryRow(label: 'Address', value: a.address),
                if (a.checkIn.isNotEmpty || a.checkOut.isNotEmpty)
                  _SummaryRow(
                    label: 'Dates',
                    value:
                        '${formatDateUK(a.checkIn)} - ${formatDateUK(a.checkOut)}',
                  ),
                if (a.confirmationNumber.isNotEmpty)
                  _SummaryRow(
                    label: 'Confirmation',
                    value: a.confirmationNumber,
                  ),
                if (a.cost > 0)
                  _SummaryRow(label: 'Cost', value: formatGBP(a.cost)),
                if (a.depositPaid > 0)
                  _SummaryRow(
                    label: 'Deposit Paid',
                    value: formatGBP(a.depositPaid),
                  ),
                if (a.balanceDue > 0)
                  _SummaryRow(
                    label: 'Balance Due',
                    value: formatGBP(a.balanceDue),
                  ),
                if (a.balanceDueDate.isNotEmpty)
                  _SummaryRow(
                    label: 'Due Date',
                    value: formatDateUK(a.balanceDueDate),
                  ),
                if (a.balancePaidDate.isNotEmpty)
                  _SummaryRow(
                    label: 'Paid Date',
                    value: formatDateUK(a.balancePaidDate),
                  ),
                if (a.notes.isNotEmpty)
                  _SummaryRow(label: 'Notes', value: a.notes),
                ..._buildInlineDocuments(a.id),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildTravelSection() {
    return _buildSection(
      title: 'Travel',
      icon: Icons.flight_rounded,
      iconColor: const Color(0xFF1565C0),
      onTap: () => context.push('/travel/${widget.holidayId}'),
      children: _travelLegs.map((leg) {
        final typeLabel = leg.type.isNotEmpty
            ? '${leg.type[0].toUpperCase()}${leg.type.substring(1)}'
            : '';
        final modeLabel = leg.mode.isNotEmpty
            ? '${leg.mode[0].toUpperCase()}${leg.mode.substring(1)}'
            : '';

        return _SummaryCard(
          children: [
            _SummaryRow(
              label: 'Type',
              value: '$typeLabel${modeLabel.isNotEmpty ? ' ($modeLabel)' : ''}',
            ),
            if (leg.from.isNotEmpty || leg.to.isNotEmpty)
              _SummaryRow(label: 'Route', value: '${leg.from} -> ${leg.to}'),
            if (leg.departureDate.isNotEmpty)
              _SummaryRow(
                label: 'Depart',
                value:
                    '${formatDateUK(leg.departureDate)}${leg.departureTime.isNotEmpty ? ' ${leg.departureTime}' : ''}',
              ),
            if (leg.arrivalDate.isNotEmpty)
              _SummaryRow(
                label: 'Arrive',
                value:
                    '${formatDateUK(leg.arrivalDate)}${leg.arrivalTime.isNotEmpty ? ' ${leg.arrivalTime}' : ''}',
              ),
            if (leg.carrier.isNotEmpty)
              _SummaryRow(label: 'Carrier', value: leg.carrier),
            if (leg.bookingReference.isNotEmpty)
              _SummaryRow(label: 'Booking Ref', value: leg.bookingReference),
            if (leg.cost > 0)
              _SummaryRow(label: 'Cost', value: formatGBP(leg.cost)),
            if (leg.notes.isNotEmpty)
              _SummaryRow(label: 'Notes', value: leg.notes),
            ..._buildInlineDocuments(leg.id),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCarHireSection() {
    return _buildSection(
      title: 'Car Hire',
      icon: Icons.directions_car_rounded,
      iconColor: const Color(0xFFE65100),
      onTap: () => context.push('/car-hire/${widget.holidayId}'),
      children: _carHires
          .map(
            (c) => _SummaryCard(
              children: [
                if (c.company.isNotEmpty)
                  _SummaryRow(label: 'Company', value: c.company),
                if (c.pickupLocation.isNotEmpty || c.pickupDate.isNotEmpty)
                  _SummaryRow(
                    label: 'Pickup',
                    value:
                        '${c.pickupLocation}${c.pickupDate.isNotEmpty ? ' on ${formatDateUK(c.pickupDate)}' : ''}${c.pickupTime.isNotEmpty ? ' at ${c.pickupTime}' : ''}',
                  ),
                if (c.dropoffLocation.isNotEmpty || c.dropoffDate.isNotEmpty)
                  _SummaryRow(
                    label: 'Dropoff',
                    value:
                        '${c.dropoffLocation}${c.dropoffDate.isNotEmpty ? ' on ${formatDateUK(c.dropoffDate)}' : ''}${c.dropoffTime.isNotEmpty ? ' at ${c.dropoffTime}' : ''}',
                  ),
                if (c.drivers.isNotEmpty)
                  _SummaryRow(label: 'Drivers', value: c.drivers),
                if (c.bookingReference.isNotEmpty)
                  _SummaryRow(label: 'Booking Ref', value: c.bookingReference),
                if (c.deposit > 0)
                  _SummaryRow(label: 'Deposit', value: formatGBP(c.deposit)),
                if (c.totalCost > 0)
                  _SummaryRow(
                    label: 'Total Cost',
                    value: formatGBP(c.totalCost),
                  ),
                if (c.notes.isNotEmpty)
                  _SummaryRow(label: 'Notes', value: c.notes),
                ..._buildInlineDocuments(c.id),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildActivitiesSection() {
    return _buildSection(
      title: 'Activities',
      icon: Icons.local_activity_rounded,
      iconColor: const Color(0xFFC62828),
      onTap: () => context.push('/activities/${widget.holidayId}'),
      children: _activities
          .map(
            (a) => _SummaryCard(
              children: [
                _SummaryRow(label: 'Name', value: a.name),
                if (a.date.isNotEmpty)
                  _SummaryRow(
                    label: 'Date',
                    value:
                        '${formatDateUK(a.date)}${a.time.isNotEmpty ? ' at ${a.time}' : ''}',
                  ),
                if (a.location.isNotEmpty)
                  _SummaryRow(label: 'Location', value: a.location),
                if (a.bookingReference.isNotEmpty)
                  _SummaryRow(label: 'Booking Ref', value: a.bookingReference),
                if (a.cost > 0)
                  _SummaryRow(label: 'Cost', value: formatGBP(a.cost)),
                if (a.notes.isNotEmpty)
                  _SummaryRow(label: 'Notes', value: a.notes),
                ..._buildInlineDocuments(a.id),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildItinerarySection() {
    return _buildSection(
      title: 'Itinerary',
      icon: Icons.map_rounded,
      iconColor: const Color(0xFF00695C),
      onTap: () => context.push('/itinerary/${widget.holidayId}'),
      children: _itineraryDays
          .map(
            (day) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF00695C,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${day.dayNumber}',
                            style: AppTextStyles.bodyBold.copyWith(
                              color: const Color(0xFF00695C),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Day ${day.dayNumber}${day.title.isNotEmpty ? ' - ${day.title}' : ''}',
                          style: AppTextStyles.bodyBold,
                        ),
                      ),
                    ],
                  ),
                  if (day.date.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 42),
                      child: Text(
                        formatDateUK(day.date),
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                  if (day.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 42),
                      child: Text(
                        day.description,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  if (day.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 42),
                      child: Text(
                        day.notes,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  ..._buildInlineDocuments(day.id).map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(left: 42, right: 0),
                      child: w,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  List<Widget> _buildInlineDocuments(String parentId) {
    final docs = _documents.where((d) => d.parentId == parentId).toList();
    if (docs.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: docs.map((doc) {
                  final fileExists = DocumentService.fileExistsSync(doc.localPath);
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: fileExists
                        ? () => DocumentService.openFile(doc.localPath)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: fileExists
                            ? const Color(0xFFFFF3E0)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_file_rounded,
                            size: 12,
                            color: fileExists
                                ? const Color(0xFFE65100)
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              doc.filename,
                              style: AppTextStyles.caption.copyWith(
                                color: fileExists
                                    ? const Color(0xFFE65100)
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
        ),
      ),
    ];
  }

  String _parentTypeLabel(String parentType) {
    return switch (parentType) {
      'holiday' => 'Holiday',
      'accommodation' => 'Accommodation',
      'travelLeg' => 'Travel',
      'carHire' => 'Car Hire',
      'activity' => 'Activity',
      'traveler' => 'Traveller',
      'itineraryDay' => 'Itinerary',
      _ => parentType,
    };
  }

  String _resolveParentName(DocumentRef doc) {
    switch (doc.parentType) {
      case 'holiday':
        return _holiday?.name ?? 'Holiday';
      case 'accommodation':
        return _accommodations
                .where((a) => a.id == doc.parentId)
                .firstOrNull
                ?.name ??
            'Accommodation';
      case 'travelLeg':
        final leg =
            _travelLegs.where((l) => l.id == doc.parentId).firstOrNull;
        if (leg != null) return '${leg.from} \u2192 ${leg.to}';
        return 'Travel';
      case 'carHire':
        return _carHires
                .where((c) => c.id == doc.parentId)
                .firstOrNull
                ?.company ??
            'Car Hire';
      case 'activity':
        return _activities
                .where((a) => a.id == doc.parentId)
                .firstOrNull
                ?.name ??
            'Activity';
      case 'traveler':
        return _travelers
                .where((t) => t.id == doc.parentId)
                .firstOrNull
                ?.name ??
            'Traveller';
      case 'itineraryDay':
        final day =
            _itineraryDays.where((d) => d.id == doc.parentId).firstOrNull;
        if (day != null) return 'Day ${day.dayNumber}';
        return 'Itinerary';
      default:
        return doc.parentType;
    }
  }

  IconData _docIconForType(String fileType) {
    return switch (fileType) {
      'PDF' => Icons.picture_as_pdf_rounded,
      'Image' => Icons.image_rounded,
      'Document' => Icons.description_rounded,
      'Spreadsheet' => Icons.table_chart_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  Color _docColorForType(String fileType) {
    return switch (fileType) {
      'PDF' => const Color(0xFFE53935),
      'Image' => const Color(0xFF43A047),
      'Document' => const Color(0xFF1E88E5),
      'Spreadsheet' => const Color(0xFF2E7D32),
      _ => AppColors.textMuted,
    };
  }

  Widget _buildDocumentsSection() {
    // Group documents by parentType
    final grouped = <String, List<DocumentRef>>{};
    for (final doc in _documents) {
      grouped.putIfAbsent(doc.parentType, () => []).add(doc);
    }

    return _buildSection(
      title: 'Documents',
      icon: Icons.attach_file_rounded,
      iconColor: const Color(0xFF5D4037),
      onTap: () => context.push('/documents/holiday/${widget.holidayId}'),
      children: grouped.entries.map((entry) {
        final typeLabel = _parentTypeLabel(entry.key);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                typeLabel,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5D4037),
                  fontSize: 12,
                ),
              ),
            ),
            ...entry.value.map((doc) {
              final fileExists = DocumentService.fileExistsSync(doc.localPath);
              final parentName = _resolveParentName(doc);
              final color = _docColorForType(doc.fileType);

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: fileExists
                      ? () => DocumentService.openFile(doc.localPath)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: (fileExists ? color : AppColors.textMuted)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _docIconForType(doc.fileType),
                            color:
                                fileExists ? color : AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.filename,
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 13,
                                  color: fileExists
                                      ? null
                                      : AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                parentName,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (fileExists)
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          )
                        else
                          Text(
                            'Missing',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFinancialSection() {
    final costs = <String, double>{};

    double accomTotal = 0;
    for (final a in _accommodations) {
      accomTotal += a.cost;
    }
    if (accomTotal > 0) costs['Accommodation'] = accomTotal;

    double travelTotal = 0;
    for (final l in _travelLegs) {
      travelTotal += l.cost;
    }
    if (travelTotal > 0) costs['Travel'] = travelTotal;

    double carTotal = 0;
    for (final c in _carHires) {
      carTotal += c.totalCost;
    }
    if (carTotal > 0) costs['Car Hire'] = carTotal;

    double activityTotal = 0;
    for (final a in _activities) {
      activityTotal += a.cost;
    }
    if (activityTotal > 0) costs['Activities'] = activityTotal;

    if (costs.isEmpty) return const SizedBox.shrink();

    double grandTotal = 0;
    for (final v in costs.values) {
      grandTotal += v;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: 'Financial Summary',
          icon: Icons.account_balance_rounded,
          iconColor: AppColors.primary,
          children: [
            ...costs.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: AppTextStyles.body),
                    Text(formatGBP(entry.value), style: AppTextStyles.bodyBold),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: AppTextStyles.subheading.copyWith(fontSize: 16),
                ),
                Text(
                  formatGBP(grandTotal),
                  style: AppTextStyles.subheading.copyWith(
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// --- Reusable summary widgets ---

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
