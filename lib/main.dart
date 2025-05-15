// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_athkar_app/screens/home_screen/home_screen.dart';
import 'package:test_athkar_app/services/app_initializer.dart';
import 'package:test_athkar_app/services/notification/notification_navigation.dart';
import 'package:test_athkar_app/screens/athkarscreen/screen/notification_settings_screen.dart';
import 'package:test_athkar_app/adhan/screens/prayer_times_screen.dart';
import 'package:test_athkar_app/adhan/screens/prayer_settings_screen.dart';
import 'package:test_athkar_app/adhan/screens/notification_settings_screen.dart' as prayer;

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
          navigatorKey: NotificationNavigation.navigatorKey,
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
            '/prayer_times': (context) => const PrayerTimesScreen(),
            '/prayer_settings': (context) => const PrayerSettingsScreen(),
            '/prayer_notification_settings': (context) => const prayer.NotificationSettingsScreen(),
          },
          // تكوين التنقل من الإشعارات
          onGenerateRoute: _onGenerateRoute,
        );
      },
    );
  }
  
  // دالة مساعدة للتنقل من الإشعارات
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    // التعامل مع مسارات الأذكار المخصصة
    if (settings.name == '/athkar_category') {
      final args = settings.arguments as Map<String, dynamic>?;
      
      return MaterialPageRoute(
        builder: (context) {
          // هنا يمكن إضافة شاشة فئة الأذكار إذا كانت موجودة
          // مثال: return AthkarCategoryScreen(categoryId: args?['categoryId']);
          
          // حالياً نعود للصفحة الرئيسية مع رسالة
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم النقر على إشعار الأذكار: ${args?['categoryId']}'),
              ),
            );
          });
          return const HomeScreen();
        },
      );
    }
    
    // التعامل مع مسارات الصلاة المخصصة مع معاملات
    if (settings.name == '/prayer_times_detail') {
      final args = settings.arguments as Map<String, dynamic>?;
      final prayerName = args?['prayer'] as String?;
      
      return MaterialPageRoute(
        builder: (context) => PrayerTimesScreen(),
        settings: RouteSettings(
          arguments: {'prayer': prayerName},
        ),
      );
    }
    
    // إضافة مسارات أخرى حسب الحاجة
    switch (settings.name) {
      case '/about':
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('حول التطبيق'),
            ),
            body: const Center(
              child: Text('صفحة حول التطبيق'),
            ),
          ),
        );
      
      // يمكن إضافة المزيد من المسارات هنا
    }
    
    return null;
  }
}