// lib/features/prayers/presentation/screens/prayer_notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/interfaces/notification_service.dart';
import '../../../../core/services/utils/notification_scheduler.dart';
import '../../../../app/themes/loading_widget.dart';
import '../providers/prayer_times_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class PrayerNotificationSettingsScreen extends StatefulWidget {
  const PrayerNotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrayerNotificationSettingsScreen> createState() => _PrayerNotificationSettingsScreenState();
}

class _PrayerNotificationSettingsScreenState extends State<PrayerNotificationSettingsScreen> 
    with SingleTickerProviderStateMixin {
  // للتحكم في الإشعارات
  late final NotificationService _notificationService;
  late final NotificationScheduler _notificationScheduler;
  
  late final AnimationController _animationController;
  bool _isLoading = true;
  bool _hasNotificationPermission = true;
  bool _isGlobalMuteEnabled = false;
  
  // قائمة الصلوات مع معلوماتها
  final List<Map<String, dynamic>> _prayers = [
    {
      'id': 'fajr',
      'title': 'صلاة الفجر',
      'icon': Icons.wb_twilight,
      'color': const Color(0xFF5C6BC0),
      'defaultMinutes': 15,
    },
    {
      'id': 'dhuhr',
      'title': 'صلاة الظهر',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFFFFB74D),
      'defaultMinutes': 15,
    },
    {
      'id': 'asr',
      'title': 'صلاة العصر',
      'icon': Icons.wb_cloudy,
      'color': const Color(0xFF66BB6A),
      'defaultMinutes': 15,
    },
    {
      'id': 'maghrib',
      'title': 'صلاة المغرب',
      'icon': Icons.nights_stay_rounded,
      'color': const Color(0xFFAB47BC),
      'defaultMinutes': 15,
    },
    {
      'id': 'isha',
      'title': 'صلاة العشاء',
      'icon': Icons.nightlight_round,
      'color': const Color(0xFF4DB6AC),
      'defaultMinutes': 15,
    },
    {
      'id': 'qibla',
      'title': 'تذكير باتجاه القبلة',
      'icon': Icons.explore,
      'color': const Color(0xFFE57373),
      'defaultMinutes': 0,
    },
  ];
  
  // حالة تفعيل كل صلاة
  Map<String, bool> _prayerNotificationEnabled = {};
  // وقت الإشعار المسبق (بالدقائق) لكل صلاة
  Map<String, int> _prayerNotificationMinutes = {};
  
  @override
  void initState() {
    super.initState();
    
    try {
      // استخدام serviceLocator للحصول على خدمات الإشعارات
      // _notificationService = serviceLocator<NotificationService>();
      // _notificationScheduler = serviceLocator<NotificationScheduler>();
    } catch (e) {
      debugPrint('Error loading notification services: $e');
    }
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _checkPermissions();
    _loadGlobalMuteStatus();
    _loadPrayerNotificationSettings();
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // التحقق من أذونات الإشعارات
  Future<void> _checkPermissions() async {
    try {
      final status = await Permission.notification.status;
      
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        setState(() {
          _hasNotificationPermission = result.isGranted;
        });
      } else {
        setState(() {
          _hasNotificationPermission = true;
        });
      }
      
      try {
        if (await Permission.scheduleExactAlarm.isDenied) {
          await Permission.scheduleExactAlarm.request();
        }
      } catch (e) {
        debugPrint('Error requesting scheduleExactAlarm permission: $e');
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      setState(() {
        _hasNotificationPermission = false;
      });
    }
  }
  
  // تحميل حالة الوضع الصامت العام
  Future<void> _loadGlobalMuteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGlobalMuteEnabled = prefs.getBool('prayers_global_mute_notifications') ?? false;
    });
  }
  
  // تحميل إعدادات إشعارات الصلوات
  Future<void> _loadPrayerNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    Map<String, bool> enabledMap = {};
    Map<String, int> minutesMap = {};
    
    for (var prayer in _prayers) {
      final prayerId = prayer['id'] as String;
      enabledMap[prayerId] = prefs.getBool('prayer_notification_enabled_$prayerId') ?? true;
      minutesMap[prayerId] = prefs.getInt('prayer_notification_minutes_$prayerId') ?? prayer['defaultMinutes'] as int;
    }
    
    setState(() {
      _prayerNotificationEnabled = enabledMap;
      _prayerNotificationMinutes = minutesMap;
    });
  }
  
  // حفظ حالة الوضع الصامت
  Future<void> _toggleGlobalMute(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prayers_global_mute_notifications', value);
    setState(() {
      _isGlobalMuteEnabled = value;
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              value ? Icons.notifications_off : Icons.notifications_active,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(value ? 'تم تفعيل الوضع الصامت' : 'تم إلغاء الوضع الصامت'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: value ? Colors.grey.shade700 : Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // تحديث حالة الإشعارات
    if (!value) {
      // إعادة جدولة الإشعارات المفعلة
      for (var prayer in _prayers) {
        final prayerId = prayer['id'] as String;
        if (_prayerNotificationEnabled[prayerId] == true) {
          _schedulePrayerNotification(prayerId);
        }
      }
    } else {
      // إلغاء جميع الإشعارات
      _cancelAllNotifications();
    }
  }
  
  // جدولة إشعار لصلاة معينة
  Future<void> _schedulePrayerNotification(String prayerId) async {
    // تنفيذ الجدولة باستخدام _notificationScheduler
    // تنفيذ الكود الفعلي سيعتمد على كيفية تنفيذ خدمات الإشعارات لديك
    debugPrint('Scheduling notification for prayer: $prayerId');
  }
  
  // إلغاء جميع الإشعارات
  Future<void> _cancelAllNotifications() async {
    // تنفيذ الإلغاء باستخدام _notificationService
    debugPrint('Cancelling all prayer notifications');
  }
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    
    return Scaffold(
      backgroundColor: surfaceColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'إشعارات الصلاة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'المساعدة',
            onPressed: _showHelp,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return _buildLoadingIndicator();
          }
          
          return Consumer2<PrayerTimesProvider, SettingsProvider>(
            builder: (context, prayerProvider, settingsProvider, _) {
              final todayPrayerTimes = prayerProvider.todayPrayerTimes;
              
              return AnimationLimiter(
                child: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 600),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        // بطاقة التحقق من الأذونات
                        if (!_hasNotificationPermission) _buildPermissionCard(),
                        
                        // بطاقة الوضع الصامت
                        _buildGlobalMuteCard(),
                        const SizedBox(height: 16),
                        
                        // الإجراءات السريعة
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        
                        // عرض التوقيت الحالي
                        _buildCurrentTimeCard(prayerProvider, todayPrayerTimes),
                        const SizedBox(height: 16),
                        
                        // عنوان الإعدادات
                        _buildSectionTitle('إعدادات الإشعارات'),
                        const SizedBox(height: 16),
                        
                        // قائمة الصلوات
                        ..._prayers.map((prayer) {
                          final prayerId = prayer['id'] as String;
                          // الحصول على وقت الصلاة إذا كان متاحًا
                          DateTime? prayerTime;
                          if (todayPrayerTimes != null) {
                            switch (prayerId) {
                              case 'fajr': prayerTime = todayPrayerTimes.fajr; break;
                              case 'dhuhr': prayerTime = todayPrayerTimes.dhuhr; break;
                              case 'asr': prayerTime = todayPrayerTimes.asr; break;
                              case 'maghrib': prayerTime = todayPrayerTimes.maghrib; break;
                              case 'isha': prayerTime = todayPrayerTimes.isha; break;
                              case 'qibla': prayerTime = null; break;
                            }
                          }
                          
                          return _buildPrayerNotificationCard(
                            prayer, 
                            prayerTime,
                            _prayerNotificationEnabled[prayerId] ?? true,
                            _prayerNotificationMinutes[prayerId] ?? prayer['defaultMinutes'] as int,
                          );
                        }),
                        
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  // مؤشر التحميل
  Widget _buildLoadingIndicator() {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingWidget(),
          const SizedBox(height: 20),
          Text(
            'جاري التحميل...',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  // بطاقة الأذونات
  Widget _buildPermissionCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.orange.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_off_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الأذونات مطلوبة',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بأوقات الصلاة',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => openAppSettings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'منح الإذن',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // بطاقة الوضع الصامت العام
  Widget _buildGlobalMuteCard() {
    final primaryColor = Theme.of(context).primaryColor;
    final greenColor = Color(0xFF2D6852);
    
    return Card(
      elevation: 8,
      shadowColor: _isGlobalMuteEnabled ? Colors.grey.withOpacity(0.4) : greenColor.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: _isGlobalMuteEnabled
                ? [Colors.grey.shade600, Colors.grey.shade800]
                : [primaryColor, greenColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isGlobalMuteEnabled ? Icons.notifications_off_rounded : Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الوضع الصامت',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isGlobalMuteEnabled ? 'جميع إشعارات الصلاة مغلقة' : 'إشعارات الصلاة نشطة',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 1.3,
                    child: Switch(
                      value: _isGlobalMuteEnabled,
                      onChanged: _hasNotificationPermission ? _toggleGlobalMute : null,
                      activeColor: Colors.white,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white30,
                      trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // عنوان القسم
  Widget _buildSectionTitle(String title) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
  
  // بطاقة عرض التوقيت الحالي
  Widget _buildCurrentTimeCard(PrayerTimesProvider provider, dynamic todayPrayerTimes) {
    final primaryColor = Theme.of(context).primaryColor;
    final timeFormat = DateFormat.jm();
    final dateFormat = DateFormat('EEEE, d MMMM', 'ar');
    final now = DateTime.now();
    
    String nextPrayerName = "";
    String nextPrayerTime = "";
    
    if (todayPrayerTimes != null) {
      // الحصول على الصلاة التالية
      final nextPrayer = todayPrayerTimes.getNextPrayer();
      
      // الحصول على اسم الصلاة التالية
      switch (nextPrayer.toString()) {
        case 'Prayer.fajr': nextPrayerName = 'الفجر'; break;
        case 'Prayer.sunrise': nextPrayerName = 'الشروق'; break;
        case 'Prayer.dhuhr': nextPrayerName = 'الظهر'; break;
        case 'Prayer.asr': nextPrayerName = 'العصر'; break;
        case 'Prayer.maghrib': nextPrayerName = 'المغرب'; break;
        case 'Prayer.isha': nextPrayerName = 'العشاء'; break;
        default: nextPrayerName = 'القادمة';
      }
      
      // الحصول على وقت الصلاة التالية
      final prayerDateTime = todayPrayerTimes.getTimeForPrayer(nextPrayer);
      nextPrayerTime = timeFormat.format(prayerDateTime);
    }
    
    return Card(
      elevation: 8,
      shadowColor: primaryColor.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    dateFormat.format(now),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (todayPrayerTimes != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'الصلاة القادمة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        nextPrayerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      nextPrayerTime,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Center(
                  child: Text(
                    'لم يتم تحميل مواقيت الصلاة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      final provider = Provider.of<PrayerTimesProvider>(context, listen: false);
                      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                      
                      if (settingsProvider.settings != null) {
                        provider.loadTodayPrayerTimes(settingsProvider.settings!);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'تحميل مواقيت الصلاة',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
    
  // الإجراءات السريعة
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.notifications_active_rounded,
            title: 'تفعيل الكل',
            color: Colors.green.shade600,
            onTap: () => _toggleAllNotifications(true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.notifications_off_rounded,
            title: 'إيقاف الكل',
            color: Colors.red.shade600,
            onTap: () => _toggleAllNotifications(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.refresh_rounded,
            title: 'استعادة الافتراضي',
            color: Colors.blue.shade600,
            onTap: _resetAllSettings,
          ),
        ),
      ],
    );
  }
  
  // بطاقة الإجراء السريع
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          if (!_isGlobalMuteEnabled) {
            HapticFeedback.lightImpact();
            onTap();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: _isGlobalMuteEnabled 
                ? [color.withOpacity(0.3), color.withOpacity(0.5)]
                : [color.withOpacity(0.9), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // تفعيل/إيقاف جميع الإشعارات
  Future<void> _toggleAllNotifications(bool enable) async {
    if (!_hasNotificationPermission) {
      _showPermissionDialog();
      return;
    }
    
    if (_isGlobalMuteEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('الرجاء إلغاء تفعيل الوضع الصامت أولًا'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحديث حالة التفعيل لجميع الصلوات
      for (var prayer in _prayers) {
        final prayerId = prayer['id'] as String;
        await prefs.setBool('prayer_notification_enabled_$prayerId', enable);
        _prayerNotificationEnabled[prayerId] = enable;
      }
      
      if (enable) {
        // جدولة الإشعارات
        for (var prayer in _prayers) {
          final prayerId = prayer['id'] as String;
          _schedulePrayerNotification(prayerId);
        }
        
        // رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('تم تفعيل جميع الإشعارات بنجاح'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        // إلغاء الإشعارات
        _cancelAllNotifications();
        
        // رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.notifications_off_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('تم إيقاف جميع الإشعارات بنجاح'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      
      setState(() {});
    } catch (e) {
      debugPrint('Error toggling all notifications: $e');
      _showErrorDialog('خطأ', 'حدث خطأ أثناء تحديث إعدادات الإشعارات:\n${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // إعادة ضبط جميع الإعدادات
  Future<void> _resetAllSettings() async {
    if (!_hasNotificationPermission) {
      _showPermissionDialog();
      return;
    }
    
    if (_isGlobalMuteEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('الرجاء إلغاء تفعيل الوضع الصامت أولًا'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // تأكيد العملية
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('تأكيد إعادة الضبط'),
          ],
        ),
        content: const Text('هل أنت متأكد من إعادة ضبط جميع إعدادات الإشعارات إلى الحالة الافتراضية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('موافق', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // إعادة ضبط جميع الإعدادات
      for (var prayer in _prayers) {
        final prayerId = prayer['id'] as String;
        final defaultMinutes = prayer['defaultMinutes'] as int;
        
        // إعادة ضبط حالة التفعيل
        await prefs.setBool('prayer_notification_enabled_$prayerId', true);
        _prayerNotificationEnabled[prayerId] = true;
        
        // إعادة ضبط دقائق الإشعار المسبق
        await prefs.setInt('prayer_notification_minutes_$prayerId', defaultMinutes);
        _prayerNotificationMinutes[prayerId] = defaultMinutes;
      }
      
      // إعادة جدولة الإشعارات
      for (var prayer in _prayers) {
        final prayerId = prayer['id'] as String;
        _schedulePrayerNotification(prayerId);
      }
      
      // رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.settings_backup_restore_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('تم إعادة ضبط جميع الإعدادات بنجاح'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blue.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
      
      setState(() {});
    } catch (e) {
      debugPrint('Error resetting all settings: $e');
      _showErrorDialog('خطأ', 'حدث خطأ أثناء إعادة ضبط الإعدادات:\n${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // بطاقة إشعار الصلاة
  Widget _buildPrayerNotificationCard(
    Map<String, dynamic> prayer,
    DateTime? prayerTime,
    bool isEnabled,
    int notificationMinutes,
  ) {
    final prayerId = prayer['id'] as String;
    final categoryColor = prayer['color'] as Color;
    final timeFormat = DateFormat.jm();
    final prayerTimeFormatted = prayerTime != null ? timeFormat.format(prayerTime) : '-';
    
    // حساب وقت الإشعار المسبق
    String notificationTimeFormatted = '-';
    if (prayerTime != null && notificationMinutes > 0) {
      final notificationTime = prayerTime.subtract(Duration(minutes: notificationMinutes));
      notificationTimeFormatted = timeFormat.format(notificationTime);
    } else if (prayerId == 'qibla') {
      // للقبلة، نستخدم وقتًا محددًا مثل 10:00 صباحًا
      notificationTimeFormatted = '10:00 AM';
    }
    
    return Card(
      elevation: 8,
      shadowColor: categoryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              categoryColor.withOpacity(0.8),
              categoryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // أيقونة الصلاة
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      prayer['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // تفاصيل الصلاة
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (prayerTime != null || prayerId == 'qibla') ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      prayerTimeFormatted,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              isEnabled && !_isGlobalMuteEnabled ? 'مفعل' : 'غير مفعل',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // مفتاح التبديل
                  Transform.scale(
                    scale: 1.2,
                    child: Switch(
                      value: isEnabled && !_isGlobalMuteEnabled,
                      onChanged: _hasNotificationPermission && !_isGlobalMuteEnabled
                          ? (value) => _togglePrayerNotification(prayer, value)
                          : null,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white.withOpacity(0.5),
                      inactiveThumbColor: Colors.white60,
                      inactiveTrackColor: Colors.white30,
                      trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                    ),
                  ),
                ],
              ),
              
              if (prayerTime != null || prayerId == 'qibla') ...[
                const SizedBox(height: 20),
                
                // معلومات الإشعار
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'وقت الإشعار',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              notificationTimeFormatted,
                              style: TextStyle(
                                color: categoryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // شريط تمرير لتعديل وقت الإشعار المسبق
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Text(
                              'قبل بـ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Slider(
                                value: notificationMinutes.toDouble(),
                                min: 0,
                                max: prayerId == 'qibla' ? 0 : 60,
                                divisions: prayerId == 'qibla' ? 1 : 12,
                                activeColor: Colors.white,
                                inactiveColor: Colors.white.withOpacity(0.3),
                                onChanged: _isGlobalMuteEnabled 
                                    ? null 
                                    : (value) => _updatePrayerNotificationMinutes(prayer, value.round()),
                              ),
                            ),
                            Container(
                              width: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '$notificationMinutes ${prayerId == 'qibla' ? '' : 'دقيقة'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  // تبديل حالة إشعار الصلاة
  Future<void> _togglePrayerNotification(Map<String, dynamic> prayer, bool value) async {
    final prayerId = prayer['id'] as String;
    final prayerTitle = prayer['title'] as String;
    final prayerColor = prayer['color'] as Color;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('prayer_notification_enabled_$prayerId', value);
      
      setState(() {
        _prayerNotificationEnabled[prayerId] = value;
      });
      
      // تأثير اهتزاز خفيف
      HapticFeedback.lightImpact();
      
      if (value) {
        // جدولة الإشعار
        _schedulePrayerNotification(prayerId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 10),
                Text('تم تفعيل إشعار $prayerTitle'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: prayerColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // إلغاء الإشعار
        // طبق كود إلغاء الإشعار هنا
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_off, color: Colors.white),
                const SizedBox(width: 10),
                Text('تم إيقاف إشعار $prayerTitle'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.grey.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling prayer notification: $e');
      _showErrorDialog('خطأ', 'حدث خطأ أثناء تحديث إعدادات الإشعار:\n${e.toString()}');
    }
  }
  
  // تحديث وقت الإشعار المسبق
  Future<void> _updatePrayerNotificationMinutes(Map<String, dynamic> prayer, int minutes) async {
    final prayerId = prayer['id'] as String;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('prayer_notification_minutes_$prayerId', minutes);
      
      setState(() {
        _prayerNotificationMinutes[prayerId] = minutes;
      });
      
      // إعادة جدولة الإشعار إذا كان مفعلاً
      if (_prayerNotificationEnabled[prayerId] == true && !_isGlobalMuteEnabled) {
        _schedulePrayerNotification(prayerId);
      }
    } catch (e) {
      debugPrint('Error updating prayer notification minutes: $e');
    }
  }
  
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('الإذن مطلوب'),
          ],
        ),
        content: const Text('يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بأوقات الصلاة'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('فتح الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حسناً', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  // عرض المساعدة
  void _showHelp() {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'المساعدة والدعم',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHelpCard(
                    'كيفية تفعيل الإشعارات',
                    'اتبع الخطوات التالية لتفعيل إشعارات الصلاة:\n\n1. اضغط على زر الإذن\n2. قم بتفعيل إذن الإشعارات\n3. ارجع إلى التطبيق وقم بتفعيل الإشعارات التي تريدها',
                    Icons.notifications_active_rounded,
                  ),
                  _buildHelpCard(
                    'ضبط وقت الإشعار',
                    'يمكنك تحديد وقت الإشعار المسبق للصلاة عن طريق تحريك شريط التمرير. على سبيل المثال، إذا كنت تريد إشعارًا قبل 15 دقيقة من وقت الصلاة، اضبط القيمة على 15.',
                    Icons.timer,
                  ),
                  _buildHelpCard(
                    'الوضع الصامت',
                    'عند تفعيل الوضع الصامت، سيتم إيقاف جميع إشعارات الصلاة مؤقتًا دون الحاجة لإيقاف كل إشعار على حدة. يمكنك إلغاء الوضع الصامت في أي وقت لاستعادة الإشعارات.',
                    Icons.notifications_off_rounded,
                  ),
                  _buildHelpCard(
                    'إدارة الإشعارات',
                    'استخدم أزرار "تفعيل الكل" أو "إيقاف الكل" في أعلى الصفحة لإدارة جميع إشعارات الصلاة دفعة واحدة.',
                    Icons.settings_rounded,
                  ),
                  _buildHelpCard(
                    'استعادة الإعدادات الافتراضية',
                    'يمكنك استعادة جميع إعدادات الإشعارات إلى الحالة الافتراضية عن طريق النقر على زر "استعادة الافتراضي".',
                    Icons.refresh_rounded,
                  ),
                  _buildHelpCard(
                    'حل المشكلات',
                    'إذا لم تظهر إشعارات الصلاة على جهازك، تأكد من إتباع الخطوات التالية:\n\n1. تأكد من منح الإذن للتطبيق في إعدادات جهازك\n2. تأكد من أن الوضع الصامت غير مفعل\n3. تأكد من تفعيل الإشعار المطلوب\n\nإذا استمرت المشكلة، جرب إعادة تشغيل التطبيق أو الجهاز.',
                    Icons.bug_report_rounded,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'حسناً، فهمت',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // بطاقة المساعدة
  Widget _buildHelpCard(String title, String content, IconData icon) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Card(
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: primaryColor,
          ),
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}