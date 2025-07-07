import 'package:calendar_app/models/todo_instance.dart';
import 'package:calendar_app/providers/todo_provider.dart';
import 'package:calendar_app/screens/add_edit_todo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Hàm helper toàn cục để hiển thị dialog từ bất kỳ đâu
void showTodoDetailsDialog(BuildContext context, TodoInstance instance) {
  showDialog(
    context: context,
    builder: (ctx) => TodoDetailsDialog(instance: instance),
  );
}

/// Widget chứa toàn bộ UI và logic cho Dialog
class TodoDetailsDialog extends ConsumerWidget {
  final TodoInstance instance;

  const TodoDetailsDialog({super.key, required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lấy ra "luật" gốc từ provider để có thể Sửa/Xóa
    final originalTodo = ref.read(todoByIdProvider(instance.originalId));
    final localDateTime = instance.concreteDateTime;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header của Dialog ---
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Icon(
                      instance.isRecurring ? Icons.event_repeat : Icons.event,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      instance.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // --- Nội dung chi tiết ---
              if (instance.content.isNotEmpty)
                Text(
                  instance.content,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),

              if (instance.content.isNotEmpty) const SizedBox(height: 24),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.access_time_filled_rounded,
                  color: Colors.grey,
                ),
                title: Text(
                  DateFormat('HH:mm', 'vi_VN').format(localDateTime),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat(
                    'EEEE, dd MMMM, yyyy',
                    'vi_VN',
                  ).format(localDateTime),
                ),
              ),

              if (!instance.isRecurring)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    instance.isCompleted ?? false
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color:
                        instance.isCompleted ?? false
                            ? Colors.green
                            : Colors.grey,
                  ),
                  title: Text(
                    instance.isCompleted ?? false
                        ? 'Đã hoàn thành'
                        : 'Chưa hoàn thành',
                  ),
                ),

              const SizedBox(height: 24),

              // --- Các nút hành động ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text('Đóng'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  if (originalTodo != null) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Xóa'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        Navigator.of(context).pop();
                        ref
                            .read(todosProvider.notifier)
                            .removeTodo(originalTodo.id);
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Sửa'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    AddEditTodoScreen.edit(todo: originalTodo),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
