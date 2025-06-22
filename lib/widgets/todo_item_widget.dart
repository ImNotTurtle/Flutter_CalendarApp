import 'package:calendar_app/models/todo_instance.dart';
import 'package:calendar_app/providers/todo_list_provider.dart';
import 'package:calendar_app/screens/add_edit_todo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TodoItemWidget extends ConsumerWidget {
  final TodoInstance todoInstance;
  const TodoItemWidget({super.key, required this.todoInstance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(selectedTodosProvider);
    final isSelected = selectedIds.contains(todoInstance.originalId);
    final isSelectionMode = selectedIds.isNotEmpty;
    final bool isCompleted = todoInstance.isCompleted ?? false;
    final todo = todoInstance;

    // Bọc Card trong Dismissible để có thể trượt xóa
    return Dismissible(
      key: ValueKey(todo.originalId),
      direction: DismissDirection.endToStart,

      // Widget hiển thị phía sau khi trượt
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),

      // Hiển thị hộp thoại xác nhận trước khi xóa
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Xác nhận xóa"),
                  content: Text(
                    "Bạn có chắc muốn xóa công việc '${todo.title}' không?",
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Hủy"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        "Xóa",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            ) ??
            false; // Nếu người dùng bấm ra ngoài dialog, coi như là `false`
      },

      // Được gọi sau khi người dùng xác nhận xóa
      onDismissed: (direction) {
        ref.read(todosProvider.notifier).removeTodo(todo.originalId);
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Đã xóa: ${todo.title}')));
      },

      // Widget chính chứa nội dung
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        elevation: isSelected ? 8.0 : 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              isSelected
                  ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                  : BorderSide.none,
        ),
        child: Opacity(
          opacity: isCompleted ? 0.6 : 1.0,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            selected: isSelected,
            selectedTileColor: Theme.of(
              context,
            ).primaryColor.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            onTap: () {
              if (isSelectionMode) {
                final notifier = ref.read(selectedTodosProvider.notifier);
                notifier.state =
                    isSelected
                        ? (notifier.state..remove(todo.originalId))
                        : ({...notifier.state, todo.originalId});
              } else {
                ref.read(todosProvider.notifier).toggle(todo.originalId);
              }
            },

            onLongPress: () {
              if (!isSelectionMode) {
                ref.read(selectedTodosProvider.notifier).state = {
                  todo.originalId,
                };
              }
            },

            leading: InkWell(
              customBorder: const CircleBorder(),
              onTap:
                  () =>
                      ref.read(todosProvider.notifier).toggle(todo.originalId),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                    isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.grey,
                        ),
              ),
            ),

            title: Text(
              todo.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey[700] : null,
              ),
            ),

            subtitle: Text(todo.content),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('dd/MM').format(todo.concreteDateTime)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_note_outlined),
                  tooltip: 'Sửa công việc',
                  onPressed:
                      isSelectionMode
                          ? null
                          : () {
                            final originalTodo = ref.read(
                              todoByIdProvider(todoInstance.originalId),
                            );

                            // Luôn kiểm tra null để đảm bảo an toàn
                            if (originalTodo != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (ctx) => AddEditTodoScreen.edit(
                                        todo: originalTodo,
                                      ),
                                ),
                              );
                            }
                          },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
