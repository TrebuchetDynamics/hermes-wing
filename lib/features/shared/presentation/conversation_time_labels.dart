import 'package:intl/intl.dart';

String conversationLatestTimeLabel(DateTime? latestAt, {DateTime? now}) {
  if (latestAt == null) return '';
  final comparisonNow = now ?? DateTime.now();
  final latestDay = conversationDay(latestAt);
  final today = conversationDay(comparisonNow);
  if (latestDay == today) return DateFormat.Hm().format(latestAt);
  if (latestAt.year == comparisonNow.year) {
    return DateFormat.MMMd().format(latestAt);
  }
  return DateFormat.yMd().format(latestAt);
}

String conversationDateSeparatorLabel(DateTime date, DateTime now) {
  final localDate = conversationDay(date);
  final localNow = conversationDay(now);
  final yesterday = localNow.subtract(const Duration(days: 1));
  if (localDate == localNow) return 'Today';
  if (localDate == yesterday) return 'Yesterday';
  return DateFormat.MMMd().format(date);
}

String conversationMessageTimeLabel(DateTime createdAt) =>
    DateFormat.Hm().format(createdAt);

DateTime conversationDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isSameConversationDay(DateTime a, DateTime b) =>
    conversationDay(a) == conversationDay(b);
