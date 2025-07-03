import 'package:calendar_app/models/day_of_week.dart';
import 'package:calendar_app/models/recurring_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:calendar_app/models/todo_instance.dart';
import 'package:calendar_app/providers/todo_provider.dart';
import 'package:calendar_app/utils/date_time_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- CÁC PROVIDER ĐIỀU KHIỂN GIAO DIỆN LỊCH ---

// Quản lý khoảng ngày được chọn trên lịch tháng
final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// Quản lý ngày đang được hiển thị trên lịch tuần/ngày
final displayedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Provider để quản lý ngày bắt đầu của trang đang xem
// trên ScheduleViewWidget. Nó có thể null nếu không có gì được chọn.
final schedulePageDateProvider = StateProvider<DateTime?>((ref) => null);

// --- PROVIDER TÍNH TOÁN DỮ LIỆU ĐỂ HIỂN THỊ ---

final visibleInstancesProvider = Provider<List<TodoInstance>>((ref) {
  final asyncTodos = ref.watch(todosProvider);//Theo dõi sự cập nhật của tất cả todo

  if (asyncTodos.value == null) {
    return [];
  }
  final allTodoRules = asyncTodos.value!;
  //Theo dõi sự thay đổi khi người dùng thay đổi khoảng thời gian trên lịch
  final selectedRange = ref.watch(selectedDateRangeProvider);

  final DateTimeRange rangeToFilter;
  if (selectedRange == null) {
    final today = DateTime.now().normalized; 
    rangeToFilter = DateTimeRange(start: today, end: today);
  } else {
    rangeToFilter = selectedRange;
  }
  
  // Chuẩn hoá thời gian, loại bỏ giờ và phút
  final rangeStart = rangeToFilter.start.normalized;
  final rangeEnd = rangeToFilter.end.normalized;
  final endBoundary = rangeEnd.add(const Duration(days: 1));

  final List<TodoInstance> instances = [];
  for (final todoRule in allTodoRules) {
    if (todoRule is SingleTodo) {
      // Chuẩn hóa ngày của todo để so sánh
      final todoDate = todoRule.dateTime.toLocal().normalized;

      if (!todoDate.isBefore(rangeStart) && todoDate.isBefore(endBoundary)) {
        instances.add(TodoInstance.fromTodo(todoRule, todoRule.dateTime));
      }
    } else if (todoRule is RecurringTodoRule) {
      for (var day = rangeStart; day.isBefore(endBoundary); day = day.add(const Duration(days: 1))) {
        if (todoRule.daysOfWeek.any((d) => d.asWeekday == day.weekday)) {
          instances.add(TodoInstance.fromTodo(todoRule, day));
        }
      }
    }
  }

  instances.sort((a, b) => a.concreteDateTime.compareTo(b.concreteDateTime));
  return instances;
});
