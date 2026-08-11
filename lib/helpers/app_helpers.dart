String formatDateForAPI(String date) {
  try {
    final parts = date.split('/');
    if (parts.length == 3) {
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year = parts[2];
      return '$year-$month-$day';
    }
    return date;
  } catch (_) {
    return date;
  }
}

String formatDateForDisplay(String date) {
  try {
    final parts = date.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return date;
  } catch (_) {
    return date;
  }
}

String formatDate(DateTime date) {
  final months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
