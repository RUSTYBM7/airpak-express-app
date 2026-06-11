import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static String date(DateTime? dt, {String pattern = 'MMM d, yyyy'}) {
    if (dt == null) return '—';
    return DateFormat(pattern).format(dt);
  }

  static String dateTime(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  static String currency(num amount, {String code = 'USD'}) {
    return NumberFormat.simpleCurrency(name: code).format(amount);
  }

  static String timeAgo(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) {
      return DateFormat('MMM d').format(dt);
    }
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
