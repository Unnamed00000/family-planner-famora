/// Returns the ISO-8601 week number for a calendar date.
///
/// The calculation deliberately uses UTC calendar dates. This prevents a
/// daylight-saving offset in the browser or on iPhone from moving a date into
/// the preceding week.
int isoWeekNumber(DateTime date) {
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  final thursday = utcDate.add(Duration(days: DateTime.thursday - utcDate.weekday));
  final yearStart = DateTime.utc(thursday.year, 1, 1);
  return (thursday.difference(yearStart).inDays ~/ 7) + 1;
}
