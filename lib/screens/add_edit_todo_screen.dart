import 'package:calendar_app/providers/todo_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendar_app/models/todo.dart';
import 'package:intl/intl.dart';

class AddEditTodoScreen extends ConsumerStatefulWidget {
  final Todo? todo;
  final bool isAddForm;

  const AddEditTodoScreen.add({super.key}) : isAddForm = true, todo = null;

  const AddEditTodoScreen.edit({super.key, required this.todo})
    : isAddForm = false;

  @override
  ConsumerState<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends ConsumerState<AddEditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime _selectedDate;

  bool get isAddForm => widget.isAddForm;

  @override
  void initState() {
    super.initState();
    if (isAddForm == false && widget.todo != null) {
      // Nếu là form sửa, điền dữ liệu cũ.
      _titleController = TextEditingController(text: widget.todo?.title ?? '');
      _contentController = TextEditingController(
        text: widget.todo?.content ?? '',
      );
      _selectedDate = widget.todo?.date ?? DateTime.now();
    } else {
      //Nếu là form thêm, dùng dữ liệu rỗng.
      _titleController = TextEditingController(text: '');
      _contentController = TextEditingController(text: '');
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // <<< TÍNH NĂNG MỚI: Hàm hiển thị DatePicker >>>
  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5, now.month, now.day),
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitTodo() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final content = _contentController.text;

      // <<< THAY ĐỔI: Xử lý logic cho cả Thêm và Sửa >>>
      if (isAddForm) {
        ref.read(todosProvider.notifier).addTodo(title, content, _selectedDate);
      } else {
        final updatedTodo = widget.todo!.copyWith(
          title: title,
          content: content,
          date: _selectedDate,
        );
        ref.read(todosProvider.notifier).updateTodo(updatedTodo);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAddForm ? 'Thêm công việc' : 'Sửa công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: _submitTodo,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: Học bài Flutter',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung',
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: Hoàn thành phần quản lý state với Riverpod',
                  alignLabelWithHint:
                      true, // Căn chỉnh label đẹp hơn với maxLines
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập nội dung';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // <<< TÍNH NĂNG MỚI: Ô chọn ngày >>>
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: _presentDatePicker,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitTodo,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Lưu công việc'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
