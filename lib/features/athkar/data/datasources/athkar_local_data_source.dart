// lib/data/datasources/local/athkar_local_data_source.dart
import '../../domain/entities/athkar.dart';

abstract class AthkarLocalDataSource {
  Future<List<Map<String, dynamic>>> getCategories();
  Future<List<Map<String, dynamic>>> getAthkarByCategory(String categoryId);
  Future<Map<String, dynamic>?> getAthkarById(String id);
  Future<void> saveAthkarFavorite(String id, bool isFavorite);
  Future<List<Map<String, dynamic>>> getFavoriteAthkar();
  Future<List<Map<String, dynamic>>> searchAthkar(String query);
  Future<List<Map<String, dynamic>>> loadAllAthkar();
}

class AthkarLocalDataSourceImpl implements AthkarLocalDataSource {
  // ممارسة جيدة: جعل البيانات المحددة مسبقًا قابلة للقراءة فقط
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
  
  // مخازن البيانات الداخلية
  final List<Map<String, dynamic>> _categories = List.from(_defaultCategories);
  final List<Map<String, dynamic>> _athkar = List.from(_defaultAthkar);
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
  
  // طريقة إضافية لإضافة ذكر جديد (مفيدة للاختبارات)
  Future<void> addAthkar(Map<String, dynamic> athkar) async {
    _athkar.add(athkar);
    return Future.value();
  }
  
  // طريقة إضافية لإضافة فئة جديدة (مفيدة للاختبارات)
  Future<void> addCategory(Map<String, dynamic> category) async {
    _categories.add(category);
    return Future.value();
  }
  
  // إعادة تعيين البيانات إلى الوضع الافتراضي (مفيدة للاختبارات)
  Future<void> resetData() async {
    _categories.clear();
    _categories.addAll(_defaultCategories);
    _athkar.clear();
    _athkar.addAll(_defaultAthkar);
    _favorites.clear();
    return Future.value();
  }
}