// LỚP CON 1: Sự kiện đơn lẻ (SingleTodo)
import 'package:calendar_app/models/base_todo.dart';

class SingleTodo extends BaseTodo {
  final DateTime dateTime; // <<< THAY ĐỔI: Giờ là một ngày giờ cụ thể
  final bool isCompleted;

  SingleTodo({
    required super.title,
    required super.content,
    DateTime? dateTime,
    super.id,
    this.isCompleted = false,
  }) : dateTime = dateTime ?? DateTime.now();

  SingleTodo copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? dateTime,
    bool? isCompleted,
  }) {
    return SingleTodo(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
