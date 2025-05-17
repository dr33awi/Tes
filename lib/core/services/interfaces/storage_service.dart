// lib/core/services/interfaces/storage_service.dart
abstract class StorageService {
  /// حفظ قيمة نصية
  Future<bool> setString(String key, String value);
  
  /// الحصول على قيمة نصية
  String? getString(String key);
  
  /// حفظ قيمة منطقية
  Future<bool> setBool(String key, bool value);
  
  /// الحصول على قيمة منطقية
  bool? getBool(String key);
  
  /// حفظ قيمة عددية صحيحة
  Future<bool> setInt(String key, int value);
  
  /// الحصول على قيمة عددية صحيحة
  int? getInt(String key);
  
  /// حفظ قيمة عددية عشرية
  Future<bool> setDouble(String key, double value);
  
  /// الحصول على قيمة عددية عشرية
  double? getDouble(String key);
  
  /// حفظ قائمة قيم نصية
  Future<bool> setStringList(String key, List<String> value);
  
  /// الحصول على قائمة قيم نصية
  List<String>? getStringList(String key);
  
  /// حفظ قاموس (Map) من البيانات
  Future<bool> setMap(String key, Map<String, dynamic> value);
  
  /// الحصول على قاموس (Map) من البيانات
  Map<String, dynamic>? getMap(String key);
  
  /// حذف قيمة
  Future<bool> remove(String key);
  
  /// حذف جميع القيم
  Future<bool> clear();
  
  /// التحقق من وجود مفتاح
  bool containsKey(String key);
  
  /// الحصول على جميع المفاتيح
  Set<String> getKeys();
}