import 'dart:async';
import 'package:calendar_app/models/day_of_week.dart';
import 'package:calendar_app/models/recurring_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:calendar_app/providers/todo_provider.dart';
import 'package:calendar_app/utils/date_time_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo_instance.dart';
import 'calendar_provider.dart';

// Một class đơn giản để chứa thông tin cho status bar
class NextNotificationInfo {
  final List<TodoInstance> upcomingInstances;
  final DateTime? nextNotificationTime;

  NextNotificationInfo({
    required this.upcomingInstances,
    this.nextNotificationTime,
  });
}

// Provider chính để tính toán thông tin
final nextNotificationProvider = Provider<NextNotificationInfo>((ref) {
  // Lắng nghe danh sách tất cả các instance đã được tính toán
  final allInstances = ref.watch(allInstancesProvider);
  final now = DateTime.now();

  // Lọc ra các instance sẽ diễn ra trong tương lai
  final upcoming = allInstances
      .where((instance) => instance.concreteDateTime.isAfter(now))
      .toList();

  // Nếu không có gì sắp tới, trả về thông tin rỗng
  if (upcoming.isEmpty) {
    return NextNotificationInfo(upcomingInstances: []);
  }

  // Sắp xếp để tìm ra instance sớm nhất
  upcoming.sort((a, b) => a.concreteDateTime.compareTo(b.concreteDateTime));

  final nextTime = upcoming.first.concreteDateTime;

  // Lấy tất cả các instance diễn ra cùng lúc với instance sớm nhất
  final nextInstances =
      upcoming.where((i) => i.concreteDateTime == nextTime).toList();

  return NextNotificationInfo(
    upcomingInstances: nextInstances,
    nextNotificationTime: nextTime,
  );
});

// Provider này sẽ tạo ra tất cả các instance có thể có trong 1 tuần tới
// Nó là nguồn dữ liệu cho cả visibleInstancesProvider và nextNotificationProvider
final allInstancesProvider = Provider<List<TodoInstance>>((ref) {
  final asyncTodos = ref.watch(todosProvider);
  if (asyncTodos.value == null) return [];

  final allTodoRules = asyncTodos.value!;
  final List<TodoInstance> instances = [];
  final now = DateTime.now();
  // Nhìn trước 7 ngày để tính toán
  final lookAheadEnd = now.add(const Duration(days: 7));

  for (final todoRule in allTodoRules) {
    if (todoRule is SingleTodo) {
      if(todoRule.dateTime.isAfter(now) && todoRule.dateTime.isBefore(lookAheadEnd)) {
         instances.add(TodoInstance.fromTodo(todoRule, todoRule.dateTime));
      }
    } else if (todoRule is RecurringTodoRule) {
      for (var day = now.normalized; day.isBefore(lookAheadEnd); day = day.add(const Duration(days: 1))) {
        if (todoRule.daysOfWeek.any((d) => d.asWeekday == day.weekday)) {
          final instance = TodoInstance.fromTodo(todoRule, day);
          if (instance.concreteDateTime.isAfter(now)) {
            instances.add(instance);
          }
        }
      }
    }
  }
  return instances;
});