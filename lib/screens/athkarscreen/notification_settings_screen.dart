// lib/screens/athkarscreen/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/athkar_service.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/notification_defaults.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/notification_service.dart';
import 'package:test_athkar_app/screens/athkarscreen/notification_info_screen.dart';
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
  List<AthkarCategory> _categories = [];
  bool _isLoading = true;
  bool _masterSwitch = true;
  
  // Variable para la zona horaria del dispositivo
  String _deviceTimeZone = '';
  
  // Maps to track notification settings
  Map<String, bool> _notificationsEnabled = {};
  Map<String, TimeOfDay?> _notificationTimes = {};
  Map<String, String?> _notificationSounds = {};
  
  // Animation controllers
  late AnimationController _animationController;
  int? _pressedIndex;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Obtener zona horaria del dispositivo
    _deviceTimeZone = _notificationService.getCurrentTimezoneName();
    
    _loadData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      final Map<String, String?> soundMap = {};
      
      for (final category in categories) {
        // Load notification status
        final isEnabled = await _notificationService.isNotificationEnabled(category.id);
        enabledMap[category.id] = isEnabled;
        
        // Load saved notification time
        final savedTime = await _notificationService.getNotificationTime(category.id);
        timeMap[category.id] = savedTime;
        
        // Load notification sounds (would need to be implemented)
        soundMap[category.id] = category.notifySound;
      }
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _notificationsEnabled = enabledMap;
          _notificationTimes = timeMap;
          _notificationSounds = soundMap;
          _isLoading = false;
          
          // Update master switch based on enabled notifications
          _updateMasterSwitch();
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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
  }

  // Toggle notification for a specific category
  Future<void> _toggleNotification(AthkarCategory category, bool value, {bool updateState = true}) async {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
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
      await _notificationService.scheduleAthkarNotification(category, selectedTime!);
      
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
  }

  // Edit notification time for a specific category
  Future<void> _editNotificationTime(AthkarCategory category) async {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
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
  }

  // Edit notification sound for a specific category
  Future<void> _editNotificationSound(AthkarCategory category) async {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Get available sounds
    final availableSounds = NotificationDefaults.getAvailableSounds();
    
    // Current sound
    String? currentSound = _notificationSounds[category.id] ?? 
                          NotificationDefaults.getDefaultSoundForCategory(category.id);
    
    // Show sound picker dialog
    final selectedSound = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اختر صوت الإشعار'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableSounds.length,
            itemBuilder: (context, index) {
              final soundKey = availableSounds.keys.elementAt(index);
              final soundName = availableSounds[soundKey]!;
              
              return RadioListTile<String>(
                title: Text(soundName),
                value: soundKey,
                groupValue: currentSound,
                onChanged: (value) {
                  Navigator.of(context).pop(value);
                },
                activeColor: kPrimary,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء'),
            style: TextButton.styleFrom(foregroundColor: kPrimary),
          ),
        ],
      ),
    );
    
    if (selectedSound != null) {
      // Update sound
      setState(() {
        _notificationSounds[category.id] = selectedSound;
      });
      
      // Create updated category with new sound
      final updatedCategory = category.copyWith(
        notifySound: selectedSound,
      );
      
      // Reschedule notification to apply new sound
      if (_notificationsEnabled[category.id] == true && _notificationTimes[category.id] != null) {
        await _notificationService.cancelAthkarNotification(category.id);
        await _notificationService.scheduleAthkarNotification(
            updatedCategory, _notificationTimes[category.id]!);
        
        // Schedule additional notifications if category has multiple reminders
        if (updatedCategory.hasMultipleReminders && updatedCategory.additionalNotifyTimes != null) {
          await _notificationService.scheduleAdditionalNotifications(updatedCategory);
        }
      }
      
      // Show message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث صوت الإشعار لـ ${category.title}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
  
  // Get category color
  Color _getCategoryColor(AthkarCategory category) {
    return category.color;
  }
  
  // Test notification
  Future<void> _testNotification() async {
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
              child: Column(
                children: [
                  // Master switch and explanation
                  Card(
                    margin: EdgeInsets.all(16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
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
                                    Icons.notifications_active,
                                    color: kPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'الإشعارات',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimary,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _masterSwitch,
                                onChanged: _toggleAllNotifications,
                                activeColor: kPrimary,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 24,
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
                                          height: 1.4,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'المنطقة الزمنية الحالية: $_deviceTimeZone',
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: Colors.grey[700],
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
                  
                  // Athkar categories list
                  Expanded(
                    child: AnimationLimiter(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final bool isNotificationEnabled = _notificationsEnabled[category.id] ?? false;
                          final TimeOfDay? notificationTime = _notificationTimes[category.id];
                          final String? notificationSound = _notificationSounds[category.id];
                          
                          final bool isPressed = _isPressed && _pressedIndex == index;
                          
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 500),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      transform: Matrix4.identity()..scale(isPressed ? 0.98 : 1.0),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // Category icon
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    _getCategoryColor(category),
                                                    _getCategoryColor(category).withOpacity(0.7),
                                                  ],
                                                  begin: Alignment.topRight,
                                                  end: Alignment.bottomLeft,
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _getCategoryColor(category).withOpacity(0.3),
                                                    blurRadius: 5,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                category.icon,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            
                                            // Category details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    category.title,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                                                        size: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        isNotificationEnabled && notificationTime != null 
                                                            ? _formatTimeOfDay(notificationTime)
                                                            : 'غير مفعّل',
                                                        style: TextStyle(
                                                          color: isNotificationEnabled 
                                                              ? _getCategoryColor(category)
                                                              : Colors.grey[600],
                                                          fontWeight: isNotificationEnabled 
                                                              ? FontWeight.bold
                                                              : FontWeight.normal,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  
                                                  // Sound info (if notification is enabled)
                                                  if (isNotificationEnabled && notificationSound != null) 
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 6),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.volume_up,
                                                            size: 14,
                                                            color: Colors.grey[600],
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            NotificationDefaults.getAvailableSounds()[notificationSound] ?? 'صوت الجهاز',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            
                                            // Edit sound button
                                            if (isNotificationEnabled) 
                                              IconButton(
                                                icon: Icon(
                                                  Icons.volume_up,
                                                  color: _getCategoryColor(category),
                                                  size: 20,
                                                ),
                                                tooltip: 'تعديل الصوت',
                                                onPressed: () => _editNotificationSound(category),
                                              ),
                                            
                                            // Edit time button
                                            if (isNotificationEnabled) 
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: _getCategoryColor(category),
                                                  size: 20,
                                                ),
                                                tooltip: 'تعديل الوقت',
                                                onPressed: () => _editNotificationTime(category),
                                              ),
                                            
                                            // Enable/disable notifications switch
                                            Switch(
                                              value: isNotificationEnabled,
                                              onChanged: (value) => _toggleNotification(category, value),
                                              activeColor: _getCategoryColor(category),
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
                        },
                      ),
                    ),
                  ),
                  
                  // Bottom padding space
                  SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}