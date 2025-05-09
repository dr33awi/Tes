// lib/screens/settings/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_service.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary,kSurface;
import 'package:test_athkar_app/screens/athkarscreen/notification_service.dart';
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
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          TimeOfDay suggestedTime;
          
          switch (category.id) {
            case 'morning':
              suggestedTime = TimeOfDay(hour: 6, minute: 0); // 6:00 صباحاً
              break;
            case 'evening':
              suggestedTime = TimeOfDay(hour: 16, minute: 0); // 4:00 مساءً
              break;
            case 'sleep':
              suggestedTime = TimeOfDay(hour: 22, minute: 0); // 10:00 مساءً
              break;
            case 'wake':
              suggestedTime = TimeOfDay(hour: 5, minute: 30); // 5:30 صباحاً
              break;
            case 'prayer':
              suggestedTime = TimeOfDay(hour: 13, minute: 0); // 1:00 ظهراً
              break;
            default:
              suggestedTime = TimeOfDay.now();
          }
          
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
                           TimeOfDay.fromDateTime(DateTime.now());
    
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
  
  // عرض إعدادات إضافية للإشعارات
  void _showAdditionalSettings(AthkarCategory category) {
    // تحقق مما إذا كانت الإشعارات مفعلة
    final isEnabled = _notificationsEnabled[category.id] ?? false;
    if (!isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('قم بتفعيل الإشعارات أولاً'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // مقبض السحب
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // العنوان
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        category.color,
                        Color.lerp(category.color, Colors.white, 0.3)!,
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      stops: const [0.3, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: category.color.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(category.icon, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'إعدادات إشعارات ${category.title}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // محتوى الإعدادات
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الوقت الرئيسي
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'وقت الإشعار الرئيسي',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: kPrimary,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, color: category.color),
                                    SizedBox(width: 8),
                                    Text(
                                      _formatTimeOfDay(_notificationTimes[category.id]!),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Spacer(),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final pickedTime = await showTimePicker(
                                          context: context,
                                          initialTime: _notificationTimes[category.id]!,
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary: category.color,
                                                  onPrimary: Colors.white,
                                                  onSurface: Colors.black,
                                                ),
                                                textButtonTheme: TextButtonThemeData(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: category.color,
                                                  ),
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        
                                        if (pickedTime != null) {
                                          setModalState(() {
                                            _notificationTimes[category.id] = pickedTime;
                                          });
                                          
                                          setState(() {
                                            _notificationTimes[category.id] = pickedTime;
                                          });
                                          
                                          // جدولة الإشعار بالوقت الجديد
                                          await _notificationService.scheduleAthkarNotification(category, pickedTime);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: category.color,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text('تغيير'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // إعدادات الصوت
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إعدادات الصوت',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: kPrimary,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.volume_up, color: category.color),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: category.notifySound ?? 'default',
                                        items: _athkarService.availableNotificationSounds.entries.map((entry) {
                                          return DropdownMenuItem<String>(
                                            value: entry.key,
                                            child: Text(entry.value),
                                          );
                                        }).toList(),
                                        onChanged: (value) async {
                                          if (value != null) {
                                            // تحديث صوت الإشعار وإعادة جدولة الإشعارات
                                            final updatedCategory = category.copyWith(
                                              notifySound: value,
                                            );
                                            
                                            // إعادة جدولة الإشعار بالصوت الجديد
                                            await _notificationService.scheduleAthkarNotification(
                                              updatedCategory, 
                                              _notificationTimes[category.id]!
                                            );
                                            
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('تم تغيير صوت الإشعار'),
                                                behavior: SnackBarBehavior.floating,
                                                backgroundColor: category.color,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                margin: EdgeInsets.all(16),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // الإشعارات المتعددة
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إشعارات إضافية',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: kPrimary,
                                  ),
                                ),
                                SizedBox(height: 12),
                                SwitchListTile(
                                  title: Text('تفعيل إشعارات متعددة'),
                                  subtitle: Text('إمكانية تعيين أوقات إضافية للتذكير'),
                                  value: category.hasMultipleReminders,
                                  activeColor: category.color,
                                  onChanged: (value) async {
                                    // تحديث حالة الإشعارات المتعددة
                                    final updatedCategory = category.copyWith(
                                      hasMultipleReminders: value,
                                    );
                                    
                                    // تحديث في قاعدة البيانات
                                    // (هذا يتطلب إضافة وظيفة جديدة في AthkarService لتحديث الفئة)
                                    
                                    setModalState(() {
                                      // يمكن هنا تحديث القائمة المحلية للفئات
                                    });
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(value ? 'تم تفعيل الإشعارات المتعددة' : 'تم إيقاف الإشعارات المتعددة'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: category.color,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        margin: EdgeInsets.all(16),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                                
                                if (category.hasMultipleReminders) ...[
                                  Divider(),
                                  SizedBox(height: 8),
                                  Text(
                                    'الأوقات الإضافية',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  
                                  // عرض الأوقات الإضافية
                                  if (category.additionalNotifyTimes != null && 
                                      category.additionalNotifyTimes!.isNotEmpty) ...[
                                    ...category.additionalNotifyTimes!.map((timeString) {
                                      final timeParts = timeString.split(':');
                                      if (timeParts.length == 2) {
                                        final hour = int.tryParse(timeParts[0]);
                                        final minute = int.tryParse(timeParts[1]);
                                        
                                        if (hour != null && minute != null) {
                                          final time = TimeOfDay(hour: hour, minute: minute);
                                          return ListTile(
                                            leading: Icon(Icons.access_time, color: category.color),
                                            title: Text(_formatTimeOfDay(time)),
                                            trailing: IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red),
                                              onPressed: () async {
                                                // حذف الوقت الإضافي
                                                await _athkarService.removeAdditionalNotificationTime(category.id, timeString);
                                                
                                                // إعادة جدولة الإشعارات
                                                await _notificationService.cancelAthkarNotification(category.id);
                                                await _notificationService.scheduleAthkarNotification(
                                                  category, 
                                                  _notificationTimes[category.id]!
                                                );
                                                await _notificationService.scheduleAdditionalNotifications(category);
                                                
                                                setModalState(() {
                                                  // تحديث القائمة المحلية
                                                });
                                              },
                                            ),
                                          );
                                        }
                                      }
                                      return SizedBox.shrink();
                                    }).toList(),
                                  ] else ...[
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          'لا توجد أوقات إضافية',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  
                                  SizedBox(height: 12),
                                  
                                  // زر إضافة وقت جديد
                                  Center(
                                    child: ElevatedButton.icon(
                                      icon: Icon(Icons.add),
                                      label: Text('إضافة وقت جديد'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: category.color,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () async {
                                        // عرض منتقي الوقت
                                        final pickedTime = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary: category.color,
                                                  onPrimary: Colors.white,
                                                  onSurface: Colors.black,
                                                ),
                                                textButtonTheme: TextButtonThemeData(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: category.color,
                                                  ),
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        
                                        if (pickedTime != null) {
                                          // إضافة الوقت الجديد
                                          final timeString = '${pickedTime.hour}:${pickedTime.minute}';
                                          await _athkarService.addAdditionalNotificationTime(category.id, timeString);
                                          
                                          // إعادة جدولة الإشعارات
                                          await _notificationService.cancelAthkarNotification(category.id);
                                          await _notificationService.scheduleAthkarNotification(
                                            category, 
                                            _notificationTimes[category.id]!
                                          );
                                          await _notificationService.scheduleAdditionalNotifications(category);
                                          
                                          setModalState(() {
                                            // تحديث القائمة المحلية
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // محتوى الإشعار
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'محتوى الإشعار',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: kPrimary,
                                  ),
                                ),
                                SizedBox(height: 12),
                                TextFormField(
                                  initialValue: category.notifyTitle ?? 'حان موعد ${category.title}',
                                  decoration: InputDecoration(
                                    labelText: 'عنوان الإشعار',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: Icon(Icons.title, color: category.color),
                                  ),
                                  onChanged: (value) async {
                                    // تحديث عنوان الإشعار
                                    final updatedCategory = category.copyWith(
                                      notifyTitle: value,
                                    );
                                    
                                    // إعادة جدولة الإشعار بالعنوان الجديد
                                    await _notificationService.scheduleAthkarNotification(
                                      updatedCategory, 
                                      _notificationTimes[category.id]!
                                    );
                                  },
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  initialValue: category.notifyBody ?? 'اضغط هنا لقراءة الأذكار',
                                  decoration: InputDecoration(
                                    labelText: 'نص الإشعار',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: Icon(Icons.message, color: category.color),
                                  ),
                                  maxLines: 2,
                                  onChanged: (value) async {
                                    // تحديث نص الإشعار
                                    final updatedCategory = category.copyWith(
                                      notifyBody: value,
                                    );
                                    
                                    // إعادة جدولة الإشعار بالنص الجديد
                                    await _notificationService.scheduleAthkarNotification(
                                      updatedCategory, 
                                      _notificationTimes[category.id]!
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // زر الإغلاق
                Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: category.color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'إغلاق',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
                                  child: Text(
                                    'يمكنك تفعيل وتخصيص إشعارات الأذكار ليذكرك التطبيق في الأوقات المناسبة',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
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
                                      child: InkWell(
                                        onTap: isNotificationEnabled 
                                            ? () => _showAdditionalSettings(category)
                                            : null,
                                        borderRadius: BorderRadius.circular(20),
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