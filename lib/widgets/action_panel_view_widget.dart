import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/ui_provider.dart';
import 'package:calendar_app/screens/add_edit_todo_screen.dart';
import 'package:calendar_app/widgets/schedule_view_widget.dart';
import 'package:calendar_app/widgets/todo_list_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActionPanelViewWidget extends ConsumerWidget {
  const ActionPanelViewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(mainViewProvider);

    return Column(
      children: [
        // Thanh công cụ sẽ thay đổi tùy theo view
        _buildActionToolbar(context, ref, currentView),
        const Divider(height: 1),
        // Nội dung sẽ chuyển đổi mượt mà giữa 2 view
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: currentView == MainViewType.schedule
                ? const ScheduleViewWidget(key: ValueKey('schedule'))
                : const TodoListViewWidget(key: ValueKey('list')),
          ),
        ),
      ],
    );
  }

  // Hàm xây dựng thanh công cụ động
  Widget _buildActionToolbar(BuildContext context, WidgetRef ref, MainViewType currentView) {
    // ---- Logic cho Schedule View ----
    if (currentView == MainViewType.schedule) {
      final selectedRange = ref.watch(selectedDateRangeProvider);
      final isSingleDay = selectedRange == null || selectedRange.duration.inDays == 0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Thêm công việc mới',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => AddEditTodoScreen.add(
                    initialDate: selectedRange?.start ?? DateTime.now(),
                  ),
                ));
              },
            ),
            const SizedBox(width: 8),
            if (isSingleDay)
              TextButton.icon(
                icon: const Icon(Icons.view_week_outlined),
                label: const Text('Xem cả tuần'),
                onPressed: () {
                  final currentDay = selectedRange?.start ?? DateTime.now();
                  final startOfWeek = currentDay.subtract(Duration(days: currentDay.weekday - 1));
                  final endOfWeek = startOfWeek.add(const Duration(days: 6));
                  ref.read(selectedDateRangeProvider.notifier).state = DateTimeRange(start: startOfWeek, end: endOfWeek);
                },
              ),
            const Spacer(),
            SegmentedButton<MainViewType>(
              segments: const [
                ButtonSegment(value: MainViewType.schedule, icon: Icon(Icons.calendar_view_week)),
                ButtonSegment(value: MainViewType.list, icon: Icon(Icons.view_list)),
              ],
              selected: {currentView},
              onSelectionChanged: (newSelection) => ref.read(mainViewProvider.notifier).state = newSelection.first,
            ),
          ],
        ),
      );
    }
    // ---- Logic cho List View ----
    else {
      final searchController = TextEditingController(text: ref.watch(todoSearchQueryProvider));
      searchController.selection = TextSelection.fromPosition(TextPosition(offset: searchController.text.length));
      
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm công việc...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                   suffixIcon: ref.watch(todoSearchQueryProvider).isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => ref.read(todoSearchQueryProvider.notifier).state = '',
                    )
                  : null,
                ),
                onChanged: (value) => ref.read(todoSearchQueryProvider.notifier).state = value,
              ),
            ),
            const SizedBox(width: 16),
            SegmentedButton<MainViewType>(
              segments: const [
                ButtonSegment(value: MainViewType.schedule, icon: Icon(Icons.calendar_view_week)),
                ButtonSegment(value: MainViewType.list, icon: Icon(Icons.view_list)),
              ],
              selected: {currentView},
              onSelectionChanged: (newSelection) => ref.read(mainViewProvider.notifier).state = newSelection.first,
            ),
          ],
        ),
      );
    }
  }
}