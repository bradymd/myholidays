import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_holidays/providers/database_provider.dart';
import 'package:my_holidays/providers/holiday_provider.dart';
import 'package:my_holidays/utils/date_helpers.dart';

enum AlertLevel { info, upcoming, urgent }

class HolidayAlert {
  final String holidayName;
  final String label;
  final String date;
  final int daysRemaining;
  final AlertLevel level;

  const HolidayAlert({
    required this.holidayName,
    required this.label,
    required this.date,
    required this.daysRemaining,
    required this.level,
  });
}

final alertsProvider =
    AsyncNotifierProvider<AlertsNotifier, List<HolidayAlert>>(
        AlertsNotifier.new);

class AlertsNotifier extends AsyncNotifier<List<HolidayAlert>> {
  @override
  Future<List<HolidayAlert>> build() async {
    final holidays = await ref.watch(holidaysProvider.future);
    final alerts = <HolidayAlert>[];
    final db = ref.read(databaseProvider);

    for (final h in holidays) {
      // Upcoming trip alerts
      if (h.startDate.isNotEmpty) {
        final days = daysUntil(h.startDate);
        if (days >= 0 && days <= 30) {
          alerts.add(HolidayAlert(
            holidayName: h.name,
            label: 'Trip starts',
            date: h.startDate,
            daysRemaining: days,
            level: days <= 7 ? AlertLevel.urgent : AlertLevel.upcoming,
          ));
        }
      }

      // Balance due date alerts
      final accommodations = await db.getAccommodations(h.id);
      for (final a in accommodations) {
        if (a.balanceDueDate.isNotEmpty && a.balancePaidDate.isEmpty) {
          final days = daysUntil(a.balanceDueDate);
          if (days >= 0 && days <= 30) {
            alerts.add(HolidayAlert(
              holidayName: h.name,
              label: '${a.name} balance due',
              date: a.balanceDueDate,
              daysRemaining: days,
              level: days <= 7 ? AlertLevel.urgent : AlertLevel.upcoming,
            ));
          }
        }
      }
    }

    // Sort by urgency (fewest days first)
    alerts.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return alerts;
  }
}
