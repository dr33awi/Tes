// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_athkar_app/services/app_initializer.dart';
import 'package:test_athkar_app/services/notification/notification_navigation.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/screens/home_screen/home_screen.dart'; // قم بتعديلها للشاشة الرئيسية الخاصة بك

// خدمة تسجيل الأخطاء
final ErrorLoggingService _errorLoggingService = ErrorLoggingService();

// معالج الأخطاء العامة غير المتوقعة
void _handleError(Object error, StackTrace stack) {
  print('حدث خطأ غير متوقع: $error');
  print(stack);
  
  // تسجيل الخطأ باستخدام خدمة تسجيل الأخطاء
  _errorLoggingService.logError(
    'Application', 
    'حدث خطأ غير متوقع في التطبيق', 
    error, 
    stackTrace: stack
  );
}

void main() {
  // التقاط جميع الأخطاء غير المعالجة
  runZonedGuarded<Future<void>>(() async {
    // تهيئة Flutter (داخل نفس المنطقة)
    WidgetsFlutterBinding.ensureInitialized();
    
    // إعداد اتجاه الشاشة
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // إعداد معالجة الأخطاء العامة
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _handleError(details.exception, details.stack ?? StackTrace.current);
    };
    
    // تهيئة خدمات التطبيق قبل تشغيل التطبيق
    await AppInitializer.initialize();
    
    // تشغيل التطبيق مع استخدام مفتاح التنقل من خدمة الإشعارات
    runApp(const MyApp());
  }, _handleError);
}

// كلاس التطبيق الرئيسي
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // حالة التطبيق
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    
    // إضافة مراقب لدورة حياة التطبيق
    WidgetsBinding.instance.addObserver(this);
    
    // تهيئة التطبيق
    _initializeApp();
    
    // فحص تحسينات الإشعارات بعد تحميل واجهة المستخدم
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationOptimizations();
    });
  }
  
  @override
  void dispose() {
    // إزالة مراقب دورة حياة التطبيق
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // معالجة تغييرات حالة دورة حياة التطبيق
    switch (state) {
      case AppLifecycleState.resumed:
        // التطبيق في المقدمة - إعادة جدولة الإشعارات إذا لزم الأمر
        AppInitializer.checkAndRescheduleNotifications();
        break;
      case AppLifecycleState.inactive:
        // التطبيق غير نشط مؤقتًا
        break;
      case AppLifecycleState.paused:
        // التطبيق في الخلفية
        _saveAppState();
        break;
      case AppLifecycleState.detached:
        // التطبيق منفصل عن واجهة المستخدم
        _saveAppState();
        break;
      default:
        break;
    }
  }
  
  // تهيئة التطبيق
  Future<void> _initializeApp() async {
    try {
      // التحقق مما إذا كان التطبيق قد فُتح من إشعار
      await NotificationNavigation.initialize();
      
      // إنهاء حالة التحميل
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('خطأ أثناء تهيئة التطبيق: $e');
      await _errorLoggingService.logError(
        'MyApp', 
        'خطأ أثناء تهيئة التطبيق', 
        e
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // حفظ حالة التطبيق
  Future<void> _saveAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_app_close', DateTime.now().toIso8601String());
    } catch (e) {
      print('خطأ في حفظ حالة التطبيق: $e');
    }
  }
  
  // فحص تحسينات الإشعارات
  Future<void> _checkNotificationOptimizations() async {
    try {
      // ننتظر بعض الوقت لضمان تحميل التطبيق بالكامل
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted && context.mounted) {
// AppInitializer.checkAndRescheduleNotifications(); // علق هذا السطر
        await AppInitializer.checkNotificationOptimizations(context);
      }
    } catch (e) {
      print('خطأ في فحص تحسينات الإشعارات: $e');
      await _errorLoggingService.logError(
        'MyApp', 
        'خطأ في فحص تحسينات الإشعارات', 
        e
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق الأذكار',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationNavigation.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF447055),
        fontFamily: 'Tajawal',
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF447055),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF447055),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        useMaterial3: true,
      ),
      home: _isLoading 
          ? const _SplashScreen() 
          : const HomeScreen(),
    );
  }
}

// شاشة البداية
class _SplashScreen extends StatelessWidget {
  const _SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF447055),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png', // تأكد من وجود هذا الملف
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            const Text(
              'تطبيق الأذكار',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}