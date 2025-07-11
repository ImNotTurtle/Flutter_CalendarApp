import 'main_web.dart' as web_app;
import 'main_desktop.dart' as desktop_app;

// --- BIẾN ĐIỀU KHIỂN ---
// Thay đổi giá trị này để chạy phiên bản tương ứng trong lúc phát triển.
// Các giá trị hợp lệ: 'web', 'desktop'
// const String environment = 'desktop';
// build: flutter build windows -t lib/main_desktop.dart
const String environment = 'web';
// build: flutter build web -t lib/main_web.dart

void main() {
  // Dựa vào biến `environment` để gọi đúng hàm main() tương ứng
  switch (environment) {
    case 'web':
      print('--- Running WEB version ---');
      web_app.main();
      break;
    case 'desktop':
    default:
      print('--- Running DESKTOP version ---');
      desktop_app.main();
      break;
  }
}