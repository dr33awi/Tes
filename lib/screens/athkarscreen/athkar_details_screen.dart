// lib/screens/athkarscreen/athkar_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary,kSurface;
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

class _AthkarDetailsScreenState extends State<AthkarDetailsScreen> with SingleTickerProviderStateMixin {
  final AthkarService _athkarService = AthkarService();
  
  // حالة المفضلة وعدادات الأذكار
  final Map<int, bool> _favorites = {};
  final Map<int, int> _counters = {};
  bool _isLoading = true;
  late AthkarCategory _loadedCategory;
  
  // متغيرات للتأثيرات البصرية
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _tappedIndex;
  bool _isPressed = false;
  int? _pressedIndex;
  
  @override
  void initState() {
    super.initState();
    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
    await _athkarService.toggleFavorite(_loadedCategory.id, index);
    setState(() {
      _favorites[index] = !(_favorites[index] ?? false);
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
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
      _isPressed = true;
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
          _isPressed = false;
          _pressedIndex = null;
        });
      }
    });
  }
  
  // نسخ الذكر
  void _copyThikr(Thikr thikr, int index) {
    setState(() {
      _isPressed = true;
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
          _isPressed = false;
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
        return [
          _loadedCategory.color,
          _loadedCategory.color.withOpacity(0.8),
        ];
    }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _loadedCategory.title,
              style: TextStyle(
                color: _getCategoryColor(),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            // سهم صغير للتوضيح
            Icon(
              Icons.arrow_forward_ios,
              color: _getCategoryColor(),
              size: 16,
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _getCategoryColor(),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // وصف الفئة (إذا كان موجودًا)
            if (_loadedCategory.description != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(),
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
            
            // قائمة الأذكار
            Expanded(
              child: _loadedCategory.athkar.isEmpty
                  ? _buildEmptyState()
                  : _buildAthkarList(),
            ),
          ],
        ),
      ),
    );
  }

  // حالة عدم وجود أذكار
  Widget _buildEmptyState() {
    return Center(
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
    );
  }

  // قائمة الأذكار المحسنة
  Widget _buildAthkarList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _loadedCategory.athkar.length,
        itemBuilder: (context, index) {
          final thikr = _loadedCategory.athkar[index];
          final isFavorite = _favorites[index] ?? false;
          final counter = _counters[index] ?? 0;
          final isCompleted = counter >= thikr.count;
          final bool isPressed = _isPressed && _pressedIndex == index;
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isPressed ? _animation.value : 1.0,
                      child: child,
                    );
                  },
                  child: Card(
                    elevation: 8,
                    shadowColor: _getCategoryColor().withOpacity(0.3),
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
                          colors: _getCategoryGradient(),
                          stops: const [0.3, 1.0],
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _incrementCounter(index),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  
                                  // زر إزالة من المفضلة
                                  Material(
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
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // محتوى الذكر
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
                                  thikr.text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    height: 1.8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // المصدر
                              if (thikr.source != null)
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
                                      '${thikr.source} | $counter/${thikr.count}',
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
                                    onPressed: () => _copyThikr(thikr, index),
                                    isPressed: isPressed && _pressedIndex == index,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildActionButton(
                                    icon: Icons.share,
                                    label: 'مشاركة',
                                    onPressed: () => _shareThikr(thikr, index),
                                    isPressed: isPressed && _pressedIndex == index,
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
              ),
            ),
          );
        },
      ),
    );
  }
  
  // زر الإجراء
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
}