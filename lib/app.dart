// lib/app.dart
import 'package:flutter/material.dart';
import 'package:test_athkar_app/screens/home_screen/home_screen.dart'; // استبدل بالشاشة الرئيسية الخاصة بك
import 'package:test_athkar_app/services/app_initializer.dart';

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  
  const MyApp({Key? key, this.navigatorKey}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // فحص وطلب تحسينات الإشعارات بعد تحميل UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationOptimizations();
    });
  }
  
  // فحص تحسينات الإشعارات
  Future<void> _checkNotificationOptimizations() async {
    try {
      // ننتظر بعض الوقت لضمان تحميل التطبيق بالكامل
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted && context.mounted) {
        // فحص إعدادات البطارية وإعدادات عدم الإزعاج
        await AppInitializer.checkNotificationOptimizations(context);
      }
    } catch (e) {
      print('خطأ في فحص تحسينات الإشعارات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق الأذكار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF447055),
        fontFamily: 'Tajawal', // استخدم الخط المناسب لتطبيقك
        appBarTheme: const AppBarTheme(
          color: Color(0xFF447055),
          centerTitle: true,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
      // استخدام مفتاح التنقل من خدمة الإشعارات
      navigatorKey: widget.navigatorKey,
      // الشاشة الرئيسية للتطبيق
      home: const HomeScreen(),
    );
  }
}