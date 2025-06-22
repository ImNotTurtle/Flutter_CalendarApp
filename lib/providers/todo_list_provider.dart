import 'package:calendar_app/data/todos.dart';
import 'package:calendar_app/models/recurring_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:calendar_app/models/todo_instance.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/base_todo.dart'; // <<< THAY ĐỔI: Import file model mới

// --- DỮ LIỆU MẪU MỚI ---

// <<< THAY ĐỔI: Notifier giờ quản lý List<BaseTodo> >>>
class TodosNotifier extends StateNotifier<List<BaseTodo>> {
  TodosNotifier() : super(sampleTodos);

  // Các phương thức thêm/sửa/xóa cần được cập nhật để làm việc với BaseTodo
  void addTodo(BaseTodo todo) {
    state = [...state, todo];
  }

  void updateTodo(BaseTodo todo) {
    state = [
      for (final t in state)
        if (t.id == todo.id) todo else t,
    ];
  }

  void removeTodo(String todoId) {
    state = state.where((t) => t.id != todoId).toList();
  }

  // Toggle chỉ hoạt động với SingleTodo
  void toggle(String todoId) {
    state = [
      for (final t in state)
        if (t.id == todoId && t is SingleTodo)
          SingleTodo(
            id: t.id,
            title: t.title,
            content: t.content,
            dateTime: t.dateTime,
            isCompleted: !t.isCompleted,
          )
        else
          t,
    ];
  }
}

final todosProvider = StateNotifierProvider<TodosNotifier, List<BaseTodo>>((
  ref,
) {
  return TodosNotifier();
});

final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// <<< Provider để lưu ngày đầu tiên của tuần đang hiển thị >>>
// Mặc định là ngày hôm nay
final displayedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
// final calendarViewProvider = StateProvider<CalendarView>(
//   (ref) => CalendarView.day,
// );

// <<< Provider chịu trách nhiệm quản lý những todo instance nào sẽ hiển thị
final visibleInstancesProvider = Provider<List<TodoInstance>>((ref) {
  final allTodoRules = ref.watch(todosProvider);
  final selectedRange = ref.watch(selectedDateRangeProvider);

  // Mặc định, nếu không có gì được chọn, hiển thị cho ngày hôm nay
  final DateTimeRange rangeToFilter;
  if (selectedRange == null) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    rangeToFilter = DateTimeRange(start: today, end: today);
  } else {
    rangeToFilter = selectedRange;
  }

  // Logic tạo instance giữ nguyên, nó sẽ hoạt động cho bất kỳ khoảng ngày nào
  final List<TodoInstance> instances = [];
  final rangeStart = rangeToFilter.start;
  final rangeEnd = rangeToFilter.end;

  for (final todoRule in allTodoRules) {
    // Trường hợp 1: Là sự kiện đơn lẻ
    if (todoRule is SingleTodo) {
      // Dùng dateNormalized để so sánh không tính giờ
      final todoDate = DateTime.utc(
        todoRule.dateTime.year,
        todoRule.dateTime.month,
        todoRule.dateTime.day,
      );
      if (!todoDate.isBefore(rangeStart) &&
          todoDate.isBefore(rangeEnd.add(const Duration(days: 1)))) {
        instances.add(
          TodoInstance(
            originalId: todoRule.id,
            title: todoRule.title,
            content: todoRule.content,
            concreteDateTime: todoRule.dateTime,
            isRecurring: false,
            isCompleted: todoRule.isCompleted,
          ),
        );
      }
    }
    // Trường hợp 2: Là "luật" lặp lại
    else if (todoRule is RecurringTodoRule) {
      for (
        var day = rangeStart;
        day.isBefore(rangeEnd.add(const Duration(days: 1)));
        day = day.add(const Duration(days: 1))
      ) {
        if (todoRule.daysOfWeek.contains(day.weekday)) {
          final concreteDateTime = DateTime(
            day.year,
            day.month,
            day.day,
            todoRule.timeOfDay.hour,
            todoRule.timeOfDay.minute,
          );
          instances.add(
            TodoInstance(
              originalId: todoRule.id,
              title: todoRule.title,
              content: todoRule.content,
              concreteDateTime: concreteDateTime,
              isRecurring: true,
              isCompleted: null,
            ),
          );
        }
      }
    }
  }

  instances.sort((a, b) => a.concreteDateTime.compareTo(b.concreteDateTime));
  return instances;
});

// Provider này giờ sẽ lưu ID của BaseTodo (cả Single và Recurring)
final selectedTodosProvider = StateProvider<Set<String>>((ref) => {});


final todoByIdProvider = Provider.family<BaseTodo?, String>((ref, todoId) {
  // Lắng nghe danh sách todo gốc
  final allTodos = ref.watch(todosProvider);
  
  // Dùng firstWhereOrNull để tìm. Nó sẽ trả về null nếu không tìm thấy.
  return allTodos.firstWhereOrNull((todo) => todo.id == todoId);
});