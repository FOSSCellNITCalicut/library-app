const Map<int, String> _ddcRanges = {
  0: 'Computer Science',
  100: 'Philosophy & Psychology',
  200: 'Religion',
  300: 'Social Sciences',
  400: 'Language',
  500: 'Sciences & Mathematics',
  600: 'Technology & Engineering',
  700: 'Arts & Recreation',
  800: 'Literature',
  900: 'History & Geography',
};

String? getBookTypeFromCallNumber(String? callNumber) {
  if (callNumber == null || callNumber.isEmpty) return null;
  final match = RegExp(r'^(\d{3})').firstMatch(callNumber.trim());
  if (match == null) return null;
  final prefix = int.parse(match.group(1)!);
  final base = (prefix ~/ 100) * 100;
  return _ddcRanges[base];
}
