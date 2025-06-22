import 'package:calendar_app/models/base_todo.dart';
import 'package:calendar_app/models/recurring_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:flutter/material.dart';

// Lấy thời gian hiện tại làm mốc
final now = DateTime.now();

// Danh sách dữ liệu mẫu mới để kiểm tra thông báo
final List<BaseTodo> sampleTodos = [
  // ================================================================
  // NHÓM TODO ĐỂ TEST THÔNG BÁO NGAY LẬP TỨC
  // ================================================================
  SingleTodo(
    title: 'Các todo dành cho calendar app',
    content: 'Không có todo hẹ hẹ hẹ',
    dateTime: now.add(
      const Duration(minutes: 1),
    ), // <<< Sẽ thông báo sau 5 phút
  ),
  SingleTodo(
    title: 'Các lỗi dành cho calendar app',
    content: 'Không có lỗi hẹ hẹ hẹ',
    dateTime: now.add(
      const Duration(minutes: 2),
    ), // <<< Sẽ thông báo sau 5 phút
  ),
  SingleTodo(
    title: 'Gọi điện cho khách hàng A',
    content: 'Xác nhận lại các yêu cầu.',
    dateTime: now.add(
      const Duration(minutes: 2, seconds: 30),
    ), // <<< Sẽ thông báo sau 10 phút
  ),
  SingleTodo(
    title: 'Kiểm tra email quan trọng',
    content: 'Kiểm tra email từ đối tác về hợp đồng.',
    dateTime: now.add(
      const Duration(minutes: 2),
    ), // <<< Trùng giờ với sự kiện trên
  ),
  SingleTodo(
    title: 'Nộp báo cáo tuần',
    content: 'Gửi báo cáo cho quản lý.',
    dateTime: now.add(
      const Duration(minutes: 3, seconds: 30),
    ), // <<< Sẽ thông báo sau 20 phút
  ),

  // ================================================================
  // NHÓM TODO LẶP LẠI ĐỂ KIỂM TRA HIỂN THỊ
  // ================================================================
  RecurringTodoRule(
    title: 'Tập thể dục',
    content: 'Chạy bộ 30 phút quanh công viên.',
    timeOfDay: const TimeOfDay(hour: 6, minute: 30),
    // Sẽ hiển thị vào các ngày T3, T5, T7 trong tuần
    daysOfWeek: {2, 4, 6},
  ),
  RecurringTodoRule(
    title:
        'Học toán thầy Đạt', // đừng thay đổi nội dung và thời gian của todo này
    content: 'Đăng nhập vào Classin và tham gia lớp học',
    timeOfDay: const TimeOfDay(hour: 21, minute: 0),
    // Sẽ hiển thị vào các ngày T3, T5, T7 trong tuần
    daysOfWeek: {2, 4, 6},
  ),
  RecurringTodoRule(
    title: 'Lên kế hoạch tuần mới',
    content: 'Xem lại các mục tiêu và sắp xếp công việc.',
    timeOfDay: const TimeOfDay(hour: 20, minute: 0),
    // Sẽ hiển thị vào mỗi Chủ Nhật
    daysOfWeek: {7},
  ),

  // ================================================================
  // MỘT TODO TRONG QUÁ KHỨ ĐỂ ĐẢM BẢO NÓ KHÔNG ĐƯỢC LÊN LỊCH
  // ================================================================
  SingleTodo(
    title: 'Task đã hoàn thành',
    content: 'Việc này đã xảy ra 2 tiếng trước.',
    dateTime: now.subtract(const Duration(hours: 2)),
    isCompleted: true,
  ),
];
