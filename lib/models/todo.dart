import 'package:uuid/uuid.dart';

final _uuid = Uuid();

class Todo {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final bool isCompleted;

  Todo({
    required this.title,
    required this.content,
    DateTime? date,
    String? id,
    this.isCompleted = false,
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();
  
  // <<< TÍNH NĂNG MỚI: Getter để chuẩn hóa ngày >>>
  DateTime get dateNormalized {
    return DateTime(date.year, date.month, date.day);
  }

  Todo copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    bool? isCompleted,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}