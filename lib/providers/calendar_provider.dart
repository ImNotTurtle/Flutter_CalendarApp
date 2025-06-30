import 'package:calendar_app/models/day_of_week.dart';
import 'package:calendar_app/models/recurring_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:calendar_app/models/todo_instance.dart';
import 'package:calendar_app/providers/todo_provider.dart'; // Import file provider mới
import 'package:calendar_app/services/timezone_service.dart';
import 'package:calendar_app/utils/date_time_utils.dart'; // Import file tiện ích mới
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- CÁC PROVIDER ĐIỀU KHIỂN GIAO DIỆN LỊCH ---

// Quản lý khoảng ngày được chọn trên lịch tháng
final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// Quản lý ngày đang được hiển thị trên lịch tuần/ngày
final displayedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Provider để quản lý ngày bắt đầu của trang đang xem
// trên ScheduleViewWidget. Nó có thể null nếu không có gì được chọn.
final schedulePageDateProvider = StateProvider<DateTime?>((ref) => null);

// --- PROVIDER TÍNH TOÁN DỮ LIỆU ĐỂ HIỂN THỊ ---

final visibleInstancesProvider = Provider<List<TodoInstance>>((ref) {
  final asyncTodos = ref.watch(todosProvider);
  // final allTodoRules = ref.watch(todosProvider);
  return asyncTodos.when(
    // Khi có dữ liệu, thực hiện logic lọc
    data: (allTodoRules) {
      final timeManager = ref.read(timezoneManagerProvider);
      final selectedRange = ref.watch(selectedDateRangeProvider);

      final DateTimeRange rangeToFilter;
      if (selectedRange == null) {
        // <<< SỬ DỤNG HÀM TIỆN ÍCH MỚI >>>
        final today = timeManager.normalizeToUtc(DateTime.now());
        rangeToFilter = DateTimeRange(start: today, end: today);
      } else {
        rangeToFilter = selectedRange;
      }

      // Chuẩn hóa ngày bắt đầu và kết thúc
      final rangeStart = timeManager.normalizeToUtc(
        rangeToFilter.start.normalized,
      );
      final rangeEnd = timeManager.normalizeToUtc(rangeToFilter.end.normalized);
      final endBoundary = rangeEnd.add(const Duration(days: 1));

      final List<TodoInstance> instances = [];
      for (final todoRule in allTodoRules) {
        if (todoRule is SingleTodo) {
          // <<< SỬ DỤNG HÀM TIỆN ÍCH MỚI >>>
          final todoDate = todoRule.dateTime.normalized;

          if (!todoDate.isBefore(rangeStart) &&
              todoDate.isBefore(endBoundary)) {
            instances.add(TodoInstance.fromTodo(todoRule, todoRule.dateTime));
          }
        } else if (todoRule is RecurringTodoRule) {
          for (
            var day = rangeStart;
            day.isBefore(endBoundary);
            day = day.add(const Duration(days: 1))
          ) {
            if (todoRule.daysOfWeek.any((d) => d.asWeekday == day.weekday)) {
              instances.add(TodoInstance.fromTodo(todoRule, day));
            }
          }
        }
      }

      instances.sort(
        (a, b) => a.concreteDateTime.compareTo(b.concreteDateTime),
      );
      return instances;
    },
    // Khi đang tải dữ liệu
    loading: () => [], // Trả về danh sách rỗng
    // Khi có lỗi
    error: (err, stack) => [], // Trả về rỗng và có thể log lỗi
  );
});
