// lib/app/routes/app_router.dart
import 'package:flutter/material.dart';
import '../../features/prayers/presentation/screens/prayer_times_screen.dart';
import '../../features/prayers/presentation/screens/qibla_screen.dart';
import '../../features/athkar/presentation/screens/athkar_details_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/permissions_onboarding_screen.dart';
import '../../features/athkar/presentation/screens/athkar_screen.dart';

import '../../features/athkar/data/models/athkar_model.dart';
class AppRouter {

  static const String initialRoute = '/';
  static const String home = '/';
  static const String prayerTimes = '/prayer-times';
  static const String athkarCategories = '/athkar-categories';
  static const String athkarDetails = '/athkar-details';
  static const String qibla = '/qibla';
  static const String settingsRoute = '/settings';
  static const String permissionsOnboarding = '/permissions-onboarding';
  static const String athkarScreen = '/athkar';
  static const String athkarDetailsScreen = '/athkar-details';
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
        
      case athkarScreen:
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => const AthkarScreen(),
  );
  
    case athkarDetailsScreen:
  final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
  final AthkarCategory category = args['category'];
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => AthkarDetailsScreen(category: category),
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