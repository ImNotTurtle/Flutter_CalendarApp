import 'dart:async';
import 'package:calendar_app/models/recurring_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:calendar_app/providers/todo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import '../models/todo_instance.dart';

class NotificationManager {
  Timer? _notificationTimer;
  final Ref _ref;

  NotificationManager(this._ref);

  void scheduleNextNotification() {
    _notificationTimer?.cancel();

    final now = DateTime.now();
    final List<TodoInstance> upcomingInstances = [];
    final lookAheadRange = DateTimeRange(
      start: now,
      end: now.add(const Duration(days: 7)),
    );
    final allTodoRules = _ref.read(todosProvider);
    // Logic tạo instance giữ nguyên
    for (final todoRule in allTodoRules) {
      if (todoRule is SingleTodo) {
        if (!todoRule.dateTime.isBefore(lookAheadRange.start) &&
            todoRule.dateTime.isBefore(lookAheadRange.end)) {
          if (todoRule.dateTime.isAfter(now)) {
            upcomingInstances.add(
              TodoInstance.fromTodo(todoRule, todoRule.dateTime),
            );
          }
        }
      } else if (todoRule is RecurringTodoRule) {
        for (
          var day = lookAheadRange.start;
          day.isBefore(lookAheadRange.end);
          day = day.add(const Duration(days: 1))
        ) {
          if (todoRule.daysOfWeek.contains(day.weekday)) {
            final instance = TodoInstance.fromTodo(todoRule, day);
            if (instance.concreteDateTime.isAfter(now)) {
              upcomingInstances.add(instance);
            }
          }
        }
      }
    }

    if (upcomingInstances.isEmpty) {
      print(
        'Không còn công việc nào trong tương lai gần để lên lịch thông báo.',
      );
      return;
    }

    upcomingInstances.sort(
      (a, b) => a.concreteDateTime.compareTo(b.concreteDateTime),
    );

    // <<< LOGIC TỐI ƯU MỚI BẮT ĐẦU TỪ ĐÂY >>>

    // 1. Lấy mốc thời gian của sự kiện gần nhất
    final nextTimestamp = upcomingInstances.first.concreteDateTime;
    final List<TodoInstance> notificationsToShow = [];

    // 2. Duyệt danh sách đã sắp xếp để gom các sự kiện trùng giờ
    for (final instance in upcomingInstances) {
      // Nếu thời gian của sự kiện này khác (lớn hơn) mốc thời gian gần nhất
      if (instance.concreteDateTime != nextTimestamp) {
        // Dừng vòng lặp ngay lập tức vì các sự kiện sau đó sẽ còn xa hơn
        break;
      }
      // Nếu không, thêm nó vào danh sách cần thông báo
      notificationsToShow.add(instance);
    }

    // 3. Phần còn lại của logic giữ nguyên, chỉ sử dụng `notificationsToShow`
    final delay = nextTimestamp.difference(now);

    if (!delay.isNegative) {
      print(
        'Sẽ thông báo cho ${notificationsToShow.length} sự kiện vào lúc: $nextTimestamp, sau $delay',
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
