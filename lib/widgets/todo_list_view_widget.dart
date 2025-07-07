import 'package:calendar_app/providers/todo_provider.dart';
import 'package:calendar_app/providers/ui_provider.dart';
import 'package:calendar_app/widgets/todo_rule_card.dart'; // <<< THÊM IMPORT MỚI
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodoListViewWidget extends ConsumerWidget {
  const TodoListViewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(searchableListProvider);
    final searchController = TextEditingController(
      text: ref.watch(todoSearchQueryProvider),
    );
    // Reset vị trí con trỏ về cuối khi build lại
    searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: searchController.text.length),
    );

    return todos.isEmpty
        ? const Center(child: Text('Không tìm thấy công việc nào.'))
        : ListView.builder(
          padding: const EdgeInsets.only(bottom: 80), // Thêm padding dưới
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            // <<< SỬ DỤNG LẠI WIDGET MỚI Ở ĐÂY >>>
            return TodoRuleCard(todo: todo);
          },
        );
  }
}
