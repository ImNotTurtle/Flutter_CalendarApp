import 'package:calendar_app/providers/todo_provider.dart';
import 'package:calendar_app/widgets/action_panel_view_widget.dart'; // <<< Import widget mới
import 'package:calendar_app/widgets/calendar_widget.dart';
import 'package:calendar_app/widgets/global_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chỉ cần watch asyncTodos để hiển thị trạng thái loading/error chung
    final asyncTodos = ref.watch(todosProvider);

    return Scaffold(
      // AppBar giờ rất đơn giản, chỉ có tiêu đề
      appBar: AppBar(title: const Text('Lịch Công Việc Của Bạn')),
      body: asyncTodos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Lỗi: $error')),
        data: (todos) {
          return Column(
            children: [
              // Nội dung chính của app chiếm hết không gian còn lại
              Expanded(
                child: const Row(
                  children: [
                    SizedBox(width: 400, child: CalendarWidget()),
                    VerticalDivider(width: 1, thickness: 1),
                    Expanded(child: ActionPanelViewWidget()),
                  ],
                ),
              ),
              // Thanh trạng thái toàn cục ở dưới cùng
              const GlobalStatusBar(),
            ],
          );
        },
      ),
    );
  }
}
