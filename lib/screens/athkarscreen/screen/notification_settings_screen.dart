// lib/screens/athkarscreen/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/athkarscreen/model/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/athkar_service.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/notification_service.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';
import 'package:test_athkar_app/screens/athkarscreen/screen/notification_info_screen.dart';
import 'package:test_athkar_app/screens/athkarscreen/screen/multiple_notifications_screen.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kSurface;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> with SingleTickerProviderStateMixin {
  final AthkarService _athkarService = AthkarService();
  final NotificationService _notificationService = NotificationService();
  final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  final BatteryOptimizationService _batteryOptimizationService = BatteryOptimizationService();
  
  List<AthkarCategory> _categories = [];
  bool _isLoading = true;
  bool _masterSwitch = true;
  bool _isResetting = false;
  
  // Variable for device timezone
  String _deviceTimeZone = '';
  
  // Maps to track notification settings
  Map<String, bool> _notificationsEnabled = {};
  Map<String, TimeOfDay?> _notificationTimes = {};
  Map<String, bool> _hasMultipleReminders = {};
  Map<String, int> _additionalRemindersCount = {};
  
  // Animation controllers
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Get device timezone
    _deviceTimeZone = _notificationService.getCurrentTimezoneName();
    
    _loadData();
    
    // Check battery optimization
    _checkBatteryOptimization();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Check battery optimization
  Future<void> _checkBatteryOptimization() async {
    try {
      // Check if notification permissions need to be requested
      await Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _batteryOptimizationService.checkAndRequestBatteryOptimization(context);
        }
      });
    } catch (e) {
      print('Error checking battery optimization: $e');
    }
  }

  // Load notification data
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all athkar categories
      final categories = await _athkarService.loadAllAthkarCategories();
      
      // Load notification settings for each category
      final Map<String, bool> enabledMap = {};
      final Map<String, TimeOfDay?> timeMap = {};
      final Map<String, bool> multipleRemindersMap = {};
      final Map<String, int> additionalCountMap = {};
      
      for (final category in categories) {
        // Load notification status
        final isEnabled = await _notificationService.isNotificationEnabled(category.id);
        enabledMap[category.id] = isEnabled;
        
        // Load saved notification time
        final savedTime = await _notificationService.getNotificationTime(category.id);
        timeMap[category.id] = savedTime;
        
        // Check if category has multiple reminders
        final hasMultiple = category.hasMultipleReminders;
        multipleRemindersMap[category.id] = hasMultiple;
        
        // Count additional reminders
        if (hasMultiple) {
          final additionalTimes = await _athkarService.getAdditionalNotificationTimes(category.id);
          additionalCountMap[category.id] = additionalTimes.length;
        } else {
          additionalCountMap[category.id] = 0;
        }
      }
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _notificationsEnabled = enabledMap;
          _notificationTimes = timeMap;
          _hasMultipleReminders = multipleRemindersMap;
          _additionalRemindersCount = additionalCountMap;
          _isLoading = false;
          
          // Update master switch based on enabled notifications
          _updateMasterSwitch();
        });
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationSettingsScreen', 
        'Error loading notification data', 
        e
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show error dialog
        _errorLoggingService.showErrorDialog(
          context,
          'خطأ في تحميل البيانات',
          'حدث خطأ أثناء تحميل إعدادات الإشعارات. يرجى المحاولة مرة أخرى.',
          onRetry: _loadData,
        );
      }
    }
  }
  
  // Update master switch state
  void _updateMasterSwitch() {
    if (_notificationsEnabled.isEmpty) {
      _masterSwitch = false;
      return;
    }
    
    // Check if any notifications are enabled
    final enabledCount = _notificationsEnabled.values.where((enabled) => enabled).length;
    _masterSwitch = enabledCount > 0;
  }

  // Toggle all notifications
  Future<void> _toggleAllNotifications(bool value) async {
    setState(() => _masterSwitch = value);
    
    try {
      // Apply setting to all categories
      for (final category in _categories) {
        await _toggleNotification(category, value, updateState: false);
      }
      
      // Update UI
      setState(() {});
      
      // Show message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'تم تفعيل جميع الإشعارات' : 'تم إيقاف جميع الإشعارات'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: value ? Colors.green : Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationSettingsScreen', 
        'Error toggling all notifications', 
        e
      );
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تبديل حالة الإشعارات'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Toggle notification for a specific category
  Future<void> _toggleNotification(AthkarCategory category, bool value, {bool updateState = true}) async {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    try {
      if (value) {
        // Enable notifications
        
        // Choose appropriate time for notification
        TimeOfDay? selectedTime = _notificationTimes[category.id];
        
        // If no saved time, use default time from category or show time picker
        if (selectedTime == null) {
          if (category.notifyTime != null) {
            // Use default time from category
            final timeParts = category.notifyTime!.split(':');
            if (timeParts.length == 2) {
              final hour = int.tryParse(timeParts[0]);
              final minute = int.tryParse(timeParts[1]);
              
              if (hour != null && minute != null) {
                selectedTime = TimeOfDay(hour: hour, minute: minute);
              }
            }
          }
          
          // If no default time, show time picker
          if (selectedTime == null) {
            // Suggest time based on category type
            TimeOfDay suggestedTime = NotificationService.getSuggestedTimeForCategory(category.id);
            
            // Show time picker
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: suggestedTime,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: kPrimary,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimary,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            
            if (pickedTime == null) {
              // User canceled time selection
              if (updateState) {
                setState(() {
                  _notificationsEnabled[category.id] = false;
                });
              } else {
                _notificationsEnabled[category.id] = false;
              }
              return;
            }
            
            selectedTime = pickedTime;
          }
        }
        
        // Schedule notification
        await _notificationService.scheduleAthkarNotification(category, selectedTime);
        
        // Schedule additional notifications if category has multiple reminders
        if (category.hasMultipleReminders && category.additionalNotifyTimes != null) {
          await _notificationService.scheduleAdditionalNotifications(category);
        }
        
        if (updateState) {
          setState(() {
            _notificationsEnabled[category.id] = true;
            _notificationTimes[category.id] = selectedTime;
          });
        } else {
          _notificationsEnabled[category.id] = true;
          _notificationTimes[category.id] = selectedTime;
        }
        
        // Update master switch
        _updateMasterSwitch();
      } else {
        // Cancel notifications
        await _notificationService.cancelAthkarNotification(category.id);
        
        if (updateState) {
          setState(() {
            _notificationsEnabled[category.id] = false;
          });
        } else {
          _notificationsEnabled[category.id] = false;
        }
        
        // Update master switch
        _updateMasterSwitch();
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationSettingsScreen', 
        'Error toggling notification for ${category.id}', 
        e
      );
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تبديل حالة الإشعار'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Edit notification time for a specific category
  Future<void> _editNotificationTime(AthkarCategory category) async {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    try {
      // Get current time
      TimeOfDay initialTime = _notificationTimes[category.id] ?? 
                           NotificationService.getSuggestedTimeForCategory(category.id);
      
      // Show time picker
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: kPrimary,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: kPrimary,
                ),
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        // Update notification time
        setState(() {
          _notificationTimes[category.id] = pickedTime;
          _notificationsEnabled[category.id] = true;
        });
        
        // Schedule notification with new time
        await _notificationService.scheduleAthkarNotification(category, pickedTime);
        
        // Schedule additional notifications if category has multiple reminders
        if (category.hasMultipleReminders && category.additionalNotifyTimes != null) {
          await _notificationService.scheduleAdditionalNotifications(category);
        }
        
        // Show message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث وقت الإشعار لـ ${category.title}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: kPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationSettingsScreen', 
        'Error editing notification time for ${category.id}', 
        e
      );
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تعديل وقت الإشعار'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Navigate to multiple notifications screen
  void _navigateToMultipleNotifications(AthkarCategory category) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultipleNotificationsScreen(
          category: category,
        ),
      ),
    );
    
    // Refresh data when returning from the screen
    _loadData();
  }

  // Format notification time
  String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'ص' : 'م';
    
    String displayHour = (time.hour > 12) ? (time.hour - 12).toString() : time.hour.toString();
    if (displayHour == '0') displayHour = '12';
    
    return '$hours:$minutes $period';
  }
  
  // Reset all notification settings
  Future<void> _resetAllNotifications() async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('إعادة ضبط الإشعارات'),
          content: Text(
            'هل أنت متأكد من إعادة ضبط جميع إعدادات الإشعارات؟ سيؤدي هذا إلى إلغاء جميع الإشعارات المجدولة وإعادة ضبط الأوقات.',
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
        setState(() => _isResetting = true);
        
        // Cancel all notifications
        await _notificationService.cancelAllNotifications();
        
        // Clear all settings
        setState(() {
          for (final category in _categories) {
            _notificationsEnabled[category.id] = false;
            _notificationTimes[category.id] = null;
            _hasMultipleReminders[category.id] = false;
            _additionalRemindersCount[category.id] = 0;
          }
          _masterSwitch = false;
        });
        
        // Show message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إعادة ضبط جميع إعدادات الإشعارات'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
        
        setState(() => _isResetting = false);
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationSettingsScreen', 
        'Error resetting notification settings', 
        e
      );
      
      setState(() => _isResetting = false);
      
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
    }
  }
  
  // Check and fix notification settings
  Future<void> _checkAndFixNotifications() async {
    try {
      setState(() => _isResetting = true);
      
      // Get pending notifications
      final pendingNotifications = await _notificationService.getPendingNotifications();
      
      // Check if notifications match saved settings
      bool needsFix = false;
      for (final category in _categories) {
        final isEnabled = _notificationsEnabled[category.id] ?? false;
        
        if (isEnabled) {
          // Category should have notifications
          final hasPending = pendingNotifications.any((pending) => 
            pending.payload?.startsWith(category.id) ?? false
          );
          
          if (!hasPending) {
            needsFix = true;
            break;
          }
        }
      }
      
      if (needsFix) {
        // Re-schedule all notifications
        await _notificationService.scheduleAllSavedNotifications();
        
        // Show message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إصلاح الإشعارات'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show message that everything is OK
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('جميع الإشعارات تعمل بشكل صحيح'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      setState(() => _isResetting = false);
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationSettingsScreen', 
        'Error checking and fixing notifications', 
        e
      );
      
      setState(() => _isResetting = false);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء فحص الإشعارات'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  // استخراج لون الفئة بناءً على معرف الفئة
  Color _getCategoryColorWithId(String categoryId) {
    // ألوان الفئات كما في athkar_screen
    switch (categoryId) {
      case 'morning':
        return const Color(0xFFFFD54F);
      case 'evening':
        return const Color(0xFFAB47BC);
      case 'sleep':
        return const Color(0xFF5C6BC0);
      case 'wake':
        return const Color(0xFFFFB74D);
      case 'prayer':
        return const Color(0xFF4DB6AC);
      case 'home':
        return const Color(0xFF66BB6A);
      case 'food':
        return const Color(0xFFE57373);
      default:
        return kPrimary; // اللون الافتراضي
    }
  }
  
  // Test notification
  Future<void> _testNotification() async {
    try {
      await _notificationService.testImmediateNotification();
      
      // Show message
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
        'NotificationSettingsScreen', 
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
  
  // Navigate to notification info screen
  void _navigateToInfoScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationInfoScreen(),
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
          // Info button
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: kPrimary,
            ),
            tooltip: 'معلومات عن الإشعارات',
            onPressed: _navigateToInfoScreen,
          ),
          // Test notification button
          IconButton(
            icon: const Icon(
              Icons.notifications_active,
              color: kPrimary,
            ),
            tooltip: 'اختبار الإشعارات',
            onPressed: _testNotification,
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
                    'جاري تحميل الإعدادات...',
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
                  Column(
                    children: [
                      // Master switch and explanation
                      AnimationConfiguration.synchronized(
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Card(
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
                                      children: [
                                        // زر التفعيل الرئيسي
                                        Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.notifications_active,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'تفعيل الإشعارات',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Switch(
                                              value: _masterSwitch,
                                              onChanged: _toggleAllNotifications,
                                              activeColor: Colors.white,
                                              inactiveThumbColor: Colors.white70,
                                              activeTrackColor: Colors.white.withOpacity(0.5),
                                              inactiveTrackColor: Colors.white30,
                                            ),
                                          ],
                                        ),
                                        
                                        SizedBox(height: 12),
                                        
                                        // معلومات المنطقة الزمنية
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.15),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'توقيت الإشعارات يعتمد على المنطقة الزمنية',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      'المنطقة الزمنية الحالية: $_deviceTimeZone',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        height: 1.4,
                                                        color: Colors.white.withOpacity(0.8),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // أزرار الإدارة
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: _checkAndFixNotifications,
                                    icon: Icon(Icons.build_rounded),
                                    label: Text('فحص وإصلاح'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: kPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: _resetAllNotifications,
                                    icon: Icon(Icons.restore),
                                    label: Text('إعادة ضبط'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Athkar categories list
                      Expanded(
                        child: AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final bool isNotificationEnabled = _notificationsEnabled[category.id] ?? false;
                              final TimeOfDay? notificationTime = _notificationTimes[category.id];
                              // ignore: unused_local_variable
                              final bool hasMultipleReminders = _hasMultipleReminders[category.id] ?? false;
                              final int additionalCount = _additionalRemindersCount[category.id] ?? 0;
                              final Color color1 = _getCategoryColorWithId(category.id);
                              final Color color2 = Color(0xFF2D6852);
                              
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 500),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Card(
                                        elevation: 8,
                                        shadowColor: color1.withOpacity(0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                color1,
                                                color2,
                                              ],
                                              begin: Alignment.topRight,
                                              end: Alignment.bottomLeft,
                                              stops: const [0.3, 1.0],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: InkWell(
                                            onTap: () => isNotificationEnabled 
                                              ? _editNotificationTime(category)
                                              : _toggleNotification(category, true),
                                            borderRadius: BorderRadius.circular(20),
                                            splashColor: Colors.white.withOpacity(0.1),
                                            highlightColor: Colors.white.withOpacity(0.05),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      // دائرة الأيقونة
                                                      Container(
                                                        width: 50,
                                                        height: 50,
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.2),
                                                          shape: BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withOpacity(0.1),
                                                              spreadRadius: 1,
                                                              blurRadius: 4,
                                                              offset: Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Center(
                                                          child: Icon(
                                                            category.icon,
                                                            color: Colors.white,
                                                            size: 28,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 16),
                                                      
                                                      // تفاصيل الأذكار
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              category.title,
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                            SizedBox(height: 8),
                                                            Container(
                                                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                              decoration: BoxDecoration(
                                                                color: Colors.white.withOpacity(0.15),
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(
                                                                    Icons.access_time,
                                                                    size: 16,
                                                                    color: Colors.white,
                                                                  ),
                                                                  SizedBox(width: 6),
                                                                  Text(
                                                                    isNotificationEnabled && notificationTime != null 
                                                                        ? _formatTimeOfDay(notificationTime)
                                                                        : 'غير مفعّل',
                                                                    style: TextStyle(
                                                                      color: Colors.white,
                                                                      fontWeight: isNotificationEnabled 
                                                                          ? FontWeight.bold
                                                                          : FontWeight.normal,
                                                                      fontSize: 13,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      
                                                      // أزرار التحكم
                                                      Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Switch(
                                                            value: isNotificationEnabled,
                                                            onChanged: (value) => _toggleNotification(category, value),
                                                            activeColor: Colors.white,
                                                            inactiveThumbColor: Colors.white70,
                                                            activeTrackColor: Colors.white.withOpacity(0.5),
                                                            inactiveTrackColor: Colors.white30,
                                                          ),
                                                          if (isNotificationEnabled)
                                                            TextButton(
                                                              onPressed: () => _editNotificationTime(category),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(
                                                                    Icons.edit,
                                                                    size: 16,
                                                                    color: Colors.white,
                                                                  ),
                                                                  SizedBox(width: 4),
                                                                  Text(
                                                                    'تعديل',
                                                                    style: TextStyle(
                                                                      color: Colors.white,
                                                                      fontSize: 12,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              style: TextButton.styleFrom(
                                                                backgroundColor: Colors.white.withOpacity(0.2),
                                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(15),
                                                                ),
                                                                minimumSize: Size.zero,
                                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  
                                                  // إعدادات الإشعارات المتعددة (فقط إذا كانت الإشعارات مفعلة)
                                                  if (isNotificationEnabled)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 12),
                                                      child: InkWell(
                                                        onTap: () => _navigateToMultipleNotifications(category),
                                                        borderRadius: BorderRadius.circular(10),
                                                        child: Container(
                                                          width: double.infinity,
                                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white.withOpacity(0.15),
                                                            borderRadius: BorderRadius.circular(10),
                                                            border: Border.all(
                                                              color: Colors.white.withOpacity(0.2),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.notifications_active,
                                                                size: 16,
                                                                color: Colors.white,
                                                              ),
                                                              SizedBox(width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  additionalCount > 0
                                                                      ? 'إشعارات متعددة (${additionalCount + 1})'
                                                                      : 'إضافة إشعارات متعددة',
                                                                  style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontSize: 12,
                                                                  ),
                                                                ),
                                                              ),
                                                              Icon(
                                                                Icons.arrow_forward_ios,
                                                                size: 12,
                                                                color: Colors.white,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Resetting overlay
                  if (_isResetting)
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
                              'جاري معالجة الإشعارات...',
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
}