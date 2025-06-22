import 'package:calendar_app/models/todo_instance.dart';
import 'package:calendar_app/widgets/todo_item_widget.dart';
import 'package:flutter/material.dart';

class TodoListWidget extends StatelessWidget {
  final List<TodoInstance> todos;
  const TodoListWidget({super.key, required this.todos});

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return const Center(
        child: Text(
          'Không có công việc nào. Hãy chọn ngày trên lịch.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (ctx, index) => TodoItemWidget(todoInstance: todos[index]),
    );
  }
}
