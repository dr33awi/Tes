// lib/features/prayers/presentation/screens/prayer_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../app/routes/app_router.dart';
import '../../../../core/services/interfaces/prayer_times_service.dart';
import '../../../settings/domain/entities/settings.dart';
import '../../domain/entities/prayer_times.dart';
import '../providers/prayer_times_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../widgets/prayer_times_section.dart';
import '../widgets/qibla_section.dart';

class PrayerDashboardScreen extends StatefulWidget {
  const PrayerDashboardScreen({Key? key}) : super(key: key);
  
  @override
  State<PrayerDashboardScreen> createState() => _PrayerDashboardScreenState();
}

class _PrayerDashboardScreenState extends State<PrayerDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _loadData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    final prayerProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    if (!prayerProvider.hasLocation) {
      // تعيين موقع افتراضي مؤقت (مكة المكرمة)
      prayerProvider.setLocation(
        latitude: 21.422510,
        longitude: 39.826168,
      );
    }
    
    if (settingsProvider.settings != null && prayerProvider.todayPrayerTimes == null) {
      await prayerProvider.initialLoad(settingsProvider.settings!);
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<PrayerTimesProvider, SettingsProvider>(
          builder: (context, prayerProvider, settingsProvider, _) {
            if (_isLoading || prayerProvider.isLoading) {
              return _buildLoadingWidget();
            }
            
            return _buildDashboardContent(prayerProvider, settingsProvider);
          },
        ),
      ),
    );
  }
  
  // عرض مؤشر التحميل
  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LoadingWidget(),
          const SizedBox(height: 20),
          Text(
            'جاري تحميل مواقيت الصلاة...',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
  
  // محتوى لوحة المعلومات
  Widget _buildDashboardContent(PrayerTimesProvider prayerProvider, SettingsProvider settingsProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        if (settingsProvider.settings != null) {
          await prayerProvider.refreshData(settingsProvider.settings!);
        }
      },
      child: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              const SizedBox(height: 8),
              
              // عنوان التطبيق
              _buildAppHeader(),
              const SizedBox(height: 16),
              
              // بطاقة الصلاة الحالية والقادمة
              _buildCurrentPrayerCard(prayerProvider),
              const SizedBox(height: 16),
              
              // خيارات التنقل السريع
              _buildQuickNavigation(),
              const SizedBox(height: 16),
              
              // عنوان مواقيت اليوم
              _buildSectionTitle('مواقيت اليوم', Icons.access_time),
              const SizedBox(height: 12),
              
              // قائمة مواقيت اليوم
              if (prayerProvider.todayPrayerTimes != null)
                _buildTodayPrayerTimes(prayerProvider.todayPrayerTimes!),
              
              const SizedBox(height: 16),
              
              // عنوان الأدوات
              _buildSectionTitle('أدوات مساعدة', Icons.compass_calibration),
              const SizedBox(height: 12),
              
              // قائمة الأدوات المساعدة
              _buildUtilitiesGrid(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  // عنوان التطبيق
  Widget _buildAppHeader() {
    final locale = Localizations.localeOf(context);
    final date = DateTime.now();
    final dateFormat = DateFormat.yMMMMEEEEd(locale.languageCode);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mosque,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مواقيت الصلاة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                dateFormat.format(date),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'الإعدادات',
          onPressed: () {
            Navigator.pushNamed(context, '/prayer-settings');
          },
        ),
      ],
    );
  }
  
  // بطاقة الصلاة الحالية والقادمة
  Widget _buildCurrentPrayerCard(PrayerTimesProvider provider) {
    final PrayerTimes? prayerTimes = provider.todayPrayerTimes;
    if (prayerTimes == null) return const SizedBox.shrink();
    
    final now = DateTime.now();
    final currentPrayer = prayerTimes.getCurrentPrayer();
    final nextPrayer = prayerTimes.getNextPrayer();
    
    // الحصول على اسم الصلاة التالية
    final nextPrayerName = _getPrayerName(nextPrayer);
    
    // الحصول على وقت الصلاة التالية
    final nextPrayerTime = prayerTimes.getTimeForPrayer(nextPrayer);
    
    // حساب الوقت المتبقي
    final remaining = nextPrayerTime.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    // تنسيق الوقت المتبقي
    String remainingText = '';
    
    if (hours > 0) {
      remainingText += '$hours ساعة';
      if (minutes > 0) {
        remainingText += ' و ';
      }
    }
    
    if (minutes > 0 || remainingText.isEmpty) {
      remainingText += '$minutes دقيقة';
    }
    
    // تنسيق الوقت
    final timeFormat = DateFormat.jm();
    
    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_alarm,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'الصلاة القادمة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          remainingText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        nextPrayerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          timeFormat.format(nextPrayerTime),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // خيارات التنقل السريع
  Widget _buildQuickNavigation() {
    final buttons = [
      {
        'title': 'مواقيت الصلاة',
        'icon': Icons.access_time_filled,
        'color': const Color(0xFF5C6BC0),
        'route': AppRouter.prayerTimes, // تم تغيير المسار ليستخدم الثابت
      },
      {
        'title': 'اتجاه القبلة',
        'icon': Icons.explore,
        'color': const Color(0xFFFF8A65),
        'route': AppRouter.qibla, // تم تغيير المسار ليستخدم الثابت
      },
      {
        'title': 'إشعارات الصلاة',
        'icon': Icons.notifications_active,
        'color': const Color(0xFF66BB6A),
        'route': '/prayer-notifications',
      },
    ];
    
    return Row(
      children: buttons.map((button) {
        final title = button['title'] as String;
        final icon = button['icon'] as IconData;
        final color = button['color'] as Color;
        final route = button['route'] as String;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildNavButton(
              title: title,
              icon: icon,
              color: color,
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(context, route);
              },
            ),
          ),
        );
      }).toList(),
    );
  }
  
  // زر التنقل
  Widget _buildNavButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // عنوان القسم
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
  
  // قائمة مواقيت اليوم
  Widget _buildTodayPrayerTimes(PrayerTimes prayerTimes) {
    final prayers = [
      {'name': 'الفجر', 'time': prayerTimes.fajr, 'icon': Icons.wb_twilight},
      {'name': 'الشروق', 'time': prayerTimes.sunrise, 'icon': Icons.wb_sunny_outlined},
      {'name': 'الظهر', 'time': prayerTimes.dhuhr, 'icon': Icons.wb_sunny},
      {'name': 'العصر', 'time': prayerTimes.asr, 'icon': Icons.wb_cloudy},
      {'name': 'المغرب', 'time': prayerTimes.maghrib, 'icon': Icons.nights_stay_outlined},
      {'name': 'العشاء', 'time': prayerTimes.isha, 'icon': Icons.nightlight_round},
    ];
    
    final timeFormat = DateFormat.jm();
    final now = DateTime.now();
    final currentPrayer = prayerTimes.getCurrentPrayer();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: prayers.map((prayer) {
            final name = prayer['name'] as String;
            final time = prayer['time'] as DateTime;
            final icon = prayer['icon'] as IconData;
            
            // التحقق ما إذا كانت الصلاة الحالية
            bool isCurrentPrayer = false;
            
            // تحسين طريقة مقارنة الصلاة الحالية مع الاسم
            if (currentPrayer == adhan.Prayer.fajr && name == 'الفجر') {
              isCurrentPrayer = true;
            } else if (currentPrayer == adhan.Prayer.sunrise && name == 'الشروق') {
              isCurrentPrayer = true;
            } else if (currentPrayer == adhan.Prayer.dhuhr && name == 'الظهر') {
              isCurrentPrayer = true;
            } else if (currentPrayer == adhan.Prayer.asr && name == 'العصر') {
              isCurrentPrayer = true;
            } else if (currentPrayer == adhan.Prayer.maghrib && name == 'المغرب') {
              isCurrentPrayer = true;
            } else if (currentPrayer == adhan.Prayer.isha && name == 'العشاء') {
              isCurrentPrayer = true;
            }
            
            return InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                // إضافة إجراء إن لزم
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCurrentPrayer
                            ? Theme.of(context).primaryColor.withOpacity(0.2)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isCurrentPrayer
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrentPrayer ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCurrentPrayer
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        timeFormat.format(time),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrentPrayer ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentPrayer
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    if (isCurrentPrayer) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  // شبكة الأدوات المساعدة
  Widget _buildUtilitiesGrid() {
    final utilities = [
      {
        'title': 'أذكار الصباح',
        'icon': Icons.wb_sunny,
        'color': const Color(0xFFFFD54F),
        'route': '/morning-athkar',
      },
      {
        'title': 'أذكار المساء',
        'icon': Icons.nights_stay,
        'color': const Color(0xFFAB47BC),
        'route': '/evening-athkar',
      },
      {
        'title': 'التقويم الهجري',
        'icon': Icons.calendar_today,
        'color': const Color(0xFF4DB6AC),
        'route': '/hijri-calendar',
      },
      {
        'title': 'مواقع المساجد',
        'icon': Icons.location_on,
        'color': const Color(0xFFE57373),
        'route': '/nearby-mosques',
      },
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: utilities.length,
      itemBuilder: (context, index) {
        final utility = utilities[index];
        final title = utility['title'] as String;
        final icon = utility['icon'] as IconData;
        final color = utility['color'] as Color;
        final route = utility['route'] as String;
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, route);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // تحويل نوع الصلاة إلى الاسم
  String _getPrayerName(adhan.Prayer prayer) {
    switch (prayer) {
      case adhan.Prayer.fajr: return 'الفجر';
      case adhan.Prayer.sunrise: return 'الشروق';
      case adhan.Prayer.dhuhr: return 'الظهر';
      case adhan.Prayer.asr: return 'العصر';
      case adhan.Prayer.maghrib: return 'المغرب';
      case adhan.Prayer.isha: return 'العشاء';
      default: return 'غير محدد';
    }
  }
}