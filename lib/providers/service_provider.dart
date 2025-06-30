import 'package:calendar_app/services/todo_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Helper client
final supabase = Supabase.instance.client;

// Provider này tạo ra một instance duy nhất của TodoService
final todoServiceProvider = Provider<TodoService>((ref) {
  return TodoService(supabase);
});