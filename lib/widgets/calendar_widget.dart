import 'package:calendar_app/providers/todo_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends ConsumerWidget {
  const CalendarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theo dõi khoảng ngày đang được chọn để cập nhật UI của lịch
    final selectedRange = ref.watch(selectedDateRangeProvider);

    // Định nghĩa các màu sắc để dễ quản lý
    const Color startColor = Colors.lightGreen;
    const Color endColor = Colors.purpleAccent;
    const Color singleDayColor = Colors.amber;
    final Color rangeHighlightColor = Colors.purple.withValues(alpha: 0.15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar(
          locale: 'vi_VN',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay:
              selectedRange?.start ?? DateTime.now(), // Focus vào ngày đã chọn
          rangeSelectionMode: RangeSelectionMode.toggledOn,
          rangeStartDay: selectedRange?.start,
          rangeEndDay: selectedRange?.end,
          onRangeSelected: (start, end, focusedDay) {
            print('selected range: ${start?.toLocal()} to ${end?.toLocal()}');
            ref.read(selectedDateRangeProvider.notifier).state = DateTimeRange(
              start: start!,
              end: end ?? start,
            );
          },
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
              color: Colors.orangeAccent.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
          ),
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

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Bỏ chọn'),
              // Nút sẽ bị vô hiệu hóa nếu không có ngày nào được chọn
              onPressed:
                  selectedRange == null
                      ? null
                      : () {
                        // Đặt lại state của provider về null để xóa lựa chọn
                        ref.read(selectedDateRangeProvider.notifier).state =
                            null;
                      },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),

        // PHẦN CHÚ THÍCH BÊN DƯỚI
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 8.0),
          child:
           Column(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 16.0, // Khoảng cách ngang giữa các mục
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ColorLegendItem(color: startColor, text: 'Bắt đầu'),
              _ColorLegendItem(color: endColor, text: 'Kết thúc'),
              _ColorLegendItem(color: singleDayColor, text: 'Chỉ 1 ngày'),
              _ColorLegendItem(
                color: Colors.orangeAccent.withValues(alpha: 0.5),
                text: 'Hôm nay',
              ),
            ],
          ),
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
