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
          // Panel bên trái - Lịch tổng quan
          SizedBox(
            width: 400,
            child: CalendarWidget(),
          ),
          // Đường kẻ phân cách
          const VerticalDivider(width: 1, thickness: 1),
          // Panel bên phải - Lịch trình chi tiết
          const Expanded(
            child: ScheduleViewWidget(),
          ),
        ],
      ),
    );
  }
}