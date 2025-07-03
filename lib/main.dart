import 'package:calendar_app/providers/notification_provider.dart';
import 'package:calendar_app/screens/home_screen.dart';
import 'package:calendar_app/secret.dart';
import 'package:calendar_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/*

*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonkey);

  // <<< Khởi tạo local_notifier >>>
  await localNotifier.setup(appName: 'Lịch Công Việc');

  final container = ProviderContainer();

  // Kích hoạt observer để bắt đầu lên lịch thông báo
  container.listen(calendarObserverProvider, (_, __) {});

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

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
      supportedLocales: const [Locale('vi'), Locale('en')],
      locale: const Locale('vi'), // Thiết lập locale mặc định là Tiếng Việt
      theme: darkTheme,
      home: const HomeScreen(),
    );
  }
}
