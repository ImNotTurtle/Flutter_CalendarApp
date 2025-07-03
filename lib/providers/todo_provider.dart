import 'package:calendar_app/models/day_of_week.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import 'package:calendar_app/models/base_todo.dart';
import 'package:calendar_app/models/recurring_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:calendar_app/providers/service_provider.dart';

class TodosNotifier extends AsyncNotifier<List<BaseTodo>> {

  // --- HÀM HELPER CHUYỂN ĐỔI MÚI GIỜ (LOGIC TẬP TRUNG TẠI ĐÂY) ---

  BaseTodo _convertToUtc(BaseTodo localTodo) {
    if (localTodo is SingleTodo) {
      return localTodo.copyWith(dateTime: localTodo.dateTime.toUtc());
    }
    if (localTodo is RecurringTodoRule) {
      if (localTodo.daysOfWeek.isEmpty) return localTodo;
      
      final sampleLocalDay = localTodo.daysOfWeek.first;
      final now = DateTime.now();
      var tempDate = DateTime(now.year, now.month, now.day, localTodo.timeOfDay.hour, localTodo.timeOfDay.minute);
      
      while (tempDate.weekday != sampleLocalDay.asWeekday) {
        tempDate = tempDate.add(const Duration(days: 1));
      }
      
      final sampleUtcDateTime = tempDate.toUtc();
      final utcTime = TimeOfDay.fromDateTime(sampleUtcDateTime);
      final dayOffset = sampleUtcDateTime.day - tempDate.day;

      final utcDays = localTodo.daysOfWeek.map((localDay) {
        final utcWeekdayInt = (localDay.asWeekday - 1 + dayOffset + 7) % 7 + 1;
        return DayOfWeek.values.firstWhere((d) => d.asWeekday == utcWeekdayInt);
      }).toSet();
      
      return localTodo.copyWith(timeOfDay: utcTime, daysOfWeek: utcDays);
    }
    return localTodo;
  }

  BaseTodo _convertToLocal(BaseTodo utcTodo) {
    if (utcTodo is SingleTodo) {
      return utcTodo.copyWith(dateTime: utcTodo.dateTime.toLocal());
    }
    if (utcTodo is RecurringTodoRule) {
      if (utcTodo.daysOfWeek.isEmpty) return utcTodo;

      final sampleUtcDay = utcTodo.daysOfWeek.first;
      final now = DateTime.now().toUtc();
      var tempDate = DateTime.utc(now.year, now.month, now.day, utcTodo.timeOfDay.hour, utcTodo.timeOfDay.minute);

      while (tempDate.weekday != sampleUtcDay.asWeekday) {
        tempDate = tempDate.add(const Duration(days: 1));
      }

      final localDateTime = tempDate.toLocal();
      final localTime = TimeOfDay.fromDateTime(localDateTime);
      final dayOffset = localDateTime.day - tempDate.day;

      final localDays = utcTodo.daysOfWeek.map((utcDay) {
        final localWeekdayInt = (utcDay.asWeekday - 1 + dayOffset + 7) % 7 + 1;
        return DayOfWeek.values.firstWhere((d) => d.asWeekday == localWeekdayInt);
      }).toSet();
      
      return utcTodo.copyWith(timeOfDay: localTime, daysOfWeek: localDays);
    }
    return utcTodo;
  }
  
  // --- CÁC HÀM CHÍNH ---

  @override
  Future<List<BaseTodo>> build() async {
    final todosFromDb = await ref.read(todoServiceProvider).fetchTodos();
    // Chuyển đổi toàn bộ danh sách về giờ Local trước khi đưa vào state
    return todosFromDb.map(_convertToLocal).toList();
  }

  Future<void> addTodo(BaseTodo todo) async {
    final todoInUtc = _convertToUtc(todo);
    await ref.read(todoServiceProvider).addTodo(todoInUtc);
    ref.invalidateSelf();
  }

  Future<void> updateTodo(BaseTodo todo) async {
    final todoInUtc = _convertToUtc(todo);
    await ref.read(todoServiceProvider).updateTodo(todoInUtc);
    ref.invalidateSelf();
  }

  Future<void> removeTodo(String todoId) async {
    await ref.read(todoServiceProvider).removeTodo(todoId);
    ref.invalidateSelf();
  }

  Future<void> toggle(String todoId) async {
     final previousState = await future;
     final todoToToggle = previousState.firstWhereOrNull((t) => t.id == todoId);
     if (todoToToggle == null || todoToToggle is! SingleTodo) return;

     final newTodos = [
       for (final todo in previousState)
         if (todo.id == todoId)
           (todo as SingleTodo).copyWith(isCompleted: !todo.isCompleted)
         else
           todo
     ];
     state = AsyncValue.data(newTodos);

     try {
       await ref.read(todoServiceProvider).toggleTodo(todoId, todoToToggle.isCompleted);
     } catch (e) {
       state = AsyncValue.data(previousState);
     }
  }
}

// ... các provider phụ thuộc khác giữ nguyên ...
final todosProvider = AsyncNotifierProvider<TodosNotifier, List<BaseTodo>>(() {
  return TodosNotifier();
});

final todoByIdProvider = Provider.family<BaseTodo?, String>((ref, todoId) {
  final asyncTodos = ref.watch(todosProvider);
  return asyncTodos.when(
    data: (allTodos) => allTodos.firstWhereOrNull((todo) => todo.id == todoId),
    loading: () => null,
    error: (error, stackTrace) => null,
  );
});

final selectedTodosProvider = StateProvider<Set<String>>((ref) => {});