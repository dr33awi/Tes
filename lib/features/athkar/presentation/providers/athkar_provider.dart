// lib/features/athkar/presentation/providers/athkar_provider.dart
import 'package:athkar_app/features/athkar/di/athkar_dependency_injection.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/athkar.dart';
import '../../domain/usecases/get_athkar_by_category.dart';
import '../../domain/usecases/get_athkar_categories.dart';
import '../../domain/usecases/get_athkar_by_id.dart';
import '../../domain/usecases/save_athkar_favorite.dart';
import '../../domain/usecases/get_favorite_athkar.dart';
import '../../domain/usecases/search_athkar.dart';

/// مزود حالة الأذكار
///
/// يوفر هذا الصف حالة وطرقًا للتفاعل مع بيانات الأذكار
/// ويستخدم حالات الاستخدام للوصول إلى البيانات
class AthkarProvider extends ChangeNotifier {
  final GetAthkarCategories _getAthkarCategories;
  final GetAthkarByCategory _getAthkarByCategory;
  final GetAthkarById _getAthkarById;
  final SaveAthkarFavorite _saveFavorite;
  final GetFavoriteAthkar _getFavorites;
  final SearchAthkar _searchAthkar;
  
  /// فئات الأذكار
  List<AthkarCategory>? _categories;
  
  /// خريطة الأذكار حسب الفئة
  final Map<String, List<Athkar>> _athkarByCategory = {};
  
  /// خريطة حالة التحميل حسب الفئة
  final Map<String, bool> _loadingStatus = {};
  
  /// حالة التحميل العامة
  bool _isLoading = false;
  
  /// رسالة الخطأ
  String? _error;
  
  /// حالة التخلص
  bool _isDisposed = false;
  
  /// هل تم تحميل البيانات الأولية
  bool _hasInitialDataLoaded = false;
  
  /// المفضلة
  List<Athkar>? _favorites;
  
  /// حالة تحميل المفضلة
  bool _isFavoritesLoading = false;
  
  /// نتائج البحث
  List<Athkar>? _searchResults;
  
  /// حالة تحميل البحث
  bool _isSearching = false;
  
  /// استعلام البحث الحالي
  String _searchQuery = '';
  
  /// المُنشئ
  AthkarProvider({
    required GetAthkarCategories getAthkarCategories,
    required GetAthkarByCategory getAthkarByCategory,
    required GetAthkarById getAthkarById,
    required SaveAthkarFavorite saveFavorite,
    required GetFavoriteAthkar getFavorites,
    required SearchAthkar searchAthkar,
  })  : _getAthkarCategories = getAthkarCategories,
        _getAthkarByCategory = getAthkarByCategory,
        _getAthkarById = getAthkarById,
        _saveFavorite = saveFavorite,
        _getFavorites = getFavorites,
        _searchAthkar = searchAthkar;
  
  // الحالة الحالية - getters
  
  /// الحصول على فئات الأذكار
  List<AthkarCategory>? get categories => _categories;
  
  /// الحصول على الأذكار حسب الفئة
  List<Athkar>? getAthkarForCategory(String categoryId) => _athkarByCategory[categoryId];
  
  /// الحصول على حالة التحميل العامة
  bool get isLoading => _isLoading;
  
  /// الحصول على رسالة الخطأ
  String? get error => _error;
  
  /// هل هناك خطأ
  bool get hasError => _error != null;
  
  /// هل تم تحميل البيانات الأولية
  bool get hasInitialDataLoaded => _hasInitialDataLoaded;
  
  /// هل توجد فئات
  bool get hasCategories => _categories != null && _categories!.isNotEmpty;
  
  /// الحصول على حالة تحميل الفئة
  bool isCategoryLoading(String categoryId) => _loadingStatus[categoryId] ?? false;
  
  /// هل توجد بيانات للفئة
  bool hasCategoryData(String categoryId) => 
    _athkarByCategory.containsKey(categoryId) && _athkarByCategory[categoryId]!.isNotEmpty;
  
  /// الحصول على المفضلة
  List<Athkar>? get favorites => _favorites;
  
  /// هل جاري تحميل المفضلة
  bool get isFavoritesLoading => _isFavoritesLoading;
  
  /// هل توجد مفضلة
  bool get hasFavorites => _favorites != null && _favorites!.isNotEmpty;
  
  /// الحصول على نتائج البحث
  List<Athkar>? get searchResults => _searchResults;
  
  /// هل جاري البحث
  bool get isSearching => _isSearching;
  
  /// الحصول على استعلام البحث الحالي
  String get searchQuery => _searchQuery;
  
  // طرق التفاعل مع البيانات
  
  /// تحميل فئات الأذكار
  ///
  /// يقوم بتحميل فئات الأذكار من مستودع البيانات
  Future<void> loadCategories() async {
    // تجنب التحميل المتكرر
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
  
  /// تحميل الأذكار حسب الفئة
  ///
  /// يقوم بتحميل الأذكار التابعة لفئة محددة من مستودع البيانات
  /// @param categoryId معرف الفئة
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
      
      // تحقق من حالة الإغلاق قبل تحديث البيانات
      if (_isDisposed) return;
      
      _athkarByCategory[categoryId] = athkar;
      _loadingStatus[categoryId] = false;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  /// الحصول على ذكر محدد
  ///
  /// يقوم بالحصول على ذكر محدد من مستودع البيانات
  /// @param id معرف الذكر
  /// @return ذكر محدد أو null إذا لم يتم العثور عليه
  Future<Athkar?> getAthkarById(String id) async {
    try {
      return await _getAthkarById(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }
  
  /// حفظ ذكر في المفضلة
  ///
  /// يقوم بحفظ ذكر في المفضلة أو إزالته منها
  /// @param id معرف الذكر
  /// @param isFavorite حالة المفضلة
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      await _saveFavorite(id, isFavorite);
      
      // تحديث الذكر في التخزين المؤقت
      for (var category in _athkarByCategory.keys) {
        final index = _athkarByCategory[category]?.indexWhere((athkar) => athkar.id == id) ?? -1;
        if (index >= 0) {
          final updatedList = List<Athkar>.from(_athkarByCategory[category]!);
          final updatedAthkar = updatedList[index].copyWith(isFavorite: isFavorite);
          updatedList[index] = updatedAthkar;
          _athkarByCategory[category] = updatedList;
        }
      }
      
      // تحديث المفضلة إذا كانت محملة
      if (_favorites != null) {
        if (isFavorite) {
          // إذا تمت الإضافة للمفضلة، قم بتحميل المفضلة مرة أخرى للحصول على الذكر الجديد
          await loadFavorites();
        } else {
          // إذا تمت الإزالة من المفضلة، قم بإزالة الذكر من قائمة المفضلة
          _favorites = _favorites!.where((athkar) => athkar.id != id).toList();
        }
      }
      
      // إشعار المستمعين بالتغييرات
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  /// تحميل المفضلة
  ///
  /// يقوم بتحميل الأذكار المفضلة من مستودع البيانات
  Future<void> loadFavorites() async {
    if (_isFavoritesLoading || _isDisposed) return;
    
    _isFavoritesLoading = true;
    if (!_isDisposed) notifyListeners();
    
    try {
      _favorites = await _getFavorites();
      _isFavoritesLoading = false;
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      _favorites = [];
      _isFavoritesLoading = false;
      _setError(e.toString());
    }
  }
  
  /// البحث في الأذكار
  ///
  /// يقوم بالبحث في الأذكار باستخدام استعلام محدد
  /// @param query استعلام البحث
  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      if (!_isDisposed) notifyListeners();
      return;
    }
    
    if (_isSearching || _isDisposed) return;
    
    _isSearching = true;
    _searchQuery = query;
    if (!_isDisposed) notifyListeners();
    
    try {
      _searchResults = await _searchAthkar(query);
      _isSearching = false;
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      _searchResults = [];
      _isSearching = false;
      _setError(e.toString());
    }
  }
  
  /// مسح نتائج البحث
  ///
  /// يقوم بمسح نتائج البحث السابقة
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    if (!_isDisposed) notifyListeners();
  }
  
  /// إعادة تحميل فئة
  ///
  /// يقوم بإعادة تحميل الأذكار التابعة لفئة محددة
  /// @param categoryId معرف الفئة
  Future<void> refreshCategory(String categoryId) async {
    _athkarByCategory.remove(categoryId);
    _loadingStatus[categoryId] = false;
    await loadAthkarByCategory(categoryId);
  }
  
  /// إعادة تحميل جميع البيانات
  ///
  /// يقوم بإعادة تهيئة الحالة وتحميل البيانات من جديد
  Future<void> refreshData() async {
    _categories = null;
    _athkarByCategory.clear();
    _loadingStatus.clear();
    _isLoading = false;
    _error = null;
    _hasInitialDataLoaded = false;
    _favorites = null;
    _isFavoritesLoading = false;
    _searchResults = null;
    _isSearching = false;
    _searchQuery = '';
    
    await loadCategories();
    if (!_isDisposed) notifyListeners();
  }
  
  /// تعيين حالة التحميل
  ///
  /// طريقة مساعدة لتعيين حالة التحميل وإشعار المستمعين
  /// @param loading حالة التحميل
  void _setLoading(bool loading) {
    _isLoading = loading;
    _error = null;
    if (!_isDisposed) notifyListeners();
  }
  
  /// تعيين رسالة الخطأ
  ///
  /// طريقة مساعدة لتعيين رسالة الخطأ وإشعار المستمعين
  /// @param errorMessage رسالة الخطأ
  void _setError(String errorMessage) {
    _isLoading = false;
    _loadingStatus.keys.forEach((key) => _loadingStatus[key] = false);
    _isFavoritesLoading = false;
    _isSearching = false;
    _error = errorMessage;
    if (!_isDisposed) notifyListeners();
  }
  
  /// مسح رسالة الخطأ
  ///
  /// يقوم بمسح رسالة الخطأ وإشعار المستمعين
  void clearError() {
    _error = null;
    if (!_isDisposed) notifyListeners();
  }
  
  /// الحصول على فئة حسب المعرف
  ///
  /// يقوم بالبحث عن فئة بمعرف محدد
  /// @param categoryId معرف الفئة
  /// @return الفئة المطلوبة أو null إذا لم يتم العثور عليها
  AthkarCategory? getCategoryById(String categoryId) {
    if (_categories == null) return null;
    try {
      return _categories!.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }
  
  /// الحصول على ذكر محدد من التخزين المؤقت
  ///
  /// يقوم بالبحث عن ذكر في التخزين المؤقت
  /// @param categoryId معرف الفئة
  /// @param athkarId معرف الذكر
  /// @return الذكر المطلوب أو null إذا لم يتم العثور عليه
  Athkar? getCachedAthkarById(String categoryId, String athkarId) {
    if (!_athkarByCategory.containsKey(categoryId)) return null;
    try {
      return _athkarByCategory[categoryId]!.firstWhere((athkar) => athkar.id == athkarId);
    } catch (e) {
      return null;
    }
  }
  
  /// تحميل الفئات الشائعة مسبقًا
  ///
  /// يقوم بتحميل الفئات الشائعة لتحسين تجربة المستخدم
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
  
  /// الحصول على إحصائيات ملخصة
  ///
  /// يقوم بحساب إحصائيات ملخصة من البيانات المتاحة
  Map<String, dynamic> getSummaryStats() {
    int totalCategories = _categories?.length ?? 0;
    int totalAthkar = 0;
    int favoriteCount = _favorites?.length ?? 0;
    Set<String> uniqueCategories = {};
    
    // حساب إجمالي الأذكار
    _athkarByCategory.forEach((category, athkarList) {
      totalAthkar += athkarList.length;
      uniqueCategories.add(category);
    });
    
    return {
      'totalCategories': totalCategories,
      'loadedCategories': uniqueCategories.length,
      'totalAthkar': totalAthkar,
      'favoriteCount': favoriteCount,
    };
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _loadingStatus.clear();
    super.dispose();
  }
}