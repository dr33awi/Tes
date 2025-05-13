// lib/screens/athkarscreen/screen/notification_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:test_athkar_app/services/notification/notification_manager.dart';
import 'package:test_athkar_app/services/di_container.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/athkar_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late final NotificationManager _notificationManager;
  late final AthkarService _athkarService;
  bool _isLoading = false;
  
  final Map<String, String> _categoryNames = {
    'morning': 'أذكار الصباح',
    'evening': 'أذكار المساء',
    'sleep': 'أذكار النوم',
    'wake': 'أذكار الاستيقاظ',
    'prayer': 'أذكار الصلاة',
    'home': 'أذكار المنزل',
    'food': 'أذكار الطعام',
  };
  
  @override
  void initState() {
    super.initState();
    _notificationManager = serviceLocator<NotificationManager>();
    _athkarService = AthkarService();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إعدادات الإشعارات'),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : ListView(
            padding: EdgeInsets.all(16),
            children: [
              // جدولة الإشعارات الافتراضية
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_active),
                  title: Text('جدولة الإشعارات الافتراضية'),
                  subtitle: Text('جدولة جميع الأذكار بأوقاتها الافتراضية'),
                  onTap: _scheduleDefaultNotifications,
                ),
              ),
              SizedBox(height: 8),
              
              // إلغاء جميع الإشعارات
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_off, color: Colors.red),
                  title: Text('إلغاء جميع الإشعارات'),
                  subtitle: Text('إيقاف جميع إشعارات الأذكار'),
                  onTap: _cancelAllNotifications,
                ),
              ),
              SizedBox(height: 8),
              
              // اختبار الإشعارات
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications, color: Colors.blue),
                  title: Text('اختبار الإشعارات'),
                  subtitle: Text('إرسال إشعار تجريبي'),
                  onTap: _testNotification,
                ),
              ),
              SizedBox(height: 24),
              
              // إعدادات الفئات المنفصلة
              Text(
                'إعدادات الفئات',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              
              ..._categoryNames.entries.map((entry) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(_getCategoryIcon(entry.key)),
                  title: Text(entry.value),
                  subtitle: FutureBuilder<bool>(
                    future: _athkarService.getNotificationEnabled(entry.key),
                    builder: (context, snapshot) {
                      final isEnabled = snapshot.data ?? false;
                      return Text(isEnabled ? 'مفعل' : 'غير مفعل');
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر التفعيل/التعطيل
                      IconButton(
                        icon: Icon(Icons.notifications_active),
                        onPressed: () => _toggleCategoryNotification(entry.key),
                      ),
                      // زر الإعدادات
                      IconButton(
                        icon: Icon(Icons.settings),
                        onPressed: () => _showCategorySettings(entry.key),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
    );
  }
  
  // جدولة الإشعارات الافتراضية
  Future<void> _scheduleDefaultNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      await _notificationManager.scheduleDefaultAthkarNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم جدولة الإشعارات الافتراضية بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جدولة الإشعارات')),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }
  
  // إلغاء جميع الإشعارات
  Future<void> _cancelAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد'),
        content: Text('هل أنت متأكد من إلغاء جميع الإشعارات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('موافق'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _notificationManager.cancelAllNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إلغاء جميع الإشعارات')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إلغاء الإشعارات')),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }
  
  // إرسال إشعار تجريبي
  Future<void> _testNotification() async {
    try {
      await _notificationManager.sendTestNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إرسال إشعار تجريبي')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال الإشعار التجريبي')),
        );
      }
    }
  }
  
  // تبديل حالة إشعار الفئة
  Future<void> _toggleCategoryNotification(String categoryId) async {
    try {
      final isEnabled = await _athkarService.getNotificationEnabled(categoryId);
      
      if (isEnabled) {
        await _notificationManager.cancelAthkarNotifications(categoryId);
        await _athkarService.setNotificationEnabled(categoryId, false);
      } else {
        await _athkarService.scheduleCategoryNotifications(categoryId);
      }
      
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تغيير حالة الإشعار')),
        );
      }
    }
  }
  
  // عرض إعدادات الفئة
  Future<void> _showCategorySettings(String categoryId) async {
    final categoryName = _categoryNames[categoryId] ?? '';
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إعدادات $categoryName',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            
            // اختيار الوقت
            ListTile(
              leading: Icon(Icons.access_time),
              title: Text('تغيير الوقت'),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                
                if (time != null) {
                  await _athkarService.setCustomNotificationTime(
                    categoryId,
                    '${time.hour}:${time.minute}',
                  );
                  await _athkarService.scheduleCategoryNotifications(categoryId);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
            ),
            
            // إضافة أوقات إضافية
            ListTile(
              leading: Icon(Icons.add_alarm),
              title: Text('إضافة أوقات إضافية'),
              onTap: () {
                Navigator.pop(context);
                // يمكن فتح شاشة لإدارة الأوقات الإضافية
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // الحصول على أيقونة الفئة
  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return Icons.wb_sunny;
      case 'evening':
        return Icons.nightlight_round;
      case 'sleep':
        return Icons.bedtime;
      case 'wake':
        return Icons.alarm;
      case 'prayer':
        return Icons.mosque;
      case 'home':
        return Icons.home;
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.notifications;
    }
  }
}