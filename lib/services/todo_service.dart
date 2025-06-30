import 'package:calendar_app/models/base_todo.dart';
import 'package:calendar_app/models/recurring_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TodoService {
  final SupabaseClient _supabase;

  TodoService(this._supabase);

  // Lấy tất cả công việc
  Future<List<BaseTodo>> fetchTodos() async {
    final data = await _supabase.from('todos').select();
    return data.map((row) {
      if (row['recurrence_type'] == 'none') {
        return SingleTodo.fromMap(row);
      } else {
        return RecurringTodoRule.fromMap(row);
      }
    }).toList();
  }

  // Thêm một công việc mới
  Future<void> addTodo(BaseTodo todo) async {
    await _supabase.from('todos').insert(todo.toMap());
  }

  // Cập nhật một công việc
  Future<void> updateTodo(BaseTodo todo) async {
    await _supabase.from('todos').update(todo.toMap()).eq('id', todo.id);
  }

  // Xóa một công việc
  Future<void> removeTodo(String todoId) async {
    await _supabase.from('todos').delete().eq('id', todoId);
  }

  // Đánh dấu hoàn thành
  Future<void> toggleTodo(String todoId, bool currentStatus) async {
    await _supabase
        .from('todos')
        .update({'is_completed': !currentStatus})
        .eq('id', todoId);
  }
}