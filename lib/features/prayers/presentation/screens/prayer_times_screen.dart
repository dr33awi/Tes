// lib/features/prayers/presentation/screens/enhanced_prayer_times_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../core/services/interfaces/prayer_times_service.dart';
import '../../../settings/domain/entities/settings.dart';
import '../../domain/entities/prayer_times.dart';
import '../providers/prayer_times_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/custom_app_bar.dart';

class EnhancedPrayerTimesScreen extends StatefulWidget {
  const EnhancedPrayerTimesScreen({Key? key}) : super(key: key);
  
  @override
  State<EnhancedPrayerTimesScreen> createState() => _EnhancedPrayerTimesScreenState();
}

class _EnhancedPrayerTimesScreenState extends State<EnhancedPrayerTimesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  PrayerTimes? _prayerTimes;
  bool _isLoading = true;
  
  // قائمة بألوان الصلوات
  final Map<String, Color> _prayerColors = {
    'fajr': const Color(0xFF5C6BC0),
    'sunrise': const Color(0xFFFFB74D),
    'dhuhr': const Color(0xFFFFD54F),
    'asr': const Color(0xFF66BB6A),
    'maghrib': const Color(0xFFAB47BC),
    'isha': const Color(0xFF4DB6AC),
  };
  
  // أسماء الصلوات بالترتيب
  final List<Map<String, dynamic>> _prayerInfo = [
    {'key': 'fajr', 'name': 'الفجر', 'icon': Icons.wb_twilight},
    {'key': 'sunrise', 'name': 'الشروق', 'icon': Icons.wb_sunny_outlined},
    {'key': 'dhuhr', 'name': 'الظهر', 'icon': Icons.wb_sunny},
    {'key': 'asr', 'name': 'العصر', 'icon': Icons.wb_cloudy},
    {'key': 'maghrib', 'name': 'المغرب', 'icon': Icons.nights_stay_outlined},
    {'key': 'isha', 'name': 'العشاء', 'icon': Icons.nightlight_round},
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _loadPrayerTimes();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _loadPrayerTimes() {
    // تأكد من تحميل مواقيت الصلاة إذا لم تكن قد حُملت بعد
    final prayerProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    if (!prayerProvider.hasLocation) {
      // تعيين موقع افتراضي مؤقت (مكة المكرمة)
      prayerProvider.setLocation(
        latitude: 21.422510,
        longitude: 39.826168,
      );
    }
    
    if (prayerProvider.todayPrayerTimes == null && settingsProvider.settings != null) {
      prayerProvider.loadTodayPrayerTimes(settingsProvider.settings!);
    }

    setState(() {
      _prayerTimes = prayerProvider.todayPrayerTimes;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'أوقات الصلاة',
        transparent: true,
        actions: [
          // زر الإشعارات
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'إشعارات الصلاة',
            onPressed: () {
              Navigator.pushNamed(context, '/prayer-notifications');
            },
          ),
          // زر الإعدادات
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'إعدادات المواقيت',
            onPressed: () {
              Navigator.pushNamed(context, '/prayer-settings');
            },
          ),
        ],
      ),
      body: Consumer2<PrayerTimesProvider, SettingsProvider>(
        builder: (context, prayerProvider, settingsProvider, _) {
          if (prayerProvider.isLoading) {
            return _buildLoadingWidget();
          } else if (prayerProvider.hasError) {
            return _buildErrorWidget(prayerProvider.error!);
          } else if (prayerProvider.todayPrayerTimes != null) {
            return _buildPrayerTimesContent(prayerProvider.todayPrayerTimes!);
          } else {
            return _buildNoDataWidget(settingsProvider);
          }
        },
      ),
    );
  }
  
  // عرض مؤشر التحميل
  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.5),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingWidget(),
            SizedBox(height: 20),
            Text(
              'جاري تحميل مواقيت الصلاة...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // عرض رسالة الخطأ
  Widget _buildErrorWidget(String error) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final prayerProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
                  final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                  
                  if (settingsProvider.settings != null) {
                    prayerProvider.loadTodayPrayerTimes(settingsProvider.settings!);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // عرض عند عدم وجود بيانات
  Widget _buildNoDataWidget(SettingsProvider settingsProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mosque_outlined,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'لا توجد بيانات متاحة',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'لم يتم العثور على مواقيت الصلاة لهذا اليوم',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final prayerProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
                  
                  if (settingsProvider.settings != null) {
                    prayerProvider.loadTodayPrayerTimes(settingsProvider.settings!);
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('تحميل مواقيت الصلاة'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // محتوى مواقيت الصلاة
  Widget _buildPrayerTimesContent(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final currentPrayer = prayerTimes.getCurrentPrayer();
    final nextPrayer = prayerTimes.getNextPrayer();
    
    // تنسيق التاريخ والوقت
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'ar');
    final timeFormat = DateFormat.jm();
    
    // الحصول على اسم الصلاة الحالية والتالية
    final currentPrayerName = _getPrayerName(currentPrayer);
    final nextPrayerName = _getPrayerName(nextPrayer);
    
    // لون خلفية الصفحة بناءً على الصلاة الحالية
    Color backgroundColor = Theme.of(context).primaryColor;
    String currentPrayerKey = _getPrayerKey(currentPrayer);
    if (_prayerColors.containsKey(currentPrayerKey)) {
      backgroundColor = _prayerColors[currentPrayerKey]!;
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor.withOpacity(0.7),
            backgroundColor.withOpacity(0.4),
          ],
        ),
      ),
      child: AnimationLimiter(
        child: SafeArea(
          child: Column(
            children: [
              // المساحة الفارغة في الأعلى للـ AppBar
              const SizedBox(height: 60),
              
              // التاريخ الهجري والميلادي
              _buildDateHeader(now, dateFormat),
              
              // الوقت الحالي والصلاة الحالية
              _buildCurrentTimeSection(currentPrayerName, nextPrayerName, nextPrayer, prayerTimes),
              
              // قائمة مواقيت الصلوات
              _buildPrayerTimesList(prayerTimes, now, timeFormat, currentPrayer),
              
              // التذكير باتجاه القبلة
              _buildQiblaReminder(),
            ],
          ),
        ),
      ),
    );
  }
  
  // عنوان التاريخ
  Widget _buildDateHeader(DateTime now, DateFormat dateFormat) {
    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(now),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // يمكن إضافة التاريخ الهجري هنا
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // قسم الوقت الحالي والصلاة القادمة
  Widget _buildCurrentTimeSection(
    String currentPrayerName,
    String nextPrayerName,
    adhan.Prayer nextPrayer,
    PrayerTimes prayerTimes,
  ) {
    final nextPrayerTime = prayerTimes.getTimeForPrayer(nextPrayer);
    final now = DateTime.now();
    final remaining = nextPrayerTime.difference(now);
    
    // تنسيق الوقت المتبقي
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
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
    
    return AnimationConfiguration.staggeredList(
      position: 1,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الصلاة الحالية',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentPrayerName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'الصلاة القادمة',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextPrayerName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Divider(color: Colors.white30, thickness: 1),
                const SizedBox(height: 20),
                
                const Text(
                  'متبقي حتى الصلاة القادمة',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      remainingText,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    DateFormat.jm().format(nextPrayerTime),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // قائمة مواقيت الصلوات
  Widget _buildPrayerTimesList(
    PrayerTimes prayerTimes,
    DateTime now,
    DateFormat timeFormat,
    adhan.Prayer currentPrayer,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'مواقيت الصلاة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DateFormat.jm().format(now),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _prayerInfo.length,
                itemBuilder: (context, index) {
                  final prayer = _prayerInfo[index];
                  final prayerKey = prayer['key'] as String;
                  final prayerName = prayer['name'] as String;
                  final prayerIcon = prayer['icon'] as IconData;
                  
                  // الحصول على وقت الصلاة
                  DateTime prayerTime;
                  switch (prayerKey) {
                    case 'fajr': prayerTime = prayerTimes.fajr; break;
                    case 'sunrise': prayerTime = prayerTimes.sunrise; break;
                    case 'dhuhr': prayerTime = prayerTimes.dhuhr; break;
                    case 'asr': prayerTime = prayerTimes.asr; break;
                    case 'maghrib': prayerTime = prayerTimes.maghrib; break;
                    case 'isha': prayerTime = prayerTimes.isha; break;
                    default: prayerTime = now;
                  }
                  
                  // تحديد ما إذا كانت الصلاة الحالية
                  bool isCurrentPrayer = _isPrayerCurrent(currentPrayer, prayerKey);
                  
                  // تحديد لون الصلاة
                  Color prayerColor = _prayerColors[prayerKey] ?? Theme.of(context).primaryColor;
                  
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 300),
                    child: SlideAnimation(
                      horizontalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildPrayerTimeItem(
                          prayerName,
                          prayerTime,
                          timeFormat,
                          isCurrentPrayer,
                          prayerIcon,
                          prayerColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // عنصر وقت الصلاة
  Widget _buildPrayerTimeItem(
    String prayerName,
    DateTime prayerTime,
    DateFormat formatter,
    bool isCurrentPrayer,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentPrayer 
            ? Colors.white.withOpacity(0.25) 
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: isCurrentPrayer
            ? Border.all(color: Colors.white, width: 1.5)
            : null,
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // يمكن إضافة تفاصيل أكثر عند النقر
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCurrentPrayer 
                      ? Colors.white.withOpacity(0.3) 
                      : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayerName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isCurrentPrayer ? FontWeight.bold : FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                    if (isCurrentPrayer) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'الصلاة الحالية',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrentPrayer 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  formatter.format(prayerTime),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCurrentPrayer ? FontWeight.bold : FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // التذكير باتجاه القبلة
  Widget _buildQiblaReminder() {
    return AnimationConfiguration.staggeredList(
      position: 9,
      duration: const Duration(milliseconds: 700),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/qibla');
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.explore,
                          color: _prayerColors['maghrib'],
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اتجاه القبلة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'اضغط للتحقق من اتجاه القبلة الصحيح',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // تحويل نوع الصلاة إلى الاسم
  String _getPrayerName(adhan.Prayer prayer) {
    switch (prayer.toString()) {
      case 'Prayer.fajr': return 'الفجر';
      case 'Prayer.sunrise': return 'الشروق';
      case 'Prayer.dhuhr': return 'الظهر';
      case 'Prayer.asr': return 'العصر';
      case 'Prayer.maghrib': return 'المغرب';
      case 'Prayer.isha': return 'العشاء';
      case 'Prayer.none': return 'غير محدد';
      default: return '';
    }
  }
  
  // تحويل نوع الصلاة إلى المفتاح
  String _getPrayerKey(adhan.Prayer prayer) {
    switch (prayer.toString()) {
      case 'Prayer.fajr': return 'fajr';
      case 'Prayer.sunrise': return 'sunrise';
      case 'Prayer.dhuhr': return 'dhuhr';
      case 'Prayer.asr': return 'asr';
      case 'Prayer.maghrib': return 'maghrib';
      case 'Prayer.isha': return 'isha';
      default: return 'isha'; // افتراضي
    }
  }
  
  // التحقق مما إذا كانت الصلاة الحالية
  bool _isPrayerCurrent(adhan.Prayer currentPrayer, String prayerKey) {
    final currentPrayerKey = _getPrayerKey(currentPrayer);
    return currentPrayerKey == prayerKey;
  }
}