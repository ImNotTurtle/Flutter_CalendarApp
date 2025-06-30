import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimezoneManager {
  /// Trả về thời gian hiện tại, luôn ở dạng UTC.
  DateTime get nowUtc => DateTime.now().toUtc();

  /// Chuyển đổi một DateTime bất kỳ (thường là giờ địa phương) sang UTC.
  /// Dùng khi lưu dữ liệu vào database.
  DateTime toUtc(DateTime localTime) {
    return localTime.toUtc();
  }

  /// Chuyển đổi một DateTime UTC (thường lấy từ database) sang giờ địa phương.
  /// Dùng khi hiển thị dữ liệu lên UI.
  DateTime toLocal(DateTime utcTime) {
    return utcTime.toLocal();
  }

  /// Chuẩn hóa một DateTime bất kỳ về 0h:00 sáng, ở múi giờ UTC.
  /// Rất quan trọng cho việc so sánh các ngày với nhau.
  DateTime normalizeToUtc(DateTime anyTime) {
    final utcTime = anyTime.toUtc();
    return DateTime.utc(utcTime.year, utcTime.month, utcTime.day);
  }
}

// Provider để có thể truy cập TimezoneManager từ bất kỳ đâu
final timezoneManagerProvider = Provider((ref) => TimezoneManager());