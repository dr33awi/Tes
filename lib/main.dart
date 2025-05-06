// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_athkar_app/screens/home_screen/home_screen.dart';
import 'package:test_athkar_app/adhan/services/prayer_notification_service.dart';
import 'package:test_athkar_app/adhan/services/prayer_times_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set screen orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize services
  try {
    // Initialize prayer notification service
    final notificationService = PrayerNotificationService();
    await notificationService.initialize();
    
    // Initialize prayer times service
    final prayerTimesService = PrayerTimesService();
    await prayerTimesService.initialize();
    
    // Schedule notifications for today's prayers
    await prayerTimesService.schedulePrayerNotifications();
    
    debugPrint('Prayer services initialized successfully');
  } catch (e) {
    debugPrint('Error initializing services: $e');
    // Continue despite error
  }
  
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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