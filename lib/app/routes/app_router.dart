// lib/app/routes/app_router.dart
import 'package:flutter/material.dart';
import '../../features/prayers/presentation/screens/prayer_times_screen.dart';
import '../../features/prayers/presentation/screens/qibla_screen.dart';
import '../../features/athkar/presentation/screens/athkar_categories_screen.dart';
import '../../features/athkar/presentation/screens/athkar_details_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/permissions_onboarding_screen.dart';

class AppRouter {

  static const String initialRoute = '/';
  static const String home = '/';
  static const String prayerTimes = '/prayer-times';
  static const String athkarCategories = '/athkar-categories';
  static const String athkarDetails = '/athkar-details';
  static const String qibla = '/qibla';
  static const String settingsRoute = '/settings';
  static const String permissionsOnboarding = '/permissions-onboarding';
  
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {

    final routeName = settings.name;
    
    debugPrint('Generando ruta para: $routeName');
    
    switch (routeName) {
      case home:
        return MaterialPageRoute(
          settings: settings, 
          builder: (_) => const HomeScreen(),
        );
        
      case prayerTimes:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PrayerTimesScreen(),
        );
        
      case athkarCategories:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AthkarCategoriesScreen(),
        );
        
      case athkarDetails:
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AthkarDetailsScreen(
            categoryId: args['categoryId'],
            categoryName: args['categoryName'],
          ),
        );
        
      case qibla:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const QiblaScreen(),
        );
        
      case settingsRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );
      
      case permissionsOnboarding:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PermissionsOnboardingScreen(),
        );
        
      default:
        debugPrint('¡RUTA NO ENCONTRADA! ${settings.name}');
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('لا يوجد طريق للمسار ${settings.name}'),
            ),
          ),
        );
    }
  }
}