import 'dart:async';
import 'package:calendar_app/providers/time_provider.dart';
import 'package:calendar_app/widgets/dialogs/todo_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/status_bar_provider.dart';
import '../models/todo_instance.dart';
// Bạn cần di chuyển hàm _showTodoDetailsDialog ra một file utils hoặc widget riêng để có thể gọi từ đây
// Hoặc tạm thời sao chép nó vào đây.

class GlobalStatusBar extends ConsumerStatefulWidget {
  const GlobalStatusBar({super.key});

  @override
  ConsumerState<GlobalStatusBar> createState() => _GlobalStatusBarState();
}

class _GlobalStatusBarState extends ConsumerState<GlobalStatusBar> {
  Timer? _timer;
  Duration? _timeUntilNext;

  @override
  void initState() {
    super.initState();
    // Tạo timer cập nhật countdown mỗi giây
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final nextNotification = ref.read(nextNotificationProvider);
    if (nextNotification.nextNotificationTime != null) {
      final newDuration = nextNotification.nextNotificationTime!.difference(
        DateTime.now(),
      );
      if (mounted && newDuration != _timeUntilNext) {
        setState(() {
          _timeUntilNext = newDuration;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "Đã qua";
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(secondlyTickProvider);
    final nextNotification = ref.watch(nextNotificationProvider);
    final upcomingInstances = nextNotification.upcomingInstances;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Thời gian hiện tại
          Icon(
            Icons.access_time,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('HH:mm:ss', 'vi_VN').format(now),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const VerticalDivider(width: 24),

          // Thông tin todo tiếp theo
          Expanded(
            child:
                upcomingInstances.isEmpty
                    ? const Text('Không có công việc nào sắp tới.')
                    : Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          size: 20,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tiếp theo: ${upcomingInstances.first.title}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _timeUntilNext != null
                              ? _formatDuration(_timeUntilNext!)
                              : '...',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
          ),

          // Nút xem chi tiết
          if (upcomingInstances.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: TextButton.icon(
                icon: const Icon(Icons.list_alt),
                label: Text('Xem (${upcomingInstances.length})'),
                onPressed:
                    () => _showUpcomingTodosSheet(context, upcomingInstances),
              ),
            ),
        ],
      ),
    );
  }

  void _showUpcomingTodosSheet(
    BuildContext context,
    List<TodoInstance> instances,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => ListView.builder(
            itemCount: instances.length,
            itemBuilder: (listCtx, index) {
              final instance = instances[index];
              return ListTile(
                leading: Icon(
                  instance.isRecurring ? Icons.event_repeat : Icons.event,
                ),
                title: Text(instance.title),
                subtitle: Text(
                  DateFormat(
                    'HH:mm',
                    'vi_VN',
                  ).format(instance.concreteDateTime),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  // Gọi hàm hiển thị dialog chi tiết (cần được refactor để truy cập được từ đây)
                  showTodoDetailsDialog(context, instance);
                },
              );
            },
          ),
    );
  }
}
