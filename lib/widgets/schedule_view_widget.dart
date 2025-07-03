import 'package:calendar_app/data/todo_data_source.dart';
import 'package:calendar_app/models/todo_instance.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/time_provider.dart';
import 'package:calendar_app/providers/todo_provider.dart';
import 'package:calendar_app/screens/add_edit_todo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ScheduleViewWidget extends ConsumerStatefulWidget {
  const ScheduleViewWidget({super.key});

  @override
  ConsumerState<ScheduleViewWidget> createState() => _ScheduleViewWidgetState();
}

class _ScheduleViewWidgetState extends ConsumerState<ScheduleViewWidget> {
  final CalendarController _calendarController = CalendarController();

  @override
  Widget build(BuildContext context) {
    // 1. Chỉ lắng nghe state, không tính toán logic phức tạp ở đây
    final instances = ref.watch(visibleInstancesProvider);
    final selectedRange = ref.watch(selectedDateRangeProvider);
    final todoDataSource = TodoDataSource(instances);

    // 2. Các side-effect được xử lý bằng ref.listen
    _setupControllerListeners();

    // 3. Logic hiển thị được suy ra từ các hàm helper
    final int displayDayCount = _calculateDisplayDayCount(selectedRange);

    return Column(
      children: [
        // 4. Các phần UI được tách thành các hàm build riêng biệt
        _buildToolbar(selectedRange, displayDayCount),
        const Divider(height: 1),
        Expanded(
          child: SfCalendar(
            key: ValueKey('${selectedRange?.toString()}_${instances.hashCode}'),
            controller: _calendarController,
            view: CalendarView.week,
            dataSource: todoDataSource,
            allowViewNavigation: false,
            headerHeight: 0,
            firstDayOfWeek: 1,
            showCurrentTimeIndicator: false,
            specialRegions: [_buildCurrentTimeRegion()],
            timeSlotViewSettings: TimeSlotViewSettings(
              numberOfDaysInView: displayDayCount,
              startHour: 0,
              endHour: 24,
              timeInterval: Duration(minutes: 30),
              timeIntervalHeight: 30,
              timeFormat: 'H:mm',
            ),
            appointmentBuilder:
                (context, details) =>
                    _buildAppointment(context, details, todoDataSource),
            onTap: _handleCalendarTap,
          ),
        ),
      ],
    );
  }

  /// Thiết lập các listener để đồng bộ hóa controller với state từ provider.
  void _setupControllerListeners() {
    ref.listen<DateTimeRange?>(selectedDateRangeProvider, (previous, next) {
      ref.read(schedulePageDateProvider.notifier).state = next?.start;
    });

    ref.listen<DateTime?>(schedulePageDateProvider, (previous, next) {
      if (next != null && _calendarController.displayDate != next) {
        _calendarController.displayDate = next;
      }
    });
  }

  /// Tính toán số ngày thực tế sẽ được hiển thị trên lịch.
  int _calculateDisplayDayCount(DateTimeRange? selectedRange) {
    if (selectedRange == null) return 1;
    final duration = selectedRange.duration.inDays + 1;
    // Giới hạn chỉ hiển thị tối đa 7 ngày để tránh lỗi UI
    return duration > 7 ? 7 : duration;
  }

  /// Xây dựng vùng thời gian đặc biệt để chỉ thị thời gian hiện tại.
  TimeRegion _buildCurrentTimeRegion() {
    final now = ref.watch(currentTimeProvider);
    return TimeRegion(
      startTime: now,
      endTime: now.add(const Duration(minutes: 2)),
      text: 'Hiện tại',
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      color: Colors.red.withValues(alpha: 0.5),
      enablePointerInteraction: false,
    );
  }

  /// Xây dựng thanh công cụ chứa các nút điều hướng.
  Widget _buildToolbar(DateTimeRange? selectedRange, int displayDayCount) {
    final currentPageDate = ref.watch(schedulePageDateProvider);

    bool canNavigateBackward = false;
    bool canNavigateForward = false;
    bool isSingleDayView = true;

    if (selectedRange != null && currentPageDate != null) {
      isSingleDayView = selectedRange.duration.inDays == 0;
      canNavigateBackward = !isSameDay(currentPageDate, selectedRange.start);
      final nextPageStart = currentPageDate.add(
        Duration(days: displayDayCount),
      );
      canNavigateForward =
          nextPageStart.isBefore(selectedRange.end) ||
          isSameDay(nextPageStart, selectedRange.end);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Trang trước',
            onPressed:
                !canNavigateBackward
                    ? null
                    : () {
                      final newPageDate = currentPageDate!.subtract(
                        Duration(days: displayDayCount),
                      );
                      ref.read(schedulePageDateProvider.notifier).state =
                          newPageDate;
                    },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Trang sau',
            onPressed:
                !canNavigateForward
                    ? null
                    : () {
                      final newPageDate = currentPageDate!.add(
                        Duration(days: displayDayCount),
                      );
                      ref.read(schedulePageDateProvider.notifier).state =
                          newPageDate;
                    },
          ),
          const Spacer(),
          if (isSingleDayView)
            TextButton.icon(
              icon: const Icon(Icons.view_week_outlined),
              label: const Text('Xem cả tuần'),
              onPressed: () {
                final currentDay = selectedRange?.start ?? DateTime.now();
                final startOfWeek = currentDay.subtract(
                  Duration(days: currentDay.weekday - 1),
                );
                final endOfWeek = startOfWeek.add(const Duration(days: 6));
                ref
                    .read(selectedDateRangeProvider.notifier)
                    .state = DateTimeRange(start: startOfWeek, end: endOfWeek);
              },
            ),
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: 'Thêm công việc mới',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (ctx) => AddEditTodoScreen.add(
                        // Lấy ngày đang được chọn trên lịch làm ngày mặc định
                        // Nếu chưa có ngày nào được chọn, lấy ngày hôm nay
                        initialDate:
                            ref.read(selectedDateRangeProvider)?.start ??
                            DateTime.now(),
                      ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Xử lý sự kiện khi người dùng nhấn vào một appointment trên lịch.
  void _handleCalendarTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.appointment) {
      final tappedInstance = details.appointments!.first as TodoInstance;
      _showTodoDetailsDialog(tappedInstance);
    }
  }

  /// Hiển thị dialog chi tiết của một công việc.
  void _showTodoDetailsDialog(TodoInstance instance) {
    final originalTodo = ref.read(todoByIdProvider(instance.originalId));
    final localDateTime = instance.concreteDateTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ), // Đặt chiều rộng tối đa
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Để Column co lại theo nội dung
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon được đặt trong một CircleAvatar
                      CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          instance.isRecurring
                              ? Icons.event_repeat
                              : Icons.event,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Tiêu đề công việc
                      Expanded(
                        child: Text(
                          instance.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Nội dung công việc
                  if (instance.content.isNotEmpty)
                    Text(
                      instance.content,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),

                  if (instance.content.isNotEmpty) const SizedBox(height: 24),

                  // Thời gian diễn ra
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Colors.grey,
                    ),
                    title: Text(
                      DateFormat('HH:mm', 'vi_VN').format(localDateTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      DateFormat(
                        'EEEE, dd MMMM, yyyy',
                        'vi_VN',
                      ).format(localDateTime),
                    ),
                  ),

                  // Trạng thái hoàn thành (chỉ cho SingleTodo)
                  if (!instance.isRecurring)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        instance.isCompleted ?? false
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                            instance.isCompleted ?? false
                                ? Colors.green
                                : Colors.grey,
                      ),
                      title: Text(
                        instance.isCompleted ?? false
                            ? 'Đã hoàn thành'
                            : 'Chưa hoàn thành',
                      ),
                    ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(width: 8),
                      if (originalTodo != null) ...[
                        // Nút xóa được làm nổi bật hơn
                        TextButton.icon(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          label: const Text('Xóa'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(); // Đóng dialog trước
                            // Có thể thêm 1 dialog xác nhận xóa ở đây
                            ref
                                .read(todosProvider.notifier)
                                .removeTodo(originalTodo.id);
                          },
                        ),
                        const SizedBox(width: 8),
                        // Nút sửa là nút chính
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Sửa'),
                          onPressed: () {
                            Navigator.of(context).pop(); // Đóng dialog trước
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => AddEditTodoScreen.edit(
                                      todo: originalTodo,
                                    ),
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        TextButton(
                          child: const Text('Đóng'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Xây dựng giao diện cho mỗi khối sự kiện (appointment).
  Widget _buildAppointment(
    BuildContext context,
    CalendarAppointmentDetails details,
    TodoDataSource todoDataSource,
  ) {
    final appointment = details.appointments.first as TodoInstance;
    final int appointmentIndex = todoDataSource.appointments!.indexOf(
      appointment,
    );
    final Color appointmentColor =
        appointmentIndex != -1
            ? todoDataSource.getColor(appointmentIndex)
            : Colors.purple;

    final DateTime now = ref.read(currentTimeProvider);
    final DateTime appointmentStartTime = appointment.concreteDateTime;
    final DateTime appointmentEndTime = appointmentStartTime.add(
      const Duration(hours: 1),
    );
    final bool isLive =
        now.isAfter(appointmentStartTime) && now.isBefore(appointmentEndTime);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: appointmentColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
        border:
            isLive
                ? Border.all(color: Colors.yellowAccent, width: 2)
                : Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 0.5,
                ),
        boxShadow:
            isLive
                ? [
                  BoxShadow(
                    color: Colors.yellowAccent.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
                : [],
      ),
      child: Text(
        appointment.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 3,
      ),
    );
  }

  // Helper để so sánh ngày
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
