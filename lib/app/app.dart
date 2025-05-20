// في بداية ملف lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// استيراد الثيمات 
import 'themes/app_theme.dart';
import 'di/service_locator.dart' as di;
import 'routes/app_router.dart';
import '../core/constants/app_constants.dart';
import '../features/athkar/presentation/providers/athkar_provider.dart';
import '../features/prayers/presentation/providers/prayer_times_provider.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import '../features/athkar/domain/usecases/get_athkar_by_category.dart';
import '../features/athkar/domain/usecases/get_athkar_categories.dart';
import '../features/athkar/domain/usecases/get_athkar_by_id.dart';
import '../features/athkar/domain/usecases/save_athkar_favorite.dart';
import '../features/athkar/domain/usecases/get_favorite_athkar.dart';
import '../features/athkar/domain/usecases/search_athkar.dart';
import '../features/prayers/domain/usecases/get_prayer_times.dart';
import '../features/prayers/domain/usecases/get_qibla_direction.dart';
import '../features/settings/domain/usecases/get_settings.dart';
import '../features/settings/domain/usecases/update_settings.dart';

class AthkarApp extends StatelessWidget {
  const AthkarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            getSettings: di.getIt<GetSettings>(),
            updateSettings: di.getIt<UpdateSettings>(),
          )..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => AthkarProvider(
            getAthkarCategories: di.getIt<GetAthkarCategories>(),
            getAthkarByCategory: di.getIt<GetAthkarByCategory>(),
            getAthkarById: di.getIt<GetAthkarById>(),
            saveFavorite: di.getIt<SaveAthkarFavorite>(),
            getFavorites: di.getIt<GetFavoriteAthkar>(),
            searchAthkar: di.getIt<SearchAthkar>(),
          )..loadCategories(),
        ),
        ChangeNotifierProvider(
          create: (_) => PrayerTimesProvider(
            getPrayerTimes: di.getIt<GetPrayerTimes>(),
            getQiblaDirection: di.getIt<GetQiblaDirection>(),
          ),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final isDarkMode = settingsProvider.settings?.enableDarkMode ?? false;
          final language = settingsProvider.settings?.language ?? AppConstants.defaultLanguage;
          
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: Locale(language),
            supportedLocales: const [
              Locale('ar'), // العربية
              Locale('en'), // الإنجليزية
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}