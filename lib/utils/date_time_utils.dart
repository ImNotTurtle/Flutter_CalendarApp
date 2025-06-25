// Đổi tên extension cho tổng quát hơn
extension DateTimeUtilsExtension on DateTime {
  
  /// Trả về một DateTime mới với cùng ngày, tháng, năm nhưng giờ, phút, giây... bằng 0.
  DateTime get normalized {
    return DateTime(year, month, day);
  }

  // <<< TÍNH NĂNG MỚI: Phương thức extension để so sánh tháng và năm >>>
  bool isSameMonth(DateTime? other) {
    // Nếu đối tượng so sánh là null, chúng không thể giống nhau
    if (other == null) {
      return false;
    }
    // So sánh năm và tháng của đối tượng hiện tại (`this`) với `other`
    return year == other.year && month == other.month;
  }
}