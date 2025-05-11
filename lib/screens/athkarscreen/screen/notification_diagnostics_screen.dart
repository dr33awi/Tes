// lib/screens/athkarscreen/screen/notification_diagnostics_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/services/notification_facade.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart' 
    show kPrimary, kSurface;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:share_plus/share_plus.dart';

class NotificationDiagnosticsScreen extends StatefulWidget {
  const NotificationDiagnosticsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationDiagnosticsScreen> createState() => _NotificationDiagnosticsScreenState();
}

class _NotificationDiagnosticsScreenState extends State<NotificationDiagnosticsScreen> {
  final NotificationFacade _notificationFacade = NotificationFacade.instance;
  final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  
  bool _isLoading = true;
  bool _isRunningDiagnostics = false;
  bool _isResetting = false;
  
  // Diagnostics results
  NotificationPermissionsStatus? _permissionsStatus;
  NotificationStatistics? _statistics;
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
      // Check permissions
      _permissionsStatus = await _notificationFacade.checkAllPermissions(context);
      
      // Get notification statistics
      _statistics = await _notificationFacade.getNotificationStatistics();
      
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
           'Timezone: ${DateTime.now().timeZoneName}\n'
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
        await _notificationFacade.cancelAllNotifications();
        
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
      
      // Request all permissions
      await _notificationFacade.requestAllPermissions(context);
      
      // Re-schedule all notifications
      await _notificationFacade.rescheduleAllSavedNotifications();
      
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
      await _notificationFacade.sendTestNotification();
      
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
          '- إذن الإشعارات: ${_permissionsStatus?.hasNotificationPermission ?? false ? 'ممنوح ✓' : 'غير ممنوح ✗'}\n'
          '- تحسين البطارية معطل: ${_permissionsStatus?.isBatteryOptimized ?? false ? 'لا ✗' : 'نعم ✓'}\n'
          '- يمكن تجاوز وضع عدم الإزعاج: ${_permissionsStatus?.canBypassDoNotDisturb ?? false ? 'نعم ✓' : 'لا ✗'}\n'
          '- عدد الإشعارات المعلقة: ${_statistics?.totalPending ?? 0}\n\n'
          'إحصائيات الإشعارات:\n'
          '- إجمالي المجدولة: ${_statistics?.totalScheduled ?? 0}\n'
          '- النشطة: ${_statistics?.totalActive ?? 0}\n'
          '- المعلقة: ${_statistics?.totalPending ?? 0}\n\n'
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
              status: _permissionsStatus?.hasNotificationPermission ?? false,
              description: 'إذن عرض الإشعارات من التطبيق',
            ),
            Divider(),
            if (Platform.isAndroid)
              _buildStatusItem(
                icon: Icons.battery_charging_full,
                title: 'تحسين البطارية',
                status: !(_permissionsStatus?.isBatteryOptimized ?? true),
                description: 'تعطيل تحسين البطارية للتطبيق',
              ),
            if (Platform.isAndroid)
              Divider(),
            _buildStatusItem(
              icon: Icons.do_not_disturb_on,
              title: 'وضع عدم الإزعاج',
              status: _permissionsStatus?.canBypassDoNotDisturb ?? false,
              description: 'القدرة على تجاوز وضع عدم الإزعاج',
            ),
            Divider(),
            _buildStatusItem(
              icon: Icons.notifications,
              title: 'الإشعارات المعلقة',
              status: (_statistics?.totalPending ?? 0) > 0,
              description: 'عدد الإشعارات المجدولة: ${_statistics?.totalPending ?? 0}',
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
            _buildStatItem(
              title: 'إجمالي المجدولة',
              value: '${_statistics?.totalScheduled ?? 0}',
            ),
            _buildStatItem(
              title: 'النشطة',
              value: '${_statistics?.totalActive ?? 0}',
            ),
            _buildStatItem(
              title: 'المعلقة',
              value: '${_statistics?.totalPending ?? 0}',
            ),
            
            if (_statistics?.categoriesCount != null)
              ..._statistics!.categoriesCount.entries.map((entry) => 
                _buildStatItem(
                  title: 'فئة ${entry.key}',
                  value: '${entry.value}',
                ),
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