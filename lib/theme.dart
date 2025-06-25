import 'package:flutter/material.dart';

final lightColorScheme = ColorScheme.light(
  primary: Color(0xFF4A90E2),
  secondary: Color(0xFF50E3C2),
  surface: Color(0xFFFFFFFF),
  // background: Color(0xFFF7F8FC),
  error: Color(0xFFDC3545),
  onPrimary: Colors.white,
  onSecondary: Colors.black,
  onSurface: Color(0xFF1D252D),
  // onBackground: Color(0xFF1D252D),
  onError: Colors.white,
);

final darkColorScheme = ColorScheme.dark(
  // primary: Color(0xFF58A6FF),
  primary: Color(0xFF03DAC6),
  // secondary: Color(0xFF50E3C2),
  secondary: Color(0xFFBB86FC),
  surface: Color(0xFF1E1E1E),
  // background: Color(0xFF121212),
  error: Color(0xFFFF6B6B),
  onPrimary: Colors.black,
  onSecondary: Colors.black,
  onSurface: Color(0xFFEAEAEA),
  // onBackground: Color(0xFFEAEAEA),
  onError: Colors.black,
);

final darkTheme = ThemeData(
  colorScheme: darkColorScheme,
  scaffoldBackgroundColor: Color(0xFF121212),
  cardColor: Color(0xFF1E1E1E),
  
);
