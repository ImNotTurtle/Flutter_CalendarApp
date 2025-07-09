import 'package:uuid/uuid.dart';

final _uuid = Uuid();

// LỚP CHA: Chứa các thuộc tính chung
abstract class BaseTodo {
  final String id;
  final String title;
  final String content;
  final Duration? remindBefore;

  BaseTodo({
    required this.title,
    required this.content,
    String? id,
    this.remindBefore,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap();
}
