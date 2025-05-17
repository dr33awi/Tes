// lib/app/app.dart - Corregir las rutas y constantes
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'themes/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../presentation/blocs/athkar/athkar_provider.dart';
import '../presentation/blocs/prayers/prayer_times_provider.dart';
import '../presentation/blocs/settings/settings_provider.dart';
import '../domain/usecases/athkar/get_athkar_by_category.dart';
import '../domain/usecases/athkar/get_athkar_categories.dart';
import '../domain/usecases/prayers/get_prayer_times.dart';
import '../domain/usecases/prayers/get_qibla_direction.dart';
import '../domain/usecases/settings/get_settings.dart';
import '../domain/usecases/settings/update_settings.dart';
import 'di/service_locator.dart';

class AthkarApp extends StatelessWidget {
  const AthkarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            getSettings: getIt<GetSettings>(),
            updateSettings: getIt<UpdateSettings>(),
          )..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => AthkarProvider(
            getAthkarCategories: getIt<GetAthkarCategories>(),
            getAthkarByCategory: getIt<GetAthkarByCategory>(),
          )..loadCategories(),
        ),
        ChangeNotifierProvider(
          create: (_) => PrayerTimesProvider(
            getPrayerTimes: getIt<GetPrayerTimes>(),
            getQiblaDirection: getIt<GetQiblaDirection>(),
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
            initialRoute: '/', // Utiliza un valor directo en lugar de AppConstants.initialRoute
            onGenerateRoute: AppRouter.onGenerateRoute, // Asegúrate de que AppRouter existe y esté correctamente importado
          );
        },
      ),
    );
  }
}