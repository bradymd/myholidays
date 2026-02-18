import 'package:intl/intl.dart';

bool isPastDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return false;
  final date = DateTime.tryParse(dateStr);
  if (date == null) return false;
  return date.isBefore(DateTime.now());
}

bool isDueSoon(String? dateStr, {int days = 30}) {
  if (dateStr == null || dateStr.isEmpty) return false;
  final date = DateTime.tryParse(dateStr);
  if (date == null) return false;
  final now = DateTime.now();
  return date.isAfter(now) &&
      date.isBefore(now.add(Duration(days: days)));
}

int daysUntil(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return -1;
  final date = DateTime.tryParse(dateStr);
  if (date == null) return -1;
  return date.difference(DateTime.now()).inDays;
}

String formatDateUK(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'Not set';
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatDateRelative(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'Not set';
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  final days = date.difference(DateTime.now()).inDays;
  if (days < 0) return '${-days} days ago';
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days < 30) return 'In $days days';
  if (days < 365) return 'In ${(days / 30).round()} months';
  return 'In ${(days / 365).round()} years';
}

String formatDateLong(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'Not set';
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  return DateFormat('d MMMM yyyy').format(date);
}

String formatTimeUK(String? timeStr) {
  if (timeStr == null || timeStr.isEmpty) return '';
  return timeStr;
}

String todayAsString() => DateFormat('yyyy-MM-dd').format(DateTime.now());
