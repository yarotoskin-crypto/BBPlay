import 'package:flutter/material.dart';
import 'package:test1/app_router.dart';
import 'package:test1/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Инициализируем AuthService, чтобы загрузить данные из SharedPreferences
  await AuthService().isLoggedIn();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BBPlay',
      theme: ThemeData(
        brightness: Brightness.light,

        // Основной тёмно-серый фон
        scaffoldBackgroundColor: const Color.fromARGB(255, 29, 29, 29),

        // Акцентные цвета
        primaryColor: const Color.fromARGB(255, 123, 13, 143),
        colorScheme: const ColorScheme.light(
          primary: Color.fromARGB(255, 123, 13, 143),       // фиолетовый
          secondary: Color.fromARGB(255, 76, 175, 80),     // зелёный
          surface: Color.fromARGB(255, 29, 29, 29),       // тёмно-серый для карточек
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),

        // Стиль карточек
        cardTheme: CardThemeData(
          color: const Color.fromARGB(255, 40, 40, 40),   // тёмно-серые карточки
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(8),
        ),

        // Стиль AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 123, 13, 143),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),

        // Стиль кнопок
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 123, 13, 143),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Стиль нижней навигации
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromARGB(255, 21, 21, 21),
          selectedItemColor: Color.fromARGB(255, 123, 13, 143),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // Стиль индикатора загрузки
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color.fromARGB(255, 123, 13, 143),
        ),

        // Шрифты с белым текстом для тёмного фона
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFFBDBDBD),
          ),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}