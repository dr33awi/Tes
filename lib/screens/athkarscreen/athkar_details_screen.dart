// lib/screens/athkarscreen/athkar_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kSurface;
import 'package:test_athkar_app/screens/athkarscreen/athkar_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AthkarDetailsScreen extends StatefulWidget {
  final AthkarCategory category;

  const AthkarDetailsScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<AthkarDetailsScreen> createState() => _AthkarDetailsScreenState();
}

class _AthkarDetailsScreenState extends State<AthkarDetailsScreen>
    with SingleTickerProviderStateMixin {
  final AthkarService _athkarService = AthkarService();
  
  // حالة المفضلة وعدادات الأذكار
  final Map<int, bool> _favorites = {};
  final Map<int, int> _counters = {};
  bool _isLoading = true;
  late AthkarCategory _loadedCategory;
  
  // متغيرات للتأثيرات البصرية
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  int? _tappedIndex;
  bool _isPressed = false;
  int? _pressedIndex;
  
  // متغيرات للأزرار
  bool _isCopyPressed = false;
  bool _isSharePressed = false;
  bool _isFavoritePressed = false;
  
  @override
  void initState() {
    super.initState();
    // إعداد الأنيميشن
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
    
    _loadCategory();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // تحميل البيانات
  Future<void> _loadCategory() async {
    try {
      // الحصول على الفئة الكاملة مع أذكارها
      final category = await _athkarService.getAthkarCategory(widget.category.id);
      
      if (category != null) {
        if (mounted) {
          setState(() {
            _loadedCategory = category;
            _isLoading = false;
          });
        }
        
        // تحميل حالة المفضلة والعدادات
        _loadThikrState();
      } else {
        if (mounted) {
          setState(() {
            _loadedCategory = widget.category;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('خطأ في تحميل البيانات: $e');
      if (mounted) {
        setState(() {
          _loadedCategory = widget.category;
          _isLoading = false;
        });
      }
    }
  }
  
  // تحميل حالة كل ذكر (المفضلة والعدادات)
  Future<void> _loadThikrState() async {
    for (int i = 0; i < _loadedCategory.athkar.length; i++) {
      final isFav = await _athkarService.isFavorite(_loadedCategory.id, i);
      final count = await _athkarService.getThikrCount(_loadedCategory.id, i);
      
      if (mounted) {
        setState(() {
          _favorites[i] = isFav;
          _counters[i] = count;
        });
      }
    }
  }
  
  // تبديل حالة المفضلة
  Future<void> _toggleFavorite(int index) async {
    setState(() {
      _isFavoritePressed = true;
      _favorites[index] = !(_favorites[index] ?? false);
    });
    
    await _athkarService.toggleFavorite(_loadedCategory.id, index);
    
    // تأثير اهتزاز خفيف
    HapticFeedback.mediumImpact();
    
    // تشغيل تأثير النبض للزر
    if (_favorites[index] == true) {
      _animationController.reset();
      _animationController.forward();
    }
    
    // إظهار رسالة للمستخدم
    if (_favorites[index] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.favorite, color: Colors.white),
              SizedBox(width: 10),
              Text('تمت الإضافة إلى المفضلة'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _getCategoryColor(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isFavoritePressed = false);
      }
    });
  }
  
  // زيادة عداد الذكر
  Future<void> _incrementCounter(int index) async {
    // تفعيل تأثير الضغط
    setState(() {
      _isPressed = true;
      _pressedIndex = index;
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    // تشغيل انيميشن الضغط
    _animationController.reset();
    _animationController.forward();
    
    final thikr = _loadedCategory.athkar[index];
    int currentCount = _counters[index] ?? 0;
    
    if (currentCount < thikr.count) {
      currentCount++;
      setState(() {
        _counters[index] = currentCount;
      });
      await _athkarService.updateThikrCount(_loadedCategory.id, index, currentCount);
    }
    
    // إعادة تعيين حالة الضغط بعد فترة وجيزة
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
          _pressedIndex = null;
        });
      }
    });
    
    // إذا اكتمل العدد المطلوب
    if (currentCount >= thikr.count) {
      // إظهار رسالة التهنئة
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.done_all, color: Colors.white),
              SizedBox(width: 10),
              Text('أحسنت! اكتمل عدد مرات الذكر'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _getCategoryColor(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'عرض الفضل',
            textColor: Colors.white,
            onPressed: () {
              if (thikr.fadl != null) {
                _showFadlDialog(thikr);
              }
            },
          ),
        ),
      );
      
      // اهتزاز خفيف (للإشعار)
      HapticFeedback.mediumImpact();
    }
  }
  
  // عرض فضل الذكر في حوار
  void _showFadlDialog(Thikr thikr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: _getCategoryColor()),
            SizedBox(width: 10),
            Text('فضل الذكر'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thikr.fadl != null)
              Text(
                thikr.fadl!,
                style: TextStyle(
                  height: 1.6,
                  fontSize: 16,
                ),
              ),
            SizedBox(height: 12),
            if (thikr.source != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCategoryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'المصدر: ${thikr.source}',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: _getCategoryColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'إغلاق',
              style: TextStyle(color: _getCategoryColor()),
            ),
          ),
        ],
      ),
    );
  }
  
  // إعادة تعيين العداد
  Future<void> _resetCounter(int index) async {
    setState(() {
      _counters[index] = 0;
    });
    await _athkarService.updateThikrCount(_loadedCategory.id, index, 0);
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    // إظهار رسالة للمستخدم
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh, color: Colors.white),
            SizedBox(width: 10),
            Text('تم إعادة ضبط العداد'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _getCategoryColor(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  // مشاركة الذكر
  void _shareThikr(Thikr thikr, int index) async {
    setState(() {
      _isSharePressed = true;
      _pressedIndex = index;
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    String text = thikr.text;
    
    if (thikr.source != null) {
      text += '\n\nالمصدر: ${thikr.source}';
    }
    
    await Share.share(text, subject: 'ذكر من تطبيق الأذكار');
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isSharePressed = false;
          _pressedIndex = null;
        });
      }
    });
  }
  
  // نسخ الذكر
  void _copyThikr(Thikr thikr, int index) {
    setState(() {
      _isCopyPressed = true;
      _pressedIndex = index;
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    String text = thikr.text;
    
    if (thikr.source != null) {
      text += '\n\nالمصدر: ${thikr.source}';
    }
    
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('تم نسخ الذكر إلى الحافظة'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _getCategoryColor(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isCopyPressed = false;
          _pressedIndex = null;
        });
      }
    });
  }
  
  // الحصول على لون الفئة حسب نوعها
  Color _getCategoryColor() {
    switch (_loadedCategory.id) {
      case 'morning':
        return const Color(0xFFFFD54F); // أصفر للصباح
      case 'evening':
        return const Color(0xFFAB47BC); // بنفسجي للمساء
      case 'sleep':
        return const Color(0xFF5C6BC0); // أزرق للنوم
      case 'wake':
        return const Color(0xFFFFB74D); // برتقالي للاستيقاظ
      case 'prayer':
        return const Color(0xFF4DB6AC); // أخضر مزرق للصلاة
      case 'home':
        return const Color(0xFF66BB6A); // أخضر للمنزل
      case 'food':
        return const Color(0xFFE57373); // أحمر للطعام
      case 'quran':
        return const Color(0xFF9575CD); // بنفسجي فاتح للقرآن
      default:
        return _loadedCategory.color;
    }
  }
  
  // الحصول على تدرج لوني للفئة
  List<Color> _getCategoryGradient() {
    Color baseColor = _getCategoryColor();
    Color darkColor = HSLColor.fromColor(baseColor).withLightness(
      HSLColor.fromColor(baseColor).lightness * 0.7
    ).toColor();
    
    switch (_loadedCategory.id) {
      case 'morning':
        return [
          const Color(0xFFFFD54F), // أصفر فاتح
          const Color(0xFFFFA000), // أصفر داكن
        ];
      case 'evening':
        return [
          const Color(0xFFAB47BC), // بنفسجي فاتح
          const Color(0xFF7B1FA2), // بنفسجي داكن
        ];
      case 'sleep':
        return [
          const Color(0xFF5C6BC0), // أزرق فاتح
          const Color(0xFF3949AB), // أزرق داكن
        ];
      case 'wake':
        return [
          const Color(0xFFFFB74D), // برتقالي فاتح
          const Color(0xFFFF9800), // برتقالي داكن
        ];
      case 'prayer':
        return [
          const Color(0xFF4DB6AC), // أخضر مزرق فاتح
          const Color(0xFF00695C), // أخضر مزرق داكن
        ];
      case 'home':
        return [
          const Color(0xFF66BB6A), // أخضر فاتح
          const Color(0xFF2E7D32), // أخضر داكن
        ];
      case 'food':
        return [
          const Color(0xFFE57373), // أحمر فاتح
          const Color(0xFFC62828), // أحمر داكن
        ];
      case 'quran':
        return [
          const Color(0xFF9575CD), // بنفسجي فاتح
          const Color(0xFF512DA8), // بنفسجي داكن
        ];
      default:
        return [baseColor, darkColor];
    }
  }
  
  // زر الإجراء محدث بنفس نمط favorites_screen
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
  
  @override
  Widget build(BuildContext context) {
    // عرض مؤشر التحميل أثناء تحميل البيانات
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kSurface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            widget.category.title,
            style: const TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: kPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingAnimationWidget.staggeredDotsWave(
                color: kPrimary,
                size: 50,
              ),
              SizedBox(height: 20),
              Text(
                'جاري تحميل الأذكار...',
                style: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
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
                      
                      // عنوان الفئة (في المنتصف)
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
                                      _loadedCategory.icon,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _loadedCategory.title,
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
                      
                      // وصف الفئة (إذا كان موجودًا)
                      if (_loadedCategory.description != null)
                        AnimationConfiguration.synchronized(
                          duration: const Duration(milliseconds: 350),
                          child: SlideAnimation(
                            verticalOffset: 20.0,
                            child: FadeInAnimation(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor().withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getCategoryColor().withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'عن ${_loadedCategory.title}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              _loadedCategory.description!,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
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
                      
                      // قائمة الأذكار المحسنة
                      _loadedCategory.athkar.isEmpty
                          ? _buildEmptyState()
                          : _buildAthkarList(),
                          
                      // مساحة إضافية في النهاية
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
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.arrow_back,
                            color: _getCategoryColor(),
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

  // حالة عدم وجود أذكار
  Widget _buildEmptyState() {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 400),
      child: SlideAnimation(
        verticalOffset: 30.0,
        child: FadeInAnimation(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.format_quote,
                  size: 80,
                  color: _getCategoryColor().withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد أذكار في هذه الفئة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'قد يكون هناك خطأ في تحميل البيانات',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // قائمة الأذكار المحسنة
  Widget _buildAthkarList() {
    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _loadedCategory.athkar.length,
        itemBuilder: (context, index) {
          final thikr = _loadedCategory.athkar[index];
          final isFavorite = _favorites[index] ?? false;
          final counter = _counters[index] ?? 0;
          final isCompleted = counter >= thikr.count;
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildThikrCard(thikr, index, isFavorite, counter, isCompleted),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // بطاقة الذكر المحسنة
  Widget _buildThikrCard(Thikr thikr, int index, bool isFavorite, int counter, bool isCompleted) {
    final bool isPressed = _isPressed && _pressedIndex == index;
    
    return Card(
      elevation: 15,
      shadowColor: _getCategoryColor().withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isPressed ? 0.98 : 1.0,
            child: child!,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: _getCategoryGradient(),
              stops: const [0.3, 1.0],
            ),
          ),
          child: InkWell(
            onTap: () => _incrementCounter(index),
            borderRadius: BorderRadius.circular(24),
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
                      // رأس البطاقة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // عنوان الذكر
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
                                  _loadedCategory.icon,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'ذكر ${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // زر المفضلة
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isFavorite ? _pulseAnimation.value : 1.0,
                                child: Material(
                                  color: Colors.transparent,
                                  child: IconButton(
                                    icon: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () => _toggleFavorite(index),
                                    tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                                    splashRadius: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // محتوى الذكر
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 25,
                        ),
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
                                Text(
                                  thikr.text,
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
                      
                      const SizedBox(height: 12),
                      
                      // المصدر وعداد التكرار
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (thikr.source != null)
                                Text(
                                  thikr.source!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              if (thikr.source != null)
                                Text(
                                  ' | ',
                                  style: TextStyle(color: Colors.white),
                                ),
                              Text(
                                '$counter/${thikr.count}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // أزرار الإجراءات
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // زر النسخ
                          _buildActionButton(
                            icon: Icons.copy,
                            label: 'نسخ',
                            onPressed: () => _copyThikr(thikr, index),
                            isPressed: _isCopyPressed && _pressedIndex == index,
                          ),
                          const SizedBox(width: 16),
                          
                          // زر المشاركة
                          _buildActionButton(
                            icon: Icons.share,
                            label: 'مشاركة',
                            onPressed: () => _shareThikr(thikr, index),
                            isPressed: _isSharePressed && _pressedIndex == index,
                          ),
                          const SizedBox(width: 16),
                          
                          // زر المفضلة
                          _buildActionButton(
                            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                            label: isFavorite ? 'إزالة' : 'المفضلة',
                            onPressed: () => _toggleFavorite(index),
                            isPressed: _isFavoritePressed && _pressedIndex == index,
                          ),
                        ],
                      ),
                      
                      // زر عرض فضل الذكر
                      if (thikr.fadl != null && isCompleted)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextButton.icon(
                            onPressed: () => _showFadlDialog(thikr),
                            icon: Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              'عرض فضل الذكر',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }
}