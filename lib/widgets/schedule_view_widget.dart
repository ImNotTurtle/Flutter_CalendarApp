import 'package:calendar_app/data/todo_data_source.dart';
import 'package:calendar_app/models/todo_instance.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/time_provider.dart';
import 'package:calendar_app/widgets/dialogs/todo_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return SfCalendar(
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
    final now = ref.watch(systemTickProvider);
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

  /// Xử lý sự kiện khi người dùng nhấn vào một appointment trên lịch.
  void _handleCalendarTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.appointment) {
      final tappedInstance = details.appointments!.first as TodoInstance;
      showTodoDetailsDialog(context, tappedInstance);
    }
  }

  /// Hiển thị dialog chi tiết của một công việc.

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

    final DateTime now = ref.read(systemTickProvider);
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
