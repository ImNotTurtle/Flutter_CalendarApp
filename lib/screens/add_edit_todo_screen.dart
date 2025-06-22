import 'package:calendar_app/models/base_todo.dart';
import 'package:calendar_app/models/recurring_todo.dart';
import 'package:calendar_app/models/single_todo.dart';
import 'package:calendar_app/providers/todo_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AddEditTodoScreen extends ConsumerStatefulWidget {
  final BaseTodo? todo;
  final bool isAddForm;

  // Constructor cho việc thêm mới: không cần todo
  const AddEditTodoScreen.add({super.key})
      : isAddForm = true,
        todo = null;

  // Constructor cho việc chỉnh sửa: yêu cầu phải có todo
  const AddEditTodoScreen.edit({super.key, required this.todo})
      : isAddForm = false;

  @override
  ConsumerState<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends ConsumerState<AddEditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  // --- State variables cho form ---
  RecurrenceType _recurrenceType = RecurrenceType.daily;
  // Dùng cho SingleTodo
  late DateTime _selectedDateTime;
  // Dùng cho RecurringTodoRule
  late Set<int> _selectedWeekdays;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();

    // Khởi tạo giá trị dựa trên chế độ Add hoặc Edit
    if (widget.isAddForm) {
      // Chế độ Thêm: Lấy thời gian hiện tại làm mặc định
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _selectedDateTime = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _recurrenceType = RecurrenceType.daily;
      _selectedWeekdays = {};
    } else {
      // Chế độ Sửa: Lấy dữ liệu từ `widget.todo`
      final todo = widget.todo!;
      _titleController = TextEditingController(text: todo.title);
      _contentController = TextEditingController(text: todo.content);

      if (todo is SingleTodo) {
        _recurrenceType = RecurrenceType.daily;
        _selectedDateTime = todo.dateTime;
        _selectedTime = TimeOfDay.fromDateTime(todo.dateTime); // Lấy time từ dateTime
        _selectedWeekdays = {}; // Reset giá trị không dùng đến
      } else if (todo is RecurringTodoRule) {
        _recurrenceType = RecurrenceType.weekly;
        _selectedWeekdays = todo.daysOfWeek;
        _selectedTime = todo.timeOfDay;
        _selectedDateTime = DateTime.now(); // Reset giá trị không dùng đến
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _presentDateTimePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _presentTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _submitTodo() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text;
    final content = _contentController.text;

    // Logic xử lý khi nhấn nút Lưu
    if (_recurrenceType == RecurrenceType.daily) {
      final todoToSave = SingleTodo(
        id: widget.isAddForm ? null : widget.todo!.id,
        title: title,
        content: content,
        dateTime: _selectedDateTime,
        isCompleted: widget.isAddForm ? false : (widget.todo! as SingleTodo).isCompleted,
      );
      if (widget.isAddForm) {
        ref.read(todosProvider.notifier).addTodo(todoToSave);
      } else {
        ref.read(todosProvider.notifier).updateTodo(todoToSave);
      }
    } else {
      if (_selectedWeekdays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ít nhất một ngày trong tuần.')),
        );
        return;
      }
      final todoToSave = RecurringTodoRule(
        id: widget.isAddForm ? null : widget.todo!.id,
        title: title,
        content: content,
        daysOfWeek: _selectedWeekdays,
        timeOfDay: _selectedTime,
      );
      if (widget.isAddForm) {
        ref.read(todosProvider.notifier).addTodo(todoToSave);
      } else {
        ref.read(todosProvider.notifier).updateTodo(todoToSave);
      }
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAddForm ? 'Thêm công việc' : 'Sửa công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: _submitTodo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              SegmentedButton<RecurrenceType>(
                segments: const [
                  ButtonSegment(value: RecurrenceType.daily, label: Text('Một lần'), icon: Icon(Icons.calendar_view_day)),
                  ButtonSegment(value: RecurrenceType.weekly, label: Text('Hàng tuần'), icon: Icon(Icons.event_repeat)),
                ],
                selected: {_recurrenceType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _recurrenceType = newSelection.first;
                  });
                },
              ),
              const Divider(height: 32, thickness: 0.5),

              // Hiển thị tùy chọn động dựa trên lựa chọn
              if (_recurrenceType == RecurrenceType.daily)
                _buildSingleEventOptions()
              else
                _buildWeeklyEventOptions(),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _submitTodo,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Lưu công việc'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleEventOptions() {
    return ListTile(
      leading: const Icon(Icons.access_time_filled),
      title: const Text('Thời gian diễn ra'),
      subtitle: Text(DateFormat('HH:mm - EEEE, dd/MM/yyyy', 'vi_VN').format(_selectedDateTime)),
      trailing: const Icon(Icons.edit_calendar_outlined, size: 28),
      onTap: _presentDateTimePicker,
    );
  }

  Widget _buildWeeklyEventOptions() {
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn các ngày trong tuần:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: List.generate(7, (index) {
            final day = index + 1; // 1=Mon, ..., 7=Sun
            final isSelected = _selectedWeekdays.contains(day);
            return FilterChip(
              label: Text(weekdays[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWeekdays.add(day);
                  } else {
                    _selectedWeekdays.remove(day);
                  }
                });
              },
            );
          }),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.watch_later_outlined),
          title: const Text('Thời gian lặp lại'),
          subtitle: Text('Vào lúc: ${_selectedTime.format(context)}'),
          trailing: const Icon(Icons.access_time_outlined, size: 28),
          onTap: _presentTimePicker,
        ),
      ],
    );
  }
}