import 'package:calendar_app/models/base_todo.dart';
import 'package:calendar_app/models/day_of_week.dart';
import 'package:calendar_app/models/recurring_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:calendar_app/screens/add_edit_todo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TodoRuleCard extends ConsumerWidget {
  final BaseTodo todo;
  const TodoRuleCard({super.key, required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sử dụng Card để có giao diện nhất quán
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Icon thay đổi theo loại công việc
        leading: CircleAvatar(
          child: Icon(
            todo is SingleTodo ? Icons.event_note : Icons.event_repeat,
          ),
        ),
        title: Text(todo.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(todo.content, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            const SizedBox(height: 8),
            // Hiển thị thông tin thời gian tương ứng
            _buildTimeInfo(context, todo),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Khi nhấn vào, điều hướng đến màn hình Sửa
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => AddEditTodoScreen.edit(todo: todo),
            ),
          );
        },
      ),
    );
  }

  // Hàm helper để hiển thị thông tin thời gian một cách đẹp mắt
  Widget _buildTimeInfo(BuildContext context, BaseTodo todo) {
    final textStyle = TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12);

    if (todo is SingleTodo) {
      return Text(
        DateFormat('EEEE, dd/MM/yyyy HH:mm', 'vi_VN').format(todo.dateTime),
        style: textStyle,
      );
    }

    if (todo is RecurringTodoRule) {
      final days = todo.daysOfWeek.map((d) => d.vietnameseName).join(', ');
      final time = todo.timeOfDay.format(context);
      return Text(
        'Hàng tuần vào lúc $time các ngày: $days',
        style: textStyle,
      );
    }
    return const SizedBox.shrink();
  }
}
