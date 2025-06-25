import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/base_todo.dart';
import '../services/notification_manager.dart';
import 'todo_provider.dart';

// Provider để truy cập vào NotificationManager
final notificationManagerProvider = Provider((ref) => NotificationManager(ref));

// Provider này không trả về gì, nó chỉ lắng nghe và hành động
final calendarObserverProvider = Provider<void>((ref) {
  // Lắng nghe khi danh sách todo thay đổi (thêm/sửa/xóa)
  ref.listen<List<BaseTodo>>(todosProvider, (previous, next) {
    // Khi có thay đổi, ra lệnh cho NotificationManager lên lịch lại
    ref.read(notificationManagerProvider).scheduleNextNotification();
  }, fireImmediately: true); // fireImmediately để nó chạy ngay lần đầu tiên
});