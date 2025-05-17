// lib/data/datasources/local/athkar_local_data_source.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../domain/entities/athkar.dart';

abstract class AthkarLocalDataSource {
  /// تحميل جميع فئات الأذكار
  Future<List<Map<String, dynamic>>> loadCategories();
  
  /// تحميل الأذكار حسب الفئة
  Future<List<Map<String, dynamic>>> loadAthkarByCategory(String categoryId);
  
  /// تحميل جميع الأذكار
  Future<List<Map<String, dynamic>>> loadAllAthkar();
}

class AthkarLocalDataSourceImpl implements AthkarLocalDataSource {
  // تخزين مؤقت للبيانات لتحسين الأداء
  Map<String, dynamic>? _cachedData;

  @override
  Future<List<Map<String, dynamic>>> loadCategories() async {
    // تحميل البيانات من ملف JSON
    final Map<String, dynamic> data = await _loadJsonData();
    
    // الحصول على فئات الأذكار
    final List<dynamic> categories = data['categories'] ?? [];
    
    // تحويل البيانات إلى قائمة من الخرائط
    return categories.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> loadAthkarByCategory(String categoryId) async {
    // تحميل البيانات من ملف JSON
    final Map<String, dynamic> data = await _loadJsonData();
    
    // الحصول على الأذكار
    final List<dynamic> athkar = data['athkar'] ?? [];
    
    // تصفية الأذكار حسب الفئة
    final filteredAthkar = athkar.where((item) => item['category'] == categoryId).toList();
    
    // تحويل البيانات إلى قائمة من الخرائط
    return filteredAthkar.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> loadAllAthkar() async {
    // تحميل البيانات من ملف JSON
    final Map<String, dynamic> data = await _loadJsonData();
    
    // الحصول على الأذكار
    final List<dynamic> athkar = data['athkar'] ?? [];
    
    // تحويل البيانات إلى قائمة من الخرائط
    return athkar.cast<Map<String, dynamic>>();
  }

  // تحميل البيانات من ملف JSON
  Future<Map<String, dynamic>> _loadJsonData() async {
    // إذا كانت البيانات مخزنة مؤقتًا، استخدمها
    if (_cachedData != null) {
      return _cachedData!;
    }
    
    // تحميل الملف من الأصول
    final String jsonString = await rootBundle.loadString('assets/data/athkar.json');
    
    // تحليل البيانات
    _cachedData = jsonDecode(jsonString) as Map<String, dynamic>;
    
    return _cachedData!;
  }
}