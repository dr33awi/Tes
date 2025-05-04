// lib/screens/favorites_screen/favorites_screen.dart بعد التعديل
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/models/daily_quote_model.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, this.newFavoriteQuote});

  final HighlightItem? newFavoriteQuote;

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // قوائم للمفضلة حسب النوع
  List<HighlightItem> _favoriteQuranVerses = []; // آيات القرآن
  List<HighlightItem> _favoriteHadiths = []; // الأحاديث
  List<HighlightItem> _favoritePrayers = []; // الأدعية
  List<HighlightItem> _favoriteAthkar = []; // الأذكار
  
  // الفئة المحددة حاليًا
  String _selectedCategory = 'quran';
  
  // للتأثيرات اللمسية
  bool _isPressed = false;
  int? _pressedIndex;
  
  // للتحكم في حالة التحميل
  bool _isLoading = true;
  
  // للتحكم في عرض الفئات
  bool _showCategories = true;
  
  @override
  void initState() {
    super.initState();
    
    // تحميل المفضلة ثم إضافة العنصر الجديد إذا وجد
    _loadFavoriteQuotes().then((_) {
      if (widget.newFavoriteQuote != null) {
        _addToFavorites(widget.newFavoriteQuote!);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          
          // تحديد الفئة الأولى التي تحتوي على عناصر
          if (_favoriteQuranVerses.isNotEmpty) {
            _selectedCategory = 'quran';
          } else if (_favoriteHadiths.isNotEmpty) {
            _selectedCategory = 'hadith';
          } else if (_favoritePrayers.isNotEmpty) {
            _selectedCategory = 'prayer';
          } else if (_favoriteAthkar.isNotEmpty) {
            _selectedCategory = 'thikr';
          }
        });
      }
    });
  }

  // تحميل الاقتباسات المفضلة من SharedPreferences
  Future<void> _loadFavoriteQuotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    try {
      // تحميل كل نوع من المفضلة
      List<String>? jsonQuranVerses = prefs.getStringList('favoriteQuranVerses');
      List<String>? jsonHadiths = prefs.getStringList('favoriteHadiths');
      List<String>? jsonPrayers = prefs.getStringList('favoritePrayers');
      List<String>? jsonAthkar = prefs.getStringList('favoriteAthkar');
      
      // قائمة قديمة للتوافق مع الإصدارات السابقة
      List<String>? jsonLegacy = prefs.getStringList('favoriteQuotes');
      
      if (mounted) {
        setState(() {
          // تحويل البيانات المحفوظة إلى كائنات HighlightItem
          if (jsonQuranVerses != null && jsonQuranVerses.isNotEmpty) {
            _favoriteQuranVerses = jsonQuranVerses
                .map((json) => HighlightItem.fromJson(jsonDecode(json)))
                .toList();
          }
          
          if (jsonHadiths != null && jsonHadiths.isNotEmpty) {
            _favoriteHadiths = jsonHadiths
                .map((json) => HighlightItem.fromJson(jsonDecode(json)))
                .toList();
          }
          
          if (jsonPrayers != null && jsonPrayers.isNotEmpty) {
            _favoritePrayers = jsonPrayers
                .map((json) => HighlightItem.fromJson(jsonDecode(json)))
                .toList();
          }
          
          if (jsonAthkar != null && jsonAthkar.isNotEmpty) {
            _favoriteAthkar = jsonAthkar
                .map((json) => HighlightItem.fromJson(jsonDecode(json)))
                .toList();
          }
          
          // إضافة القائمة القديمة إلى الفئات المناسبة للتوافق
          if (jsonLegacy != null && jsonLegacy.isNotEmpty) {
            List<HighlightItem> legacyItems = jsonLegacy
                .map((json) => HighlightItem.fromJson(jsonDecode(json)))
                .toList();
                
            for (var item in legacyItems) {
              _categorizeAndAddItem(item, false); // لا تحفظ بعد كل إضافة
            }
            
            // حفظ مرة واحدة بعد إضافة كل العناصر
            _saveFavoriteQuotes();
          }
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
      // في حالة حدوث خطأ، قم بمسح البيانات القديمة
      await prefs.remove('favoriteQuranVerses');
      await prefs.remove('favoriteHadiths');
      await prefs.remove('favoritePrayers');
      await prefs.remove('favoriteAthkar');
      await prefs.remove('favoriteQuotes');
      
      // تهيئة القوائم كفارغة
      if (mounted) {
        setState(() {
          _favoriteQuranVerses = [];
          _favoriteHadiths = [];
          _favoritePrayers = [];
          _favoriteAthkar = [];
        });
      }
    }
  }

  // تصنيف العنصر وإضافته للقائمة المناسبة
  void _categorizeAndAddItem(HighlightItem item, [bool saveAfterAdd = true]) {
    bool itemAdded = false;
    
    // تحديد نوع الاقتباس بناءً على العنوان أو المحتوى
    if (_isQuranVerse(item)) {
      // تجنب التكرار
      if (!_listContainsQuote(_favoriteQuranVerses, item)) {
        if (mounted) {
          setState(() {
            _favoriteQuranVerses.add(item);
          });
        }
        itemAdded = true;
      }
    } else if (_isHadith(item)) {
      // تجنب التكرار
      if (!_listContainsQuote(_favoriteHadiths, item)) {
        if (mounted) {
          setState(() {
            _favoriteHadiths.add(item);
          });
        }
        itemAdded = true;
      }
    } else if (_isPrayer(item)) {
      // تجنب التكرار
      if (!_listContainsQuote(_favoritePrayers, item)) {
        if (mounted) {
          setState(() {
            _favoritePrayers.add(item);
          });
        }
        itemAdded = true;
      }
    } else {
      // تجنب التكرار
      if (!_listContainsQuote(_favoriteAthkar, item)) {
        if (mounted) {
          setState(() {
            _favoriteAthkar.add(item);
          });
        }
        itemAdded = true;
      }
    }
    
    // حفظ بعد الإضافة إذا تم طلب ذلك وتمت إضافة العنصر بنجاح
    if (saveAfterAdd && itemAdded) {
      _saveFavoriteQuotes();
    }
  }
  
  // التحقق من وجود الاقتباس في القائمة
  bool _listContainsQuote(List<HighlightItem> list, HighlightItem item) {
    for (var existingItem in list) {
      if (existingItem.quote == item.quote) {
        return true;
      }
    }
    return false;
  }
  
  // دوال مساعدة لتحديد نوع الاقتباس
  bool _isQuranVerse(HighlightItem item) {
    return item.headerTitle.contains('آية') || 
           item.quote.contains('﴿') || 
           item.source.contains('سورة');
  }
  
  bool _isHadith(HighlightItem item) {
    return item.headerTitle.contains('حديث') || 
           item.quote.contains('قال رسول الله') || 
           item.source.contains('صحيح') || 
           item.source.contains('مسلم') || 
           item.source.contains('البخاري');
  }
  
  bool _isPrayer(HighlightItem item) {
    return item.quote.contains('اللهم') || 
           item.headerTitle.contains('دعاء');
  }

  // حفظ الاقتباسات المفضلة في SharedPreferences
  Future<void> _saveFavoriteQuotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    try {
      // تحويل العناصر إلى JSON وحفظها
      List<String> jsonQuranVerses = _favoriteQuranVerses
          .map((quote) => jsonEncode(quote.toJson()))
          .toList();
          
      List<String> jsonHadiths = _favoriteHadiths
          .map((quote) => jsonEncode(quote.toJson()))
          .toList();
          
      List<String> jsonPrayers = _favoritePrayers
          .map((quote) => jsonEncode(quote.toJson()))
          .toList();
          
      List<String> jsonAthkar = _favoriteAthkar
          .map((quote) => jsonEncode(quote.toJson()))
          .toList();
      
      // حفظ كل قائمة بشكل منفصل
      await prefs.setStringList('favoriteQuranVerses', jsonQuranVerses);
      await prefs.setStringList('favoriteHadiths', jsonHadiths);
      await prefs.setStringList('favoritePrayers', jsonPrayers);
      await prefs.setStringList('favoriteAthkar', jsonAthkar);
      
      // حذف القائمة القديمة
      await prefs.remove('favoriteQuotes');
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // إضافة اقتباس إلى المفضلة
  void _addToFavorites(HighlightItem quote) {
    _categorizeAndAddItem(quote, true);
  }

  // إزالة اقتباس من المفضلة
  void _removeFromFavorites(HighlightItem quote, String type) {
    if (mounted) {
      setState(() {
        switch (type) {
          case 'quran':
            _favoriteQuranVerses.removeWhere((item) => item.quote == quote.quote);
            break;
          case 'hadith':
            _favoriteHadiths.removeWhere((item) => item.quote == quote.quote);
            break;
          case 'prayer':
            _favoritePrayers.removeWhere((item) => item.quote == quote.quote);
            break;
          case 'thikr':
            _favoriteAthkar.removeWhere((item) => item.quote == quote.quote);
            break;
        }
      });
    }
    
    // حفظ التغييرات
    _saveFavoriteQuotes();
  }
  
  // نسخ الاقتباس
  void _copyQuote(HighlightItem quote, String type, int index) {
    setState(() {
      _isPressed = true;
      _pressedIndex = index;
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    String text = '${quote.quote}\n\n${quote.source}';
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text('تم النسخ إلى الحافظة', style: TextStyle(fontSize: 16)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
          _pressedIndex = null;
        });
      }
    });
  }
  
  // مشاركة الاقتباس
  void _shareQuote(HighlightItem quote, String type, int index) async {
    setState(() {
      _isPressed = true;
      _pressedIndex = index;
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    String text = '${quote.quote}\n\n${quote.source}';
    await Share.share(text, subject: 'اقتباس من تطبيق أذكار');
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
          _pressedIndex = null;
        });
      }
    });
  }
  
  // الحصول على عنوان الفئة
  String _getCategoryTitle(String categoryId) {
    switch (categoryId) {
      case 'quran':
        return 'آيات القرآن';
      case 'hadith':
        return 'الأحاديث';
      case 'prayer':
        return 'الأدعية';
      case 'thikr':
        return 'الأذكار';
      default:
        return '';
    }
  }
  
  // الحصول على أيقونة الفئة
  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'quran':
        return Icons.menu_book;
      case 'hadith':
        return Icons.format_quote;
      case 'prayer':
        return Icons.healing;
      case 'thikr':
        return Icons.favorite;
      default:
        return Icons.bookmark;
    }
  }
  
  // الحصول على لون الفئة
  List<Color> _getCategoryGradient(String categoryId) {
    switch (categoryId) {
      case 'quran':
        return [
          const Color(0xFF2E7D32), // أخضر داكن
          const Color(0xFF66BB6A), // أخضر فاتح
        ];
      case 'hadith':
        return [
          const Color(0xFF1565C0), // أزرق داكن
          const Color(0xFF42A5F5), // أزرق فاتح
        ];
      case 'prayer':
        return [
          const Color(0xFF6A1B9A), // بنفسجي داكن
          const Color(0xFFAB47BC), // بنفسجي فاتح
        ];
      case 'thikr':
        return [
          const Color(0xFFC62828), // أحمر داكن
          const Color(0xFFE57373), // أحمر فاتح
        ];
      default:
        return [kPrimary, kPrimaryLight];
    }
  }
  
  // الحصول على قائمة العناصر للفئة المحددة
  List<HighlightItem> _getCategoryItems(String categoryId) {
    switch (categoryId) {
      case 'quran':
        return _favoriteQuranVerses;
      case 'hadith':
        return _favoriteHadiths;
      case 'prayer':
        return _favoritePrayers;
      case 'thikr':
        return _favoriteAthkar;
      default:
        return [];
    }
  }
  
  // الحصول على عدد العناصر في كل فئة
  int _getCategoryItemCount(String categoryId) {
    return _getCategoryItems(categoryId).length;
  }
  
  // التحقق مما إذا كانت جميع الفئات فارغة
  bool _areAllCategoriesEmpty() {
    return _favoriteQuranVerses.isEmpty &&
           _favoriteHadiths.isEmpty &&
           _favoritePrayers.isEmpty &&
           _favoriteAthkar.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Stack(
            children: [
              // المحتوى الرئيسي
              _isLoading
                ? _buildLoadingIndicator()
                : _areAllCategoriesEmpty()
                  ? _buildEmptyView()
                  : _showCategories
                    ? _buildCategoriesGrid()
                    : _buildCategoryContent(),
              
              // زر الرجوع - تم تعديله هنا لإزالة الظل
              Positioned(
                top: 16,
                right: 16,
                child: AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 300),
                  child: FadeInAnimation(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          // إذا كنا نعرض المحتوى، نعود إلى قائمة الفئات
                          if (!_showCategories && !_areAllCategoriesEmpty()) {
                            setState(() {
                              _showCategories = true;
                            });
                          } else {
                            // وإلا نخرج من الصفحة
                            Navigator.of(context).pop();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.arrow_back,
                            color: kPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // بناء شبكة الفئات
  Widget _buildCategoriesGrid() {
    // إعداد قائمة بالفئات التي تحتوي على عناصر
    List<Map<String, dynamic>> categories = [];
    
    if (_favoriteQuranVerses.isNotEmpty) {
      categories.add({
        'id': 'quran',
        'title': 'آيات القرآن',
        'icon': Icons.menu_book,
        'count': _favoriteQuranVerses.length,
        'gradient': _getCategoryGradient('quran'),
      });
    }
    
    if (_favoriteHadiths.isNotEmpty) {
      categories.add({
        'id': 'hadith',
        'title': 'الأحاديث',
        'icon': Icons.format_quote,
        'count': _favoriteHadiths.length,
        'gradient': _getCategoryGradient('hadith'),
      });
    }
    
    if (_favoritePrayers.isNotEmpty) {
      categories.add({
        'id': 'prayer',
        'title': 'الأدعية',
        'icon': Icons.healing,
        'count': _favoritePrayers.length,
        'gradient': _getCategoryGradient('prayer'),
      });
    }
    
    if (_favoriteAthkar.isNotEmpty) {
      categories.add({
        'id': 'thikr',
        'title': 'الأذكار',
        'icon': Icons.favorite,
        'count': _favoriteAthkar.length,
        'gradient': _getCategoryGradient('thikr'),
      });
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // عنوان الصفحة
          const Text(
            'المفضلة',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: AnimationLimiter(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    columnCount: 2,
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildCategoryButton(
                          id: categories[index]['id'],
                          title: categories[index]['title'],
                          icon: categories[index]['icon'],
                          count: categories[index]['count'],
                          gradient: categories[index]['gradient'],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // بناء زر الفئة
  Widget _buildCategoryButton({
    required String id,
    required String title,
    required IconData icon,
    required int count,
    required List<Color> gradient,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = id;
            _showCategories = false;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Stack(
            children: [
              // النمط الزخرفي
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 80,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              
              // المحتوى
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count عنصر',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // بناء محتوى الفئة المحددة
  Widget _buildCategoryContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          // عنوان الفئة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getCategoryGradient(_selectedCategory),
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(_selectedCategory),
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _getCategoryTitle(_selectedCategory),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_getCategoryItemCount(_selectedCategory)} عنصر',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // قائمة العناصر
          Expanded(
            child: _buildFavoritesList(
              items: _getCategoryItems(_selectedCategory),
              type: _selectedCategory,
              gradientColors: _getCategoryGradient(_selectedCategory),
            ),
          ),
        ],
      ),
    );
  }
  
  // مؤشر التحميل
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: kPrimary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل المفضلة...',
            style: TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  // بناء قائمة عناصر المفضلة
  Widget _buildFavoritesList({
    required List<HighlightItem> items,
    required String type,
    required List<Color> gradientColors,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'لا توجد عناصر في هذه الفئة',
          style: TextStyle(
            color: gradientColors[0],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }
    
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final quote = items[index];
          final bool isPressed = _isPressed && _pressedIndex == index;
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Card(
                  elevation: 8,
                  shadowColor: gradientColors[0].withOpacity(0.3),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: gradientColors,
                        stops: const [0.3, 1.0],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // رأس البطاقة
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // عنوان الاقتباس
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      quote.headerIcon,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      quote.headerTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // زر إزالة من المفضلة
                              Material(
                                color: Colors.transparent,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () => _removeFromFavorites(quote, type),
                                  tooltip: 'إزالة من المفضلة',
                                  splashRadius: 20,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // محتوى الاقتباس
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              quote.quote,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // المصدر
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                quote.source,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // أزرار الإجراءات
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                icon: Icons.copy,
                                label: 'نسخ',
                                onPressed: () => _copyQuote(quote, type, index),
                                isPressed: isPressed,
                              ),
                              const SizedBox(width: 16),
                              _buildActionButton(
                                icon: Icons.share,
                                label: 'مشاركة',
                                onPressed: () => _shareQuote(quote, type, index),
                                isPressed: isPressed,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // بناء زر الإجراء
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPressed = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      transform: Matrix4.identity()..scale(isPressed ? 0.95 : 1.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // عرض رسالة عند عدم وجود عناصر
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'لا توجد اقتباسات مفضلة حتى الآن',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'استعرض الاقتباسات وأضفها للمفضلة للعودة إليها لاحقًا',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}