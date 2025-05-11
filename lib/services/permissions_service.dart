// lib/services/permissions_service.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';

/// خدمة لإدارة أذونات التطبيق
class PermissionsService {
  // مفاتيح التخزين المحلي
  static const String _locationPermissionRequestedKey = 'location_permission_requested';
  static const String _notificationsPermissionRequestedKey = 'notifications_permission_requested';
  static const String _sensorsPermissionRequestedKey = 'sensors_permission_requested';

  // تنفيذ نمط Singleton مع التبعية المعكوسة
  static final PermissionsService _instance = PermissionsService._internal();
  
  factory PermissionsService({
    ErrorLoggingService? errorLoggingService,
  }) {
    _instance._errorLoggingService = errorLoggingService ?? ErrorLoggingService();
    return _instance;
  }
  
  PermissionsService._internal();
  
  // التبعية المعكوسة
  late ErrorLoggingService _errorLoggingService;

  // ========== أذونات الموقع ==========
  
  /// التحقق من أذونات الموقع
  Future<bool> checkLocationPermission() async {
    try {
      return await Permission.location.isGranted;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في التحقق من إذن الموقع', 
        e
      );
      return false;
    }
  }

  /// طلب أذونات الموقع
  Future<bool> requestLocationPermission() async {
    try {
      PermissionStatus status = await Permission.location.request();
      
      // تخزين حالة الطلب
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationPermissionRequestedKey, true);
      
      return status.isGranted;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في طلب إذن الموقع', 
        e
      );
      return false;
    }
  }
  
  /// التحقق من خدمات الموقع وطلب الإذن إذا لزم الأمر
  Future<bool> checkAndRequestLocationPermission() async {
    try {
      // التحقق ما إذا كانت خدمة الموقع مفعلة
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        // هنا يمكن عرض رسالة للمستخدم لتفعيل خدمة الموقع
        return false;
      }
      
      // التحقق من الإذن
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        // طلب الإذن
        return await requestLocationPermission();
      }
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في التحقق وطلب إذن الموقع', 
        e
      );
      return false;
    }
  }
  
  /// التحقق مما إذا كانت خدمة الموقع مفعلة
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Permission.location.serviceStatus.isEnabled;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في التحقق من تفعيل خدمة الموقع', 
        e
      );
      return false;
    }
  }
  
  /// فتح إعدادات الموقع
  Future<void> openLocationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.location);
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في فتح إعدادات الموقع', 
        e
      );
    }
  }

  // ========== أذونات الإشعارات ==========
  
  /// التحقق من أذونات الإشعارات
  Future<bool> checkNotificationPermission() async {
    try {
      return await Permission.notification.isGranted;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في التحقق من إذن الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// طلب أذونات الإشعارات
  Future<bool> requestNotificationPermission() async {
    try {
      PermissionStatus status = await Permission.notification.request();
      
      // تخزين حالة الطلب
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsPermissionRequestedKey, true);
      
      return status.isGranted;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في طلب إذن الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// التحقق وطلب إذن الإشعارات إذا لزم الأمر
  Future<bool> checkAndRequestNotificationPermission() async {
    try {
      bool hasPermission = await checkNotificationPermission();
      if (!hasPermission) {
        return await requestNotificationPermission();
      }
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في التحقق وطلب إذن الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// فتح إعدادات الإشعارات
  Future<void> openNotificationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في فتح إعدادات الإشعارات', 
        e
      );
    }
  }

  // ========== أذونات المستشعرات ==========
  
  /// التحقق من أذونات المستشعرات
  Future<bool> checkSensorsPermission() async {
    try {
      return await Permission.sensors.isGranted;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في التحقق من إذن المستشعرات', 
        e
      );
      return false;
    }
  }
  
  /// طلب أذونات المستشعرات
  Future<bool> requestSensorsPermission() async {
    try {
      PermissionStatus status = await Permission.sensors.request();
      
      // تخزين حالة الطلب
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sensorsPermissionRequestedKey, true);
      
      return status.isGranted;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في طلب إذن المستشعرات', 
        e
      );
      return false;
    }
  }
  
  /// التحقق وطلب إذن المستشعرات إذا لزم الأمر
  Future<bool> checkAndRequestSensorsPermission() async {
    try {
      bool hasPermission = await checkSensorsPermission();
      if (!hasPermission) {
        return await requestSensorsPermission();
      }
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في التحقق وطلب إذن المستشعرات', 
        e
      );
      return false;
    }
  }

  // ========== واجهة عرض طلب الإذن ==========
  
  /// عرض حوار طلب الإذن للمستخدم مع شرح السبب
  Future<bool> showPermissionDialog(
    BuildContext context, 
    String title, 
    String message, 
    String permission,
    IconData icon,
  ) async {
    bool result = false;
    
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                result = false;
              },
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // طلب الإذن المناسب
                if (permission == 'location') {
                  result = await requestLocationPermission();
                  if (!result) {
                    await openLocationSettings();
                  }
                } else if (permission == 'notification') {
                  result = await requestNotificationPermission();
                  if (!result) {
                    await openNotificationSettings();
                  }
                } else if (permission == 'sensors') {
                  result = await requestSensorsPermission();
                }
              },
              child: Text('منح الإذن'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
      
      return result;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في عرض حوار الإذن', 
        e
      );
      return false;
    }
  }
  
  /// عرض حوار خاص بإذن الموقع
  Future<bool> showLocationPermissionDialog(BuildContext context) async {
    try {
      return await showPermissionDialog(
        context,
        'إذن الموقع',
        'يحتاج التطبيق إلى الوصول إلى موقعك لتحديد اتجاه القبلة بدقة وحساب مواقيت الصلاة المحلية.',
        'location',
        Icons.location_on,
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في عرض حوار إذن الموقع', 
        e
      );
      return false;
    }
  }
  
  /// عرض حوار خاص بإذن الإشعارات
  Future<bool> showNotificationPermissionDialog(BuildContext context) async {
    try {
      return await showPermissionDialog(
        context,
        'إذن الإشعارات',
        'يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بمواقيت الصلاة والأذكار اليومية.',
        'notification',
        Icons.notifications,
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في عرض حوار إذن الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// عرض حوار خاص بإذن المستشعرات
  Future<bool> showSensorsPermissionDialog(BuildContext context) async {
    try {
      return await showPermissionDialog(
        context,
        'إذن المستشعرات',
        'تحتاج بوصلة القبلة إلى الوصول إلى مستشعرات الجهاز لتحديد الاتجاه الصحيح.',
        'sensors',
        Icons.compass_calibration,
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في عرض حوار إذن المستشعرات', 
        e
      );
      return false;
    }
  }
  
  // ========== التحقق من جميع الأذونات اللازمة لميزة معينة ==========
  
  /// التحقق من الأذونات اللازمة للإشعارات
  Future<bool> checkNotificationsPermissions(BuildContext context, {bool showDialogs = true}) async {
    try {
      // التحقق من إذن الإشعارات
      bool notificationGranted = await checkNotificationPermission();
      
      // إذا كان الإذن غير ممنوح وكان عرض الحوارات مسموحًا
      if (!notificationGranted && showDialogs) {
        notificationGranted = await showNotificationPermissionDialog(context);
      }
      
      return notificationGranted;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في التحقق من أذونات الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// التحقق من الأذونات اللازمة لبوصلة القبلة
  Future<bool> checkQiblaPermissions(BuildContext context, {bool showDialogs = true}) async {
    try {
      // التحقق من إذن الموقع
      bool locationGranted = await checkLocationPermission();
      
      // التحقق من إذن المستشعرات
      bool sensorsGranted = await checkSensorsPermission();
      
      // إذا كان أحد الأذونات غير ممنوح وكان عرض الحوارات مسموحًا
      if (showDialogs) {
        if (!locationGranted) {
          locationGranted = await showLocationPermissionDialog(context);
        }
        
        if (!sensorsGranted) {
          sensorsGranted = await showSensorsPermissionDialog(context);
        }
      }
      
      // يجب أن تكون كل الأذونات ممنوحة
      return locationGranted && sensorsGranted;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في التحقق من أذونات بوصلة القبلة', 
        e
      );
      return false;
    }
  }
  
  /// التحقق من الأذونات اللازمة لمواقيت الصلاة
  Future<bool> checkPrayerTimesPermissions(BuildContext context, {bool showDialogs = true}) async {
    try {
      // التحقق من إذن الموقع
      bool locationGranted = await checkLocationPermission();
      
      // التحقق من إذن الإشعارات إذا كان التذكير بالصلاة مفعلاً
      bool notificationGranted = await checkNotificationPermission();
      
      // إذا كان أحد الأذونات غير ممنوح وكان عرض الحوارات مسموحًا
      if (showDialogs) {
        if (!locationGranted) {
          locationGranted = await showLocationPermissionDialog(context);
        }
        
        if (!notificationGranted) {
          notificationGranted = await showNotificationPermissionDialog(context);
        }
      }
      
      // النتيجة النهائية - قد نحتاج فقط للموقع إذا كانت الإشعارات غير مطلوبة
      return locationGranted;
    } catch (e) {
      await _errorLoggingService.logError(
        'PermissionsService', 
        'خطأ في التحقق من أذونات مواقيت الصلاة', 
        e
      );
      return false;
    }
  }
}