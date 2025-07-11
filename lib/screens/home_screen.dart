import 'package:calendar_app/providers/todo_provider.dart';
import 'package:calendar_app/widgets/action_panel_view_widget.dart';
import 'package:calendar_app/widgets/calendar_widget.dart';
import 'package:calendar_app/widgets/global_status_bar.dart';
import 'package:calendar_app/widgets/mobile_layout_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Đặt một ngưỡng (breakpoint) để quyết định layout
  static const double desktopBreakpoint = 800.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTodos = ref.watch(todosProvider);

    return Scaffold(
      // Không cần AppBar ở đây nữa vì các layout con sẽ tự quản lý AppBar của riêng mình
      body: asyncTodos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Lỗi: $error')),
        data: (todos) {
          // <<< SỬ DỤNG LAYOUTBUILDER ĐỂ QUYẾT ĐỊNH GIAO DIỆN >>>
          return LayoutBuilder(
            builder: (context, constraints) {
              // Nếu chiều rộng màn hình lớn hơn ngưỡng đã đặt
              if (constraints.maxWidth > desktopBreakpoint) {
                // Hiển thị giao diện Desktop
                return const DesktopLayout();
              } else {
                // Ngược lại, hiển thị giao diện Mobile
                return const MobileLayoutWidget();
              }
            },
          );
        },
      ),
    );
  }
}

// <<< WIDGET MỚI: Tách layout desktop ra cho gọn gàng >>>
class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 400, // Chiều rộng cố định cho panel lịch
                child: CalendarWidget(),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              const Expanded(
                child: ActionPanelViewWidget(),
              ),
            ],
          ),
        ),
        // Thanh trạng thái chỉ hiển thị ở chế độ desktop
        const GlobalStatusBar(),
      ],
    );
  }
}