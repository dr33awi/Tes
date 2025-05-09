// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/screens/athkarscreen/background_task_handler.dart';
import 'package:test_athkar_app/screens/athkarscreen/notification_navigation.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/notification_service.dart';
import 'package:test_athkar_app/screens/home_screen/home_screen.dart';
import 'package:test_athkar_app/adhan/services/prayer_notification_service.dart';
import 'package:test_athkar_app/adhan/services/prayer_times_service.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';


void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set screen orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // تهيئة نظام الإنذار للأندرويد
  await AndroidAlarmManager.initialize();
  
  // تهيئة الاتصال بين الخلفية والواجهة للإشعارات
  // Note: This function does not exist in the provided code, so I've commented it out
  // BackgroundTaskHandler.setupBackgroundListener();
  
  // Initialize prayer services
  try {
    debugPrint('Initializing prayer services...');
    
    // Initialize prayer notification service
    final notificationService = PrayerNotificationService();
    final notificationInitialized = await notificationService.initialize();
    debugPrint('Prayer notification service initialized: $notificationInitialized');
    
    // اختبار الإشعارات الفورية
    if (notificationInitialized) {
      await notificationService.testImmediateNotification();
      // اختبار الإشعارات المجدولة بعد 30 ثانية
      await notificationService.testScheduledNotification();
    }
    
    // Initialize prayer times service
    final prayerTimesService = PrayerTimesService();
    final prayerServiceInitialized = await prayerTimesService.initialize();
    debugPrint('Prayer times service initialized: $prayerServiceInitialized');
    
    // Schedule notifications for today's prayers
    if (notificationInitialized && prayerServiceInitialized) {
      final scheduled = await prayerTimesService.schedulePrayerNotifications();
      debugPrint('Prayer notifications scheduled: $scheduled');
      
      // التحقق من الإشعارات المجدولة
      final pendingNotifications = await notificationService.getPendingNotifications();
      debugPrint('Total pending prayer notifications: ${pendingNotifications.length}');
    }
    
    debugPrint('Prayer services initialization complete');
  } catch (e) {
    debugPrint('Error initializing prayer services: $e');
    // Continue despite error
  }
  
  // Initialize Athkar notification service
  try {
    debugPrint('Initializing Athkar notification service...');
    
    // Initialize Athkar notification service
    final athkarNotificationService = NotificationService();
    await athkarNotificationService.initialize();
    
    // Schedule saved Athkar notifications
    await athkarNotificationService.scheduleAllSavedNotifications();
    
    debugPrint('Athkar notification service initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Athkar notification service: $e');
    // Continue despite error
  }
  
  // Check if app was opened from a notification
  final prefs = await SharedPreferences.getInstance();
  final notificationOpened = prefs.getBool('opened_from_notification') ?? false;
    
  if (notificationOpened) {
    // Get the notification payload
    final notificationPayload = prefs.getString('notification_payload');
    
    // Reset the flag
    await prefs.setBool('opened_from_notification', false);
    
    // Will handle navigation after app is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (notificationPayload != null) {
        NotificationNavigation.handleNotificationNavigation(notificationPayload);
      }
    });
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // عند استئناف التطبيق، تحقق مما إذا كان يجب تحديث الإشعارات
      _checkAndUpdateNotifications();
    }
  }

  Future<void> _checkAndUpdateNotifications() async {
    try {
      // التحقق من إشعارات الصلاة
      debugPrint('Checking if prayer notifications need to be updated...');
      
      final notificationService = PrayerNotificationService();
      final shouldUpdate = await notificationService.shouldUpdateNotifications();
      
      if (shouldUpdate) {
        debugPrint('Prayer notifications need to be updated. Scheduling new notifications...');
        
        // جدولة الإشعارات لليوم الجديد
        final prayerTimesService = PrayerTimesService();
        final scheduled = await prayerTimesService.schedulePrayerNotifications();
        
        debugPrint('Prayer notifications updated: $scheduled scheduled');
      } else {
        debugPrint('Prayer notifications already up-to-date');
      }
      
      // التحقق من إشعارات الأذكار
      debugPrint('Checking Athkar notifications...');
      
      // لا حاجة لإعادة تحديث إشعارات الأذكار بشكل يومي لأنها تتكرر تلقائيًا
      // لكن يمكننا التأكد من أنها لا تزال مجدولة
      final athkarNotificationService = NotificationService();
      
      // قم بإعادة جدولة الإشعارات المحفوظة للتأكد من أنها تعمل
      await athkarNotificationService.scheduleAllSavedNotifications();
      
      debugPrint('Athkar notifications checked and updated if needed');
    } catch (e) {
      debugPrint('Error checking/updating notifications: $e');
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
          navigatorKey: NotificationNavigation.navigatorKey, // Add navigator key for notifications
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
          home: const HomeScreen(),
        );
      },
    );
  }
}