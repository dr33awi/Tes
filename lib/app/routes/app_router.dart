// lib/app/routes/app_router.dart
import 'package:flutter/material.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/athkar/athkar_categories_screen.dart';
import '../../presentation/screens/athkar/athkar_details_screen.dart';
import '../../presentation/screens/prayers/prayer_times_screen.dart';
import '../../presentation/screens/prayers/qibla_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';

class AppRouter {
  static const String initialRoute = '/';
  static const String home = '/';
  static const String athkarCategories = '/athkar-categories';
  static const String athkarDetails = '/athkar-details';
  static const String prayerTimes = '/prayer-times';
  static const String qibla = '/qibla';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case athkarCategories:
        return MaterialPageRoute(
          builder: (_) => const AthkarCategoriesScreen(),
        );
      case athkarDetails:
        final arguments = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AthkarDetailsScreen(
            categoryId: arguments['categoryId'],
            categoryName: arguments['categoryName'],
          ),
        );
      case prayerTimes:
        return MaterialPageRoute(
          builder: (_) => const PrayerTimesScreen(),
        );
      case qibla:
        return MaterialPageRoute(
          builder: (_) => const QiblaScreen(),
        );
      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}