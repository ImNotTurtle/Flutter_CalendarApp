import 'package:calendar_app/models/base_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:calendar_app/providers/service_provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodosNotifier extends AsyncNotifier<List<BaseTodo>> {
  // `build` là hàm khởi tạo. Nó gọi service để lấy dữ liệu ban đầu.
  @override
  Future<List<BaseTodo>> build() async {
    return ref.read(todoServiceProvider).fetchTodos();
  }

  // Phương thức addTodo giờ chỉ gọi service và làm mới lại state
  Future<void> addTodo(BaseTodo todo) async {
    // Đặt state về loading để UI có thể hiển thị chỉ báo
    state = const AsyncValue.loading();
    // Dùng try-catch để xử lý lỗi
    try {
      await ref.read(todoServiceProvider).addTodo(todo);
    } finally {
      // Dù thành công hay thất bại, làm mới lại provider để fetch dữ liệu mới nhất
      ref.invalidateSelf();
    }
  }

  Future<void> updateTodo(BaseTodo todo) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(todoServiceProvider).updateTodo(todo);
    } finally {
      ref.invalidateSelf();
    }
  }

  Future<void> removeTodo(String todoId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(todoServiceProvider).removeTodo(todoId);
    } finally {
      ref.invalidateSelf();
    }
  }

  // Toggle cần tìm todo trước để biết trạng thái hiện tại
  Future<void> toggle(String todoId) async {
    final todoToToggle = state.value?.firstWhereOrNull((t) => t.id == todoId);
    if (todoToToggle == null || todoToToggle is! SingleTodo) return;

    state = const AsyncValue.loading();
    try {
      await ref
          .read(todoServiceProvider)
          .toggleTodo(todoId, todoToToggle.isCompleted);
    } finally {
      ref.invalidateSelf();
    }
  }
}

final todosProvider = AsyncNotifierProvider<TodosNotifier, List<BaseTodo>>(() {
  return TodosNotifier();
});

// Provider để tìm một Todo theo ID
final todoByIdProvider = Provider.family<BaseTodo?, String>((ref, todoId) {
  // Lắng nghe trạng thái bất đồng bộ của provider chính
  final asyncTodos = ref.watch(todosProvider);

  // Dùng .when() để xử lý tất cả các trạng thái một cách an toàn
  return asyncTodos.when(
    // Khi có dữ liệu, thực hiện tìm kiếm trên danh sách `allTodos`
    data: (allTodos) => allTodos.firstWhereOrNull((todo) => todo.id == todoId),

    // Khi đang tải hoặc có lỗi, chúng ta không có dữ liệu để tìm, nên trả về null
    loading: () => null,
    error: (error, stackTrace) => null,
  );
});

// Provider quản lý các ID đang được chọn trong danh sách
final selectedTodosProvider = StateProvider<Set<String>>((ref) => {});
