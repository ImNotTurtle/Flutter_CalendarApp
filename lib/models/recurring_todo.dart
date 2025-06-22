// LỚP CON 2: "Luật" lặp lại hàng tuần
import 'package:calendar_app/models/base_todo.dart';
import 'package:flutter/material.dart';

class RecurringTodoRule extends BaseTodo {
  final TimeOfDay timeOfDay; // Thời gian trong ngày (VD: 21:00)
  final Set<int> daysOfWeek; // Các ngày trong tuần lặp lại (1=T2, 7=CN)

  RecurringTodoRule({
    required super.title,
    required super.content,
    required this.timeOfDay,
    required this.daysOfWeek,
    super.id,
  });

  // <<< HÀM COPYWITH CHO RECURRINGTODORULE >>>
  RecurringTodoRule copyWith({
    String? id,
    String? title,
    String? content,
    TimeOfDay? timeOfDay,
    Set<int>? daysOfWeek,
  }) {
    return RecurringTodoRule(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }
}
