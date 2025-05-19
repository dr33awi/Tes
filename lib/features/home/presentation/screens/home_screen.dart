import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../athkar/presentation/providers/athkar_provider.dart';
import '../../../prayers/presentation/providers/prayer_times_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../prayers/presentation/widgets/prayer_times_section.dart';
import '../widgets/category_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // تأخير قصير لضمان تجهيز Provider
    Future.microtask(() {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final prayerTimesProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
      
      // تعيين موقع افتراضي مؤقت (سيتم استبداله بموقع المستخدم الحقيقي)
      // الإحداثيات الافتراضية لمكة المكرمة
      prayerTimesProvider.setLocation(
        latitude: 21.422510,
        longitude: 39.826168,
      );
      
      // تحميل مواقيت الصلاة إذا كانت الإعدادات جاهزة
      if (settingsProvider.settings != null) {
        prayerTimesProvider.loadTodayPrayerTimes(settingsProvider.settings!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // استخدام معرف settingsRoute بدلاً من settings
              Navigator.pushNamed(context, AppRouter.settingsRoute);
            },
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const LoadingWidget();
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (settingsProvider.settings != null) {
                await Provider.of<PrayerTimesProvider>(context, listen: false)
                    .refreshData(settingsProvider.settings!);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قسم مواقيت الصلاة
                  const PrayerTimesSection(),
                  const SizedBox(height: 24),
                  
                  // عنوان قسم الفئات
                  Text(
                    'الأقسام',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // قسم شبكة الفئات
                  CustomScrollView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    slivers: [
                      const CategoryGrid(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // معلومات إضافية
                  Center(
                    child: Text(
                      '${AppConstants.appName} - ${AppConstants.appVersion}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}