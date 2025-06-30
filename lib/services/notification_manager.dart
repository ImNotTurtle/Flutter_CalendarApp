import 'dart:async';
import 'package:calendar_app/models/day_of_week.dart';
import 'package:calendar_app/models/recurring_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:calendar_app/models/todo_instance.dart';
import 'package:calendar_app/providers/todo_provider.dart';
import 'package:calendar_app/utils/date_time_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';

class NotificationManager {
  Timer? _notificationTimer;
  final Ref _ref;

  NotificationManager(this._ref);

  void scheduleNextNotification() {
    _notificationTimer?.cancel();

    final asyncTodos = _ref.read(todosProvider);
    if (!asyncTodos.hasValue || asyncTodos.isLoading) {
      print('NotificationManager: Đang chờ dữ liệu công việc...');
      return;
    }
    final allTodoRules = asyncTodos.value!;

    final now = DateTime.now();
    final List<TodoInstance> upcomingInstances = [];
    final lookAheadRange = DateTimeRange(
      start: now,
      end: now.add(const Duration(days: 7)),
    );

    // <<< BẮT ĐẦU LOGIC ĐÃ ĐƯỢC ĐỒNG BỘ HÓA >>>
    final rangeStart = lookAheadRange.start.normalized; // Chuẩn hóa
    final rangeEnd = lookAheadRange.end.normalized; // Chuẩn hóa
    final endBoundary = rangeEnd.add(const Duration(days: 1));

    for (final todoRule in allTodoRules) {
      if (todoRule is SingleTodo) {
        // Chỉ xử lý các sự kiện đơn lẻ nằm trong tương lai
        if (todoRule.dateTime.isAfter(now)) {
          final todoDate = todoRule.dateTime.normalized;
          // So sánh các ngày đã được chuẩn hóa
          if (!todoDate.isBefore(rangeStart) &&
              todoDate.isBefore(endBoundary)) {
            upcomingInstances.add(
              TodoInstance.fromTodo(todoRule, todoRule.dateTime),
            );
          }
        }
      } else if (todoRule is RecurringTodoRule) {
        // Vòng lặp này cũng dùng ngày đã chuẩn hóa
        for (
          var day = rangeStart;
          day.isBefore(endBoundary);
          day = day.add(const Duration(days: 1))
        ) {
          if (todoRule.daysOfWeek.any((d) => d.asWeekday == day.weekday)) {
            final instance = TodoInstance.fromTodo(todoRule, day);
            if (instance.concreteDateTime.isAfter(now)) {
              upcomingInstances.add(instance);
            }
          }
        }
      }
    }
    // <<< KẾT THÚC LOGIC ĐÃ ĐƯỢC ĐỒNG BỘ HÓA >>>

    if (upcomingInstances.isEmpty) {
      print(
        'NotificationManager: Không có công việc nào trong tương lai gần để lên lịch.',
      );
      return;
    }

    upcomingInstances.sort(
      (a, b) => a.concreteDateTime.compareTo(b.concreteDateTime),
    );

    final nextTimestamp = upcomingInstances.first.concreteDateTime;
    final List<TodoInstance> notificationsToShow = [];

    for (final instance in upcomingInstances) {
      if (instance.concreteDateTime != nextTimestamp) {
        break;
      }
      notificationsToShow.add(instance);
    }

    final delay = nextTimestamp.difference(now);

    if (!delay.isNegative) {
      // Sửa lại log để hiển thị giờ địa phương cho dễ debug
      print(
        'NotificationManager: Sẽ thông báo cho ${notificationsToShow.length} sự kiện vào lúc (Local): $nextTimestamp, sau: $delay',
      );

      _notificationTimer = Timer(delay, () {
        for (final instance in notificationsToShow) {
          _showNotification(instance);
        }
        scheduleNextNotification();
      });
    }
  }

  Future<void> _showNotification(TodoInstance todo) async {
    LocalNotification notification = LocalNotification(
      title: todo.title,
      body: todo.content,
      silent: false,
    );
    await notification.show();
  }
}
