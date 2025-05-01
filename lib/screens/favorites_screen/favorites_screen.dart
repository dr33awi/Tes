import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/models/daily_quote_model.dart';
import 'package:test_athkar_app/models/athkar_model.dart';
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

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  // قوائم للمفضلة حسب النوع
  List<HighlightItem> _favoriteQuranVerses = []; // آيات القرآن
  List<HighlightItem> _favoriteHadiths = []; // الأحاديث
  List<HighlightItem> _favoritePrayers = []; // الأدعية
  List<HighlightItem> _favoriteAthkar = []; // الأذكار
  
  // للتأثيرات اللمسية
  bool _isPressed = false;
  int? _pressedIndex;
  String? _pressedType;
  
  // للتحكم في تبويبات المفضلة
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    
    // إنشاء تبويبات المفضلة
    _tabController = TabController(length: 4, vsync: this);
    
    // تحميل المفضلة ثم إضافة العنصر الجديد إذا وجد
    _loadFavoriteQuotes().then((_) {
      if (widget.newFavoriteQuote != null) {
        _addToFavorites(widget.newFavoriteQuote!);
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      
      print('Saved favorites - Quran: ${jsonQuranVerses.length}, Hadiths: ${jsonHadiths.length}, Prayers: ${jsonPrayers.length}, Athkar: ${jsonAthkar.length}');
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // إضافة اقتباس إلى المفضلة
  void _addToFavorites(HighlightItem quote) {
    _categorizeAndAddItem(quote, true);
    
    // إظهار رسالة
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تمت إضافة الاقتباس إلى المفضلة'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
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
    
    // إظهار رسالة
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تمت إزالة الاقتباس من المفضلة'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
  
  // نسخ الاقتباس
  void _copyQuote(HighlightItem quote, String type, int index) {
    setState(() {
      _isPressed = true;
      _pressedIndex = index;
      _pressedType = type;
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
          _pressedType = null;
        });
      }
    });
  }
  
  // مشاركة الاقتباس
  void _shareQuote(HighlightItem quote, String type, int index) async {
    setState(() {
      _isPressed = true;
      _pressedIndex = index;
      _pressedType = type;
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
          _pressedType = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        title: const Text(
          'المفضلة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.menu_book),
              text: 'القرآن',
            ),
            Tab(
              icon: Icon(Icons.format_quote),
              text: 'الأحاديث',
            ),
            Tab(
              icon: Icon(Icons.healing),
              text: 'الأدعية',
            ),
            Tab(
              icon: Icon(Icons.favorite),
              text: 'الأذكار',
            ),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: TabBarView(
          controller: _tabController,
          children: [
            // قائمة آيات القرآن
            _buildFavoritesList(
              items: _favoriteQuranVerses,
              type: 'quran',
              emptyMessage: 'لا توجد آيات مفضلة حتى الآن.',
              icon: Icons.menu_book,
              gradientColors: [
                const Color(0xFF2E7D32), // أخضر داكن
                const Color(0xFF66BB6A), // أخضر فاتح
              ],
            ),
            
            // قائمة الأحاديث
            _buildFavoritesList(
              items: _favoriteHadiths,
              type: 'hadith',
              emptyMessage: 'لا توجد أحاديث مفضلة حتى الآن.',
              icon: Icons.format_quote,
              gradientColors: [
                const Color(0xFF1565C0), // أزرق داكن
                const Color(0xFF42A5F5), // أزرق فاتح
              ],
            ),
            
            // قائمة الأدعية
            _buildFavoritesList(
              items: _favoritePrayers,
              type: 'prayer',
              emptyMessage: 'لا توجد أدعية مفضلة حتى الآن.',
              icon: Icons.healing,
              gradientColors: [
                const Color(0xFF6A1B9A), // بنفسجي داكن
                const Color(0xFFAB47BC), // بنفسجي فاتح
              ],
            ),
            
            // قائمة الأذكار
            _buildFavoritesList(
              items: _favoriteAthkar,
              type: 'thikr',
              emptyMessage: 'لا توجد أذكار مفضلة حتى الآن.',
              icon: Icons.favorite,
              gradientColors: [
                const Color(0xFFC62828), // أحمر داكن
                const Color(0xFFE57373), // أحمر فاتح
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // بناء قائمة عناصر المفضلة
  Widget _buildFavoritesList({
    required List<HighlightItem> items,
    required String type,
    required String emptyMessage,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    if (items.isEmpty) {
      return _buildEmptyView(emptyMessage, icon);
    }
    
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final quote = items[index];
          final bool isPressed = _isPressed && _pressedIndex == index && _pressedType == type;
          
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
                                isPressed: isPressed && _pressedType == type,
                              ),
                              const SizedBox(width: 16),
                              _buildActionButton(
                                icon: Icons.share,
                                label: 'مشاركة',
                                onPressed: () => _shareQuote(quote, type, index),
                                isPressed: isPressed && _pressedType == type,
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
              horizontal: 12,
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
  Widget _buildEmptyView(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'استعرض الاقتباسات وأضفها للمفضلة للعودة إليها لاحقاً',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}