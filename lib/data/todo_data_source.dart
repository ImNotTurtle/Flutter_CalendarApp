import 'package:calendar_app/models/todo_instance.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class TodoDataSource extends CalendarDataSource {
  // Constructor nhận vào danh sách các TodoInstance
  TodoDataSource(List<TodoInstance> source) {
    appointments = source;
  }

  // --- Override các phương thức để mapping dữ liệu ---

  @override
  DateTime getStartTime(int index) {
    // Lấy thời gian bắt đầu của sự kiện
    return appointments![index].concreteDateTime;
  }

  @override
  DateTime getEndTime(int index) {
    // Model chưa có 'thời lượng', nên ta mặc định mỗi todo kéo dài 1 tiếng 
    // (chỉ thêm 59 phút 59 giây để tránh edge case khi todo diễn ra vào lúc 23h và kết thúc vào đúng 24h)
    return appointments![index].concreteDateTime.add(
      const Duration(minutes: 59, seconds: 59),
    );
  }

  @override
  String getSubject(int index) {
    // Lấy tiêu đề của sự kiện
    return appointments![index].title;
  }

  @override
  Color getColor(int index) {
    // Tô màu khác nhau cho sự kiện lặp lại và sự kiện đơn lẻ
    return appointments![index].isRecurring ? Colors.deepPurple : Colors.teal;
  }

  @override
  bool isAllDay(int index) {
    return false;
  }
}
