// lib/core/services/implementations/battery_service_impl.dart
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import '../interfaces/battery_service.dart' as app_battery;

class BatteryServiceImpl implements app_battery.BatteryService {
  final Battery _battery = Battery();
  final StreamController<app_battery.BatteryState> _batteryStateController = 
      StreamController<app_battery.BatteryState>.broadcast();
  
  // الحد الأدنى لمستوى البطارية لإرسال الإشعارات
  int _minimumBatteryLevel = 15;
  StreamSubscription? _batterySubscription;
  
  BatteryServiceImpl() {
    // تسجيل المراقبة لتغييرات البطارية
    _initBatteryStateListener();
  }
  
  void _initBatteryStateListener() {
    // مراقبة مستوى البطارية
    _batterySubscription = _battery.onBatteryStateChanged.listen((BatteryState state) async {
      final int level = await getBatteryLevel();
      final bool charging = await isCharging();
      final bool powerSaveMode = await isPowerSaveMode();
      
      _batteryStateController.add(
        app_battery.BatteryState(
          level: level,
          isCharging: charging,
          isPowerSaveMode: powerSaveMode,
        ),
      );
    });
  }
  
  @override
  Future<int> getBatteryLevel() async {
    try {
      final int level = await _battery.batteryLevel;
      return level;
    } catch (e) {
      // في حالة حدوث خطأ، نفترض أن مستوى البطارية مرتفع لتجنب تعطيل الإشعارات
      return 100;
    }
  }
  
  @override
  Future<bool> isCharging() async {
    try {
      final batteryState = await _battery.batteryState;
      return batteryState == BatteryState.charging || 
             batteryState == BatteryState.full;
    } catch (e) {
      // في حالة حدوث خطأ، نفترض أن الجهاز قيد الشحن لتجنب تعطيل الإشعارات
      return true;
    }
  }
  
  @override
  Future<bool> isPowerSaveMode() async {
    try {
      final bool isPowerSaveMode = await _battery.isInBatterySaveMode;
      return isPowerSaveMode;
    } catch (e) {
      // في حالة حدوث خطأ، نفترض أن وضع توفير الطاقة غير مفعل
      return false;
    }
  }
  
  @override
  Future<bool> canSendNotification() async {
    // إذا كان الجهاز قيد الشحن، فيمكن إرسال الإشعارات بغض النظر عن حالة البطارية
    final bool charging = await isCharging();
    if (charging) {
      return true;
    }
    
    // التحقق من مستوى البطارية ووضع توفير الطاقة
    final int level = await getBatteryLevel();
    final bool powerSaveMode = await isPowerSaveMode();
    
    // إذا كان مستوى البطارية منخفضًا ووضع توفير الطاقة مفعل، فلا يتم إرسال الإشعارات
    if (level <= _minimumBatteryLevel && powerSaveMode) {
      return false;
    }
    
    return true;
  }
  
  @override
  Future<void> setMinimumBatteryLevel(int level) async {
    if (level >= 5 && level <= 30) {
      _minimumBatteryLevel = level;
    }
  }
  
  @override
  Stream<app_battery.BatteryState> getBatteryStateStream() {
    return _batteryStateController.stream;
  }
  
  /// إغلاق الموارد عند الانتهاء
  Future<void> dispose() async {
    await _batterySubscription?.cancel();
    await _batteryStateController.close();
  }
}