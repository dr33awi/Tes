// lib/app/routes/app_router.dart
import 'package:flutter/material.dart';
import '../../presentation/screens/prayers/prayer_times_screen.dart';
import '../../presentation/screens/prayers/qibla_screen.dart';
import '../../presentation/screens/athkar/athkar_categories_screen.dart';
import '../../presentation/screens/athkar/athkar_details_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/home/home_screen.dart';

class AppRouter {
  // معرفات الطرق الثابتة
  static const String initialRoute = '/';
  static const String home = '/';
  static const String prayerTimes = '/prayer-times';
  static const String athkarCategories = '/athkar-categories';
  static const String athkarDetails = '/athkar-details';
  static const String qibla = '/qibla';
  static const String settingsRoute = '/settings'; // تغيير الاسم لتجنب التضارب
  
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // استخدام متغير آخر لتجنب تداخل الأسماء
    final routeName = settings.name;
    
    switch (routeName) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
        
      case prayerTimes:
        return MaterialPageRoute(
          builder: (_) => const PrayerTimesScreen(),
        );
        
      case athkarCategories:
        return MaterialPageRoute(
          builder: (_) => const AthkarCategoriesScreen(),
        );
        
      case athkarDetails:
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AthkarDetailsScreen(
            categoryId: args['categoryId'],
            categoryName: args['categoryName'],
          ),
        );
        
      case qibla:
        return MaterialPageRoute(
          builder: (_) => const QiblaScreen(),
        );
        
      case settingsRoute: // استخدام الاسم الجديد
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
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