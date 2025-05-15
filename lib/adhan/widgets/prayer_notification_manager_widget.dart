// lib/adhan/widgets/prayer_notification_manager_widget.dart
import 'package:flutter/material.dart';
import 'package:test_athkar_app/adhan/services/prayer_notification_service.dart';
import 'package:test_athkar_app/adhan/services/prayer_times_service.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';
import 'package:test_athkar_app/services/do_not_disturb_service.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/di_container.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// واجهة مستخدم متكاملة لإدارة إشعارات الصلاة
class PrayerNotificationManagerWidget extends StatefulWidget {
  const PrayerNotificationManagerWidget({Key? key}) : super(key: key);

  @override
  State<PrayerNotificationManagerWidget> createState() => _PrayerNotificationManagerWidgetState();
}

class _PrayerNotificationManagerWidgetState extends State<PrayerNotificationManagerWidget> {
  // الخدمات
  final PrayerNotificationService _notificationService = PrayerNotificationService();
  final PrayerTimesService _prayerService = PrayerTimesService();
  late final BatteryOptimizationService _batteryService;
  late final DoNotDisturbService _dndService;
  late final ErrorLoggingService _errorService;
  
  // حالة البيانات
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _hasPermissions = false;
  Map<String, bool> _prayerSettings = {};
  Map<String, dynamic>? _notificationStats;
  
  // قائمة مواقيت الصلاة
  List<String> _prayerNames = [
    'الفجر',
    'الشروق',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];
  
  // تفاصيل حالة النظام
  bool _hasBatteryOptimization = false;
  bool _hasDoNotDisturbBypass = false;
  int _pendingNotificationsCount = 0;
  
  // ألوان الثيم - ستعيين في didChangeDependencies
  late Color kPrimary;
  late Color kPrimaryLight;
  late Color kSurface;
  
  @override
  void initState() {
    super.initState();
    _batteryService = serviceLocator<BatteryOptimizationService>();
    _dndService = serviceLocator<DoNotDisturbService>();
    _errorService = serviceLocator<ErrorLoggingService>();
    _loadSettings();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // تعيين ألوان الثيم
    kPrimary = Theme.of(context).primaryColor;
    kPrimaryLight = Theme.of(context).primaryColor.withOpacity(0.7);
    kSurface = Theme.of(context).scaffoldBackgroundColor;
    
    // تعيين السياق في الخدمات
    _notificationService.setContext(context);
    _prayerService.setContext(context);
  }
  
  /// تحميل الإعدادات والحالة
  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // التحقق من أذونات الإشعارات
      _hasPermissions = await _notificationService.checkNotificationPermission();
      
      // تحميل إعدادات الإشعارات
      _notificationsEnabled = _notificationService.isNotificationEnabled;
      _prayerSettings = Map.from(_notificationService.prayerNotificationSettings);
      
      // تحميل معلومات إضافية عن حالة النظام
      _notificationStats = await _notificationService.getNotificationStatistics();
      _hasBatteryOptimization = _notificationStats?['has_battery_optimization'] ?? false;
      _hasDoNotDisturbBypass = _notificationStats?['has_dnd_bypass'] ?? false;
      _pendingNotificationsCount = _notificationStats?['pending_count'] ?? 0;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _errorService.logError(
        'PrayerNotificationManagerWidget', 
        'خطأ في تحميل إعدادات الإشعارات', 
        e
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _showErrorSnackBar('حدث خطأ أثناء تحميل الإعدادات');
      }
    }
  }
  
  /// تبديل حالة تفعيل الإشعارات (المفتاح الرئيسي)
  Future<void> _toggleMasterSwitch(bool value) async {
    if (!mounted) return;
    
    setState(() {
      _notificationsEnabled = value;
    });
    
    try {
      _notificationService.isNotificationEnabled = value;
      
      if (value) {
        // إعادة جدولة الإشعارات عند التفعيل
        await _prayerService.schedulePrayerNotifications();
        _showSuccessSnackBar('تم تفعيل إشعارات الصلاة');
      } else {
        // إلغاء جميع الإشعارات عند التعطيل
        await _notificationService.cancelAllNotifications();
        _showSuccessSnackBar('تم تعطيل إشعارات الصلاة');
      }
      
      // تحديث الإحصائيات
      _loadSettings();
    } catch (e) {
      _errorService.logError(
        'PrayerNotificationManagerWidget', 
        'خطأ في تبديل حالة الإشعارات', 
        e
      );
      
      _showErrorSnackBar('حدث خطأ أثناء تغيير إعدادات الإشعارات');
    }
  }
  
  /// تبديل حالة إشعار لصلاة محددة
  Future<void> _togglePrayerNotification(String prayerName, bool value) async {
    if (!mounted) return;
    
    setState(() {
      _prayerSettings[prayerName] = value;
    });
    
    try {
      await _notificationService.setPrayerNotificationEnabled(prayerName, value);
      
      // إعادة جدولة الإشعارات
      await _prayerService.schedulePrayerNotifications();
      
      // تحديث الإحصائيات
      final updatedStats = await _notificationService.getNotificationStatistics();
      
      setState(() {
        _notificationStats = updatedStats;
        _pendingNotificationsCount = updatedStats['pending_count'] ?? 0;
      });
      
      _showSuccessSnackBar(value 
          ? 'تم تفعيل إشعارات صلاة $prayerName' 
          : 'تم تعطيل إشعارات صلاة $prayerName');
    } catch (e) {
      _errorService.logError(
        'PrayerNotificationManagerWidget', 
        'خطأ في تبديل حالة إشعار $prayerName', 
        e
      );
      
      _showErrorSnackBar('حدث خطأ أثناء تغيير إعدادات إشعار $prayerName');
      
      // إرجاع الحالة السابقة في واجهة المستخدم
      setState(() {
        _prayerSettings[prayerName] = !value;
      });
    }
  }
  
  /// طلب أذونات الإشعارات
  Future<void> _requestNotificationPermission() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      _hasPermissions = await _notificationService.requestNotificationPermission();
      
      setState(() {
        _isLoading = false;
      });
      
      if (_hasPermissions) {
        _showSuccessSnackBar('تم منح إذن الإشعارات بنجاح');
        
        // إعادة جدولة إشعارات مواقيت الصلاة
        await _prayerService.schedulePrayerNotifications();
      } else {
        // عرض حوار إرشادي لمنح الإذونات يدوياً
        if (mounted) {
          _showPermissionsGuideDialog();
        }
      }
    } catch (e) {
      _errorService.logError(
        'PrayerNotificationManagerWidget', 
        'خطأ في طلب أذونات الإشعارات', 
        e
      );
      
      setState(() {
        _isLoading = false;
      });
      
      _showErrorSnackBar('حدث خطأ أثناء طلب أذونات الإشعارات');
    }
  }
  
  /// إجراء تحديث شامل لإعدادات الإشعارات وحل مشاكلها
  Future<void> _performHealthCheck() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // إجراء الفحص الشامل
      final results = await _notificationService.performHealthCheck(context);
      
      // تحديث البيانات بعد الفحص
      await _loadSettings();
      
      setState(() {
        _isLoading = false;
      });
      
      // عرض نتائج الفحص
      if (mounted) {
        _showHealthCheckResultsDialog(results);
      }
    } catch (e) {
      _errorService.logError(
        'PrayerNotificationManagerWidget', 
        'خطأ في إجراء الفحص الشامل للإشعارات', 
        e
      );
      
      setState(() {
        _isLoading = false;
      });
      
      _showErrorSnackBar('حدث خطأ أثناء إجراء الفحص الشامل للإشعارات');
    }
  }
  
  /// إظهار رسالة نجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  /// إظهار رسالة خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  /// عرض حوار إرشادي لمنح الأذونات يدوياً
  void _showPermissionsGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إذن الإشعارات مطلوب'),
        content: const Text(
          'لم يتم منح إذن الإشعارات. يرجى فتح إعدادات التطبيق وتمكين الإشعارات يدويًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _batteryService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
            ),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
  
  /// عرض نتائج الفحص الشامل
  void _showHealthCheckResultsDialog(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.health_and_safety, color: kPrimary),
            const SizedBox(width: 10),
            const Text('نتائج فحص النظام'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthCheckItem(
              'أذونات الإشعارات',
              results['has_permission'] == true,
              'تم منح الإذن بنجاح',
              'لم يتم منح الإذن'
            ),
            const SizedBox(height: 8),
            _buildHealthCheckItem(
              'تحسينات البطارية',
              results['battery_optimization_enabled'] != true,
              'غير مفعل - جيد',
              'مفعل - قد يؤثر على الإشعارات'
            ),
            const SizedBox(height: 8),
            _buildHealthCheckItem(
              'وضع عدم الإزعاج',
              results['can_bypass_dnd'] == true || results['dnd_enabled'] != true,
              'مسموح للإشعارات بالوصول',
              'قد يمنع وصول الإشعارات'
            ),
            const SizedBox(height: 8),
            _buildHealthCheckItem(
              'إشعارات مجدولة',
              results['pending_notifications_count'] > 0,
              '${results['pending_notifications_count']} إشعار مجدول',
              'لا توجد إشعارات مجدولة'
            ),
            const SizedBox(height: 16),
            const Text(
              'ملاحظة: قد تحتاج إلى إعادة تشغيل التطبيق لتطبيق بعض التغييرات.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadSettings(); // إعادة تحميل الإعدادات بعد الغلق
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
            ),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }
  
  /// بناء عنصر من نتائج الفحص
  Widget _buildHealthCheckItem(String title, bool isGood, String goodMessage, String badMessage) {
    return Row(
      children: [
        Icon(
          isGood ? Icons.check_circle : Icons.warning,
          color: isGood ? Colors.green : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                isGood ? goodMessage : badMessage,
                style: TextStyle(
                  fontSize: 12,
                  color: isGood ? Colors.green.shade700 : Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // واجهة المستخدم
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'إعدادات إشعارات الصلاة',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.medical_services_outlined, color: kPrimary),
            onPressed: _performHealthCheck,
            tooltip: 'فحص وإصلاح مشاكل الإشعارات',
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: kPrimary))
        : Directionality(
            textDirection: TextDirection.rtl,
            child: RefreshIndicator(
              color: kPrimary,
              onRefresh: _loadSettings,
              child: AnimationLimiter(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 600),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                          child: widget,
                        ),
                      ),
                      children: [
                        // عرض شعار الإشعارات عند أعلى الشاشة
                        _buildLogoSection(),
                        
                        const SizedBox(height: 16),
                        
                        // إظهار بانر الأذونات إذا لم تمنح
                        if (!_hasPermissions)
                          _buildPermissionBanner(),
                        
                        // بانر حالة النظام (بطارية وعدم الإزعاج)
                        _buildSystemInfoBanner(),
                        
                        const SizedBox(height: 24),
                        
                        // مفتاح تشغيل/إيقاف الإشعارات الرئيسي
                        _buildMasterSwitchCard(),
                        
                        const SizedBox(height: 24),
                        
                        // عنوان إعدادات الصلوات
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: kPrimary.withOpacity(0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'إعدادات إشعارات الصلوات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // قائمة إعدادات الصلوات
                        _buildPrayerSettingsCard(),
                        
                        const SizedBox(height: 24),
                        
                        // بطاقة معلومات عن الإشعارات
                        _buildInfoCard(),
                        
                        const SizedBox(height: 24),
                        
                        // زر تحديث الإشعارات
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _updateAllNotifications,
                            icon: const Icon(Icons.refresh),
                            label: const Text('تحديث جميع الإشعارات'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // زر اختبار الإشعارات
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _testNotification,
                            icon: const Icon(Icons.assignment_turned_in),
                            label: const Text('اختبار الإشعارات'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side: BorderSide(color: kPrimary),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }
  
  /// بناء قسم الشعار
  Widget _buildLogoSection() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary, kPrimaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'إدارة إشعارات الصلاة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_pendingNotificationsCount.toString()} إشعار مجدول',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  /// بناء بانر الأذونات
  Widget _buildPermissionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.15),
            Colors.orange.withOpacity(0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_off,
                color: Colors.orange.shade800,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إذن الإشعارات غير ممنوح',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بأوقات الصلاة. يرجى منح الإذن لتلقي إشعارات.',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _requestNotificationPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('منح إذن الإشعارات'),
          ),
        ],
      ),
    );
  }
  
  /// بناء بانر معلومات النظام
  Widget _buildSystemInfoBanner() {
    // تحقق من وجود مشاكل في تحسين البطارية أو وضع عدم الإزعاج
    final hasSystemIssues = _hasBatteryOptimization || !_hasDoNotDisturbBypass;
    
    if (!hasSystemIssues) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.15),
            Colors.blue.withOpacity(0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade800,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تحسين إشعارات النظام',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (_hasBatteryOptimization)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.battery_alert,
                    color: Colors.blue.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تحسين البطارية مفعل وقد يؤثر على وصول الإشعارات. ينصح بإلغاء تفعيله.',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
          if (!_hasDoNotDisturbBypass)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.do_not_disturb_on,
                  color: Colors.blue.shade700,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'وضع عدم الإزعاج قد يمنع وصول إشعارات الصلاة. ينصح بالسماح للتطبيق بتجاوزه.',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: _performHealthCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('فحص وإصلاح المشاكل'),
            ),
          ),
        ],
      ),
    );
  }
  
  /// بناء بطاقة المفتاح الرئيسي
  Widget _buildMasterSwitchCard() {
    return Card(
      elevation: 8,
      shadowColor: kPrimary.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryLight],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_active,
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
                    'تفعيل إشعارات مواقيت الصلاة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'استلم إشعارات عند حلول أوقات الصلاة',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 1.2,
              child: Switch(
                value: _notificationsEnabled,
                onChanged: _hasPermissions ? _toggleMasterSwitch : null,
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(0.4),
                inactiveThumbColor: Colors.white.withOpacity(0.8),
                inactiveTrackColor: Colors.white.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// بناء بطاقة إعدادات الصلوات
  Widget _buildPrayerSettingsCard() {
    return Card(
      elevation: 4,
      shadowColor: kPrimary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _prayerSettings.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: entry.value ? kPrimary.withOpacity(0.07) : null,
                  border: entry.value 
                      ? Border.all(color: kPrimary.withOpacity(0.3), width: 1) 
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _getPrayerIcon(entry.key),
                      color: entry.value ? kPrimary : Colors.grey,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: entry.value ? kPrimary : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getPrayerDescription(entry.key),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 1.1,
                      child: Switch(
                        value: entry.value,
                        onChanged: _notificationsEnabled && _hasPermissions
                            ? (value) => _togglePrayerNotification(entry.key, value)
                            : null,
                        activeColor: kPrimary,
                        activeTrackColor: kPrimary.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  /// بناء بطاقة المعلومات
  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.orange.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.1),
              Colors.amber.withOpacity(0.05),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade800,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'معلومات عن إشعارات الصلاة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildInfoItem(
                    Icons.notifications_active,
                    'سيتم إرسال إشعارات للصلوات المفعلة في وقتها المحدد. تأكد من السماح للتطبيق بالعمل في الخلفية وعدم إيقافه من قبل نظام التشغيل.'
                  ),
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    Icons.update,
                    'يمكنك تحديث الإشعارات عند تغيير الموقع الجغرافي أو تغيير إعدادات حساب مواقيت الصلاة.'
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// بناء عنصر معلومات
  Widget _buildInfoItem(IconData icon, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.orange.shade700,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade900,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
  
  /// الحصول على أيقونة الصلاة
  IconData _getPrayerIcon(String prayer) {
    switch (prayer) {
      case 'الفجر':
        return Icons.brightness_2;
      case 'الشروق':
        return Icons.wb_sunny_outlined;
      case 'الظهر':
        return Icons.wb_sunny;
      case 'العصر':
        return Icons.wb_twighlight;
      case 'المغرب':
        return Icons.nights_stay_outlined;
      case 'العشاء':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }
  
  /// الحصول على وصف الصلاة
  String _getPrayerDescription(String prayer) {
    switch (prayer) {
      case 'الفجر':
        return 'صلاة الفجر - قبل شروق الشمس';
      case 'الشروق':
        return 'وقت شروق الشمس';
      case 'الظهر':
        return 'صلاة الظهر - منتصف النهار';
      case 'العصر':
        return 'صلاة العصر - بعد الظهر';
      case 'المغرب':
        return 'صلاة المغرب - عند غروب الشمس';
      case 'العشاء':
        return 'صلاة العشاء - بعد المغرب';
      default:
        return '';
    }
  }
  
  /// تحديث جميع الإشعارات
  Future<void> _updateAllNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // التحقق من الأذونات
      if (!_hasPermissions) {
        _hasPermissions = await _notificationService.requestNotificationPermission();
        if (!_hasPermissions) {
          setState(() {
            _isLoading = false;
          });
          _showPermissionsGuideDialog();
          return;
        }
      }
      
      // إعادة جدولة جميع الإشعارات
      await _prayerService.recalculatePrayerTimes();
      await _prayerService.schedulePrayerNotifications();
      
      // تحديث البيانات
      await _loadSettings();
      
      setState(() {
        _isLoading = false;
      });
      
      _showSuccessSnackBar('تم تحديث إشعارات الصلاة بنجاح');
    } catch (e) {
      _errorService.logError(
        'PrayerNotificationManagerWidget', 
        'خطأ في تحديث الإشعارات', 
        e
      );
      
      setState(() {
        _isLoading = false;
      });
      
      _showErrorSnackBar('حدث خطأ أثناء تحديث الإشعارات');
    }
  }
  
  /// اختبار الإشعارات
  Future<void> _testNotification() async {
    try {
      await _notificationService.testImmediateNotification();
      _showSuccessSnackBar('تم إرسال إشعار اختباري، يرجى التحقق من شريط الإشعارات');
    } catch (e) {
      _errorService.logError(
        'PrayerNotificationManagerWidget', 
        'خطأ في اختبار الإشعارات', 
        e
      );
      
      _showErrorSnackBar('حدث خطأ أثناء اختبار الإشعارات');
    }
  }
}