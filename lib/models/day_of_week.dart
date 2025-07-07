enum DayOfWeek { mon, tues, wed, thus, fri, sat, sun }

extension DayOfWeekExtension on DayOfWeek {
  // Hàm để lấy tên hiển thị tiếng Việt
  String get vietnameseName {
    switch (this) {
      case DayOfWeek.mon:
        return 'T2';
      case DayOfWeek.tues:
        return 'T3';
      case DayOfWeek.wed:
        return 'T4';
      case DayOfWeek.thus:
        return 'T5';
      case DayOfWeek.fri:
        return 'T6';
      case DayOfWeek.sat:
        return 'T7';
      case DayOfWeek.sun:
        return 'CN';
    }
  }
  // Hàm để lấy giá trị số tương ứng với DateTime.weekday (Thứ 2 = 1, ..., Chủ Nhật = 7)
  int get asWeekday {
    return index + 1;
  }
}
