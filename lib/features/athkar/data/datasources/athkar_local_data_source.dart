// lib/data/datasources/local/athkar_local_data_source.dart
import '../../domain/entities/athkar.dart';

abstract class AthkarLocalDataSource {
  Future<List<Map<String, dynamic>>> getCategories();
  Future<List<Map<String, dynamic>>> getAthkarByCategory(String categoryId);
  Future<Map<String, dynamic>?> getAthkarById(String id);
  Future<void> saveAthkarFavorite(String id, bool isFavorite);
  Future<List<Map<String, dynamic>>> getFavoriteAthkar();
  Future<List<Map<String, dynamic>>> searchAthkar(String query);
  Future<List<Map<String, dynamic>>> loadAllAthkar(); // أضفنا هذه الطريقة
}

class AthkarLocalDataSourceImpl implements AthkarLocalDataSource {
  // هنا يمكنك استخدام sqflite أو hive أو غيرها من قواعد البيانات المحلية
  // للتبسيط، سنستخدم بيانات ثابتة
  
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'morning',
      'name': 'أذكار الصباح',
      'description': 'الأذكار التي تقال في الصباح',
      'icon': 'sunrise'
    },
    {
      'id': 'evening',
      'name': 'أذكار المساء',
      'description': 'الأذكار التي تقال في المساء',
      'icon': 'sunset'
    },
    // إضافة المزيد من الفئات
  ];
  
  final List<Map<String, dynamic>> _athkar = [
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
    // إضافة المزيد من الأذكار
  ];
  
  final Map<String, bool> _favorites = {};
  
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
    return Future.value();
  }
  
  @override
  Future<List<Map<String, dynamic>>> getFavoriteAthkar() async {
    return Future.value(_athkar.where((athkar) => _favorites[athkar['id']] == true).toList());
  }
  
  @override
  Future<List<Map<String, dynamic>>> searchAthkar(String query) async {
    final lowercaseQuery = query.toLowerCase();
    return Future.value(_athkar.where((athkar) => 
      athkar['title'].toLowerCase().contains(lowercaseQuery) || 
      athkar['content'].toLowerCase().contains(lowercaseQuery)
    ).toList());
  }
  
  @override
  Future<List<Map<String, dynamic>>> loadAllAthkar() async {
    return Future.value(_athkar);
  }
  
  // طريقة إضافية لتحميل الأذكار حسب الفئة (نستخدمها في الملف المعدل)
  Future<List<Map<String, dynamic>>> loadAthkarByCategory(String categoryId) async {
    return getAthkarByCategory(categoryId);
  }
  
  // طريقة إضافية لتحميل فئات الأذكار (نستخدمها في الملف المعدل)
  Future<List<Map<String, dynamic>>> loadCategories() async {
    return getCategories();
  }
}