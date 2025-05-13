// lib/screens/athkarscreen/notification_diagnostics_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/notification_service.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/error_logging_service.dart';
import 'package:test_athkar_app/screens/athkarscreen/battery_optimization_service.dart';
import 'package:test_athkar_app/screens/athkarscreen/do_not_disturb_service.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart' 
    show kPrimary, kSurface;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:share_plus/share_plus.dart';

class NotificationDiagnosticsScreen extends StatefulWidget {
  const NotificationDiagnosticsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationDiagnosticsScreen> createState() => _NotificationDiagnosticsScreenState();
}

class _NotificationDiagnosticsScreenState extends State<NotificationDiagnosticsScreen> {
  final NotificationService _notificationService = NotificationService();
  final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  final BatteryOptimizationService _batteryOptimizationService = BatteryOptimizationService();
  final DoNotDisturbService _doNotDisturbService = DoNotDisturbService();
  
  bool _isLoading = true;
  bool _isRunningDiagnostics = false;
  bool _isResetting = false;
  
  // Diagnostics results
  bool _hasNotificationPermission = false;
  bool _batteryOptimizationDisabled = false;
  bool _canBypassDnd = false;
  bool _isInDndMode = false;
  int _pendingNotificationsCount = 0;
  Map<String, dynamic> _notificationStats = {};
  Map<String, dynamic> _errorStats = {};
  String _deviceInfo = '';
  
  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }
  
  // Load diagnostic information
  Future<void> _loadDiagnostics() async {
    setState(() => _isLoading = true);
    
    try {
      await _runDiagnostics();
      
      setState(() => _isLoading = false);
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationDiagnosticsScreen', 
        'Error loading diagnostics', 
        e
      );
      
      setState(() => _isLoading = false);
    }
  }
  
  // Run all diagnostics
  Future<void> _runDiagnostics() async {
    setState(() => _isRunningDiagnostics = true);
    
    try {
      // Check notification permission
      final flnp = FlutterLocalNotificationsPlugin();
      _hasNotificationPermission = await flnp
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ?? false;
      
      // Check battery optimization (Android only)
      if (Platform.isAndroid) {
        _batteryOptimizationDisabled = !(await _batteryOptimizationService.isBatteryOptimizationEnabled());
      }
      
      // Check Do Not Disturb status
      _isInDndMode = await _doNotDisturbService.isInDoNotDisturbMode();
      _canBypassDnd = await _doNotDisturbService.canBypassDoNotDisturb();
      
      // Count pending notifications
      final pendingNotifications = await _notificationService.getPendingNotifications();
      _pendingNotificationsCount = pendingNotifications.length;
      
      // Get notification statistics
      _notificationStats = await _notificationService.getNotificationStatistics();
      
      // Get error statistics
      _errorStats = await _errorLoggingService.getErrorStats();
      
      // Get device info
      _deviceInfo = _getDeviceInfo();
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationDiagnosticsScreen', 
        'Error running diagnostics', 
        e
      );
    } finally {
      setState(() => _isRunningDiagnostics = false);
    }
  }
  
  // Get device info string
  String _getDeviceInfo() {
    return 'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
           'Timezone: ${_notificationService.getCurrentTimezoneName()}\n'
           'Locale: ${Platform.localeName}';
  }
  
  // Reset all notifications
  Future<void> _resetAllNotifications() async {
    try {
      setState(() => _isResetting = true);
      
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('إعادة ضبط جميع الإشعارات'),
          content: Text(
            'سيؤدي هذا إلى حذف جميع الإشعارات المجدولة وإعدادات الإشعارات الحالية. '
            'هل أنت متأكد من أنك تريد إعادة ضبط جميع الإشعارات؟'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('إعادة ضبط'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ) ?? false;
      
      if (confirm) {
        // Cancel all notifications
        await _notificationService.cancelAllNotifications();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إعادة ضبط جميع الإشعارات بنجاح'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Refresh diagnostics
        await _runDiagnostics();
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationDiagnosticsScreen', 
        'Error resetting notifications', 
        e
      );
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إعادة ضبط الإشعارات'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _isResetting = false);
    }
  }
  
  // Fix notification issues
  Future<void> _fixNotificationIssues() async {
    try {
      setState(() => _isResetting = true);
      
      // Check permissions
      if (!_hasNotificationPermission) {
        // Request notification permission
        final flnp = FlutterLocalNotificationsPlugin();
        await flnp
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
      
      // Configure notification channels for Do Not Disturb
      if (Platform.isAndroid) {
        await _doNotDisturbService.configureNotificationChannelsForDoNotDisturb();
      }
      
      // Handle battery optimization
      if (Platform.isAndroid && !_batteryOptimizationDisabled) {
        await _batteryOptimizationService.requestDisableBatteryOptimization();
      }
      
      // Re-schedule all notifications
      await _notificationService.scheduleAllSavedNotifications();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إصلاح مشاكل الإشعارات وإعادة جدولتها'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Refresh diagnostics
      await _runDiagnostics();
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationDiagnosticsScreen', 
        'Error fixing notification issues', 
        e
      );
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إصلاح مشاكل الإشعارات'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _isResetting = false);
    }
  }
  
  // Test notification
  Future<void> _testNotification() async {
    try {
      await _notificationService.testImmediateNotification();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال إشعار تجريبي'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationDiagnosticsScreen', 
        'Error sending test notification', 
        e
      );
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إرسال الإشعار التجريبي'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Export diagnostic report
  Future<void> _exportDiagnosticReport() async {
    try {
      final report = await _errorLoggingService.getDiagnosticReport();
      
      // Add more diagnostics information
      final fullReport = 'تقرير تشخيص إشعارات الأذكار\n'
          '==========================\n\n'
          'معلومات الجهاز:\n$_deviceInfo\n\n'
          'حالة الإشعارات:\n'
          '- إذن الإشعارات: ${_hasNotificationPermission ? 'ممنوح ✓' : 'غير ممنوح ✗'}\n'
          '- تحسين البطارية معطل: ${_batteryOptimizationDisabled ? 'نعم ✓' : 'لا ✗'}\n'
          '- وضع عدم الإزعاج: ${_isInDndMode ? 'مفعل ✗' : 'غير مفعل ✓'}\n'
          '- يمكن تجاوز وضع عدم الإزعاج: ${_canBypassDnd ? 'نعم ✓' : 'لا ✗'}\n'
          '- عدد الإشعارات المعلقة: $_pendingNotificationsCount\n\n'
          'إحصائيات الإشعارات:\n'
          '$_notificationStats\n\n'
          '$report';
      
      // Share the report
      await Share.share(fullReport, subject: 'تقرير تشخيص إشعارات الأذكار');
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationDiagnosticsScreen', 
        'Error exporting diagnostic report', 
        e
      );
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تصدير تقرير التشخيص'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Open notification settings
  Future<void> _openNotificationSettings() async {
    try {
      await AppSettings.openNotificationSettings();
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationDiagnosticsScreen', 
        'Error opening notification settings', 
        e
      );
    }
  }
  
  // Open battery settings
  Future<void> _openBatterySettings() async {
    try {
      if (Platform.isAndroid) {
        await _batteryOptimizationService.requestDisableBatteryOptimization();
      } else {
        await AppSettings.openAppSettings();
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationDiagnosticsScreen', 
        'Error opening battery settings', 
        e
      );
    }
  }
  
  // Open Do Not Disturb settings
  Future<void> _openDoNotDisturbSettings() async {
    try {
      await _doNotDisturbService.openDoNotDisturbSettings();
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationDiagnosticsScreen', 
        'Error opening Do Not Disturb settings', 
        e
      );
    }
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
          'تشخيص الإشعارات',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: kPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: kPrimary,
            ),
            tooltip: 'تحديث',
            onPressed: _runDiagnostics,
          ),
          // Export report button
          IconButton(
            icon: const Icon(
              Icons.share,
              color: kPrimary,
            ),
            tooltip: 'تصدير تقرير',
            onPressed: _exportDiagnosticReport,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: kPrimary,
                    size: 50,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'جاري تحميل التشخيص...',
                    style: TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _runDiagnostics,
                    color: kPrimary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 375),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: widget,
                            ),
                          ),
                          children: [
                            // أزرار الإجراءات السريعة
                            _buildQuickActionsCard(),
                            SizedBox(height: 16),
                            
                            // حالة الإشعارات
                            _buildNotificationStatusCard(),
                            SizedBox(height: 16),
                            
                            // إحصائيات الإشعارات
                            _buildNotificationStatsCard(),
                            SizedBox(height: 16),
                            
                            // إحصائيات الأخطاء
                            if (_errorStats.isNotEmpty)
                              _buildErrorStatsCard(),
                            SizedBox(height: 16),
                            
                            // معلومات الجهاز
                            _buildDeviceInfoCard(),
                            SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // تراكب التحميل
                  if (_isRunningDiagnostics || _isResetting)
                    Container(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LoadingAnimationWidget.staggeredDotsWave(
                              color: Colors.white,
                              size: 50,
                            ),
                            SizedBox(height: 20),
                            Text(
                              _isResetting
                                  ? 'جاري إعادة ضبط الإشعارات...'
                                  : 'جاري تشخيص الإشعارات...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
  
  // بطاقة الإجراءات السريعة
  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 8,
      shadowColor: kPrimary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              kPrimary,
              Color(0xFF2D6852),
            ],
            stops: const [0.3, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'الإجراءات السريعة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildActionButton(
                    icon: Icons.notification_important,
                    label: 'اختبار الإشعارات',
                    onPressed: _testNotification,
                  ),
                  _buildActionButton(
                    icon: Icons.build,
                    label: 'إصلاح المشاكل',
                    onPressed: _fixNotificationIssues,
                  ),
                  _buildActionButton(
                    icon: Icons.restore,
                    label: 'إعادة ضبط',
                    onPressed: _resetAllNotifications,
                    isDestructive: true,
                  ),
                  _buildActionButton(
                    icon: Icons.settings,
                    label: 'إعدادات الإشعارات',
                    onPressed: _openNotificationSettings,
                  ),
                  if (Platform.isAndroid)
                    _buildActionButton(
                      icon: Icons.battery_full,
                      label: 'إعدادات البطارية',
                      onPressed: _openBatterySettings,
                    ),
                  _buildActionButton(
                    icon: Icons.do_not_disturb_on,
                    label: 'وضع عدم الإزعاج',
                    onPressed: _openDoNotDisturbSettings,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // زر إجراء
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white,
        size: 18,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontSize: 12,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(isDestructive ? 0.9 : 0.2),
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  // بطاقة حالة الإشعارات
  Widget _buildNotificationStatusCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: kPrimary,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'حالة الإشعارات',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildStatusItem(
              icon: Icons.notifications_active,
              title: 'أذونات الإشعارات',
              status: _hasNotificationPermission,
              description: 'إذن عرض الإشعارات من التطبيق',
            ),
            Divider(),
            if (Platform.isAndroid)
              _buildStatusItem(
                icon: Icons.battery_charging_full,
                title: 'تحسين البطارية',
                status: _batteryOptimizationDisabled,
                description: 'تعطيل تحسين البطارية للتطبيق',
              ),
            if (Platform.isAndroid)
              Divider(),
            _buildStatusItem(
              icon: Icons.do_not_disturb_on,
              title: 'وضع عدم الإزعاج',
              status: !_isInDndMode || _canBypassDnd,
              description: _isInDndMode 
                  ? (_canBypassDnd 
                      ? 'وضع عدم الإزعاج مفعل، ولكن التطبيق يمكنه تجاوزه'
                      : 'وضع عدم الإزعاج مفعل، وقد يؤثر على الإشعارات')
                  : 'وضع عدم الإزعاج غير مفعل',
            ),
            Divider(),
            _buildStatusItem(
              icon: Icons.notifications,
              title: 'الإشعارات المعلقة',
              status: _pendingNotificationsCount > 0,
              description: 'عدد الإشعارات المجدولة: $_pendingNotificationsCount',
              showIcon: false,
            ),
          ],
        ),
      ),
    );
  }
  
  // عنصر حالة
  Widget _buildStatusItem({
    required IconData icon,
    required String title,
    required bool status,
    required String description,
    bool showIcon = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: kPrimary,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (showIcon)
            Icon(
              status ? Icons.check_circle : Icons.error,
              color: status ? Colors.green : Colors.red,
              size: 24,
            ),
        ],
      ),
    );
  }
  
  // بطاقة إحصائيات الإشعارات
  Widget _buildNotificationStatsCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: kPrimary,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'إحصائيات الإشعارات',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_notificationStats.containsKey('total_notifications'))
              _buildStatItem(
                title: 'إجمالي الإشعارات',
                value: '${_notificationStats['total_notifications']}',
              ),
            if (_notificationStats.containsKey('pending_count'))
              _buildStatItem(
                title: 'الإشعارات المعلقة',
                value: '${_notificationStats['pending_count']}',
              ),
            if (_notificationStats.containsKey('last_scheduled'))
              _buildStatItem(
                title: 'آخر جدولة',
                value: '${_notificationStats['last_scheduled']}',
              ),
            if (_notificationStats.containsKey('last_scheduled_count'))
              _buildStatItem(
                title: 'عدد آخر جدولة',
                value: '${_notificationStats['last_scheduled_count']}',
              ),
            if (_notificationStats.containsKey('last_reset'))
              _buildStatItem(
                title: 'آخر إعادة ضبط',
                value: '${_notificationStats['last_reset']}',
              ),
          ],
        ),
      ),
    );
  }
  
  // عنصر إحصائية
  Widget _buildStatItem({
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // بطاقة إحصائيات الأخطاء
  Widget _buildErrorStatsCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.orange,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'إحصائيات الأخطاء',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            for (var entry in _errorStats.entries)
              _buildErrorStatItem(
                source: entry.key,
                count: entry.value['count'],
                lastSeen: entry.value['lastSeen'],
              ),
          ],
        ),
      ),
    );
  }
  
  // عنصر إحصائية أخطاء
  Widget _buildErrorStatItem({
    required String source,
    required int count,
    required String lastSeen,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'عدد الأخطاء: $count',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'آخر ظهور: $lastSeen',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          Divider(),
        ],
      ),
    );
  }
  
  // بطاقة معلومات الجهاز
  Widget _buildDeviceInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone_android,
                  color: kPrimary,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'معلومات الجهاز',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              _deviceInfo,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}