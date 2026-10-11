import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'splash_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Palette.bg,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const CropMedicApp());
}

class CropMedicApp extends StatelessWidget {
  const CropMedicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropMedic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Palette.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Palette.primary,
          brightness: Brightness.light,
          primary: Palette.primary,
          secondary: Palette.gold,
          surface: Palette.surface,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Palette.text,
              displayColor: Palette.text,
            ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
