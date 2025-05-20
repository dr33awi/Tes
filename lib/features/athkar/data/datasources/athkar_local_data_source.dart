// lib/data/datasources/local/athkar_local_data_source.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/athkar.dart';

/// واجهة لمصدر البيانات المحلي للأذكار
///
/// توفر هذه الواجهة طرقًا للوصول إلى بيانات الأذكار المخزنة محليًا
abstract class AthkarLocalDataSource {
  /// الحصول على فئات الأذكار
  Future<List<Map<String, dynamic>>> getCategories();
  
  /// الحصول على الأذكار حسب الفئة
  Future<List<Map<String, dynamic>>> getAthkarByCategory(String categoryId);
  
  /// الحصول على ذكر محدد بواسطة المعرف
  Future<Map<String, dynamic>?> getAthkarById(String id);
  
  /// حفظ ذكر في المفضلة
  Future<void> saveAthkarFavorite(String id, bool isFavorite);
  
  /// الحصول على الأذكار المفضلة
  Future<List<Map<String, dynamic>>> getFavoriteAthkar();
  
  /// البحث في الأذكار
  Future<List<Map<String, dynamic>>> searchAthkar(String query);
  
  /// تحميل جميع الأذكار
  Future<List<Map<String, dynamic>>> loadAllAthkar();
}

/// تنفيذ لمصدر البيانات المحلي للأذكار
///
/// يوفر هذا التنفيذ طرقًا للوصول إلى بيانات الأذكار المخزنة محليًا
/// يستخدم [SharedPreferences] لتخزين حالة المفضلة
class AthkarLocalDataSourceImpl implements AthkarLocalDataSource {
  // قسم البيانات الثابتة - يتم تخزينها هنا لتوفير بيانات افتراضية
  
  /// فئات الأذكار الافتراضية
  static final List<Map<String, dynamic>> _defaultCategories = [
    {
      'id': 'morning',
      'name': 'أذكار الصباح',
      'description': 'الأذكار التي تقال في الصباح',
      'icon': 'Icons.wb_sunny'
    },
    {
      'id': 'evening',
      'name': 'أذكار المساء',
      'description': 'الأذكار التي تقال في المساء',
      'icon': 'Icons.nightlight_round'
    },
    {
      'id': 'sleep',
      'name': 'أذكار النوم',
      'description': 'الأذكار التي تقال عند النوم',
      'icon': 'Icons.bedtime'
    },
    {
      'id': 'wake',
      'name': 'أذكار الاستيقاظ',
      'description': 'الأذكار التي تقال عند الاستيقاظ',
      'icon': 'Icons.alarm'
    },
    {
      'id': 'prayer',
      'name': 'أذكار الصلاة',
      'description': 'الأذكار التي تقال قبل وبعد الصلاة',
      'icon': 'Icons.mosque'
    },
  ];
  
  /// الأذكار الافتراضية
  static final List<Map<String, dynamic>> _defaultAthkar = [
    {
      'id': '1',
      'title': 'الاستعاذة',
      'content': 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
      'count': 1,
      'categoryId': 'morning',
      'source': 'القرآن الكريم',
      'notes': null,
      'fadl': 'للاستعاذة فضل كبير وهي من أسباب حفظ العبد من الشيطان',
    },
    {
      'id': '2',
      'title': 'البسملة',
      'content': 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      'count': 1,
      'categoryId': 'morning',
      'source': 'القرآن الكريم',
      'notes': null,
      'fadl': 'البدء بالبسملة من أسباب البركة والتوفيق',
    },
    {
      'id': '3',
      'title': 'الاستغفار',
      'content': 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لا إِلَهَ إِلا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
      'count': 3,
      'categoryId': 'evening',
      'source': 'من السنة النبوية',
      'notes': null,
      'fadl': 'يغفر الله به الذنوب، ويفرج الهموم، ويرزق من حيث لا يحتسب',
    },
  ];
  
  // قسم البيانات المتغيرة - يتم تخزينها هنا لاستخدامها في الذاكرة
  
  /// فئات الأذكار الحالية
  final List<Map<String, dynamic>> _categories = List.from(_defaultCategories);
  
  /// الأذكار الحالية
  final List<Map<String, dynamic>> _athkar = List.from(_defaultAthkar);
  
  /// خريطة المفضلة
  final Map<String, bool> _favorites = {};
  
  /// عداد للعمليات المتزامنة
  int _operationCounter = 0;
  
  /// مثيل واحد من الصف (Singleton)
  static final AthkarLocalDataSourceImpl _instance = AthkarLocalDataSourceImpl._internal();
  
  /// المُنشئ الداخلي للصف
  AthkarLocalDataSourceImpl._internal() {
    _initFromSharedPreferences();
  }
  
  /// المُنشئ العام للصف - يعيد المثيل الوحيد
  factory AthkarLocalDataSourceImpl() {
    return _instance;
  }
  
  /// تهيئة البيانات من التفضيلات المشتركة
  ///
  /// يتم استدعاء هذه الطريقة عند إنشاء المثيل الوحيد
  Future<void> _initFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل المفضلة
      final favoriteKeys = prefs.getKeys().where((key) => key.startsWith('favorite_athkar_'));
      for (final key in favoriteKeys) {
        final id = key.replaceFirst('favorite_athkar_', '');
        _favorites[id] = prefs.getBool(key) ?? false;
      }
      
      // تحميل الفئات المخصصة (إذا وجدت)
      final customCategoriesJson = prefs.getString('custom_athkar_categories');
      if (customCategoriesJson != null) {
        try {
          final customCategories = List<Map<String, dynamic>>.from(
            (json.decode(customCategoriesJson) as List).map((x) => Map<String, dynamic>.from(x)),
          );
          
          // دمج الفئات المخصصة مع الفئات الافتراضية
          for (final category in customCategories) {
            final index = _categories.indexWhere((cat) => cat['id'] == category['id']);
            if (index >= 0) {
              _categories[index] = category;
            } else {
              _categories.add(category);
            }
          }
        } catch (e) {
          debugPrint('خطأ في تحميل الفئات المخصصة: $e');
        }
      }
      
      // تحميل الأذكار المخصصة (إذا وجدت)
      final customAthkarJson = prefs.getString('custom_athkar_items');
      if (customAthkarJson != null) {
        try {
          final customAthkar = List<Map<String, dynamic>>.from(
            (json.decode(customAthkarJson) as List).map((x) => Map<String, dynamic>.from(x)),
          );
          
          // دمج الأذكار المخصصة مع الأذكار الافتراضية
          for (final thikr in customAthkar) {
            final index = _athkar.indexWhere((t) => t['id'] == thikr['id']);
            if (index >= 0) {
              _athkar[index] = thikr;
            } else {
              _athkar.add(thikr);
            }
          }
        } catch (e) {
          debugPrint('خطأ في تحميل الأذكار المخصصة: $e');
        }
      }
    } catch (e) {
      debugPrint('خطأ في تهيئة البيانات من التفضيلات المشتركة: $e');
    }
  }
  
  /// حفظ البيانات في التفضيلات المشتركة
  ///
  /// يتم استدعاء هذه الطريقة بعد أي تغيير في البيانات
  Future<void> _saveToSharedPreferences() async {
    try {
      // زيادة عداد العمليات
      _operationCounter++;
      
      // إذا كانت هناك عمليات متزامنة أخرى، انتظر حتى تنتهي
      if (_operationCounter > 1) {
        // دورة زمنية قصيرة للسماح للعمليات الأخرى بالانتهاء
        await Future.delayed(const Duration(milliseconds: 100));
        // نقص عداد العمليات
        _operationCounter--;
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ المفضلة
      for (final entry in _favorites.entries) {
        await prefs.setBool('favorite_athkar_${entry.key}', entry.value);
      }
      
      // حفظ الفئات المخصصة - فقط التي تختلف عن الافتراضية
      final customCategories = _categories.where((category) {
        final defaultCategory = _defaultCategories.firstWhere(
          (cat) => cat['id'] == category['id'],
          orElse: () => <String, dynamic>{},
        );
        
        // إذا كانت الفئة غير موجودة في الفئات الافتراضية، فهي مخصصة
        if (defaultCategory.isEmpty) return true;
        
        // إذا كانت الفئة موجودة في الفئات الافتراضية، تحقق من وجود اختلافات
        return !_areEqual(category, defaultCategory);
      }).toList();
      
      if (customCategories.isNotEmpty) {
        await prefs.setString('custom_athkar_categories', json.encode(customCategories));
      }
      
      // حفظ الأذكار المخصصة - فقط التي تختلف عن الافتراضية
      final customAthkar = _athkar.where((thikr) {
        final defaultThikr = _defaultAthkar.firstWhere(
          (t) => t['id'] == thikr['id'],
          orElse: () => <String, dynamic>{},
        );
        
        // إذا كان الذكر غير موجود في الأذكار الافتراضية، فهو مخصص
        if (defaultThikr.isEmpty) return true;
        
        // إذا كان الذكر موجودًا في الأذكار الافتراضية، تحقق من وجود اختلافات
        return !_areEqual(thikr, defaultThikr);
      }).toList();
      
      if (customAthkar.isNotEmpty) {
        await prefs.setString('custom_athkar_items', json.encode(customAthkar));
      }
      
      // نقص عداد العمليات
      _operationCounter--;
    } catch (e) {
      // نقص عداد العمليات في حالة حدوث خطأ
      _operationCounter--;
      debugPrint('خطأ في حفظ البيانات في التفضيلات المشتركة: $e');
    }
  }
  
  /// مقارنة كائنين من نوع Map للتحقق من التساوي
  bool _areEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      
      if (a[key] is Map && b[key] is Map) {
        if (!_areEqual(a[key] as Map<String, dynamic>, b[key] as Map<String, dynamic>)) {
          return false;
        }
      } else if (a[key] is List && b[key] is List) {
        final aList = a[key] as List;
        final bList = b[key] as List;
        
        if (aList.length != bList.length) return false;
        
        for (int i = 0; i < aList.length; i++) {
          if (aList[i] is Map && bList[i] is Map) {
            if (!_areEqual(aList[i] as Map<String, dynamic>, bList[i] as Map<String, dynamic>)) {
              return false;
            }
          } else if (aList[i] != bList[i]) {
            return false;
          }
        }
      } else if (a[key] != b[key]) {
        return false;
      }
    }
    
    return true;
  }
  
  // تنفيذ طرق الواجهة
  
  @override
  Future<List<Map<String, dynamic>>> getCategories() async {
    return Future.value(_categories);
  }
  
  @override
  Future<List<Map<String, dynamic>>> getAthkarByCategory(String categoryId) async {
    return Future.value(_athkar.where((athkar) => athkar['categoryId'] == categoryId).toList());
  }
  
  @override
  Future<Map<String, dynamic>?> getAthkarById(String id) async {
    final result = _athkar.where((athkar) => athkar['id'] == id).toList();
    return Future.value(result.isNotEmpty ? result.first : null);
  }
  
  @override
  Future<void> saveAthkarFavorite(String id, bool isFavorite) async {
    _favorites[id] = isFavorite;
    await _saveToSharedPreferences();
    return Future.value();
  }
  
  @override
  Future<List<Map<String, dynamic>>> getFavoriteAthkar() async {
    return Future.value(_athkar.where((athkar) => _favorites[athkar['id']] == true).toList());
  }
  
  @override
  Future<List<Map<String, dynamic>>> searchAthkar(String query) async {
    if (query.isEmpty) {
      return Future.value([]);
    }
    
    final lowercaseQuery = query.toLowerCase();
    return Future.value(_athkar.where((athkar) => 
      athkar['title'].toString().toLowerCase().contains(lowercaseQuery) || 
      athkar['content'].toString().toLowerCase().contains(lowercaseQuery)
    ).toList());
  }
  
  @override
  Future<List<Map<String, dynamic>>> loadAllAthkar() async {
    return Future.value(_athkar);
  }
  
  // طرق إضافية (أكثر من المطلوب في الواجهة)
  
  /// إضافة ذكر جديد
  ///
  /// @param athkar بيانات الذكر الجديد
  /// @return لا شيء
  Future<void> addAthkar(Map<String, dynamic> athkar) async {
    // البحث عن ذكر بنفس المعرف
    final index = _athkar.indexWhere((t) => t['id'] == athkar['id']);
    
    if (index >= 0) {
      // تحديث الذكر الموجود
      _athkar[index] = athkar;
    } else {
      // إضافة ذكر جديد
      _athkar.add(athkar);
    }
    
    await _saveToSharedPreferences();
    return Future.value();
  }
  
  /// إضافة فئة جديدة
  ///
  /// @param category بيانات الفئة الجديدة
  /// @return لا شيء
  Future<void> addCategory(Map<String, dynamic> category) async {
    // البحث عن فئة بنفس المعرف
    final index = _categories.indexWhere((c) => c['id'] == category['id']);
    
    if (index >= 0) {
      // تحديث الفئة الموجودة
      _categories[index] = category;
    } else {
      // إضافة فئة جديدة
      _categories.add(category);
    }
    
    await _saveToSharedPreferences();
    return Future.value();
  }
  
  /// إعادة تعيين البيانات إلى الوضع الافتراضي
  ///
  /// @return لا شيء
  Future<void> resetData() async {
    _categories.clear();
    _categories.addAll(_defaultCategories);
    _athkar.clear();
    _athkar.addAll(_defaultAthkar);
    _favorites.clear();
    
    // حذف البيانات المخصصة من التفضيلات المشتركة
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_athkar_categories');
    await prefs.remove('custom_athkar_items');
    
    // حذف جميع المفضلة
    final favoriteKeys = prefs.getKeys().where((key) => key.startsWith('favorite_athkar_'));
    for (final key in favoriteKeys) {
      await prefs.remove(key);
    }
    
    return Future.value();
  }
  
  /// حذف ذكر
  ///
  /// @param id معرف الذكر المراد حذفه
  /// @return لا شيء
  Future<void> deleteAthkar(String id) async {
    _athkar.removeWhere((athkar) => athkar['id'] == id);
    _favorites.remove(id);
    
    await _saveToSharedPreferences();
    return Future.value();
  }
  
  /// حذف فئة
  ///
  /// @param id معرف الفئة المراد حذفها
  /// @return لا شيء
  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((category) => category['id'] == id);
    
    // حذف جميع الأذكار التابعة للفئة
    final relatedAthkar = _athkar.where((athkar) => athkar['categoryId'] == id).toList();
    for (final athkar in relatedAthkar) {
      await deleteAthkar(athkar['id'] as String);
    }
    
    await _saveToSharedPreferences();
    return Future.value();
  }
  
  /// الحصول على حالة المفضلة لذكر محدد
  ///
  /// @param id معرف الذكر
  /// @return حالة المفضلة (true/false)
  Future<bool> isFavorite(String id) async {
    return Future.value(_favorites[id] ?? false);
  }
  
  /// الحصول على عدد الأذكار في فئة محددة
  ///
  /// @param categoryId معرف الفئة
  /// @return عدد الأذكار
  Future<int> getAthkarCountInCategory(String categoryId) async {
    return Future.value(_athkar.where((athkar) => athkar['categoryId'] == categoryId).length);
  }
}