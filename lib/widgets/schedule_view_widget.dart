import 'package:calendar_app/data/todo_data_source.dart';
import 'package:calendar_app/models/todo_instance.dart';
import 'package:calendar_app/providers/time_provider.dart';
import 'package:calendar_app/providers/todo_list_provider.dart';
import 'package:calendar_app/shared_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ScheduleViewWidget extends ConsumerStatefulWidget {
  const ScheduleViewWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _ScheduleViewWidgetState();
  }
}

class _ScheduleViewWidgetState extends ConsumerState<ScheduleViewWidget> {
  final CalendarController _calendarController = CalendarController();
  String _headerText = '';

  @override
  Widget build(BuildContext context) {
    final instances = ref.watch(visibleInstancesProvider);
    final todoDataSource = TodoDataSource(instances);
    final selectedRange = ref.watch(selectedDateRangeProvider);
    final DateTime now = ref.watch(currentTimeProvider);

    ref.listen<DateTimeRange?>(selectedDateRangeProvider, (previous, next) {
      if (next != null) {
        _calendarController.displayDate = next.start;
      }
    });

    // <<< Tính toán số ngày hiển thị>>>
    final int dayCount;
    if (selectedRange == null) {
      dayCount = 1; // Mặc định hiển thị 1 ngày
    } else {
      dayCount = selectedRange.end.difference(selectedRange.start).inDays + 1;
    }

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
        _buildCalendarHeader(),
        const Divider(),
        Expanded(
          child: SfCalendar(
            minDate: kStartDate,
            maxDate: kEndDate,
            controller: _calendarController,
            view: CalendarView.week,
            headerHeight: 0,
            allowViewNavigation: true,
            onViewChanged: (ViewChangedDetails viewChangedDetails) {
              // Cập nhật ngày cho provider và text cho header tùy chỉnh
              final firstVisibleDate = viewChangedDetails.visibleDates.first;
              Future.delayed(const Duration(milliseconds: 50), () {
                // Dùng post frame callback để tránh lỗi setState trong lúc build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _headerText = capitalizeFirstLetter(
                        DateFormat(
                          'MMMM, yyyy',
                          'vi_VN',
                        ).format(firstVisibleDate),
                      );
                    });
                    ref.read(displayedDateProvider.notifier).state =
                        firstVisibleDate;
                  }
                });
              });
            },
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
              numberOfDaysInView: dayCount,
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

  // <<< TÍNH NĂNG MỚI: Hàm xây dựng header tùy chỉnh >>>
  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút quay về tuần/ngày trước
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Tuần trước',
            onPressed: () {
              // Ra lệnh cho controller quay về trước
              _calendarController.backward!();
            },
          ),
          // Hiển thị tháng và năm
          Text(
            _headerText,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          // Nút đi tới tuần/ngày tiếp theo
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Tuần sau',
            onPressed: () {
              // Ra lệnh cho controller đi tới
              _calendarController.forward!();
            },
          ),
        ],
      ),
    );
  }
}
