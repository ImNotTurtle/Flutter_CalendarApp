import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/time_provider.dart';
import 'package:calendar_app/shared_data.dart';
import 'package:calendar_app/utils/date_time_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends ConsumerStatefulWidget {
  const CalendarWidget({super.key});

  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  // State cục bộ chỉ để quản lý tháng/trang đang hiển thị trên TableCalendar
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = ref.read(selectedDateRangeProvider)?.start ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe provider để đồng bộ state cục bộ khi cần
    ref.listen<DateTimeRange?>(selectedDateRangeProvider, (previous, next) {
      if (next != null && !next.start.isSameMonth(_focusedDay)) {
        // Nếu ngày được chọn nằm ở tháng khác, cập nhật lại tháng đang hiển thị
        setState(() {
          _focusedDay = next.start;
        });
      }
    });

    final selectedRange = ref.watch(selectedDateRangeProvider);

    // Định nghĩa các màu sắc để dễ quản lý
    const Color startColor = Colors.purpleAccent;
    const Color endColor = Colors.purpleAccent;
    const Color todayColor = Colors.blue;
    const Color singleDayColor = Colors.amber;
    final Color rangeHighlightColor = Colors.purple.withValues(alpha: 0.25);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref, _focusedDay),
            const SizedBox(height: 8),
            TableCalendar(
              locale: 'vi_VN',
              firstDay: kStartDate,
              lastDay: kEndDate,
              focusedDay: _focusedDay,
              headerVisible: false,
              rangeStartDay: selectedRange?.start,
              rangeEndDay: selectedRange?.end,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                rangeHighlightColor: rangeHighlightColor,
                rangeStartDecoration: const BoxDecoration(
                  color: startColor,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: const BoxDecoration(
                  color: endColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: todayColor,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              // <<< Logic khi người dùng chọn ngày >>>
              onRangeSelected: (start, end, newFocusedDay) {
                if (start == null) {
                  // Nếu người dùng bỏ chọn, không làm gì
                  return;
                }
                ref
                    .read(selectedDateRangeProvider.notifier)
                    .state = DateTimeRange(start: start, end: end ?? start);
              },
              onPageChanged: (focusedDay) {
                // Khi lướt tay, chỉ thay đổi state cục bộ để lật trang.
                // KHÔNG cập nhật provider ở đây để tránh vòng lặp lỗi.
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              // <<< Xây dựng UI trên lịch cho mỗi sự kiện>>>
              calendarBuilders: CalendarBuilders(
                prioritizedBuilder: (context, day, focusedDay) {
                  if (selectedRange != null &&
                      isSameDay(day, selectedRange.start) &&
                      isSameDay(day, selectedRange.end)) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: singleDayColor,
                        shape: BoxShape.circle,
                      ),
                      margin: const EdgeInsets.all(6.0),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),

            Divider(),

            // <<< Nút "Hôm nay" và "Bỏ chọn" >>>
            _buildNavigateButtons(ref, selectedRange),

            // PHẦN CHÚ THÍCH BÊN DƯỚI
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 16.0, // Khoảng cách ngang giữa các mục
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ColorLegendItem(color: startColor, text: 'Khoảng thời gian'),
                  _ColorLegendItem(color: singleDayColor, text: 'Chỉ 1 ngày'),
                  _ColorLegendItem(color: todayColor, text: 'Hôm nay'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header tùy chỉnh ---
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    DateTime focusedDay,
  ) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_left),
          tooltip: 'Tháng trước',
          onPressed: () {
            // <<< Chỉ cập nhật state cục bộ để lật trang >>>
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
            });
          },
        ),
        const Spacer(),
        Text(
          DateFormat('LLLL yyyy', 'vi_VN').format(focusedDay),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_right),
          tooltip: 'Tháng sau',
          onPressed: () {
            // <<< Chỉ cập nhật state cục bộ để lật trang >>>
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
            });
          },
        ),
      ],
    );
  }

  Widget _buildNavigateButtons(WidgetRef ref, DateTimeRange? selectedRange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.today),
          label: const Text('Hôm nay'),
          onPressed: () {
            final today = ref.read(currentTimeProvider).normalized;
            ref.read(selectedDateRangeProvider.notifier).state = DateTimeRange(
              start: today,
              end: today,
            );
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.clear_all_outlined),
          label: const Text('Bỏ chọn'),
          onPressed:
              selectedRange == null
                  ? null
                  : () {
                    ref.read(selectedDateRangeProvider.notifier).state = null;
                  },
        ),
      ],
    );
  }
}

// Widget con để hiển thị một mục trong chú thích (giúp code gọn gàng)
class _ColorLegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _ColorLegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:
          MainAxisSize.min, // Giúp Row chỉ chiếm đủ không gian cần thiết
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
