import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/athkar/athkar_provider.dart';
import '../../blocs/prayers/prayer_times_provider.dart';
import '../../blocs/settings/settings_provider.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/athkar_section.dart';
import 'widgets/prayer_times_section.dart';
import 'widgets/qibla_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // تحسين: استخدام Future.microtask للعمليات التي تحتاج للسياق
    // لكن تجنب استخدام listen: false داخل initState إلا إذا كان ضروريًا
    Future.microtask(() => _initializeData());
  }

  // تحسين: فصل منطق التهيئة إلى دالة منفصلة للقراءة بشكل أفضل
  void _initializeData() {
    final prayerTimesProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    // تحسين: التحقق مما إذا كانت البيانات محملة بالفعل قبل تحميلها مرة أخرى
    if (!prayerTimesProvider.hasLocation) {
      // تعيين موقع افتراضي مؤقت (سيتم استبداله بموقع المستخدم الحقيقي)
      prayerTimesProvider.setLocation(
        latitude: 21.422510,
        longitude: 39.826168,
      );
    }
    
    // تحميل مواقيت الصلاة إذا كانت الإعدادات جاهزة
    final settings = settingsProvider.settings;
    if (settings != null && !prayerTimesProvider.hasLoaded) {
      prayerTimesProvider.loadTodayPrayerTimes(settings);
    }
    
    // تحسين: تحميل مستبق للبيانات الشائعة الاستخدام
    Provider.of<AthkarProvider>(context, listen: false).preloadCommonCategories();
  }

  @override
  Widget build(BuildContext context) {
    // تحسين: استخدام Selector بدلاً من Consumer للحد من إعادة البناء
    return Selector<SettingsProvider, bool>(
      // فقط إعادة البناء عند تغيير حالة التحميل
      selector: (_, provider) => provider.isLoading,
      builder: (context, isLoading, child) {
        // استخدام child للعناصر الثابتة التي لا تحتاج إعادة بناء
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppConstants.appName),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.pushNamed(context, AppRouter.settingsRoute),
              ),
            ],
          ),
          // استخدام child للمحتوى إذا لم تتغير حالة التحميل
          body: isLoading ? const LoadingWidget() : child!,
        );
      },
      // تحسين: تمرير العناصر الثابتة كـ child لتجنب إعادة بناءها
      child: RefreshIndicator(
        onRefresh: () async {
          final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
          final prayerProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
          final athkarProvider = Provider.of<AthkarProvider>(context, listen: false);
          
          if (settingsProvider.settings != null) {
            await prayerProvider.refreshData(settingsProvider.settings!);
            await athkarProvider.refreshData();
          }
        },
        child: _buildHomeContent(),
      ),
    );
  }

  // تحسين: فصل بناء المحتوى إلى دالة منفصلة للقراءة بشكل أفضل
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          // استخدام const للعناصر الثابتة لتحسين الأداء
          PrayerTimesSection(),
          SizedBox(height: 24),
          QiblaSection(),
          SizedBox(height: 24),
          AthkarSection(),
          SizedBox(height: 24),
          _AppInfoFooter(),
        ],
      ),
    );
  }
}

// تحسين: استخراج عناصر ثابتة لويدجيت منفصلة
class _AppInfoFooter extends StatelessWidget {
  const _AppInfoFooter();
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '${AppConstants.appName} - ${AppConstants.appVersion}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}