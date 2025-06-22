final DateTime kStartDate = DateTime.utc(2000, 1, 1);
final DateTime kEndDate = DateTime.utc(2030, 12, 31);


String capitalizeFirstLetter(String text) {
  if (text.isEmpty) {
    return text;
  }
  return text[0].toUpperCase() + text.substring(1);
}