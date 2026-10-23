import 'package:intl/intl.dart';

final _kes = NumberFormat.decimalPattern('en_KE');
final _date = DateFormat('d MMM yyyy');

/// Amounts are whole shillings, as stored by the backend.
String formatKes(num amount) => 'KES ${_kes.format(amount)}';

String formatDate(DateTime date) => _date.format(date);

/// "just now", "5 min ago", "3 h ago", "yesterday", "12 Oct 2026".
String formatRelative(DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'yesterday';
  return _date.format(then);
}
