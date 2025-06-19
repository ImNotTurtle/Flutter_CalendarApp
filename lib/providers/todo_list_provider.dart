import 'package:calendar_app/data/todos.dart';
import 'package:calendar_app/models/todo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodosNotifier extends StateNotifier<List<Todo>> {
  TodosNotifier() : super(todosData);

  void addTodo(String title, String content, DateTime date) {
    state = [...state, Todo(title: title, content: content, date: date)];
  }

  void updateTodo(Todo updatedTodo) {
    state = [
      for (final todo in state)
        if (todo.id == updatedTodo.id) updatedTodo else todo,
    ];
  }

  void deleteTodo(String id){
    state = state.where((todo) => todo.id != id).toList();
  }

  void deleteMultipleTodos(Set<String> idsToDelete) {
    state = state.where((todo) => !idsToDelete.contains(todo.id)).toList();
  }

  void toggle(String todoId) {
    state = [
      for (final todo in state)
        if (todo.id == todoId)
          todo.copyWith(isCompleted: !todo.isCompleted)
        else
          todo,
    ];
  }
}

final todosProvider = StateNotifierProvider<TodosNotifier, List<Todo>>((ref) {
  return TodosNotifier();
});

// Provider này giữ khoảng ngày (start, end) mà người dùng chọn trên lịch
// Dùng StateProvider vì nó đơn giản và chỉ giữ một giá trị duy nhất.
final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// Provider này sẽ trả về danh sách các công việc đã được lọc
// Nó sẽ "lắng nghe" cả danh sách gốc (todosProvider) và khoảng ngày được chọn
// (selectedDateRangeProvider) để tự động cập nhật.
final filteredTodosProvider = Provider<List<Todo>>((ref) {
  // Lắng nghe sự thay đổi từ 2 provider khác
  final allTodos = ref.watch(todosProvider);
  final selectedRange = ref.watch(selectedDateRangeProvider);

  // Nếu không có ngày nào được chọn, trả về danh sách rỗng
  if (selectedRange == null) {
    return allTodos;
  }
  // Lọc và trả về danh sách công việc có ngày nằm trong khoảng đã chọn
  return allTodos.where((todo) {
    // Chuẩn hóa ngày về 0h:00 để so sánh chỉ dựa trên ngày, không tính giờ
    final todoDate = todo.dateNormalized;
    final startDate = DateTime(selectedRange.start.year, selectedRange.start.month, selectedRange.start.day);
    final endDate = DateTime(selectedRange.end.year, selectedRange.end.month, selectedRange.end.day);

    return (todoDate.isAtSameMomentAs(startDate) || todoDate.isAfter(startDate)) &&
           (todoDate.isAtSameMomentAs(endDate) || todoDate.isBefore(endDate));
  }).toList();
});


//Provider dùng để truy vấn nhanh theo ID
// Dùng Set để tránh trùng lặp và truy vấn nhanh
final selectedTodosProvider = StateProvider<Set<String>>((ref) => {});