extension DateTimeX on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool isWithinMinutes(int minutes) {
    return DateTime.now().difference(this).inMinutes < minutes;
  }

  bool isWithinHours(int hours) {
    return DateTime.now().difference(this).inHours < hours;
  }

  String toAge() {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return '$age years';
  }
}
