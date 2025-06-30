import 'package:uuid/uuid.dart';

final _uuid = Uuid();

// LỚP CHA: Chứa các thuộc tính chung
abstract class BaseTodo {
  final String id;
  final String title;
  final String content;

  BaseTodo({required this.title, required this.content, String? id})
    : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap();
}
