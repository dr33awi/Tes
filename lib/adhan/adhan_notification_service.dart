// lib/services/adhan_notification_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdhanNotificationService {
  // تطبيق نمط Singleton
  static final AdhanNotificationService _instance = AdhanNotificationService._internal();
  factory AdhanNotificationService() => _instance;
  AdhanNotificationService._internal();

  // إعدادات تفضيلات الإشعارات
  bool _isNotificationEnabled = true;
  Map<String, bool> _prayerNotificationSettings = {
    'الفجر': true,
    'الشروق': false,
    'الظهر': true,
    'العصر': true,
    'المغرب': true,
    'العشاء': true,
  };

  // دالة التهيئة لخدمة الإشعارات
  Future<void> initialize() async {
    // تحميل الإعدادات المحفوظة
    await _loadNotificationSettings();
    debugPrint('تم تهيئة خدمة الإشعارات (نسخة مبسطة)');
  }
  
  // تحميل إعدادات الإشعارات المحفوظة
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل حالة تفعيل الإشعارات
      _isNotificationEnabled = prefs.getBool('adhan_notification_enabled') ?? true;
      
      // تحميل إعدادات كل صلاة
      for (final prayer in _prayerNotificationSettings.keys) {
        final enabled = prefs.getBool('adhan_notification_${prayer}') ?? 
            _prayerNotificationSettings[prayer]!;
        _prayerNotificationSettings[prayer] = enabled;
      }
    } catch (e) {
      debugPrint('خطأ في تحميل إعدادات الإشعارات: $e');
    }
  }
  
  // حفظ إعدادات الإشعارات
  Future<void> saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ حالة تفعيل الإشعارات
      await prefs.setBool('adhan_notification_enabled', _isNotificationEnabled);
      
      // حفظ إعدادات كل صلاة
      for (final prayer in _prayerNotificationSettings.keys) {
        await prefs.setBool(
          'adhan_notification_${prayer}', 
          _prayerNotificationSettings[prayer]!
        );
      }
    } catch (e) {
      debugPrint('خطأ في حفظ إعدادات الإشعارات: $e');
    }
  }
  
  // جدولة إشعار لوقت صلاة (وهمي حاليًا)
  Future<void> schedulePrayerNotification({
    required String prayerName,
    required DateTime prayerTime,
    int notificationId = 0,
  }) async {
    // تحقق من تفعيل الإشعارات وإعدادات الصلاة المحددة
    if (!_isNotificationEnabled || !(_prayerNotificationSettings[prayerName] ?? false)) {
      return;
    }
    
    // التأكد من أن وقت الصلاة في المستقبل
    if (prayerTime.isBefore(DateTime.now())) {
      return;
    }
    
    // إخراج معلومات توضيحية في وضع التصحيح
    debugPrint('(محاكاة) جدولة إشعار لصلاة $prayerName في $prayerTime');
  }
  
  // جدولة إشعارات جميع الصلوات للأوقات المحددة
  Future<void> scheduleAllPrayerNotifications(List<Map<String, dynamic>> prayerTimes) async {
    // إلغاء جميع الإشعارات السابقة
    await cancelAllNotifications();
    
    // جدولة إشعارات جديدة لكل صلاة
    for (int i = 0; i < prayerTimes.length; i++) {
      final prayer = prayerTimes[i];
      await schedulePrayerNotification(
        prayerName: prayer['name'],
        prayerTime: prayer['time'],
        notificationId: i,
      );
    }
    
    debugPrint('(محاكاة) تمت جدولة ${prayerTimes.length} إشعارات للصلوات');
  }
  
  // إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    debugPrint('(محاكاة) تم إلغاء جميع الإشعارات');
  }
  
  // دوال للحصول على/تعيين الإعدادات
  bool get isNotificationEnabled => _isNotificationEnabled;
  
  set isNotificationEnabled(bool value) {
    _isNotificationEnabled = value;
    saveNotificationSettings();
  }
  
  Map<String, bool> get prayerNotificationSettings => _prayerNotificationSettings;
  
  Future<void> setPrayerNotificationEnabled(String prayer, bool enabled) async {
    if (_prayerNotificationSettings.containsKey(prayer)) {
      _prayerNotificationSettings[prayer] = enabled;
      await saveNotificationSettings();
    }
  }
}