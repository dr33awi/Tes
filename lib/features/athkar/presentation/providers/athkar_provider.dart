// lib/features/athkar/presentation/providers/athkar_provider.dart
import 'package:flutter/material.dart';
import '../../domain/entities/athkar.dart';
import '../../domain/usecases/get_athkar_by_category.dart';
import '../../domain/usecases/get_athkar_categories.dart';

class AthkarProvider extends ChangeNotifier {
  final GetAthkarCategories _getAthkarCategories;
  final GetAthkarByCategory _getAthkarByCategory;
  
  // تحسين: استخدام نوع عام للبيانات
  List<AthkarCategory>? _categories;
  Map<String, List<Athkar>> _athkarByCategory = {};
  Map<String, bool> _loadingStatus = {};
  
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;
  // تحسين: إضافة متغير لتتبع ما إذا تم تحميل البيانات
  bool _hasInitialDataLoaded = false;
  
  AthkarProvider({
    required GetAthkarCategories getAthkarCategories,
    required GetAthkarByCategory getAthkarByCategory,
  })  : _getAthkarCategories = getAthkarCategories,
        _getAthkarByCategory = getAthkarByCategory;
  
  // الحالة الحالية مع getters محسنة
  List<AthkarCategory>? get categories => _categories;
  List<Athkar>? getAthkarForCategory(String categoryId) => _athkarByCategory[categoryId];
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasInitialDataLoaded => _hasInitialDataLoaded;
  bool get hasCategories => _categories != null && _categories!.isNotEmpty;
  
  bool isCategoryLoading(String categoryId) => _loadingStatus[categoryId] ?? false;
  bool hasCategoryData(String categoryId) => _athkarByCategory.containsKey(categoryId) && 
                                             _athkarByCategory[categoryId]!.isNotEmpty;
  
  // تحميل فئات الأذكار بتحسين الأداء
  Future<void> loadCategories() async {
    // تحسين: التحقق من حالة التحميل بشكل أفضل
    if (_categories != null || _isLoading || _isDisposed) return;
    
    _setLoading(true);
    
    try {
      _categories = await _getAthkarCategories();
      _hasInitialDataLoaded = true;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // تحميل الأذكار حسب الفئة بتحسين الأداء
  Future<void> loadAthkarByCategory(String categoryId) async {
    // تجنب التحميل المتكرر
    if (_athkarByCategory.containsKey(categoryId) || 
        _loadingStatus[categoryId] == true || 
        _isDisposed) {
      return;
    }
    
    _loadingStatus[categoryId] = true;
    _setLoading(true);
    
    try {
      final athkar = await _getAthkarByCategory(categoryId);
      
      // تحسين: التحقق من حالة الإغلاق قبل تحديث البيانات
      if (_isDisposed) return;
      
      _athkarByCategory[categoryId] = athkar;
      _loadingStatus[categoryId] = false;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // تحميل أو إعادة تحميل الفئة بشكل قسري
  Future<void> refreshCategory(String categoryId) async {
    _athkarByCategory.remove(categoryId);
    _loadingStatus[categoryId] = false;
    await loadAthkarByCategory(categoryId);
  }
  
  // إعادة تحميل جميع البيانات
  Future<void> refreshData() async {
    _categories = null;
    _athkarByCategory.clear();
    _loadingStatus.clear();
    _isLoading = false;
    _error = null;
    _hasInitialDataLoaded = false;
    
    await loadCategories();
    notifyListeners();
  }
  
  // تحسين: طرق مساعدة لتحديث الحالة
  void _setLoading(bool loading) {
    _isLoading = loading;
    _error = null;
    if (!_isDisposed) notifyListeners();
  }
  
  void _setError(String errorMessage) {
    _isLoading = false;
    _error = errorMessage;
    if (!_isDisposed) notifyListeners();
  }
  
  void clearError() {
    _error = null;
    if (!_isDisposed) notifyListeners();
  }
  
  // الحصول على فئة بواسطة المعرف
  AthkarCategory? getCategoryById(String categoryId) {
    if (_categories == null) return null;
    try {
      return _categories!.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }
  
  // الحصول على ذكر معين
  Athkar? getAthkarById(String categoryId, String athkarId) {
    if (!_athkarByCategory.containsKey(categoryId)) return null;
    try {
      return _athkarByCategory[categoryId]!.firstWhere((athkar) => athkar.id == athkarId);
    } catch (e) {
      return null;
    }
  }
  
  // تحميل البيانات الشائعة مسبقاً
  Future<void> preloadCommonCategories() async {
    if (_isDisposed || _hasInitialDataLoaded) return;
    
    await loadCategories();
    
    if (_categories != null && _categories!.isNotEmpty) {
      for (final category in _categories!) {
        if (['morning', 'evening', 'sleep'].contains(category.id)) {
          await loadAthkarByCategory(category.id);
        }
      }
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _loadingStatus.clear();
    super.dispose();
  }
}