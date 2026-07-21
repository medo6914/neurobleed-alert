import 'package:intl/intl.dart';

class Formatters {
  static String date(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String time(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  static String dateTimeWithSeconds(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm:ss').format(date);
  }

  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return dateTime(date);
  }

  static String heartRate(double hr) => '${hr.toInt()} bpm';
  static String oxygenSaturation(double spo2) => '${spo2.toInt()}%';
  static String bloodPressure(double systolic, double diastolic) =>
      '${systolic.toInt()}/${diastolic.toInt()} mmHg';
  static String temperature(double temp) => '${temp.toStringAsFixed(1)}°C';
  static String respiratoryRate(double rr) => '${rr.toInt()} /min';
  static String icp(double value) => '${value.toInt()} mmHg';
  static String cpp(double value) => '${value.toInt()} mmHg';
  static String riskScore(double score) =>
      '${(score * 100).toStringAsFixed(1)}%';
  static String battery(double level) => '${level.toInt()}%';

  static String mrn(String mrn) => 'MRN: $mrn';

  static String phone(String phone) {
    if (phone.length >= 10) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6)}';
    }
    return phone;
  }

  static String gender(String gender) =>
      gender == 'male' ? 'Male' : 'Female';

  static String bloodType(String type) {
    final map = {
      'aPositive': 'A+',
      'aNegative': 'A-',
      'bPositive': 'B+',
      'bNegative': 'B-',
      'oPositive': 'O+',
      'oNegative': 'O-',
      'abPositive': 'AB+',
      'abNegative': 'AB-',
    };
    return map[type] ?? type;
  }
}
