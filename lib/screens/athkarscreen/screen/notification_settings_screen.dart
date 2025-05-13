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
      'icon': Icons.wb_sunny,
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
      'icon': Icons.bedtime,
      'color': const Color(0xFF5C6BC0),
      'defaultTime': '22:00',
    },
    {
      'id': 'wake',
      'title': 'أذكار الاستيقاظ',
      'icon': Icons.alarm,
      'color': const Color(0xFFFFB74D),
      'defaultTime': '05:30',
    },
    {
      'id': 'prayer',
      'title': 'أذكار الصلاة',
      'icon': Icons.mosque,
      'color': const Color(0xFF4DB6AC),
      'defaultTime': '12:00',
    },
    {
      'id': 'home',
      'title': 'أذكار المنزل',
      'icon': Icons.home,
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
        backgroundColor: value ? Colors.grey : kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 500),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  // بطاقة التحقق من الأذونات
                  if (!_hasNotificationPermission) _buildPermissionCard(),
                  
                  // بطاقة الوضع الصامت
                  _buildGlobalMuteCard(),
                  const SizedBox(height: 12),
                  
                  // الإجراءات السريعة
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                  
                  // عنوان الفئات
                  _buildSectionTitle('إعدادات الفئات'),
                  const SizedBox(height: 12),
                  
                  // قائمة الفئات
                  ..._categories.map((category) => _buildCategoryCard(category)),
                  
                  const SizedBox(height: 30),
                ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning, color: Colors.white),
          ),
          title: const Text(
            'الأذونات مطلوبة',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: const Text(
            'يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بالأذكار',
            style: TextStyle(color: Colors.white70),
          ),
          trailing: ElevatedButton(
            onPressed: () => openAppSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('منح الإذن', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
  
  // بطاقة الوضع الصامت العام
  Widget _buildGlobalMuteCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: _isGlobalMuteEnabled
                ? [Colors.grey.shade400, Colors.grey.shade600]
                : [kPrimary, const Color(0xFF2D6852)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SwitchListTile(
          contentPadding: const EdgeInsets.all(16),
          secondary: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isGlobalMuteEnabled ? Icons.notifications_off : Icons.notifications_active,
              color: Colors.white,
            ),
          ),
          title: const Text(
            'الوضع الصامت',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            _isGlobalMuteEnabled ? 'جميع الإشعارات مغلقة' : 'الإشعارات نشطة',
            style: const TextStyle(color: Colors.white70),
          ),
          value: _isGlobalMuteEnabled,
          onChanged: _hasNotificationPermission ? _toggleGlobalMute : null,
          activeColor: Colors.white,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.white30,
        ),
      ),
    );
  }
  
  // عنوان القسم
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: kPrimary,
      ),
    );
  }
    
  // الإجراءات السريعة
  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.notifications_active,
            title: 'جدولة الكل',
            color: Colors.green,
            onTap: _scheduleAllNotifications,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.notifications_off,
            title: 'إلغاء الكل',
            color: Colors.red,
            onTap: _cancelAllNotifications,
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
        
        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  (category['color'] as Color).withOpacity(0.8),
                  category['color'] as Color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category['icon'] as IconData,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                category['title'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                isEnabled ? 'مفعل - $currentTime' : 'غير مفعل',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Switch(
                value: isEnabled && !_isGlobalMuteEnabled,
                onChanged: _hasNotificationPermission && !_isGlobalMuteEnabled
                    ? (value) => _toggleCategoryNotification(category['id'], value)
                    : null,
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(0.5),
                inactiveThumbColor: Colors.white60,
                inactiveTrackColor: Colors.white30,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // اختيار الوقت
                      ListTile(
                        leading: const Icon(Icons.access_time, color: Colors.white),
                        title: const Text(
                          'وقت الإشعار',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          currentTime,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _selectTime(category['id'], currentTime),
                        ),
                      ),
                      
                      // الإعدادات المتقدمة للفئة
                      ListTile(
                        leading: const Icon(Icons.tune, color: Colors.white),
                        title: const Text(
                          'إعدادات متقدمة',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          onPressed: () => _showCategoryAdvancedSettings(category),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      
      return {
        'isEnabled': isEnabled,
        'customTime': customTime,
      };
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationSettings',
        'Error getting category info: $categoryId',
        e,
      );
      return {'isEnabled': false, 'customTime': null};
    }
  }
  
  // اختيار الوقت
  Future<void> _selectTime(String categoryId, String currentTime) async {
    try {
      final parts = currentTime.split(':');
      final initialTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
      
      final time = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: kPrimary,
                onPrimary: Colors.white,
                onSurface: kPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (time != null) {
        final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        await _athkarService.setCustomNotificationTime(categoryId, formattedTime);
        
        if (await _athkarService.getNotificationEnabled(categoryId)) {
          await _athkarService.scheduleCategoryNotifications(categoryId);
        }
        
        setState(() {});
        
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
            backgroundColor: kPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  Future<void> _toggleCategoryNotification(String categoryId, bool value) async {
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
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      
      if (value) {
        // تفعيل الإشعارات
        // الحصول على معلومات الفئة
        final category = _categories.firstWhere((cat) => cat['id'] == categoryId);
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
          categoryTitle: category['title'] as String,
          times: [time],
          color: category['color'] as Color,
        );
        
        if (result.success) {
          await _athkarService.setNotificationEnabled(categoryId, true);
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('تم تفعيل إشعارات ${category['title']}'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          
          final category = _categories.firstWhere((cat) => cat['id'] == categoryId);
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.notifications_off, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('تم إيقاف إشعارات ${category['title']}'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          // سيتم تحديث فقط البطاقة المعنية
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
      
      // جدولة الإشعارات الافتراضية
      await _notificationManager.scheduleDefaultAthkarNotifications();
      
      // تفعيل جميع الفئات في الإعدادات المحلية
      for (var category in _categories) {
        await _athkarService.setNotificationEnabled(category['id'], true);
      }
      
      if (_isGlobalMuteEnabled) {
        await _toggleGlobalMute(false);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('تم جدولة جميع الإشعارات بنجاح'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 10),
            const Text('تأكيد الإلغاء'),
          ],
        ),
        content: const Text('هل أنت متأكد من إلغاء جميع الإشعارات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
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
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.notifications_off, color: Colors.white),
                SizedBox(width: 10),
                Text('تم إلغاء جميع الإشعارات'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
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
        color: Colors.blue,
        repeat: false,
        priority: 4,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.notifications, color: Colors.white),
                SizedBox(width: 10),
                Text('تم إرسال إشعار تجريبي'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
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
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'المساعدة والدعم',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHelpCard(
                    'كيفية تفعيل الإشعارات',
                    'اتبع الخطوات التالية لتفعيل الإشعارات:\n1. اضغط على زر الإذن\n2. قم بتفعيل إذن الإشعارات\n3. ارجع إلى التطبيق',
                    Icons.notifications_active,
                  ),
                  _buildHelpCard(
                    'الوضع الصامت',
                    'يمكنك تفعيل الوضع الصامت لإيقاف جميع الإشعارات مؤقتاً دون الحاجة لإلغاء الجدولة',
                    Icons.notifications_off,
                  ),
                  _buildHelpCard(
                    'تخصيص الأوقات',
                    'يمكنك تخصيص وقت كل إشعار حسب احتياجاتك من خلال النقر على أيقونة التعديل بجانب الوقت',
                    Icons.access_time,
                  ),
                ],
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // عرض إعدادات الفئة المتقدمة
  void _showCategoryAdvancedSettings(Map<String, dynamic> category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (category['color'] as Color).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: category['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['title'] as String,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'إعدادات متقدمة',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildAdvancedOption(
                    'نوع التنبيه',
                    'اختر نوع التنبيه المناسب',
                    Icons.notifications_active,
                    onTap: () => _showNotificationTypeDialog(category['id']),
                  ),
                  _buildAdvancedOption(
                    'الأيام النشطة',
                    'حدد الأيام التي تريد تلقي الإشعارات فيها',
                    Icons.calendar_today,
                    onTap: () => _showDaysSelectionDialog(category['id']),
                  ),
                  _buildAdvancedOption(
                    'نغمة الإشعار',
                    'اختر نغمة مخصصة لهذه الفئة',
                    Icons.music_note,
                    onTap: () => _showSoundSelectionDialog(category['id']),
                  ),
                  _buildAdvancedOption(
                    'الأوقات الإضافية',
                    'أضف أوقات إضافية للتذكير',
                    Icons.add_alarm,
                    onTap: () => _showAdditionalTimesDialog(category['id']),
                  ),
                  _buildAdvancedOption(
                    'رسالة مخصصة',
                    'تخصيص نص الإشعار',
                    Icons.message,
                    onTap: () => _showCustomMessageDialog(category['id']),
                  ),
                  _buildAdvancedOption(
                    'السجل',
                    'عرض سجل الإشعارات لهذه الفئة',
                    Icons.history,
                    onTap: () => _showCategoryHistory(category['id']),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // خيار متقدم
  Widget _buildAdvancedOption(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
  
  // حوارات مختلفة للإعدادات المتقدمة
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.orange),
            const SizedBox(width: 10),
            const Text('الإذن مطلوب'),
          ],
        ),
        content: const Text('يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بأوقات الأذكار'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
  
  // وظائف إضافية ستحتاج إلى تنفيذها لاحقاً
  void _showNotificationTypeDialog(String categoryId) {
    // TODO: Implement notification type selection
  }
  
  void _showDaysSelectionDialog(String categoryId) {
    // TODO: Implement days selection
  }
  
  void _showSoundSelectionDialog(String categoryId) {
    // TODO: Implement sound selection
  }
  
  void _showAdditionalTimesDialog(String categoryId) {
    // TODO: Implement additional times
  }
  
  void _showCustomMessageDialog(String categoryId) {
    // TODO: Implement custom message
  }
  
  void _showCategoryHistory(String categoryId) {
    // TODO: Implement category history
  }
}