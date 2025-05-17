// lib/presentation/blocs/athkar/athkar_provider.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/athkar.dart';
import '../../../domain/usecases/athkar/get_athkar_by_category.dart';
import '../../../domain/usecases/athkar/get_athkar_categories.dart';

class AthkarProvider extends ChangeNotifier {
  final GetAthkarCategories _getAthkarCategories;
  final GetAthkarByCategory _getAthkarByCategory;
  
  List<AthkarCategory>? _categories;
  Map<String, List<Athkar>> _athkarByCategory = {};
  
  bool _isLoading = false;
  String? _error;
  
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
  
  // تحميل فئات الأذكار
  Future<void> loadCategories() async {
    if (_categories != null) return; // تجنب التحميل المتكرر
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _categories = await _getAthkarCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // تحميل الأذكار حسب الفئة
  Future<void> loadAthkarByCategory(String categoryId) async {
    if (_athkarByCategory.containsKey(categoryId)) return; // تجنب التحميل المتكرر
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final athkar = await _getAthkarByCategory(categoryId);
      _athkarByCategory[categoryId] = athkar;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // إعادة تحميل البيانات
  Future<void> refreshData() async {
    _categories = null;
    _athkarByCategory.clear();
    
    await loadCategories();
  }
}