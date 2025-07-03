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
    return  appointments![index].concreteDateTime;
  }

  @override
  DateTime getEndTime(int index) {
    // Thời lượng mặc định là 1 tiếng (hoặc 59m59s để tránh lỗi render)
    return appointments![index].concreteDateTime.add(const Duration(minutes: 59, seconds: 59));
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
