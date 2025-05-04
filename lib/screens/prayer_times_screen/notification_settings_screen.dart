// lib/screens/settings/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;
import 'package:test_athkar_app/services/adhan_notification_service.dart';
import 'package:test_athkar_app/services/prayer_times_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final AdhanNotificationService _notificationService = AdhanNotificationService();
  final PrayerTimesService _prayerService = PrayerTimesService();
  
  bool _notificationsEnabled = true;
  Map<String, bool> _prayerSettings = {};
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _notificationsEnabled = _notificationService.isNotificationEnabled;
      _prayerSettings = Map.from(_notificationService.prayerNotificationSettings);
    });
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
          icon: const Icon(
            Icons.arrow_back,
            color: kPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة تفعيل الإشعارات
              _buildMasterSwitchCard(),
              
              const SizedBox(height: 20),
              
              // عنوان إعدادات الصلوات
              const Text(
                'إعدادات إشعارات الصلوات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // إعدادات الصلوات الفردية
              _buildPrayerSettingsCard(),
              
              const SizedBox(height: 24),
              
              // معلومات توضيحية
              _buildInfoCard(),
              
              const SizedBox(height: 24),
              
              // زر تحديث الإشعارات
              Center(
                child: ElevatedButton.icon(
                  onPressed: _updateNotifications,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث الإشعارات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // بطاقة تفعيل/تعطيل الإشعارات
  Widget _buildMasterSwitchCard() {
    return Card(
      elevation: 4,
      shadowColor: kPrimary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kPrimary,
              kPrimaryLight,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 24,
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
            Switch(
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  _notificationsEnabled = value;
                });
                
                _notificationService.isNotificationEnabled = value;
                
                if (value) {
                  // إعادة جدولة الإشعارات عند تفعيلها
                  await _prayerService.schedulePrayerNotifications();
                } else {
                  // إلغاء جميع الإشعارات عند إيقافها
                  await _notificationService.cancelAllNotifications();
                }
              },
              activeColor: Colors.white,
              activeTrackColor: Colors.white.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
  
  // بطاقة إعدادات الصلوات الفردية
  Widget _buildPrayerSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _prayerSettings.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    _getPrayerIcon(entry.key),
                    color: kPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Switch(
                    value: entry.value,
                    onChanged: _notificationsEnabled
                        ? (value) async {
                            setState(() {
                              _prayerSettings[entry.key] = value;
                            });
                            
                            await _notificationService.setPrayerNotificationEnabled(
                              entry.key, 
                              value
                            );
                            await _prayerService.schedulePrayerNotifications();
                          }
                        : null,
                    activeColor: kPrimary,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  // أيقونة لكل صلاة
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
  
  // بطاقة معلومات
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
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
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade800,
                  size: 24,
                ),
                const SizedBox(width: 8),
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
            Text(
              'سيتم إرسال إشعارات للصلوات المفعلة في وقتها المحدد. تأكد من السماح للتطبيق بالعمل في الخلفية وعدم إيقافه من قبل نظام التشغيل.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك تحديث الإشعارات عند تغيير الموقع الجغرافي أو تغيير إعدادات حساب مواقيت الصلاة.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // تحديث إشعارات الصلاة
  Future<void> _updateNotifications() async {
    try {
      // إعادة جدولة جميع الإشعارات
      await _prayerService.schedulePrayerNotifications();
      
      // إظهار رسالة تأكيد
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('تم تحديث إشعارات الصلاة بنجاح'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: kPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      // إظهار رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Text('حدث خطأ أثناء تحديث الإشعارات'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}