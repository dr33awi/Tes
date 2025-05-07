import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionsService {
  // مفاتيح التخزين المحلي
  static const String _locationPermissionRequestedKey = 'location_permission_requested';
  static const String _notificationsPermissionRequestedKey = 'notifications_permission_requested';
  static const String _sensorsPermissionRequestedKey = 'sensors_permission_requested';

  // Singleton نمط
  static final PermissionsService _instance = PermissionsService._internal();
  
  factory PermissionsService() {
    return _instance;
  }
  
  PermissionsService._internal();

  // ========== أذونات الموقع ==========
  
  /// التحقق من أذونات الموقع
  Future<bool> checkLocationPermission() async {
    return await Permission.location.isGranted;
  }

  /// طلب أذونات الموقع
  Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    
    // تخزين حالة الطلب
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationPermissionRequestedKey, true);
    
    return status.isGranted;
  }
  
  /// التحقق من خدمات الموقع وطلب الإذن إذا لزم الأمر
  Future<bool> checkAndRequestLocationPermission() async {
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
  }
  
  /// التحقق مما إذا كانت خدمة الموقع مفعلة
  Future<bool> isLocationServiceEnabled() async {
    return await Permission.location.serviceStatus.isEnabled;
  }
  
  /// فتح إعدادات الموقع
  Future<void> openLocationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.location);
  }

  // ========== أذونات الإشعارات ==========
  
  /// التحقق من أذونات الإشعارات
  Future<bool> checkNotificationPermission() async {
    return await Permission.notification.isGranted;
  }
  
  /// طلب أذونات الإشعارات
  Future<bool> requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();
    
    // تخزين حالة الطلب
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsPermissionRequestedKey, true);
    
    return status.isGranted;
  }
  
  /// التحقق وطلب إذن الإشعارات إذا لزم الأمر
  Future<bool> checkAndRequestNotificationPermission() async {
    bool hasPermission = await checkNotificationPermission();
    if (!hasPermission) {
      return await requestNotificationPermission();
    }
    return true;
  }
  
  /// فتح إعدادات الإشعارات
  Future<void> openNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  // ========== أذونات المستشعرات ==========
  
  /// التحقق من أذونات المستشعرات
  Future<bool> checkSensorsPermission() async {
    return await Permission.sensors.isGranted;
  }
  
  /// طلب أذونات المستشعرات
  Future<bool> requestSensorsPermission() async {
    PermissionStatus status = await Permission.sensors.request();
    
    // تخزين حالة الطلب
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sensorsPermissionRequestedKey, true);
    
    return status.isGranted;
  }
  
  /// التحقق وطلب إذن المستشعرات إذا لزم الأمر
  Future<bool> checkAndRequestSensorsPermission() async {
    bool hasPermission = await checkSensorsPermission();
    if (!hasPermission) {
      return await requestSensorsPermission();
    }
    return true;
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
  }
  
  /// عرض حوار خاص بإذن الموقع
  Future<bool> showLocationPermissionDialog(BuildContext context) async {
    return await showPermissionDialog(
      context,
      'إذن الموقع',
      'يحتاج التطبيق إلى الوصول إلى موقعك لتحديد اتجاه القبلة بدقة وحساب مواقيت الصلاة المحلية.',
      'location',
      Icons.location_on,
    );
  }
  
  /// عرض حوار خاص بإذن الإشعارات
  Future<bool> showNotificationPermissionDialog(BuildContext context) async {
    return await showPermissionDialog(
      context,
      'إذن الإشعارات',
      'يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بمواقيت الصلاة والأذكار اليومية.',
      'notification',
      Icons.notifications,
    );
  }
  
  /// عرض حوار خاص بإذن المستشعرات
  Future<bool> showSensorsPermissionDialog(BuildContext context) async {
    return await showPermissionDialog(
      context,
      'إذن المستشعرات',
      'تحتاج بوصلة القبلة إلى الوصول إلى مستشعرات الجهاز لتحديد الاتجاه الصحيح.',
      'sensors',
      Icons.compass_calibration,
    );
  }
  
  // ========== التحقق من جميع الأذونات اللازمة لميزة معينة ==========
  
  /// التحقق من الأذونات اللازمة لبوصلة القبلة
  Future<bool> checkQiblaPermissions(BuildContext context, {bool showDialogs = true}) async {
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
  }
  
  /// التحقق من الأذونات اللازمة لمواقيت الصلاة
  Future<bool> checkPrayerTimesPermissions(BuildContext context, {bool showDialogs = true}) async {
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
  }
}