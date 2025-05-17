// lib/core/services/interfaces/battery_service.dart
abstract class BatteryService {
  /// الحصول على نسبة البطارية الحالية (0-100)
  Future<int> getBatteryLevel();
  
  /// التحقق مما إذا كان الجهاز قيد الشحن
  Future<bool> isCharging();
  
  /// الحصول على حالة توفير الطاقة
  Future<bool> isPowerSaveMode();
  
  /// التحقق من إمكانية إرسال إشعارات بناءً على حالة البطارية
  /// إذا كانت نسبة البطارية أقل من الحد الأدنى ووضع توفير الطاقة مفعل 
  /// والجهاز غير متصل بالشاحن، فلا يتم إرسال الإشعارات
  Future<bool> canSendNotification();
  
  /// تعيين الحد الأدنى لمستوى البطارية لإرسال الإشعارات
  Future<void> setMinimumBatteryLevel(int level);
  
  /// تسجيل مراقب لتغييرات حالة البطارية
  Stream<BatteryState> getBatteryStateStream();
  
  /// تنظيف الموارد
  Future<void> dispose();
}

/// تمثيل حالة البطارية
class BatteryState {
  final int level;
  final bool isCharging;
  final bool isPowerSaveMode;
  
  BatteryState({
    required this.level,
    required this.isCharging,
    required this.isPowerSaveMode,
  });
}