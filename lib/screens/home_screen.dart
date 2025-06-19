import 'package:calendar_app/providers/todo_list_provider.dart';
import 'package:calendar_app/screens/add_edit_todo_screen.dart';
import 'package:calendar_app/widgets/calendar_widget.dart';
import 'package:calendar_app/widgets/todo_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // --- HÀM HỖ TRỢ CHO APPBAR ---
  // AppBar mặc định khi không có gì được chọn
  AppBar _buildDefaultAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text('Lịch Công Việc'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_task),
          tooltip: 'Thêm công việc mới',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => AddEditTodoScreen.add()),
            );
          },
        ),
      ],
    );
  }

  // AppBar khi đang trong chế độ chọn
  AppBar _buildContextualAppBar(
    BuildContext context,
    WidgetRef ref,
    Set<String> selectedIds,
  ) {
    return AppBar(
      // Nút đóng để thoát chế độ chọn
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => ref.read(selectedTodosProvider.notifier).state = {},
      ),
      title: Text('${selectedIds.length} đã chọn'),
      backgroundColor: Colors.blueGrey.shade700, // Màu nền khác biệt
      actions: [
        // Nút xóa hàng loạt
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: 'Xóa các mục đã chọn',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Xác nhận xóa'),
                    content: Text(
                      'Bạn có chắc muốn xóa ${selectedIds.length} mục đã chọn không?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            );

            if (confirm ?? false) {
              ref.read(todosProvider.notifier).deleteMultipleTodos(selectedIds);
              ref.read(selectedTodosProvider.notifier).state =
                  {}; // Thoát chế độ chọn
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTodos = ref.watch(filteredTodosProvider);
    final selectedIds = ref.watch(selectedTodosProvider);

    return Scaffold(
      // Hiển thị AppBar tùy theo chế độ chọn
      appBar:
          selectedIds.isEmpty
              ? _buildDefaultAppBar(context, ref)
              : _buildContextualAppBar(context, ref, selectedIds),
      body: Row(
        children: [
          const SizedBox(
            width: 400, // Tăng chiều rộng lịch cho dễ nhìn
            child: CalendarWidget(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Danh sách công việc',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(child: TodoListWidget(todos: filteredTodos)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
