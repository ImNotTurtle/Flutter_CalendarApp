import 'package:calendar_app/data/todos.dart';
import 'package:calendar_app/models/base_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier quản lý danh sách "luật" gốc
class TodosNotifier extends StateNotifier<List<BaseTodo>> {
  TodosNotifier() : super(sampleTodos);

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

  void toggle(String todoId) {
    state = [
      for (final t in state)
        if (t.id == todoId && t is SingleTodo)
          t.copyWith(isCompleted: !t.isCompleted)
        else
          t,
    ];
  }
}

// Provider chính cho danh sách công việc
final todosProvider = StateNotifierProvider<TodosNotifier, List<BaseTodo>>((ref) {
  return TodosNotifier();
});

// Provider để tìm một Todo theo ID
final todoByIdProvider = Provider.family<BaseTodo?, String>((ref, todoId) {
  final allTodos = ref.watch(todosProvider);
  return allTodos.firstWhereOrNull((todo) => todo.id == todoId);
});

// Provider quản lý các ID đang được chọn trong danh sách
final selectedTodosProvider = StateProvider<Set<String>>((ref) => {});