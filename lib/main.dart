// lib/main.dart - تعديلات للإشعارات
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_athkar_app/screens/home_screen/home_screen.dart';
import 'package:test_athkar_app/services/adhan_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  // تأكد من تهيئة Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // تحديد اتجاه الشاشة
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // تهيئة خدمة الإشعارات
  final adhanNotificationService = AdhanNotificationService();
  await adhanNotificationService.initialize();
  
  // طلب إذن الإشعارات على أندرويد 13 وما فوق
  if (Theme.of(context, nullOk: true) == null) {
    // إذا لم يكن هناك سياق، يجب إنشاء سياق مؤقت
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
  
  // تشغيل التطبيق
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // حجم التصميم الأصلي للتطبيق
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'تطبيق الأذكار',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [
            Locale('ar', ''),
            Locale('en', ''),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            primaryColor: const Color(0xFF447055),
            colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: const Color(0xFF447055),
              secondary: const Color(0xFF447055),
              background: const Color(0xFFE7E8E3),
            ),
            scaffoldBackgroundColor: const Color(0xFFE7E8E3),
            fontFamily: 'Cairo',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF447055),
              centerTitle: true,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}