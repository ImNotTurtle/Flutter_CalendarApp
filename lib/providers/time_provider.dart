import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier này sẽ giữ state là thời gian hiện tại và tự cập nhật
class TimeNotifier extends StateNotifier<DateTime> {
  late final Timer _timer;

  TimeNotifier() : super(DateTime.now()) {
    // Tạo một timer chạy mỗi 10 phút
    _timer = Timer.periodic(const Duration(minutes: 10), (timer) {
      // Cứ sau 10 phút, cập nhật state với thời gian mới nhất
      // Bất kỳ widget nào "watch" provider này sẽ được build lại
      state = DateTime.now();
    });
  }

  // Hủy timer khi provider bị hủy để tránh memory leak
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

// Provider để cung cấp TimeNotifier cho toàn bộ ứng dụng
final currentTimeProvider = StateNotifierProvider<TimeNotifier, DateTime>((
  ref,
) {
  return TimeNotifier();
});
