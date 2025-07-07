import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enum để định nghĩa các loại view chính
enum MainViewType { schedule, list }

// Provider để quản lý xem người dùng đang ở view nào
// Mặc định là xem lịch trình (schedule)
final mainViewProvider = StateProvider<MainViewType>((ref) => MainViewType.schedule);

// Provider để lưu trữ từ khóa tìm kiếm mà người dùng nhập
final todoSearchQueryProvider = StateProvider<String>((ref) => '');