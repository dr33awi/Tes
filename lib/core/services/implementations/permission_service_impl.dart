import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart' as app_settings;
import '../interfaces/permission_service.dart';

class PermissionServiceImpl implements PermissionService {
  final Map<AppPermissionType, int> _permissionAttempts = {};

  @override
  Future<bool> requestLocationPermission() async {
    _permissionAttempts[AppPermissionType.location] = 
        (_permissionAttempts[AppPermissionType.location] ?? 0) + 1;
    
    final status = await Permission.location.request();
    return status.isGranted;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    _permissionAttempts[AppPermissionType.notification] = 
        (_permissionAttempts[AppPermissionType.notification] ?? 0) + 1;
    
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  @override
  Future<bool> requestDoNotDisturbPermission() async {
    try {
      _permissionAttempts[AppPermissionType.doNotDisturb] = 
          (_permissionAttempts[AppPermissionType.doNotDisturb] ?? 0) + 1;
      
      final status = await Permission.accessNotificationPolicy.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestBatteryOptimizationPermission() async {
    try {
      _permissionAttempts[AppPermissionType.batteryOptimization] = 
          (_permissionAttempts[AppPermissionType.batteryOptimization] ?? 0) + 1;
          
      // الطريقة المحسنة - التحقق أولاً إذا كان الإذن ممنوحًا بالفعل
      if (await Permission.ignoreBatteryOptimizations.isGranted) {
        return true;
      }
      
      // إذا لم يكن ممنوحًا، نطلب الإذن
      final status = await Permission.ignoreBatteryOptimizations.request();
      
      // للتأكد من تحديث حالة الإذن، نتحقق مرة أخرى بعد الطلب
      if (!status.isGranted) {
        // قد نحتاج إلى التوجيه إلى إعدادات البطارية يدويًا
        await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.batteryOptimization);
        
        // انتظار وقت قصير ثم إعادة التحقق من الحالة
        await Future.delayed(const Duration(seconds: 2));
        return await Permission.ignoreBatteryOptimizations.isGranted;
      }
      
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    // تحسين طريقة التحقق من استثناء البطارية
    final batteryOptStatus = await Permission.ignoreBatteryOptimizations.status;
    final batteryOptGranted = await checkBatteryOptimizationStatus();
    
    return {
      AppPermissionType.location: _mapToPermissionStatus(await Permission.location.status),
      AppPermissionType.notification: _mapToPermissionStatus(await Permission.notification.status),
      AppPermissionType.doNotDisturb: _mapToPermissionStatus(await Permission.accessNotificationPolicy.status),
      // استخدام النتيجة المحسنة للبطارية
      AppPermissionType.batteryOptimization: batteryOptGranted 
          ? AppPermissionStatus.granted 
          : _mapToPermissionStatus(batteryOptStatus),
    };
  }
  
  /// طريقة جديدة للتحقق بشكل أفضل من حالة استثناء البطارية
  Future<bool> checkBatteryOptimizationStatus() async {
    try {
      // التحقق من حالة الإذن باستخدام permission_handler
      bool isGranted = await Permission.ignoreBatteryOptimizations.isGranted;
      
      // إذا كان الإذن غير ممنوح، يمكننا محاولة التحقق بطريقة ثانية
      if (!isGranted) {
        // اختياري: يمكن إضافة تحقق إضافي هنا باستخدام منفذ خاص إلى نظام التشغيل
        // على سبيل المثال باستخدام method channel للتحقق من حالة البطارية مباشرة
      }
      
      return isGranted;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> openAppSettings([AppSettingsType? type]) async {
    switch (type) {
      case AppSettingsType.location:
        await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.location);
        break;
      case AppSettingsType.notification:
        await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.notification);
        break;
      case AppSettingsType.battery:
        await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.batteryOptimization);
        break;
      default:
        await app_settings.AppSettings.openAppSettings();
    }
  }

  AppPermissionStatus _mapToPermissionStatus(PermissionStatus status) {
    if (status.isGranted) return AppPermissionStatus.granted;
    if (status.isPermanentlyDenied) return AppPermissionStatus.permanentlyDenied;
    if (status.isRestricted) return AppPermissionStatus.restricted;
    if (status.isLimited) return AppPermissionStatus.limited;
    return AppPermissionStatus.denied;
  }
}