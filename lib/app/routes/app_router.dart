// lib/app/routes/app_router.dart
import 'package:flutter/material.dart';
import '../../features/prayers/presentation/screens/prayer_times_screen.dart';
import '../../features/prayers/presentation/screens/qibla_screen.dart';
import '../../features/athkar/presentation/screens/athkar_details_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/permissions_onboarding_screen.dart';
import '../../features/athkar/presentation/screens/athkar_screen.dart';
import '../../features/athkar/presentation/screens/athkar_categories_screen.dart';

class AppRouter {
  // تعريف مسارات التطبيق
  static const String initialRoute = '/';
  static const String home = '/';
  static const String prayerTimes = '/prayer-times';
  static const String athkarCategories = '/athkar-categories';
  static const String athkarDetails = '/athkar-details';
  static const String qibla = '/qibla';
  static const String settingsRoute = '/settings';
  static const String permissionsOnboarding = '/permissions-onboarding';
  static const String athkarScreen = '/athkar';
  
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    
    debugPrint('توليد مسار لـ: $routeName');
    
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
        
      case athkarScreen:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AthkarScreen(
            id: 'general',
            name: 'الأذكار',
            description: 'جميع الأذكار والأدعية',
            icon: 'Icons.auto_awesome',
          ),
        );
        
      case athkarDetails:
        // استخراج معلومات الفئة من arguments
        final args = settings.arguments as Map<String, dynamic>;
        
        // إذا كان هناك فئة مُمررة مباشرةً
        if (args.containsKey('category')) {
          final category = args['category'];
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => AthkarDetailsScreen(category: category),
          );
        } 
        // إذا كان هناك معرفات للفئة
        else {
          final categoryId = args['categoryId'] as String;
          final categoryName = args['categoryName'] as String;
          
          // إنشاء موجه AthkarScreen لاستخدامه مع AthkarDetailsScreen
          final category = AthkarScreen(
            id: categoryId,
            name: categoryName,
            description: args['description'] as String? ?? '',
            icon: args['icon'] as String? ?? 'Icons.auto_awesome',
            athkar: [],
          );
          
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => AthkarDetailsScreen(category: category),
          );
        }
        
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
        debugPrint('مسار غير موجود! ${settings.name}');
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