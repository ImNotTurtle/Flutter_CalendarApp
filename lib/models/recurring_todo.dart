import 'package:calendar_app/models/base_todo.dart';
import 'package:calendar_app/models/day_of_week.dart';
import 'package:flutter/material.dart';

class RecurringTodoRule extends BaseTodo {
  final TimeOfDay timeOfDay; // Thời gian trong ngày (VD: 21:00)
  final Set<DayOfWeek> daysOfWeek; // Các ngày trong tuần lặp lại

  RecurringTodoRule({
    required super.title,
    required super.content,
    required this.timeOfDay,
    required this.daysOfWeek,
    super.id,
    super.remindBefore,
  });
  RecurringTodoRule copyWith({
    String? id,
    String? title,
    String? content,
    TimeOfDay? timeOfDay,
    Set<DayOfWeek>? daysOfWeek,
    Duration? remindBefore,
  }) {
    return RecurringTodoRule(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      remindBefore: remindBefore ?? this.remindBefore,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    // Chuyển đổi Set<DayOfWeek> thành List<int> để lưu trữ
    final List<int> daysOfWeekAsInt =
        daysOfWeek.map((day) => day.asWeekday).toList();

    return {
      // id và created_at sẽ được Supabase tự động tạo
      'title': title,
      'content': content,
      'recurrence_type': 'weekly', // Đánh dấu đây là luật lặp lại hàng tuần
      // Chuyển TimeOfDay thành chuỗi 'HH:mm:ss' mà PostgreSQL có thể hiểu
      'time_of_day':
          '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}:00',

      // Chuyển Set thành List để Supabase có thể lưu dưới dạng mảng (array)
      'days_of_week': daysOfWeekAsInt,
      'remind_before': remindBefore?.inMinutes,
    };
  }

  // <<< HÀM MỚI: Tạo Object Dart từ Map lấy về từ Supabase >>>
  factory RecurringTodoRule.fromMap(Map<String, dynamic> map) {
    // Lấy ra danh sách các số nguyên từ Supabase
    final List<int> daysAsInt =
        (map['days_of_week'] as List<dynamic>).cast<int>();
    // Chuyển đổi ngược lại thành Set<DayOfWeek>
    final Set<DayOfWeek> daysOfWeekFromDb =
        daysAsInt.map((dayInt) {
          return DayOfWeek.values.firstWhere(
            (dayEnum) => dayEnum.asWeekday == dayInt,
          );
        }).toSet();
    // Lấy ra chuỗi thời gian (ví dụ: '21:00:00') và phân tích nó
    final timeParts = (map['time_of_day'] as String).split(':');

    return RecurringTodoRule(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      timeOfDay: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      daysOfWeek: daysOfWeekFromDb,
      remindBefore:
          map['remind_before'] != null
              ? _parseDuration(map['remind_before'])
              : null,
    );
  }
}

Duration? _parseDuration(dynamic minutes) {
  if (minutes == null) return null;

  if (minutes is int) {
    return Duration(minutes: minutes);
  }
  if (minutes is String) {
    if (int.tryParse(minutes) != null) {
      return Duration(minutes: int.parse(minutes));
    }
  }

  return null;
}
