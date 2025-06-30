import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/todo_instance.dart';
import '../providers/todo_provider.dart';
import '../screens/add_edit_todo_screen.dart';

class TodoItemWidget extends ConsumerWidget {
  final TodoInstance todoInstance;
  const TodoItemWidget({super.key, required this.todoInstance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe provider để biết item này có đang được chọn hay không
    final selectedIds = ref.watch(selectedTodosProvider);
    final isSelected = selectedIds.contains(todoInstance.originalId);
    final isSelectionMode = selectedIds.isNotEmpty;

    // Trạng thái hoàn thành chỉ áp dụng cho sự kiện đơn lẻ
    final bool isCompleted = todoInstance.isCompleted ?? false;

    // Bọc trong Dismissible để có thể trượt xóa
    return Dismissible(
      // Key cần duy nhất cho mỗi instance trên màn hình để Flutter nhận diện
      key: ValueKey(todoInstance.originalId + todoInstance.concreteDateTime.toIso8601String()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Xác nhận xóa"),
              content: Text(
                  "Bạn có chắc muốn xóa '${todoInstance.title}' không? Thao tác này sẽ xóa toàn bộ quy luật (nếu có)."),
              actions: <Widget>[
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Hủy")),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Xóa", style: TextStyle(color: Colors.red))),
              ],
            );
          },
        ) ?? false;
      },
      
      onDismissed: (direction) {
        // <<< Gọi hàm `removeTodo` từ notifier >>>
        ref.read(todosProvider.notifier).removeTodo(todoInstance.originalId);
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Đã xóa: ${todoInstance.title}')));
      },
      
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        elevation: isSelected ? 8.0 : 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Opacity(
          opacity: isCompleted ? 0.6 : 1.0,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            selected: isSelected,
            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            
            // --- XỬ LÝ SỰ KIỆN NHẤN ---
            onTap: () {
              final selectedNotifier = ref.read(selectedTodosProvider.notifier);
              final todosNotifier = ref.read(todosProvider.notifier);

              if (isSelectionMode) {
                // Nếu đang trong chế độ chọn -> Tap để chọn/bỏ chọn
                isSelected
                    ? selectedNotifier.update((state) => state..remove(todoInstance.originalId))
                    : selectedNotifier.update((state) => {...state, todoInstance.originalId});
              } else if (!todoInstance.isRecurring) {
                // Nếu ở chế độ thường và là sự kiện đơn lẻ -> Tap để đánh dấu hoàn thành
                todosNotifier.toggle(todoInstance.originalId);
              }
            },
            onLongPress: () {
              // Luôn dùng LongPress để bắt đầu chế độ chọn
              if (!isSelectionMode) {
                ref.read(selectedTodosProvider.notifier).state = {todoInstance.originalId};
              }
            },

            // --- GIAO DIỆN ---
            leading: InkWell(
              customBorder: const CircleBorder(),
              onTap: todoInstance.isRecurring
                  ? null // Vô hiệu hóa nhấn cho sự kiện lặp lại
                  : () => ref.read(todosProvider.notifier).toggle(todoInstance.originalId),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: todoInstance.isRecurring
                    ? Icon(Icons.event_repeat, color: Colors.blue.shade300)
                    : isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
              ),
            ),
            
            title: Text(
              todoInstance.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey[700] : null,
              ),
            ),
            
            subtitle: Text(todoInstance.content),
            
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('HH:mm - dd/MM').format(todoInstance.concreteDateTime)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_note_outlined),
                  tooltip: 'Sửa công việc',
                  onPressed: isSelectionMode ? null : () {
                    // <<< SỬ DỤNG LOGIC MỚI: Gọi provider `todoByIdProvider` >>>
                    final originalTodo = ref.read(todoByIdProvider(todoInstance.originalId));

                    if (originalTodo != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => AddEditTodoScreen.edit(todo: originalTodo),
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