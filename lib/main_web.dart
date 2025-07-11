import 'package:calendar_app/screens/home_screen.dart';
import 'package:calendar_app/secret.dart';
import 'package:calendar_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Đảm bảo các binding của Flutter đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Supabase cho web (đơn giản hơn)
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonkey);

  // Chỉ cần chạy ứng dụng bên trong một ProviderScope tiêu chuẩn
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
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