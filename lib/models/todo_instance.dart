import 'package:calendar_app/models/base_todo.dart';
import 'package:calendar_app/models/recurring_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:flutter/material.dart';

class TodoInstance {
  final String originalId;
  final String title;
  final String content;
  final DateTime concreteDateTime;
  final bool isRecurring;
  final bool? isCompleted;

  TodoInstance({
    required this.originalId,
    required this.title,
    required this.content,
    required this.concreteDateTime,
    required this.isRecurring,
    this.isCompleted,
  });

  factory TodoInstance.fromTodo(BaseTodo todoRule, DateTime day) {
    bool isRecurring;
    bool? isCompleted;
    DateTime concreteDateTime;

    // Kiểm tra loại của "luật" gốc
    if (todoRule is SingleTodo) {
      // <<< SỬA LỖI: Dùng trực tiếp dateTime của SingleTodo để giữ nguyên độ chính xác >>>
      concreteDateTime = todoRule.dateTime;
      isRecurring = false;
      isCompleted = todoRule.isCompleted;

    } else if (todoRule is RecurringTodoRule) {
      // Đối với luật lặp lại, việc khởi tạo lại là đúng vì nó không có giây/mili-giây
      final time = todoRule.timeOfDay;
      concreteDateTime = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );
      isRecurring = true;
      isCompleted = null;
      
    } else {
      throw Exception('Loại Todo không xác định: ${todoRule.runtimeType}');
    }

    // Trả về một đối tượng TodoInstance hoàn chỉnh
    return TodoInstance(
      originalId: todoRule.id,
      title: todoRule.title,
      content: todoRule.content,
      concreteDateTime: concreteDateTime,
      isRecurring: isRecurring,
      isCompleted: isCompleted,
    );
  }
}