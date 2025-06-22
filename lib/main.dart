import 'package:calendar_app/providers/notification_provider.dart';
import 'package:calendar_app/screens/home_screen.dart';
import 'package:calendar_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // <<< THAY ĐỔI: Khởi tạo local_notifier >>>
  await localNotifier.setup(
    appName: 'Lịch Công Việc', // Tên ứng dụng của bạn
  );

  final container = ProviderContainer();
  // Kích hoạt observer để bắt đầu lên lịch thông báo
  // Không cần `await` cho việc initialize trong manager nữa
  container.listen(calendarObserverProvider, (_, __) {});

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

// Trong file main.dart

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lịch Tiếng Việt',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi'), // Chỉ cần mã ngôn ngữ là đủ
        Locale('en'), // Tiếng Anh dự phòng
      ],
      locale: const Locale('vi'), // Thiết lập locale mặc định là Tiếng Việt
      theme: ThemeData(colorScheme: darkColorScheme),
      home: const HomeScreen(),
    );
  }
}
