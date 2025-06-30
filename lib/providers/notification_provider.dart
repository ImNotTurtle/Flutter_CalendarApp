import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/base_todo.dart';
import '../services/notification_manager.dart';
import 'todo_provider.dart';

// Provider để truy cập vào NotificationManager
final notificationManagerProvider = Provider((ref) => NotificationManager(ref));

// Provider này không trả về gì, nó chỉ lắng nghe và hành động
final calendarObserverProvider = Provider<void>((ref) {
  // Lắng nghe khi danh sách todo thay đổi (thêm/sửa/xóa)
  ref.listen<AsyncValue<List<BaseTodo>>>(
    todosProvider,
    (previous, next) {
      // <<< Chỉ lên lịch lại khi có dữ liệu mới (không phải lúc đang loading hay lỗi) >>>
      // `next.hasValue` là cách kiểm tra an toàn xem state có phải là AsyncData hay không.
      if (next.hasValue && !next.isLoading) {
        // Khi có thay đổi và có dữ liệu, ra lệnh cho NotificationManager lên lịch lại
        ref.read(notificationManagerProvider).scheduleNextNotification();
      }
    },
    fireImmediately: true,
  ); // fireImmediately để nó chạy ngay lần đầu tiên khi có dữ liệu
});
