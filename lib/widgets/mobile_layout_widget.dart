import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendar_app/widgets/action_panel_view_widget.dart';
import 'package:calendar_app/widgets/calendar_widget.dart';

class MobileLayoutWidget extends ConsumerWidget {
  const MobileLayoutWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sử dụng DefaultTabController để tự động quản lý trạng thái của các tab
    return DefaultTabController(
      length: 2, // Có 2 tab: Lịch và Lịch trình
      child: Scaffold(
        appBar: AppBar(
          // AppBar giờ sẽ chứa TabBar để chuyển đổi
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.calendar_month_outlined),
                text: 'Lịch tháng',
              ),
              Tab(
                icon: Icon(Icons.view_week_outlined),
                text: 'Lịch trình',
              ),
            ],
          ),
          // Giữ lại tiêu đề chính của ứng dụng
          title: const Text('Lịch Công Việc'),
        ),
        body: const TabBarView(
          children: [
            // Tab 1: Hiển thị CalendarWidget (lịch tháng)
            // Bọc trong một SingleChildScrollView để tránh lỗi tràn màn hình
            SingleChildScrollView(
              child: CalendarWidget(),
            ),
            
            // Tab 2: Hiển thị ActionPanelViewWidget (lịch trình chi tiết)
            ActionPanelViewWidget(),
          ],
        ),
      ),
    );
  }
}