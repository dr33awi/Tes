// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_athkar_app/screens/home_screen/home_screen.dart';
import 'package:test_athkar_app/services/di_container.dart';
import 'package:test_athkar_app/services/notification/notification_manager.dart';
import 'package:test_athkar_app/services/notification/notification_navigation.dart';
import 'package:test_athkar_app/services/app_initializer.dart';


import 'package:test_athkar_app/screens/athkarscreen/screen/notification_settings_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set screen orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // تهيئة التطبيق بالكامل (تتضمن DI container والإشعارات)
  final initSuccess = await AppInitializer.initialize();
  
  if (!initSuccess) {
    print('تحذير: فشلت بعض عمليات التهيئة، لكن التطبيق سيستمر');
  }
  
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // التحقق من التحسينات بعد بناء الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppInitializer.checkNotificationOptimizations(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // التحقق من الإشعارات عند استئناف التطبيق
      AppInitializer.checkAndRescheduleNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Original design size
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'تطبيق الأذكار',
          debugShowCheckedModeBanner: false,
          navigatorKey: AppInitializer.getNavigatorKey(),
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
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF447055)),
              titleTextStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // إضافة المسارات المحتاجة
          routes: {
            '/': (context) => const HomeScreen(),
            '/notification_settings': (context) => const NotificationSettingsScreen(),
          },
          // تكوين التنقل من الإشعارات
          onGenerateRoute: _onGenerateRoute,
        );
      },
    );
  }
  
  // دالة مساعدة للتنقل من الإشعارات
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    // يمكن إضافة منطق تنقل مخصص هنا إذا لزم الأمر
    return null;
  }
}