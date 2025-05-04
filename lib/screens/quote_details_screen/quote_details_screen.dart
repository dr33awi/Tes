import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_athkar_app/models/daily_quote_model.dart';
import 'package:test_athkar_app/screens/favorites_screen/favorites_screen.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuoteDetailsScreen extends StatefulWidget {
  const QuoteDetailsScreen({super.key, required this.quoteItem});

  final HighlightItem quoteItem;

  @override
  State<QuoteDetailsScreen> createState() => _QuoteDetailsScreenState();
}

class _QuoteDetailsScreenState extends State<QuoteDetailsScreen> 
    with SingleTickerProviderStateMixin {
  // متغيرات لتأثيرات الحركة
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isFavorite = false;
  
  // للتأثيرات اللمسية
  bool _isCopyPressed = false;
  bool _isSharePressed = false;
  bool _isFavoritePressed = false;
  
  @override
  void initState() {
    super.initState();
    
    // إعداد التحريك
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7),
      ),
    );
    
    // تشغيل التحريك مباشرة
    _animationController.forward();
    
    // التحقق مما إذا كان الاقتباس موجودًا بالفعل في المفضلة
    _checkIfFavorite();
  }
  
  // دالة للتحقق مما إذا كان الاقتباس موجودًا في المفضلة
  Future<void> _checkIfFavorite() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // قراءة قوائم المفضلة المختلفة
      List<String>? jsonQuranVerses = prefs.getStringList('favoriteQuranVerses');
      List<String>? jsonHadiths = prefs.getStringList('favoriteHadiths');
      List<String>? jsonPrayers = prefs.getStringList('favoritePrayers');
      List<String>? jsonAthkar = prefs.getStringList('favoriteAthkar');
      List<String>? jsonLegacy = prefs.getStringList('favoriteQuotes');
      
      // تحويل جميع قوائم المفضلة إلى كائنات HighlightItem
      List<HighlightItem> allFavorites = [];
      
      // إضافة جميع المفضلات من كل الفئات
      if (jsonQuranVerses != null && jsonQuranVerses.isNotEmpty) {
        allFavorites.addAll(jsonQuranVerses
            .map((json) => HighlightItem.fromJson(jsonDecode(json)))
            .toList());
      }
      
      if (jsonHadiths != null && jsonHadiths.isNotEmpty) {
        allFavorites.addAll(jsonHadiths
            .map((json) => HighlightItem.fromJson(jsonDecode(json)))
            .toList());
      }
      
      if (jsonPrayers != null && jsonPrayers.isNotEmpty) {
        allFavorites.addAll(jsonPrayers
            .map((json) => HighlightItem.fromJson(jsonDecode(json)))
            .toList());
      }
      
      if (jsonAthkar != null && jsonAthkar.isNotEmpty) {
        allFavorites.addAll(jsonAthkar
            .map((json) => HighlightItem.fromJson(jsonDecode(json)))
            .toList());
      }
      
      // التوافق مع القائمة القديمة
      if (jsonLegacy != null && jsonLegacy.isNotEmpty) {
        allFavorites.addAll(jsonLegacy
            .map((json) => HighlightItem.fromJson(jsonDecode(json)))
            .toList());
      }
      
      // التحقق مما إذا كان الاقتباس الحالي موجودًا في المفضلة
      bool isFound = false;
      for (var favorite in allFavorites) {
        if (favorite.quote == widget.quoteItem.quote) {
          isFound = true;
          break;
        }
      }
      
      // تحديث حالة المفضلة إذا كان الاقتباس موجودًا
      if (mounted && isFound) {
        setState(() {
          _isFavorite = true;
        });
        
        // نقوم بتشغيل تأثير النبض للزر إذا كان مفضلاً
        if (_isFavorite) {
          _animationController.reset();
          _animationController.forward();
        }
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من المفضلة: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // إجراء النسخ
  void _copyQuote(BuildContext context) {
    setState(() => _isCopyPressed = true);
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    final copyText = '${widget.quoteItem.quote}\n\n${widget.quoteItem.source}';
    Clipboard.setData(ClipboardData(text: copyText)).then((_) {
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
        setState(() => _isCopyPressed = false);
      }
    });
  }

  // إجراء المشاركة
  void _shareQuote(BuildContext context) async {
    setState(() => _isSharePressed = true);
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    final String text = '${widget.quoteItem.quote}\n\n${widget.quoteItem.source}';
    
    // عرض قائمة منبثقة بخيارات المشاركة المختلفة
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مقبض السحب
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              
              // العنوان
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.share_rounded,
                      color: kPrimary,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'مشاركة الاقتباس عبر',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // خيارات المشاركة
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 20,
                children: [
                  // واتساب
                  _buildSocialShareOption(
                    context: context, 
                    icon: Icons.whatshot, 
                    color: Color(0xFF25D366),
                    title: 'واتساب',
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.share(
                        text,
                        subject: 'اقتباس من تطبيق أذكار',
                      );
                    },
                  ),
                  
                  // تلجرام
                  _buildSocialShareOption(
                    context: context, 
                    icon: Icons.send, 
                    color: Color(0xFF0088cc),
                    title: 'تلجرام',
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.share(
                        text,
                        subject: 'اقتباس من تطبيق أذكار',
                      );
                    },
                  ),
                  
                  // تويتر
                  _buildSocialShareOption(
                    context: context, 
                    icon: Icons.flutter_dash, 
                    color: Color(0xFF1DA1F2),
                    title: 'تويتر',
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.share(
                        text,
                        subject: 'اقتباس من تطبيق أذكار',
                      );
                    },
                  ),
                  
                  // فيسبوك
                  _buildSocialShareOption(
                    context: context, 
                    icon: Icons.facebook, 
                    color: Color(0xFF1877F2),
                    title: 'فيسبوك',
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.share(
                        text,
                        subject: 'اقتباس من تطبيق أذكار',
                      );
                    },
                  ),
                  
                  // ماسنجر
                  _buildSocialShareOption(
                    context: context, 
                    icon: Icons.message, 
                    color: Color(0xFF00B2FF),
                    title: 'ماسنجر',
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.share(
                        text,
                        subject: 'اقتباس من تطبيق أذكار',
                      );
                    },
                  ),
                  
                  // نسخ
                  _buildSocialShareOption(
                    context: context, 
                    icon: Icons.copy, 
                    color: Colors.orange,
                    title: 'نسخ النص',
                    onTap: () {
                      Navigator.pop(context);
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
                    },
                  ),
                  
                  // مشاركة أخرى
                  _buildSocialShareOption(
                    context: context, 
                    icon: Icons.more_horiz, 
                    color: Colors.blueGrey,
                    title: 'المزيد',
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.share(
                        text,
                        subject: 'اقتباس من تطبيق أذكار',
                      );
                    },
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // زر إلغاء
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'إلغاء',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isSharePressed = false);
      }
    });
  }

  // إضافة للمفضلة
  void _toggleFavorite(BuildContext context) async {
    setState(() {
      _isFavoritePressed = true;
      _isFavorite = !_isFavorite;
    });
    
    // تأثير اهتزاز
    HapticFeedback.mediumImpact();
    
    if (_isFavorite) {
      // تشغيل تأثير النبض للزر
      _animationController.reset();
      _animationController.forward();
      
      // إضافة الاقتباس للمفضلة بدون الانتقال إلى صفحة المفضلة
      await _addToFavorites();
    } else {
      // إزالة العنصر من المفضلة مباشرةً
      await _removeFromFavorites();
    }
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isFavoritePressed = false);
      }
    });
  }
  
  // إضافة الاقتباس إلى المفضلة
  Future<void> _addToFavorites() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // تحديد نوع الاقتباس لإضافته إلى القائمة المناسبة
      String listKey;
      if (_isQuranVerse(widget.quoteItem)) {
        listKey = 'favoriteQuranVerses';
      } else if (_isHadith(widget.quoteItem)) {
        listKey = 'favoriteHadiths';
      } else if (_isPrayer(widget.quoteItem)) {
        listKey = 'favoritePrayers';
      } else {
        listKey = 'favoriteAthkar';
      }
      
      // قراءة القائمة الحالية
      List<String> currentList = prefs.getStringList(listKey) ?? [];
      
      // التحقق من عدم وجود العنصر مسبقًا في القائمة
      bool alreadyExists = false;
      for (var jsonItem in currentList) {
        HighlightItem item = HighlightItem.fromJson(jsonDecode(jsonItem));
        if (item.quote == widget.quoteItem.quote) {
          alreadyExists = true;
          break;
        }
      }
      
      // إضافة العنصر فقط إذا لم يكن موجودًا
      if (!alreadyExists) {
        currentList.add(jsonEncode(widget.quoteItem.toJson()));
        await prefs.setStringList(listKey, currentList);
      }
      
    } catch (e) {
      debugPrint('خطأ في إضافة العنصر إلى المفضلة: $e');
    }
  }

  // إزالة الاقتباس من المفضلة مباشرة
  Future<void> _removeFromFavorites() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // قراءة جميع قوائم المفضلة
      List<String> jsonQuranVerses = prefs.getStringList('favoriteQuranVerses') ?? [];
      List<String> jsonHadiths = prefs.getStringList('favoriteHadiths') ?? [];
      List<String> jsonPrayers = prefs.getStringList('favoritePrayers') ?? [];
      List<String> jsonAthkar = prefs.getStringList('favoriteAthkar') ?? [];
      
      // تحويل كل قائمة إلى كائنات HighlightItem
      List<HighlightItem> quranVerses = jsonQuranVerses
          .map((json) => HighlightItem.fromJson(jsonDecode(json)))
          .toList();
      
      List<HighlightItem> hadiths = jsonHadiths
          .map((json) => HighlightItem.fromJson(jsonDecode(json)))
          .toList();
      
      List<HighlightItem> prayers = jsonPrayers
          .map((json) => HighlightItem.fromJson(jsonDecode(json)))
          .toList();
      
      List<HighlightItem> athkar = jsonAthkar
          .map((json) => HighlightItem.fromJson(jsonDecode(json)))
          .toList();
      
      // إزالة الاقتباس من القائمة المناسبة
      quranVerses.removeWhere((item) => item.quote == widget.quoteItem.quote);
      hadiths.removeWhere((item) => item.quote == widget.quoteItem.quote);
      prayers.removeWhere((item) => item.quote == widget.quoteItem.quote);
      athkar.removeWhere((item) => item.quote == widget.quoteItem.quote);
      
      // تحويل القوائم مرة أخرى إلى JSON وحفظها
      List<String> updatedQuranVerses = quranVerses
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      
      List<String> updatedHadiths = hadiths
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      
      List<String> updatedPrayers = prayers
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      
      List<String> updatedAthkar = athkar
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      
      // حفظ القوائم المحدثة
      await prefs.setStringList('favoriteQuranVerses', updatedQuranVerses);
      await prefs.setStringList('favoriteHadiths', updatedHadiths);
      await prefs.setStringList('favoritePrayers', updatedPrayers);
      await prefs.setStringList('favoriteAthkar', updatedAthkar);
      
      // إزالة القائمة القديمة للتوافق
      await prefs.remove('favoriteQuotes');
      
    } catch (e) {
      debugPrint('خطأ في إزالة العنصر من المفضلة: $e');
    }
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
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // مساحة لزر العودة
                      const SizedBox(height: 60),
                      
                      // عنوان الاقتباس (في المنتصف)
                      AnimationConfiguration.synchronized(
                        duration: const Duration(milliseconds: 300),
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.quoteItem.headerIcon,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.quoteItem.headerTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // بطاقة الاقتباس المحسّنة
                      AnimationConfiguration.synchronized(
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(
                            child: Card(
                              elevation: 15,
                              shadowColor: kPrimary.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      kPrimary,
                                      Color(0xFF2D6852) // لون غامق لمزيد من العمق
                                    ],
                                    stops: const [0.3, 1.0],
                                  ),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // نمط زخرفي في الخلفية
                                    Positioned(
                                      right: -15,
                                      top: 20,
                                      child: Opacity(
                                        opacity: 0.08,
                                        child: Image.asset(
                                          'assets/images/islamic_pattern.png',
                                          width: 120,
                                          height: 120,
                                          errorBuilder: (context, error, stackTrace) {
                                            // إذا لم يتم العثور على الصورة، استخدم أيقونة بديلة
                                            return Icon(
                                              Icons.format_quote,
                                              size: 100,
                                              color: Colors.white.withOpacity(0.1),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // قسم الاقتباس
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 25,
                                            ),
                                            margin: const EdgeInsets.only(bottom: 15),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.12),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: Stack(
                                              children: [
                                                // علامة اقتباس في البداية
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: Icon(
                                                    Icons.format_quote,
                                                    size: 18,
                                                    color: Colors.white.withOpacity(0.5),
                                                  ),
                                                ),
                                                
                                                Column(
                                                  children: [
                                                    // نص الاقتباس - تمت إزالة دالة _removeNonWords للحفاظ على التشكيل
                                                    Text(
                                                      widget.quoteItem.quote,
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                        height: 2.0,
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        fontFamily: 'Amiri-Bold',
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                
                                                // علامة اقتباس في النهاية
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  child: Transform.rotate(
                                                    angle: 3.14, // 180 درجة
                                                    child: Icon(
                                                      Icons.format_quote,
                                                      size: 18,
                                                      color: Colors.white.withOpacity(0.5),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // المصدر
                                          Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(30),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.15),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                widget.quoteItem.source,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // أزرار الإجراءات بتصميم متناسق مع الكارد
                      AnimationConfiguration.synchronized(
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // زر المفضلة - لون خاص عند التفعيل فقط
                                _buildMatchingStyleButton(
                                  context: context,
                                  icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                                  title: _isFavorite ? 'تمت الإضافة' : 'المفضلة',
                                  color: Colors.red,
                                  isActive: _isFavorite,
                                  onPressed: () => _toggleFavorite(context),
                                  isPressed: _isFavoritePressed,
                                  useActiveColor: true, // استخدام اللون الأحمر فقط عند التفعيل
                                ),
                                const SizedBox(width: 16),
                                
                                // زر النسخ
                                _buildMatchingStyleButton(
                                  context: context,
                                  icon: Icons.copy_rounded,
                                  title: 'نسخ',
                                  color: Colors.blue,
                                  onPressed: () => _copyQuote(context),
                                  isPressed: _isCopyPressed,
                                  useOriginalColor: true,
                                ),
                                const SizedBox(width: 16),
                                
                                // زر المشاركة
                                _buildMatchingStyleButton(
                                  context: context,
                                  icon: Icons.share_rounded,
                                  title: 'مشاركة',
                                  color: Colors.green,
                                  onPressed: () => _shareQuote(context),
                                  isPressed: _isSharePressed,
                                  useOriginalColor: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              
              // زر الرجوع
              Positioned(
                top: 16,
                right: 16,
                child: AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 300),
                  child: FadeInAnimation(
                    child: Material(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
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
  
  // دالة لإنشاء أزرار بنمط متناسق مع الكارد
  Widget _buildMatchingStyleButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
    bool isActive = false,
    bool isPressed = false,
    bool useOriginalColor = false,
    bool useActiveColor = false,
  }) {
    // تحديد لون الزر
    List<Color> gradientColors;
    
    if (useActiveColor && isActive) {
      // استخدام اللون الأحمر فقط عند التفعيل
      gradientColors = [color, color.withOpacity(0.7)];
    } else if (useOriginalColor) {
      // استخدام اللون الأصلي دائمًا
      gradientColors = [color, color.withOpacity(0.7)];
    } else {
      // استخدام لون الكارد الأخضر
      gradientColors = [
        const Color(0xFF447055).withOpacity(0.9),
        const Color(0xFF2D6852).withOpacity(0.7),
      ];
    }
    
    return Transform.scale(
      scale: isPressed ? 0.95 : (isActive ? _pulseAnimation.value : 1.0),
      child: Card(
        elevation: 8,
        shadowColor: (useActiveColor && isActive) || useOriginalColor
            ? color.withOpacity(0.3)
            : Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: gradientColors,
              stops: const [0.3, 1.0],
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة دائرية
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // عنوان الزر
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // دالة إضافية لبناء خيارات المشاركة الاجتماعية
  Widget _buildSocialShareOption({
    required BuildContext context, 
    required IconData icon, 
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}