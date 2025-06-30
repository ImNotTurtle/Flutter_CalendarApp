import 'package:calendar_app/models/single_todo.dart';
import 'package:calendar_app/providers/todo_provider.dart';
import 'package:calendar_app/widgets/calendar_widget.dart';
import 'package:calendar_app/widgets/schedule_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.notification_add_outlined),
            tooltip: 'Tạo công việc trong 5 phút nữa',
            onPressed: () async {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Đang tạo công việc kiểm tra...'),
                  ),
                );

              // 1. Tạo một công việc mẫu
              final testTodo = SingleTodo(
                title: 'Kiểm tra thông báo tự động',
                content: 'Email nhắc nhở sẽ được gửi cho công việc này.',
                dateTime: DateTime.now().toUtc().add(const Duration(minutes: 5)),
              );

              // 2. Gọi hàm addTodo từ notifier.
              // Hàm này đã bao gồm logic gọi service, xử lý loading và làm mới state.
              try {
                await ref.read(todosProvider.notifier).addTodo(testTodo);

                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Thành công! Vui lòng chờ thông báo trong 5 phút.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('Lỗi khi tạo công việc: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                }
              }
            },
          ),
          // Panel bên trái - Lịch tổng quan
          SizedBox(width: 400, child: CalendarWidget()),
          // Đường kẻ phân cách
          const VerticalDivider(width: 1, thickness: 1),
          // Panel bên phải - Lịch trình chi tiết
          const Expanded(child: ScheduleViewWidget()),
        ],
      ),
    );
  }
}
