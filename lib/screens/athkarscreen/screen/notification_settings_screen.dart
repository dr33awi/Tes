// lib/screens/athkarscreen/screen/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:test_athkar_app/services/notification/notification_manager.dart';
import 'package:test_athkar_app/services/di_container.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/athkar_service.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart' 
    show kPrimary, kSurface;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> 
    with SingleTickerProviderStateMixin {
  late final NotificationManager _notificationManager;
  late final AthkarService _athkarService;
  late final ErrorLoggingService _errorLoggingService;
  late final AnimationController _animationController;
  
  bool _isLoading = false;
  bool _hasNotificationPermission = true;
  bool _isGlobalMuteEnabled = false;
  
  // قائمة الفئات مع معلوماتها
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'morning',
      'title': 'أذكار الصباح',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFFFFD54F),
      'defaultTime': '06:00',
    },
    {
      'id': 'evening',
      'title': 'أذكار المساء',
      'icon': Icons.nightlight_round,
      'color': const Color(0xFFAB47BC),
      'defaultTime': '18:00',
    },
    {
      'id': 'sleep',
      'title': 'أذكار النوم',
      'icon': Icons.bedtime_rounded,
      'color': const Color(0xFF5C6BC0),
      'defaultTime': '22:00',
    },
    {
      'id': 'wake',
      'title': 'أذكار الاستيقاظ',
      'icon': Icons.alarm_rounded,
      'color': const Color(0xFFFFB74D),
      'defaultTime': '05:30',
    },
    {
      'id': 'prayer',
      'title': 'أذكار الصلاة',
      'icon': Icons.mosque_rounded,
      'color': const Color(0xFF4DB6AC),
      'defaultTime': '12:00',
    },
    {
      'id': 'home',
      'title': 'أذكار المنزل',
      'icon': Icons.home_rounded,
      'color': const Color(0xFF66BB6A),
      'defaultTime': '18:00',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _notificationManager = serviceLocator<NotificationManager>();
    _athkarService = AthkarService();
    _errorLoggingService = serviceLocator<ErrorLoggingService>();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _checkPermissions();
    _loadGlobalMuteStatus();
    
    // التأكد من تهيئة الإشعارات
    _initializeNotifications();
  }
  
  // تهيئة الإشعارات
  Future<void> _initializeNotifications() async {
    try {
      // تهيئة الإشعارات إذا لم تكن مُهيأة بعد
      final initialized = await _notificationManager.initialize();
      if (!initialized) {
        debugPrint('فشل في تهيئة الإشعارات');
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      await _errorLoggingService.logError(
        'NotificationSettings',
        'Error initializing notifications',
        e,
      );
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // التحقق من الأذونات
  Future<void> _checkPermissions() async {
    try {
      // التحقق من إذن الإشعارات
      final status = await Permission.notification.status;
      
      if (!status.isGranted) {
        // طلب الإذن إذا لم يكن ممنوحًا
        final result = await Permission.notification.request();
        setState(() {
          _hasNotificationPermission = result.isGranted;
        });
      } else {
        setState(() {
          _hasNotificationPermission = true;
        });
      }
      
      // التحقق من إذن جدولة التنبيهات الدقيقة
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationSettings',
        'Error checking permissions',
        e,
      );
      setState(() {
        _hasNotificationPermission = false;
      });
    }
  }
  
  // تحميل حالة الوضع الصامت العام
  Future<void> _loadGlobalMuteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGlobalMuteEnabled = prefs.getBool('global_mute_notifications') ?? false;
    });
  }
  
  // حفظ حالة الوضع الصامت
  Future<void> _toggleGlobalMute(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('global_mute_notifications', value);
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
        backgroundColor: value ? Colors.grey.shade700 : kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final greenColor = const Color(0xFF2D6852);
    
    return Scaffold(
      backgroundColor: kSurface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'إعدادات الإشعارات',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // زر المساعدة
          IconButton(
            icon: const Icon(Icons.help_outline, color: kPrimary),
            tooltip: 'المساعدة',
            onPressed: _showHelp,
          ),
        ],
      ),
      body: _isLoading 
        ? _buildLoadingIndicator()
        : AnimationLimiter(
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
                    
                    // عنوان الفئات
                    _buildSectionTitle('إعدادات الفئات'),
                    const SizedBox(height: 16),
                    
                    // قائمة الفئات
                    ..._categories.map((category) => _buildCategoryCard(category)),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
    );
  }
  
  // مؤشر التحميل
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: kPrimary,
            size: 50,
          ),
          const SizedBox(height: 20),
          const Text(
            'جاري التحميل...',
            style: TextStyle(
              color: kPrimary,
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
                          'يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بالأذكار',
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
    final greenColor = const Color(0xFF2D6852);
    
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
                : [kPrimary, greenColor],
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
                    child: Icon(
                      _isGlobalMuteEnabled ? Icons.notifications_off_rounded : Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 28,
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
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isGlobalMuteEnabled ? 'جميع الإشعارات مغلقة' : 'الإشعارات نشطة',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 1.2,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: kPrimary,
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
            title: 'جدولة الكل',
            color: Colors.green.shade600,
            onTap: _scheduleAllNotifications,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.notifications_off_rounded,
            title: 'إلغاء الكل',
            color: Colors.red.shade600,
            onTap: _cancelAllNotifications,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.refresh_rounded,
            title: 'إعادة ضبط',
            color: Colors.blue.shade600,
            onTap: _resetAllNotificationSettings,
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
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.9), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // بطاقة الفئة
  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCategoryInfo(category['id']),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data?['isEnabled'] ?? false;
        final customTime = snapshot.data?['customTime'];
        final currentTime = customTime ?? category['defaultTime'];
        final Color categoryColor = category['color'] as Color;
        
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // أيقونة الفئة
                      Container(
                        padding: const EdgeInsets.all(12),
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
                          category['icon'] as IconData,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // تفاصيل الفئة
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        currentTime,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                        scale: 1.1,
                        child: Switch(
                          value: isEnabled && !_isGlobalMuteEnabled,
                          onChanged: _hasNotificationPermission && !_isGlobalMuteEnabled
                              ? (value) => _toggleCategoryNotification(category, value)
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
                  const SizedBox(height: 16),
                  
                  // زر تغيير الوقت
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGlobalMuteEnabled 
                              ? null 
                              : () => _selectTime(category, currentTime),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            disabledBackgroundColor: Colors.white.withOpacity(0.1),
                            disabledForegroundColor: Colors.white.withOpacity(0.4),
                          ),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text(
                            'تغيير الوقت',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // زر إعادة ضبط الوقت الافتراضي
                      ElevatedButton(
                        onPressed: _isGlobalMuteEnabled 
                            ? null 
                            : () => _resetCategoryDefaultTime(category),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          disabledBackgroundColor: Colors.white.withOpacity(0.1),
                          disabledForegroundColor: Colors.white.withOpacity(0.4),
                        ),
                        child: const Icon(Icons.restore, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // الحصول على معلومات الفئة
  Future<Map<String, dynamic>> _getCategoryInfo(String categoryId) async {
    try {
      final isEnabled = await _athkarService.getNotificationEnabled(categoryId);
      final customTime = await _athkarService.getCustomNotificationTime(categoryId);
      
      // إذا كان الوقت المخصص غير موجود (null)، استخدم الوقت الافتراضي
      final category = _categories.firstWhere(
        (cat) => cat['id'] == categoryId,
        orElse: () => {'defaultTime': '12:00'}, // قيمة افتراضية إذا لم يجد الفئة
      );
      
      return {
        'isEnabled': isEnabled,
        'customTime': customTime ?? category['defaultTime'],
      };
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationSettings',
        'Error getting category info: $categoryId',
        e,
      );
      return {'isEnabled': false, 'customTime': '12:00'}; // قيمة افتراضية في حالة الخطأ
    }
  }
  
  // اختيار الوقت
  Future<void> _selectTime(Map<String, dynamic> category, String currentTime) async {
    final categoryId = category['id'];
    // استخدام اللون الأخضر بدلاً من لون الفئة
    final greenColor = const Color(0xFF2D6852);
    
    try {
      final parts = currentTime.split(':');
      final initialTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
      
      // تأثير اهتزاز خفيف
      HapticFeedback.lightImpact();
      
      final time = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: greenColor,
                onPrimary: Colors.white,
                onSurface: greenColor,
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                dayPeriodShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                dayPeriodColor: greenColor.withOpacity(0.1),
                dayPeriodTextColor: greenColor,
                hourMinuteColor: greenColor.withOpacity(0.1),
                hourMinuteTextColor: greenColor,
                dialHandColor: greenColor,
                dialBackgroundColor: greenColor.withOpacity(0.1),
                hourMinuteTextStyle: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                dayPeriodTextStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                helpTextStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: greenColor,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: greenColor),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                dialTextColor: MaterialStateColor.resolveWith((states) => 
                  states.contains(MaterialState.selected) ? Colors.white : greenColor),
                entryModeIconColor: greenColor,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (time != null) {
        final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        await _athkarService.setCustomNotificationTime(categoryId, formattedTime);
        
        // إذا كانت الإشعارات مفعلة، فأعد جدولتها
        if (await _athkarService.getNotificationEnabled(categoryId) && !_isGlobalMuteEnabled) {
          await _athkarService.scheduleCategoryNotifications(categoryId);
        }
        
        setState(() {});
        
        // تأثير اهتزاز خفيف
        HapticFeedback.mediumImpact();
        
        // إظهار رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text('تم تحديث الوقت إلى $formattedTime'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: greenColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationSettings',
        'Error selecting time',
        e,
      );
      
      _showErrorDialog('خطأ في تحديد الوقت', 'حدث خطأ أثناء تحديد الوقت. يرجى المحاولة مرة أخرى.');
    }
  }
  
  // تبديل حالة إشعار الفئة
  Future<void> _toggleCategoryNotification(Map<String, dynamic> category, bool value) async {
    final categoryId = category['id'];
    final categoryColor = category['color'] as Color;
    final categoryTitle = category['title'] as String;
    
    // لا نستخدم setState لتحميل كامل الصفحة
    try {
      // إظهار مؤشر تحميل مؤقت
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 10),
              Text('جاري ${value ? 'تفعيل' : 'إيقاف'} الإشعارات...'),
            ],
          ),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
      
      // تأثير اهتزاز خفيف
      HapticFeedback.lightImpact();
      
      if (value) {
        // تفعيل الإشعارات
        // الحصول على وقت الإشعار
        final customTime = await _athkarService.getCustomNotificationTime(categoryId);
        final defaultTime = category['defaultTime'] as String;
        final timeString = customTime ?? defaultTime;
        
        // تحويل الوقت إلى TimeOfDay
        final parts = timeString.split(':');
        final time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
        
        // جدولة الإشعارات
        final result = await _notificationManager.scheduleAthkarNotifications(
          categoryId: categoryId,
          categoryTitle: categoryTitle,
          times: [time],
          color: categoryColor,
        );
        
        if (result.success) {
          await _athkarService.setNotificationEnabled(categoryId, true);
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('تم تفعيل إشعارات $categoryTitle'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: categoryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception('فشل في جدولة الإشعارات');
        }
      } else {
        // إيقاف الإشعارات
        final success = await _notificationManager.cancelAthkarNotifications(categoryId);
        
        if (success) {
          await _athkarService.setNotificationEnabled(categoryId, false);
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_off, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('تم إيقاف إشعارات $categoryTitle'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception('فشل في إلغاء الإشعارات');
        }
      }
      
      // تحديث حالة البطاقة فقط بدون إعادة تحميل الصفحة كاملة
      if (mounted) {
        setState(() {
          // سيتم تحديث البطاقة المعنية فقط عن طريق FutureBuilder
        });
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationSettings',
        'Error toggling category notification',
        e,
      );
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorDialog('خطأ', 'حدث خطأ أثناء تغيير حالة الإشعار.\n\nتفاصيل الخطأ:\n${e.toString()}');
    }
  }
  
  // جدولة جميع الإشعارات
  Future<void> _scheduleAllNotifications() async {
    if (!_hasNotificationPermission) {
      _showPermissionDialog();
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // التأكد من تهيئة الإشعارات أولاً
      await _initializeNotifications();
      
      // إلغاء الوضع الصامت إذا كان مفعلاً
      if (_isGlobalMuteEnabled) {
        await _toggleGlobalMute(false);
      }
      
      // جدولة الإشعارات الافتراضية
      await _notificationManager.scheduleDefaultAthkarNotifications();
      
      // تفعيل جميع الفئات في الإعدادات المحلية
      for (var category in _categories) {
        await _athkarService.setNotificationEnabled(category['id'], true);
      }
      
      // تأثير اهتزاز
      HapticFeedback.mediumImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              const Text('تم جدولة جميع الإشعارات بنجاح'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      
      setState(() {});
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationSettings',
        'Error scheduling all notifications',
        e,
      );
      
      _showErrorDialog('خطأ في جدولة الإشعارات', 'حدث خطأ أثناء جدولة الإشعارات.\n\nتفاصيل الخطأ:\n${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // إلغاء جميع الإشعارات
  Future<void> _cancelAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('تأكيد الإلغاء'),
          ],
        ),
        content: const Text('هل أنت متأكد من إلغاء جميع الإشعارات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
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
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    setState(() => _isLoading = true);
    
    try {
      // إلغاء جميع الإشعارات
      final success = await _notificationManager.cancelAllNotifications();
      
      if (success) {
        // إيقاف جميع الإشعارات في الإعدادات
        for (var category in _categories) {
          await _athkarService.setNotificationEnabled(category['id'], false);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.notifications_off_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('تم إلغاء جميع الإشعارات بنجاح'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('فشل في إلغاء الإشعارات');
      }
      
      setState(() {});
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationSettings',
        'Error canceling all notifications',
        e,
      );
      
      _showErrorDialog('خطأ في الإلغاء', 'حدث خطأ أثناء إلغاء الإشعارات.\n\nتفاصيل الخطأ:\n${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // إرسال إشعار تجريبي
  Future<void> _testNotification() async {
    if (!_hasNotificationPermission) {
      _showPermissionDialog();
      return;
    }
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    try {
      // استخدام ID آمن للإشعار التجريبي
      final testId = DateTime.now().millisecondsSinceEpoch ~/ 1000000; // تقسيم على مليون للحصول على رقم صغير
      
      // استخدام scheduleNotification مع وقت فوري
      final success = await _notificationManager.scheduleNotification(
        notificationId: 'test_$testId',
        title: 'إشعار تجريبي',
        body: 'هذا إشعار تجريبي من تطبيق الأذكار',
        notificationTime: TimeOfDay.now(),
        channelId: 'test_channel',
        payload: 'test_notification',
        color: Colors.blue.shade600,
        repeat: false,
        priority: 4,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.notifications_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('تم إرسال إشعار تجريبي'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _showErrorDialog('خطأ', 'فشل في إرسال الإشعار التجريبي');
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationSettings',
        'Error sending test notification',
        e,
      );
      
      _showErrorDialog('خطأ في الإشعار التجريبي', 'حدث خطأ أثناء إرسال الإشعار التجريبي.\n\nتفاصيل الخطأ:\n${e.toString()}');
    }
  }
  
  // عرض المساعدة
  void _showHelp() {
    // تأثير اهتزاز خفيف
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
                  const Icon(
                    Icons.help_outline_rounded,
                    color: kPrimary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'المساعدة والدعم',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
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
                    'اتبع الخطوات التالية لتفعيل الإشعارات:\n\n1. اضغط على زر الإذن\n2. قم بتفعيل إذن الإشعارات\n3. ارجع إلى التطبيق وقم بتفعيل الإشعارات التي تريدها',
                    Icons.notifications_active_rounded,
                  ),
                  _buildHelpCard(
                    'الوضع الصامت',
                    'يمكنك تفعيل الوضع الصامت في أعلى الصفحة لإيقاف جميع الإشعارات مؤقتًا دون الحاجة لإلغاء الجدولة. عند تعطيل الوضع الصامت، ستعود الإشعارات للعمل تلقائيًا.',
                    Icons.notifications_off_rounded,
                  ),
                  _buildHelpCard(
                    'تخصيص الأوقات',
                    'يمكنك تخصيص وقت كل إشعار على حدة من خلال:\n\n1. اضغط على زر "تغيير الوقت" في بطاقة الذكر\n2. اختر الوقت المناسب\n3. اضغط "موافق" لحفظ الإعدادات',
                    Icons.access_time_rounded,
                  ),
                  _buildHelpCard(
                    'إدارة الإشعارات',
                    'استخدم أزرار "جدولة الكل" أو "إلغاء الكل" في أعلى الصفحة لإدارة جميع الإشعارات دفعة واحدة.',
                    Icons.settings_rounded,
                  ),
                  _buildHelpCard(
                    'حل المشكلات',
                    'إذا لم تظهر الإشعارات على جهازك، تأكد من إتباع الخطوات التالية:\n\n1. تأكد من منح الإذن للتطبيق في إعدادات جهازك\n2. تأكد من أن الوضع الصامت غير مفعل\n3. تأكد من تفعيل الإشعار المطلوب\n\nإذا استمرت المشكلة، جرب إعادة تشغيل التطبيق أو الجهاز.',
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
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
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
    return Card(
      elevation: 2,
      shadowColor: kPrimary.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: kPrimary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: kPrimary,
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
        content: const Text('يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بأوقات الأذكار'),
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
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('فتح الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  // إعادة ضبط جميع إعدادات الإشعارات إلى الإعدادات الافتراضية
  Future<void> _resetAllNotificationSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('إعادة ضبط'),
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
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    setState(() => _isLoading = true);
    
    try {
      // إعادة ضبط الوضع الصامت
      if (_isGlobalMuteEnabled) {
        await _toggleGlobalMute(false);
      }
      
      // إلغاء جميع الإشعارات أولاً
      await _notificationManager.cancelAllNotifications();
      
      // إعادة ضبط جميع الأوقات إلى الأوقات الافتراضية لكل فئة
      for (var category in _categories) {
        final categoryId = category['id'];
        final defaultTime = category['defaultTime'] as String;
        // استخدام القيمة الافتراضية بدلاً من null
        await _athkarService.setCustomNotificationTime(categoryId, defaultTime);
        // إعادة ضبط حالة التفعيل
        await _athkarService.setNotificationEnabled(categoryId, true);
      }
      
      // إعادة جدولة الإشعارات الافتراضية
      await _notificationManager.scheduleDefaultAthkarNotifications();
      
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
          duration: const Duration(seconds: 2),
        ),
      );
      
      setState(() {});
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationSettings',
        'Error resetting notification settings',
        e,
      );
      
      _showErrorDialog('خطأ في إعادة الضبط', 'حدث خطأ أثناء إعادة ضبط الإعدادات.\n\nتفاصيل الخطأ:\n${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // إعادة ضبط وقت فئة محددة إلى الوقت الافتراضي
  Future<void> _resetCategoryDefaultTime(Map<String, dynamic> category) async {
    final categoryId = category['id'];
    final defaultTime = category['defaultTime'] as String;
    final greenColor = const Color(0xFF2D6852);
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    try {
      // استخدام الوقت الافتراضي بدلاً من null
      await _athkarService.setCustomNotificationTime(categoryId, defaultTime);
      
      // إذا كانت الإشعارات مفعلة، فأعد جدولتها
      if (await _athkarService.getNotificationEnabled(categoryId) && !_isGlobalMuteEnabled) {
        await _athkarService.scheduleCategoryNotifications(categoryId);
      }
      
      setState(() {});
      
      // إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.restore_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text('تم إعادة ضبط الوقت إلى $defaultTime'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: greenColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationSettings',
        'Error resetting category default time',
        e,
      );
      
      _showErrorDialog('خطأ في إعادة الضبط', 'حدث خطأ أثناء إعادة ضبط الوقت الافتراضي. يرجى المحاولة مرة أخرى.');
    }
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
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حسناً', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}