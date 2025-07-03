// LỚP CON 1: Sự kiện đơn lẻ (SingleTodo)
import 'package:calendar_app/models/base_todo.dart';

class SingleTodo extends BaseTodo {
  final DateTime dateTime;
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

  // Hàm chuyển object thành Map để gửi lên Supabase
  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'recurrence_type': 'none',
      'date_time': dateTime.toIso8601String(),
      'is_completed': isCompleted,
    };
  }

  // Hàm tạo object từ Map lấy về từ Supabase
  factory SingleTodo.fromMap(Map<String, dynamic> map) {
    return SingleTodo(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      dateTime: DateTime.parse(map['date_time']),
      isCompleted: map['is_completed'] ?? false,
    );
  }
}
