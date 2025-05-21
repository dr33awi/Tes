// lib/app/routes/app_router.dart
import 'package:flutter/material.dart';

// Feature-Imports
import '../../features/home/favorites/presentation/screens/favorites_screen.dart';
import '../../features/home/models/daily_quote_model.dart';
import '../../features/home/presentation/quotes/screens/quote_details_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

// Gebetszeiten-Feature-Imports
import '../../features/prayers/presentation/screens/prayer_dashboard_screen.dart';
import '../../features/prayers/presentation/screens/prayer_times_screen.dart';
import '../../features/prayers/presentation/screens/qibla_screen.dart';
import '../../features/prayers/presentation/screens/prayer_settings_screen.dart';
import '../../features/prayers/presentation/screens/prayer_notification_settings_screen.dart';

// Athkar-Feature-Imports
import '../../features/athkar/presentation/screens/athkar_details_screen.dart';
import '../../features/athkar/presentation/screens/athkar_screen.dart';
import '../../features/athkar/presentation/screens/athkar_categories_screen.dart';

// Andere Features
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/onboarding/presentation/screens/permissions_onboarding_screen.dart';

class AppRouter {
  // Allgemeine Routen
  static const String initialRoute = '/';
  static const String home = '/';
  static const String settingsRoute = '/settings';
  static const String permissionsOnboarding = '/permissions-onboarding';
  
  // Gebetszeiten-Routen
  static const String prayerDashboard = '/prayer-dashboard';
  static const String prayerTimes = '/prayer-times';
  static const String qibla = '/qibla';
  static const String prayerSettings = '/prayer-settings';
  static const String prayerNotifications = '/prayer-notifications';
  
  // Athkar-Routen
  static const String athkarCategories = '/athkar-categories';
  static const String athkarScreen = '/athkar';
  static const String athkarDetails = '/athkar-details';
  
  // Home-Feature-Routen
  static const String favorites = '/favorites';
  static const String quoteDetails = '/quote-details';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    
    debugPrint('توليد مسار لـ: $routeName');
    
    switch (routeName) {
      // Allgemeine Routen
      case home:
        return MaterialPageRoute(
          settings: settings, 
          builder: (_) => const HomeScreen(),
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
      
      // Gebetszeiten-Routen
      case prayerDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PrayerDashboardScreen(),
        );
        
      case prayerTimes:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PrayerTimesScreen(),
        );
        
      case qibla:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const EnhancedQiblaScreen(),
        );
        
      case prayerSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PrayerSettingsScreen(),
        );
        
      case prayerNotifications:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PrayerNotificationSettingsScreen(),
        );
      
      // Athkar-Routen
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
      
      // Home-Feature-Routen
      case favorites:
        final args = settings.arguments as HighlightItem?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => FavoritesScreen(newFavoriteQuote: args),
        );

      case quoteDetails:
        final quoteItem = settings.arguments as HighlightItem;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => QuoteDetailsScreen(quoteItem: quoteItem),
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