import 'package:intl/intl.dart';

String conversationLatestTimeLabel(DateTime? latestAt, {DateTime? now}) {
  if (latestAt == null) return '';
  final comparisonNow = now ?? DateTime.now();
  final latestDay = DateTime(latestAt.year, latestAt.month, latestAt.day);
  final today = DateTime(
    comparisonNow.year,
    comparisonNow.month,
    comparisonNow.day,
  );
  if (latestDay == today) return DateFormat.Hm().format(latestAt);
  if (latestAt.year == comparisonNow.year) {
    return DateFormat.MMMd().format(latestAt);
  }
  return DateFormat.yMd().format(latestAt);
}

String conversationDateSeparatorLabel(DateTime date, DateTime now) {
  final localDate = DateTime(date.year, date.month, date.day);
  final localNow = DateTime(now.year, now.month, now.day);
  final yesterday = localNow.subtract(const Duration(days: 1));
  if (localDate == localNow) return 'Today';
  if (localDate == yesterday) return 'Yesterday';
  return DateFormat.MMMd().format(date);
}
