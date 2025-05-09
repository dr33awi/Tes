// lib/screens/athkarscreen/athkar_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kSurface;
import 'package:test_athkar_app/screens/athkarscreen/services/athkar_service.dart';
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
  final Map<int, bool> _hiddenThikrs = {}; // لتتبع الأذكار المخفية مؤقتًا
  bool _isLoading = true;
  bool _showCompletionMessage = false; // لإظهار رسالة الإتمام
  late AthkarCategory _loadedCategory;
  ScrollController _scrollController = ScrollController();
  
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
  bool _isReadAgainPressed = false; // إضافة متغير لزر القراءة مرة أخرى
  bool _isFadlPressed = false; // إضافة متغير لزر فضل الذكر
  
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
    _scrollController.dispose();
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
        
        // تصفير جميع التكرارات وتحميل حالة المفضلة
        _resetAllCounters();
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
  
  // تصفير جميع التكرارات وتحميل حالة المفضلة
  Future<void> _resetAllCounters() async {
    for (int i = 0; i < _loadedCategory.athkar.length; i++) {
      // تصفير العدادات
      await _athkarService.updateThikrCount(_loadedCategory.id, i, 0);
      
      // تحميل حالة المفضلة
      final isFav = await _athkarService.isFavorite(_loadedCategory.id, i);
      
      if (mounted) {
        setState(() {
          _counters[i] = 0; // تصفير العدادات في واجهة المستخدم
          _favorites[i] = isFav;
          _hiddenThikrs[i] = false; // جعل جميع الأذكار ظاهرة
        });
      }
    }
    
    setState(() {
      _showCompletionMessage = false;
    });
  }
  
  // إعادة تعيين جميع الأذكار (تصفير العدادات وإظهار جميع الأذكار)
  Future<void> _resetAllAthkar() async {
    setState(() {
      _isReadAgainPressed = true; // تفعيل حالة الضغط
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.mediumImpact();
    
    // إعادة ضبط العدادات وإظهار جميع الأذكار
    for (int i = 0; i < _loadedCategory.athkar.length; i++) {
      await _athkarService.updateThikrCount(_loadedCategory.id, i, 0);
      
      setState(() {
        _counters[i] = 0;
        _hiddenThikrs[i] = false;
      });
    }
    
    // إخفاء رسالة الإتمام والعودة إلى قائمة الأذكار
    setState(() {
      _showCompletionMessage = false;
    });
    
    // إعادة التمرير إلى الأعلى بشكل سلس
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    
    // إظهار رسالة للمستخدم
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh, color: Colors.white),
            SizedBox(width: 10),
            Text('تمت إعادة تهيئة جميع الأذكار'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _getCategoryColor(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
    
    // إعادة تعيين حالة الضغط بعد فترة وجيزة
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _isReadAgainPressed = false);
      }
    });
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
  
  // التحقق من إكمال جميع الأذكار
  void _checkAllAthkarCompleted() {
    // التحقق إذا كانت جميع الأذكار مخفية بالفعل (تم إكمالها في هذه الجلسة)
    bool allHidden = true;
    
    for (int i = 0; i < _loadedCategory.athkar.length; i++) {
      if (!(_hiddenThikrs[i] ?? false)) {
        allHidden = false;
        break;
      }
    }
    
    // إذا لم يكن هناك أي ذكر ظاهر، عرض رسالة الإكمال
    if (allHidden && _loadedCategory.athkar.isNotEmpty && !_showCompletionMessage) {
      setState(() {
        _showCompletionMessage = true;
      });
    }
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
      
      // إذا اكتمل العدد المطلوب
      if (currentCount >= thikr.count) {
        // اهتزاز خفيف (للإشعار)
        HapticFeedback.mediumImpact();
        
        // إخفاء الذكر بعد إكماله
        setState(() {
          _hiddenThikrs[index] = true;
        });
        
        // عرض رسالة للمستخدم
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('تم إكمال هذا الذكر'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _getCategoryColor(),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
        
        // التحقق إذا كانت جميع الأذكار مكتملة
        _checkAllAthkarCompleted();
      }
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
  }
  
  // عرض فضل الذكر في حوار
  void _showFadlDialog(Thikr thikr, int index) {
    setState(() {
      _isFadlPressed = true;
      _pressedIndex = index;
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
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
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isFadlPressed = false;
          _pressedIndex = null;
        });
      }
    });
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
  
  // رسالة إتمام الأذكار مع زر "قراءتها مرة أخرى"
  Widget _buildCompletionMessage() {
    // الحصول على لون القسم الحالي
    Color categoryColor = _getCategoryColor();
    
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: EdgeInsets.all(24),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor,
                  categoryColor.withOpacity(0.7),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة الإتمام مع تحسين المظهر
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'أحسنت!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'لقد أتممت جميع الأذكار بحمد الله',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'تقبل الله منك، وجزاك الله خيراً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24),
                
                // زر قراءة الأذكار مرة أخرى
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.identity()..scale(_isReadAgainPressed ? 0.95 : 1.0),
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.replay_rounded,
                      color: Colors.white, // لون الأيقونة أبيض على خلفية شفافة
                    ),
                    label: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        'قراءتها مرة أخرى',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // لون النص أبيض
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _resetAllAthkar,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // زر العودة إلى أقسام الأذكار
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.home_rounded,
                    color: categoryColor, // لون الأيقونة مطابق للون القسم
                  ),
                  label: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'العودة إلى أقسام الأذكار',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: categoryColor, // لون النص مطابق للون القسم
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: categoryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      // إضافة أبار جديد لعرض العنوان والأزرار
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _loadedCategory.title,
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: kPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // زر إعادة تعيين الأذكار
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: kPrimary,
            ),
            tooltip: 'إعادة تهيئة جميع الأذكار',
            onPressed: _resetAllAthkar,
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: _showCompletionMessage
              ? Center(child: _buildCompletionMessage())
              : SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // مساحة في الأعلى
                        const SizedBox(height: 16),
                        
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
          final isHidden = _hiddenThikrs[index] ?? false;
          
          // تخطي العناصر المخفية
          if (isHidden) {
            return SizedBox.shrink();
          }
          
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
    final bool isHiding = isCompleted; // هذا المتغير يستخدم لحالات الإخفاء التدريجي
    
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
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isHiding ? 0.0 : 1.0,  // استخدام AnimatedOpacity بدلاً من الخاصية opacity في AnimatedContainer
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
                            // عدد التكرار
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
                                    'عدد التكرار ${counter}/${thikr.count}',
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
                        
                        // المصدر فقط (بدون عداد التكرار)
                        if (thikr.source != null)
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
                                thikr.source!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
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
                            const SizedBox(width: 12),
                            
                            // زر المشاركة
                            _buildActionButton(
                              icon: Icons.share,
                              label: 'مشاركة',
                              onPressed: () => _shareThikr(thikr, index),
                              isPressed: _isSharePressed && _pressedIndex == index,
                            ),
                            
                            // زر فضل الذكر (إضافة فاصل صغير إذا كان موجودًا)
                            if (thikr.fadl != null)
                              const SizedBox(width: 12),
                            
                            // زر فضل الذكر (إظهاره لجميع الأذكار التي لديها فضل)
                            if (thikr.fadl != null)
                              _buildActionButton(
                                icon: Icons.info_outline,
                                label: 'فضل الذكر',
                                onPressed: () => _showFadlDialog(thikr, index),
                                isPressed: _isFadlPressed && _pressedIndex == index,
                              ),
                          ],
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
    );
  }
}