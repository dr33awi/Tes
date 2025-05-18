// lib/presentation/blocs/athkar/athkar_provider.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/athkar.dart';
import '../../../domain/usecases/athkar/get_athkar_by_category.dart';
import '../../../domain/usecases/athkar/get_athkar_categories.dart';

class AthkarProvider extends ChangeNotifier {
  final GetAthkarCategories _getAthkarCategories;
  final GetAthkarByCategory _getAthkarByCategory;
  
  // قائمة الفئات
  List<AthkarCategory>? _categories;
  // خريطة للأذكار حسب الفئة
  Map<String, List<Athkar>> _athkarByCategory = {};
  // خريطة للتحكم في عمليات التحميل المتزامنة لتجنب التكرار
  final Map<String, bool> _loadingStatus = {};
  
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;
  
  AthkarProvider({
    required GetAthkarCategories getAthkarCategories,
    required GetAthkarByCategory getAthkarByCategory,
  })  : _getAthkarCategories = getAthkarCategories,
        _getAthkarByCategory = getAthkarByCategory;
  
  // الحالة الحالية
  List<AthkarCategory>? get categories => _categories;
  List<Athkar>? getAthkarForCategory(String categoryId) => _athkarByCategory[categoryId];
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  
  bool isCategoryLoading(String categoryId) => _loadingStatus[categoryId] ?? false;
  
  // تحميل فئات الأذكار بتحسين الأداء
  Future<void> loadCategories() async {
    // تجنب التحميل المتكرر أو إذا كان التطبيق في حالة الإغلاق
    if (_categories != null || _isLoading || _isDisposed) return;
    
    // تعيين حالة التحميل
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // تنفيذ التحميل من المصدر
      _categories = await _getAthkarCategories();
      _isLoading = false;
      
      // إخطار المستمعين فقط إذا كان التطبيق لا يزال نشطًا
      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      // معالجة الخطأ
      _isLoading = false;
      _error = e.toString();
      
      // إخطار المستمعين فقط إذا كان التطبيق لا يزال نشطًا
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }
  
  // تحميل الأذكار حسب الفئة بتحسين الأداء
  Future<void> loadAthkarByCategory(String categoryId) async {
    // تجنب التحميل المتكرر أو إذا كان التطبيق في حالة الإغلاق
    if (_athkarByCategory.containsKey(categoryId) || 
        _loadingStatus[categoryId] == true || 
        _isDisposed) {
      return;
    }
    
    // تعيين حالة التحميل لهذه الفئة
    _loadingStatus[categoryId] = true;
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // تنفيذ التحميل من المصدر
      final athkar = await _getAthkarByCategory(categoryId);
      _athkarByCategory[categoryId] = athkar;
      _loadingStatus[categoryId] = false;
      _isLoading = false;
      
      // إخطار المستمعين فقط إذا كان التطبيق لا يزال نشطًا
      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      // معالجة الخطأ
      _loadingStatus[categoryId] = false;
      _isLoading = false;
      _error = e.toString();
      
      // إخطار المستمعين فقط إذا كان التطبيق لا يزال نشطًا
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }
  
  // تحميل أو إعادة تحميل الفئة بشكل قسري
  Future<void> refreshCategory(String categoryId) async {
    // إعادة تعيين حالة الفئة
    _athkarByCategory.remove(categoryId);
    _loadingStatus[categoryId] = false;
    
    // إعادة تحميل البيانات
    await loadAthkarByCategory(categoryId);
  }
  
  // إعادة تحميل جميع البيانات
  Future<void> refreshData() async {
    _categories = null;
    _athkarByCategory.clear();
    _loadingStatus.clear();
    _isLoading = false;
    _error = null;
    
    await loadCategories();
  }
  
  // تنظيف الموارد عند التخلص من Provider
  @override
  void dispose() {
    _isDisposed = true;
    _loadingStatus.clear();
    super.dispose();
  }
  
  // تحسين: تحميل البيانات الشائعة مسبقًا
  Future<void> preloadCommonCategories() async {
    if (_isDisposed) return;
    
    // تحميل الفئات أولاً
    await loadCategories();
    
    if (_categories != null && _categories!.isNotEmpty) {
      // تحميل الفئات الأكثر استخداماً في الخلفية
      for (final category in _categories!) {
        if (['morning', 'evening', 'sleep'].contains(category.id)) {
          // استخدام Future.microtask للسماح بتحميل أكثر من فئة في وقت واحد
          Future.microtask(() => loadAthkarByCategory(category.id));
        }
      }
    }
  }
}