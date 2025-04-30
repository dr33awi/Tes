import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ignore_for_file: unused_import

import 'package:test_athkar_app/screens/athkar_screen/athkar_screen.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart';
import 'package:test_athkar_app/screens/home_screen/home_screen.dart';
import 'package:test_athkar_app/models/daily_quote_model.dart';
import 'package:test_athkar_app/services/daily_quote_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق الأذكار',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [

      ],
      theme: ThemeData(
        primaryColor: const Color(0xFF447055),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF447055),
          secondary: const Color(0xFF447055),
          background: const Color(0xFFE7E8E3),
        ),
        scaffoldBackgroundColor: const Color(0xFFE7E8E3),
        fontFamily: 'Cairo', // Make sure to add this font in pubspec.yaml
      ),
      home: const HomeScreen(),
    );
  }
}