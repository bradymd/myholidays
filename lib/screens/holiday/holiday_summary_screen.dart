import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:my_holidays/models/accommodation.dart';
import 'package:my_holidays/models/activity.dart';
import 'package:my_holidays/models/car_hire.dart';
import 'package:my_holidays/models/holiday_plan.dart';
import 'package:my_holidays/models/itinerary_day.dart';
import 'package:my_holidays/models/travel_leg.dart';
import 'package:my_holidays/models/traveler.dart';
import 'package:my_holidays/providers/accommodation_provider.dart';
import 'package:my_holidays/providers/activity_provider.dart';
import 'package:my_holidays/providers/car_hire_provider.dart';
import 'package:my_holidays/providers/holiday_provider.dart';
import 'package:my_holidays/providers/itinerary_provider.dart';
import 'package:my_holidays/providers/travel_provider.dart';
import 'package:my_holidays/providers/traveler_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/currency_helpers.dart';
import 'package:my_holidays/utils/date_helpers.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';

class HolidaySummaryScreen extends ConsumerStatefulWidget {
  const HolidaySummaryScreen({super.key, required this.holidayId});

  final String holidayId;

  @override
  ConsumerState<HolidaySummaryScreen> createState() =>
      _HolidaySummaryScreenState();
}

class _HolidaySummaryScreenState extends ConsumerState<HolidaySummaryScreen> {
  bool _loading = true;

  HolidayPlan? _holiday;
  List<Traveler> _travelers = [];
  List<Accommodation> _accommodations = [];
  List<TravelLeg> _travelLegs = [];
  List<CarHire> _carHires = [];
  List<Activity> _activities = [];
  List<ItineraryDay> _itineraryDays = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final holidays = await ref.read(holidaysProvider.future);
    final holiday =
        holidays.where((h) => h.id == widget.holidayId).firstOrNull;

    final travelers =
        await ref.read(travelersProvider(widget.holidayId).future);
    final accommodations =
        await ref.read(accommodationsProvider(widget.holidayId).future);
    final travelLegs =
        await ref.read(travelLegsProvider(widget.holidayId).future);
    final carHires =
        await ref.read(carHiresProvider(widget.holidayId).future);
    final activities =
        await ref.read(activitiesProvider(widget.holidayId).future);
    final itineraryDays =
        await ref.read(itineraryDaysProvider(widget.holidayId).future);

    if (mounted) {
      setState(() {
        _holiday = holiday;
        _travelers = travelers;
        _accommodations = accommodations;
        _travelLegs = travelLegs;
        _carHires = carHires;
        _activities = activities;
        _itineraryDays = List<ItineraryDay>.from(itineraryDays)
          ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
        _loading = false;
      });
    }
  }

  // --- Build the plain-text summary ---

  String _buildSummaryText() {
    final buf = StringBuffer();
    final h = _holiday;
    if (h == null) return 'Holiday not found.';

    // Header
    buf.writeln('='.padRight(50, '='));
    buf.writeln(h.name.toUpperCase());
    buf.writeln('='.padRight(50, '='));
    buf.writeln();

    if (h.startDate.isNotEmpty || h.endDate.isNotEmpty) {
      buf.writeln(
          'Dates: ${formatDateUK(h.startDate)} - ${formatDateUK(h.endDate)}');
      buf.writeln();
    }

    // Travellers
    if (_travelers.isNotEmpty) {
      buf.writeln('TRAVELLERS');
      buf.writeln('-'.padRight(30, '-'));
      for (final t in _travelers) {
        buf.writeln('  - ${t.name}');
      }
      buf.writeln();
    }

    // Accommodation
    if (_accommodations.isNotEmpty) {
      buf.writeln('ACCOMMODATION');
      buf.writeln('-'.padRight(30, '-'));
      for (final a in _accommodations) {
        buf.writeln('  ${a.name}');
        if (a.address.isNotEmpty) buf.writeln('  Address: ${a.address}');
        if (a.checkIn.isNotEmpty || a.checkOut.isNotEmpty) {
          buf.writeln(
              '  Dates: ${formatDateUK(a.checkIn)} - ${formatDateUK(a.checkOut)}');
        }
        if (a.confirmationNumber.isNotEmpty) {
          buf.writeln('  Confirmation: ${a.confirmationNumber}');
        }
        if (a.cost > 0) buf.writeln('  Cost: ${formatGBP(a.cost)}');
        buf.writeln();
      }
    }

    // Travel
    if (_travelLegs.isNotEmpty) {
      buf.writeln('TRAVEL');
      buf.writeln('-'.padRight(30, '-'));
      for (final leg in _travelLegs) {
        final typeLabel = leg.type.isNotEmpty
            ? '${leg.type[0].toUpperCase()}${leg.type.substring(1)}'
            : '';
        final modeLabel = leg.mode.isNotEmpty
            ? '${leg.mode[0].toUpperCase()}${leg.mode.substring(1)}'
            : '';
        buf.writeln(
            '  $typeLabel${modeLabel.isNotEmpty ? ' ($modeLabel)' : ''}');
        if (leg.from.isNotEmpty || leg.to.isNotEmpty) {
          buf.writeln('  ${leg.from} -> ${leg.to}');
        }
        if (leg.departureDate.isNotEmpty) {
          buf.write('  Depart: ${formatDateUK(leg.departureDate)}');
          if (leg.departureTime.isNotEmpty) {
            buf.write(' ${leg.departureTime}');
          }
          buf.writeln();
        }
        if (leg.arrivalDate.isNotEmpty) {
          buf.write('  Arrive: ${formatDateUK(leg.arrivalDate)}');
          if (leg.arrivalTime.isNotEmpty) buf.write(' ${leg.arrivalTime}');
          buf.writeln();
        }
        if (leg.carrier.isNotEmpty) buf.writeln('  Carrier: ${leg.carrier}');
        if (leg.bookingReference.isNotEmpty) {
          buf.writeln('  Booking Ref: ${leg.bookingReference}');
        }
        if (leg.cost > 0) buf.writeln('  Cost: ${formatGBP(leg.cost)}');
        buf.writeln();
      }
    }

    // Car Hire
    if (_carHires.isNotEmpty) {
      buf.writeln('CAR HIRE');
      buf.writeln('-'.padRight(30, '-'));
      for (final c in _carHires) {
        if (c.company.isNotEmpty) buf.writeln('  Company: ${c.company}');
        if (c.pickupLocation.isNotEmpty || c.pickupDate.isNotEmpty) {
          buf.write('  Pickup: ${c.pickupLocation}');
          if (c.pickupDate.isNotEmpty) {
            buf.write(' on ${formatDateUK(c.pickupDate)}');
          }
          if (c.pickupTime.isNotEmpty) buf.write(' at ${c.pickupTime}');
          buf.writeln();
        }
        if (c.dropoffLocation.isNotEmpty || c.dropoffDate.isNotEmpty) {
          buf.write('  Dropoff: ${c.dropoffLocation}');
          if (c.dropoffDate.isNotEmpty) {
            buf.write(' on ${formatDateUK(c.dropoffDate)}');
          }
          if (c.dropoffTime.isNotEmpty) buf.write(' at ${c.dropoffTime}');
          buf.writeln();
        }
        if (c.bookingReference.isNotEmpty) {
          buf.writeln('  Booking Ref: ${c.bookingReference}');
        }
        if (c.totalCost > 0) {
          buf.writeln('  Cost: ${formatGBP(c.totalCost)}');
        }
        buf.writeln();
      }
    }

    // Activities
    if (_activities.isNotEmpty) {
      buf.writeln('ACTIVITIES');
      buf.writeln('-'.padRight(30, '-'));
      for (final a in _activities) {
        buf.writeln('  ${a.name}');
        if (a.date.isNotEmpty) {
          buf.write('  Date: ${formatDateUK(a.date)}');
          if (a.time.isNotEmpty) buf.write(' at ${a.time}');
          buf.writeln();
        }
        if (a.location.isNotEmpty) buf.writeln('  Location: ${a.location}');
        if (a.bookingReference.isNotEmpty) {
          buf.writeln('  Booking Ref: ${a.bookingReference}');
        }
        if (a.cost > 0) buf.writeln('  Cost: ${formatGBP(a.cost)}');
        buf.writeln();
      }
    }

    // Itinerary
    if (_itineraryDays.isNotEmpty) {
      buf.writeln('ITINERARY');
      buf.writeln('-'.padRight(30, '-'));
      for (final day in _itineraryDays) {
        buf.writeln(
            '  Day ${day.dayNumber}${day.title.isNotEmpty ? ' - ${day.title}' : ''}');
        if (day.date.isNotEmpty) {
          buf.writeln('  ${formatDateUK(day.date)}');
        }
        if (day.description.isNotEmpty) {
          buf.writeln('  ${day.description}');
        }
        buf.writeln();
      }
    }

    // Financial summary
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
      buf.writeln('FINANCIAL SUMMARY');
      buf.writeln('-'.padRight(30, '-'));
      double grandTotal = 0;
      for (final entry in costs.entries) {
        buf.writeln('  ${entry.key}: ${formatGBP(entry.value)}');
        grandTotal += entry.value;
      }
      buf.writeln('  ${'=' * 25}');
      buf.writeln('  TOTAL: ${formatGBP(grandTotal)}');
      buf.writeln();
    }

    return buf.toString();
  }

  void _shareSummary() {
    final text = _buildSummaryText();
    Share.share(text);
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBackButton: true,
      title: 'Trip Summary',
      actions: [
        if (!_loading)
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareSummary,
            tooltip: 'Share Summary',
          ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _holiday == null
              ? Center(
                  child: Text('Holiday not found.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      if (_travelers.isNotEmpty) _buildTravellersSection(),
                      if (_accommodations.isNotEmpty)
                        _buildAccommodationSection(),
                      if (_travelLegs.isNotEmpty) _buildTravelSection(),
                      if (_carHires.isNotEmpty) _buildCarHireSection(),
                      if (_activities.isNotEmpty) _buildActivitiesSection(),
                      if (_itineraryDays.isNotEmpty)
                        _buildItinerarySection(),
                      _buildFinancialSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final h = _holiday!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.softPurple, AppColors.softPink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h.name,
                style: AppTextStyles.heading.copyWith(fontSize: 22)),
            if (h.startDate.isNotEmpty || h.endDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${formatDateUK(h.startDate)} - ${formatDateUK(h.endDate)}',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.subheading.copyWith(fontSize: 17)),
        ],
      ),
    );
  }

  Widget _buildTravellersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Travellers', Icons.people_rounded),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _travelers
              .map((t) => Chip(
                    avatar: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    label: Text(t.name, style: AppTextStyles.body),
                    backgroundColor: AppColors.softLilac,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAccommodationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Accommodation', Icons.hotel_rounded),
        ..._accommodations.map((a) => _SummaryCard(
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
                      label: 'Confirmation', value: a.confirmationNumber),
                if (a.cost > 0)
                  _SummaryRow(label: 'Cost', value: formatGBP(a.cost)),
              ],
            )),
      ],
    );
  }

  Widget _buildTravelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Travel', Icons.flight_rounded),
        ..._travelLegs.map((leg) {
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
                  value:
                      '$typeLabel${modeLabel.isNotEmpty ? ' ($modeLabel)' : ''}'),
              if (leg.from.isNotEmpty || leg.to.isNotEmpty)
                _SummaryRow(
                    label: 'Route', value: '${leg.from} -> ${leg.to}'),
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
                _SummaryRow(
                    label: 'Booking Ref', value: leg.bookingReference),
              if (leg.cost > 0)
                _SummaryRow(label: 'Cost', value: formatGBP(leg.cost)),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCarHireSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Car Hire', Icons.directions_car_rounded),
        ..._carHires.map((c) => _SummaryCard(
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
                if (c.bookingReference.isNotEmpty)
                  _SummaryRow(
                      label: 'Booking Ref', value: c.bookingReference),
                if (c.totalCost > 0)
                  _SummaryRow(
                      label: 'Cost', value: formatGBP(c.totalCost)),
              ],
            )),
      ],
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Activities', Icons.local_activity_rounded),
        ..._activities.map((a) => _SummaryCard(
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
                  _SummaryRow(
                      label: 'Booking Ref', value: a.bookingReference),
                if (a.cost > 0)
                  _SummaryRow(label: 'Cost', value: formatGBP(a.cost)),
              ],
            )),
      ],
    );
  }

  Widget _buildItinerarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Itinerary', Icons.map_rounded),
        ..._itineraryDays.map((day) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${day.dayNumber}',
                              style: AppTextStyles.bodyBold
                                  .copyWith(color: Colors.white, fontSize: 13),
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
                        child: Text(formatDateUK(day.date),
                            style: AppTextStyles.caption),
                      ),
                    ],
                    if (day.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 42),
                        child: Text(day.description,
                            style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ],
                ),
              ),
            )),
      ],
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
        _buildSectionTitle('Financial Summary', Icons.account_balance_rounded),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          shadowColor: AppColors.cardShadow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...costs.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: AppTextStyles.body),
                          Text(formatGBP(entry.value),
                              style: AppTextStyles.bodyBold),
                        ],
                      ),
                    )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL',
                        style: AppTextStyles.subheading
                            .copyWith(fontSize: 16)),
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
          ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
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
            child: Text('$label:',
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.body.copyWith(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
