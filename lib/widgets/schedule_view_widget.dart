import 'package:calendar_app/data/todo_data_source.dart';
import 'package:calendar_app/models/todo_instance.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/time_provider.dart';
import 'package:calendar_app/services/timezone_service.dart';
import 'package:calendar_app/shared_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleViewWidget extends ConsumerStatefulWidget {
  const ScheduleViewWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _ScheduleViewWidgetState();
  }
}

class _ScheduleViewWidgetState extends ConsumerState<ScheduleViewWidget> {
  final CalendarController _calendarController = CalendarController();

  @override
  Widget build(BuildContext context) {
    final instances = ref.watch(visibleInstancesProvider);
    final timezoneManager = ref.read(timezoneManagerProvider);
    final todoDataSource = TodoDataSource(instances, timezoneManager);
    final selectedRange = ref.watch(selectedDateRangeProvider);
    final DateTime now = ref.watch(currentTimeProvider);

    // 1. Lắng nghe khi người dùng chọn một khoảng mới ở panel trái
    ref.listen<DateTimeRange?>(selectedDateRangeProvider, (previous, next) {
      // Khi có khoảng mới, reset trang đang xem về ngày bắt đầu của khoảng đó
      ref.read(schedulePageDateProvider.notifier).state = next?.start;
    });

    // 2. Lắng nghe trang đang xem để ra lệnh cho controller nhảy đến
    ref.listen<DateTime?>(schedulePageDateProvider, (previous, next) {
      if (next != null) {
        _calendarController.displayDate = next;
      }
    });

    // <<< Tính toán view dựa trên số ngày được chọn >>>
    final int dayCount =
        selectedRange == null ? 1 : selectedRange.duration.inDays + 1;
    final int displayDayCount = dayCount > 7 ? 7 : dayCount;

    // <<< Tạo một "vùng" đặc biệt nổi bật cho thời gian hiện tại >>>
    final TimeRegion currentTimeRegion = TimeRegion(
      startTime: now,
      // Tạo một vùng kéo dài 3 phút để dễ nhìn hơn
      endTime: now.add(const Duration(minutes: 3)),
      // Dòng chữ hiển thị bên trong vùng
      text: 'Hiện tại',
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      // Màu nền của vùng được làm nổi bật
      color: Colors.red,
      // Cho phép sự kiện (appointment) vẽ đè lên trên vùng này
      enablePointerInteraction: false,
    );

    return Column(
      children: [
        _buildScheduleToolbar(selectedRange, displayDayCount),

        const Divider(),
        Expanded(
          child: SfCalendar(
            minDate: kStartDate,
            maxDate: kEndDate,
            controller: _calendarController,
            view: CalendarView.week,
            headerHeight: 0,
            allowViewNavigation: false,
            todayHighlightColor: Colors.blue,
            // Dữ liệu sẽ được lấy từ đây
            dataSource: todoDataSource,
            // Bắt đầu tuần từ Thứ Hai
            firstDayOfWeek: 1,
            // Hiển thị ngày giờ hiện tại
            showCurrentTimeIndicator: false,
            // <<< Dùng specialRegions để làm nổi bật thời gian hiện tại >>>
            specialRegions: [currentTimeRegion],
            // Cấu hình cho giao diện timeline
            timeSlotViewSettings: TimeSlotViewSettings(
              numberOfDaysInView: displayDayCount,
              timeInterval: Duration(minutes: 30),
              startHour: 0,
              endHour: 24,
              timeIntervalHeight: 30, // Chiều cao cho mỗi ô 1 tiếng
              timeFormat: 'H:mm', // Định dạng 24h
            ),

            // Tùy chỉnh hiển thị của mỗi sự kiện
            appointmentBuilder: (context, calendarAppointmentDetails) {
              final appointment =
                  calendarAppointmentDetails.appointments.first as TodoInstance;
              final int appointmentIndex = todoDataSource.appointments!.indexOf(
                appointment,
              );
              final Color appointmentColor =
                  appointmentIndex != -1
                      ? todoDataSource.getColor(appointmentIndex)
                      : Colors.purple; // Một màu mặc định nếu có lỗi

              // --- Kiểm tra xem công việc có đang diễn ra không ---
              final DateTime now = DateTime.now();
              final DateTime appointmentStartTime =
                  appointment.concreteDateTime;
              // Mặc định thời lượng là 1 tiếng
              final DateTime appointmentEndTime = appointmentStartTime.add(
                const Duration(hours: 1),
              );

              // Biến để xác định công việc có "live" hay không
              final bool isLive =
                  now.isAfter(appointmentStartTime) &&
                  now.isBefore(appointmentEndTime);

              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: appointmentColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                  // <<< Thêm viền nếu công việc đang diễn ra >>>
                  border:
                      isLive
                          // Nếu đang live, thêm viền màu vàng sáng, dày
                          ? Border.all(color: Colors.yellowAccent, width: 2)
                          // Nếu không, dùng viền trắng mờ như cũ
                          : Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                  // Thêm hiệu ứng đổ bóng để làm nổi bật hơn nữa
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleToolbar(
    DateTimeRange? selectedRange,
    int displayDayCount,
  ) {
    final selectedRange = ref.watch(selectedDateRangeProvider);
    final currentPageDate =
        ref.watch(schedulePageDateProvider) ?? selectedRange?.start;

    // --- Logic để bật/tắt các nút điều hướng ---
    bool canNavigateBackward = false;
    bool canNavigateForward = false;
    // Biến để xác định có đang xem một ngày duy nhất hay không
    bool isSingleDayView = true;

    if (selectedRange != null && currentPageDate != null) {
      isSingleDayView = selectedRange.duration.inDays == 0;

      final displayDayCount =
          isSingleDayView
              ? 1
              : (selectedRange.duration.inDays + 1 > 7
                  ? 7
                  : selectedRange.duration.inDays + 1);

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
          // Nút lùi trang
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
          // Nút tiến trang
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
          const Spacer(),

          // <<< TÍNH NĂNG MỚI: Nút Xem cả tuần >>>
          // Chỉ hiển thị nút này khi đang xem một ngày duy nhất
          if (isSingleDayView)
            TextButton.icon(
              icon: const Icon(Icons.view_week_outlined),
              label: const Text('Xem cả tuần'),
              onPressed: () {
                final currentDay = selectedRange?.start ?? DateTime.now();
                // Tính toán ngày đầu tuần (Thứ 2)
                final startOfWeek = currentDay.subtract(
                  Duration(days: currentDay.weekday - 1),
                );
                // Tính toán ngày cuối tuần (Chủ Nhật)
                final endOfWeek = startOfWeek.add(const Duration(days: 6));

                // Cập nhật lại provider với khoảng thời gian là cả tuần
                ref
                    .read(selectedDateRangeProvider.notifier)
                    .state = DateTimeRange(start: startOfWeek, end: endOfWeek);
              },
            ),
          // Nút chuyển đổi Ngày/Tuần vẫn có thể giữ lại nếu muốn
        ],
      ),
    );
  }
}
