import 'package:aves/utils/constants.dart';
import 'package:intl/intl.dart';

/// returns a string representation of the date in a specific locale,
///
/// for example if you call `formatDay(DateTime(2022, 12, 25, 21, 58, 0), 'en_US')`
///
/// the output will be "Dec 25, 2022"
String formatDay(DateTime date, String locale) => DateFormat.yMMMd(locale).format(date);

/// returns a string representation of the date in a specific locale,
///
/// for example if you call `formatDay(DateTime(2022, 12, 25, 21, 58, 0), 'en_US')`
///
/// the output will be "Dec 25, 2022"
String formatTime(DateTime date, String locale, bool use24hour) => (use24hour ? DateFormat.Hm(locale) : DateFormat.jm(locale)).format(date);

///  formats the date and time input (DateTime) to a string, join the output of formatDay and formatTime with Constants.separator
String formatDateTime(DateTime date, String locale, bool use24hour) => [
      formatDay(date, locale),
      formatTime(date, locale, use24hour),
    ].join(Constants.separator);

/// returns a string representation of the duration in hours, minutes and seconds,
///
/// for example if you call `formatFriendlyDuration(Duration(hours: 1, minutes: 20, seconds: 30))`
///
/// the output will be "1:20:30"
String formatFriendlyDuration(Duration d) {
  final seconds = (d.inSeconds.remainder(Duration.secondsPerMinute)).toString().padLeft(2, '0');
  if (d.inHours == 0) return '${d.inMinutes}:$seconds';

  final minutes = (d.inMinutes.remainder(Duration.minutesPerHour)).toString().padLeft(2, '0');
  return '${d.inHours}:$minutes:$seconds';
}

/// returns a string representation of the duration in hours, minutes, seconds and milliseconds,
///
/// for example if you call  `formatPreciseDuration(Duration(hours: 1, minutes: 20, seconds: 30, milliseconds: 500))`
///
/// the output will be "01:20:30.500"
String formatPreciseDuration(Duration d) {
  final millis = ((d.inMicroseconds / 1000.0).round() % 1000).toString().padLeft(3, '0');
  final seconds = (d.inSeconds.remainder(Duration.secondsPerMinute)).toString().padLeft(2, '0');
  final minutes = (d.inMinutes.remainder(Duration.minutesPerHour)).toString().padLeft(2, '0');
  final hours = (d.inHours).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds.$millis';
}
