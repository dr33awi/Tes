import 'package:flutter/material.dart';
import '../../presentation/screens/prayers/prayer_times_screen.dart';
// استيراد الشاشات الأخرى

class AppRouter {
  static const String home = '/';
  static const String prayerTimes = '/prayer-times';
  static const String athkarCategories = '/athkar-categories';
  static const String athkarList = '/athkar-list';
  static const String athkarDetail = '/athkar-detail';
  static const String qibla = '/qibla';
  static const String settings = '/settings';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('الصفحة الرئيسية'))),
        );
        
      case prayerTimes:
        return MaterialPageRoute(
          builder: (_) => const PrayerTimesScreen(),
        );
        
      // أضف باقي الطرق هنا
        
      case settings.name: // استخدم متغير آخر لتجنب هذا الخطأ
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('الإعدادات'))),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('لا يوجد طريق للمسار ${settings.name}'),
            ),
          ),
        );
    }
  }
}