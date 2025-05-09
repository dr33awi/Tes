// lib/screens/athkarscreen/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/athkar_service.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/notification_service.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kSurface;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

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
  String _currentTimeZone = 'Unknown';
  
  Map<String, bool> _notificationsEnabled = {};
  Map<String, TimeOfDay?> _notificationTimes = {};
  
  // متغيرات للتأثيرات البصرية
  late AnimationController _animationController;
  int? _pressedIndex;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _loadData();
    _loadTimeZone();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // تحميل المنطقة الزمنية
  Future<void> _loadTimeZone() async {
    try {
      final String timeZone = await FlutterNativeTimezone.getLocalTimezone();
      setState(() {
        _currentTimeZone = timeZone;
      });
    } catch (e) {
      print('خطأ في تحميل المنطقة الزمنية: $e');
    }
  }

  // تحميل البيانات
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // تحميل جميع فئات الأذكار
      final categories = await _athkarService.loadAllAthkarCategories();
      
      // تحميل إعدادات الإشعارات لكل فئة
      final Map<String, bool> enabledMap = {};
      final Map<String, TimeOfDay?> timeMap = {};
      
      for (final category in categories) {
        // تحميل حالة تفعيل الإشعارات
        final isEnabled = await _notificationService.isNotificationEnabled(category.id);
        enabledMap[category.id] = isEnabled;
        
        // تحميل وقت الإشعارات المحفوظ
        final savedTime = await _notificationService.getNotificationTime(category.id);
        timeMap[category.id] = savedTime;
      }
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _notificationsEnabled = enabledMap;
          _notificationTimes = timeMap;
          _isLoading = false;
          
          // تحديد حالة المفتاح الرئيسي بناءً على ما إذا كانت جميع الإشعارات مفعلة
          _updateMasterSwitch();
        });
      }
    } catch (e) {
      print('خطأ في تحميل البيانات: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // تحديث حالة المفتاح الرئيسي
  void _updateMasterSwitch() {
    if (_notificationsEnabled.isEmpty) {
      _masterSwitch = false;
      return;
    }
    
    // التحقق مما إذا كانت جميع الإشعارات مفعلة
    final enabledCount = _notificationsEnabled.values.where((enabled) => enabled).length;
    _masterSwitch = enabledCount > 0;
  }

  // تبديل حالة الإشعارات لجميع الفئات
  Future<void> _toggleAllNotifications(bool value) async {
    setState(() => _masterSwitch = value);
    
    // تطبيق الإعداد على جميع الفئات
    for (final category in _categories) {
      await _toggleNotification(category, value, updateState: false);
    }
    
    // تحديث الواجهة
    setState(() {});
    
    // عرض رسالة
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

  // تبديل حالة الإشعارات لفئة معينة
  Future<void> _toggleNotification(AthkarCategory category, bool value, {bool updateState = true}) async {
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    if (value) {
      // تفعيل الإشعارات
      
      // اختيار الوقت المناسب للإشعار
      TimeOfDay? selectedTime = _notificationTimes[category.id];
      
      // إذا لم يكن هناك وقت محفوظ، استخدم الوقت الافتراضي من الفئة أو اعرض منتقي الوقت
      if (selectedTime == null) {
        if (category.notifyTime != null) {
          // استخدام الوقت الافتراضي من الفئة
          final timeParts = category.notifyTime!.split(':');
          if (timeParts.length == 2) {
            final hour = int.tryParse(timeParts[0]);
            final minute = int.tryParse(timeParts[1]);
            
            if (hour != null && minute != null) {
              selectedTime = TimeOfDay(hour: hour, minute: minute);
            }
          }
        }
        
        // إذا لم يتوفر وقت افتراضي، اعرض منتقي الوقت
        if (selectedTime == null) {
          // اقتراح وقت بناءً على نوع الفئة
          TimeOfDay suggestedTime = NotificationService.getSuggestedTimeForCategory(category.id);
          
          // عرض منتقي الوقت
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
            // المستخدم ألغى اختيار الوقت
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
      
      // جدولة الإشعار
      await _notificationService.scheduleAthkarNotification(category, selectedTime!);
      await _notificationService.scheduleAdditionalNotifications(category);
      
      if (updateState) {
        setState(() {
          _notificationsEnabled[category.id] = true;
          _notificationTimes[category.id] = selectedTime;
        });
      } else {
        _notificationsEnabled[category.id] = true;
        _notificationTimes[category.id] = selectedTime;
      }
      
      // تحديث المفتاح الرئيسي
      _updateMasterSwitch();
    } else {
      // إلغاء الإشعارات
      await _notificationService.cancelAthkarNotification(category.id);
      
      if (updateState) {
        setState(() {
          _notificationsEnabled[category.id] = false;
        });
      } else {
        _notificationsEnabled[category.id] = false;
      }
      
      // تحديث المفتاح الرئيسي
      _updateMasterSwitch();
    }
  }

  // تعديل وقت الإشعار لفئة معينة
  Future<void> _editNotificationTime(AthkarCategory category) async {
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    // الحصول على الوقت الحالي
    TimeOfDay initialTime = _notificationTimes[category.id] ?? 
                           NotificationService.getSuggestedTimeForCategory(category.id);
    
    // عرض منتقي الوقت
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
      // تحديث وقت الإشعار
      setState(() {
        _notificationTimes[category.id] = pickedTime;
        _notificationsEnabled[category.id] = true;
      });
      
      // جدولة الإشعار بالوقت الجديد
      await _notificationService.scheduleAthkarNotification(category, pickedTime);
      await _notificationService.scheduleAdditionalNotifications(category);
      
      // عرض رسالة
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

  // تنسيق وقت الإشعار
  String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'ص' : 'م';
    
    String displayHour = (time.hour > 12) ? (time.hour - 12).toString() : time.hour.toString();
    if (displayHour == '0') displayHour = '12';
    
    return '$hours:$minutes $period';
  }
  
  // الحصول على لون الفئة
  Color _getCategoryColor(AthkarCategory category) {
    return category.color;
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
                  // المفتاح الرئيسي وشرح
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
                                        'توقيت الإشعارات يعتمد على منطقتك الزمنية',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          height: 1.4,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'منطقتك الزمنية الحالية: $_currentTimeZone',
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
                  
                  // قائمة فئات الأذكار
                  Expanded(
                    child: AnimationLimiter(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final bool isNotificationEnabled = _notificationsEnabled[category.id] ?? false;
                          final TimeOfDay? notificationTime = _notificationTimes[category.id];
                          
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
                                            // أيقونة الفئة
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
                                            
                                            // تفاصيل الفئة
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
                                                ],
                                              ),
                                            ),
                                            
                                            // زر تعديل الوقت
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
                                            
                                            // زر تفعيل/إيقاف الإشعارات
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
                ],
              ),
            ),
    );
  }
}