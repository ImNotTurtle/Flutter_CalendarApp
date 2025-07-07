import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier này sẽ giữ state là thời gian hiện tại và tự cập nhật
class TimeNotifier extends StateNotifier<DateTime> {
  late final Timer _timer;

  TimeNotifier() : super(DateTime.now()) {
    // Tạo một timer chạy mỗi 5 phút
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      // Cứ sau 5 phút, cập nhật state với thời gian mới nhất
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
final systemTickProvider = StateNotifierProvider<TimeNotifier, DateTime>((
  ref,
) {
  return TimeNotifier();
});



// Provider này cập nhật mỗi giây, chỉ dành cho các widget nhẹ, cần thời gian thực
class SecondlyNotifier extends StateNotifier<DateTime> {
  late final Timer _timer;
  SecondlyNotifier() : super(DateTime.now()) {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = DateTime.now();
    });
  }
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

final secondlyTickProvider = StateNotifierProvider<SecondlyNotifier, DateTime>((ref) {
  return SecondlyNotifier();
});