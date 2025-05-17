// lib/core/services/interfaces/do_not_disturb_service.dart
/// أنواع تجاوز وضع عدم الإزعاج
enum DoNotDisturbOverrideType {
  none,          // لا تجاوز
  prayer,        // إشعارات الصلاة
  importantAthkar, // الأذكار المهمة
  critical,      // إشعارات حرجة
}

abstract class DoNotDisturbService {
  /// التحقق من حالة وضع عدم الإزعاج
  Future<bool> isDoNotDisturbEnabled();
  
  /// طلب إذن للوصول لحالة وضع عدم الإزعاج
  Future<bool> requestDoNotDisturbPermission();
  
  /// فتح إعدادات وضع عدم الإزعاج
  Future<void> openDoNotDisturbSettings();
  
  /// تسجيل مراقب لتغييرات وضع عدم الإزعاج
  Future<void> registerDoNotDisturbListener(Function(bool) onDoNotDisturbChange);
  
  /// إلغاء مراقب تغييرات وضع عدم الإزعاج
  Future<void> unregisterDoNotDisturbListener();
  
  /// التحقق مما إذا كان يجب تجاوز وضع عدم الإزعاج بناءً على نوع الإشعار
  Future<bool> shouldOverrideDoNotDisturb(DoNotDisturbOverrideType type);
}