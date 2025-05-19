// lib/features/athkar/presentation/screens/athkar_details_screen.dart
import 'package:athkar_app/features/athkar/presentation/screens/athkar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/di/service_locator.dart';

import '../../data/datasources/athkar_service.dart';
import '../../data/utils/icon_helper.dart';
import '../../domain/entities/athkar.dart';
import '../../../widgets/common/loading_widget.dart';
import '../theme/athkar_theme_manager.dart';

class AthkarDetailsScreen extends StatefulWidget {
  final AthkarScreen category;

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
  late AthkarScreen _loadedCategory;
  final ScrollController _scrollController = ScrollController();
  
  // متغيرات للتأثيرات البصرية
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  int? _pressedIndex;
  bool _isPressed = false;
  
  // متغيرات للأزرار
  bool _isCopyPressed = false;
  bool _isSharePressed = false;
  bool _isFavoritePressed = false;
  bool _isReadAgainPressed = false;
  bool _isFadlPressed = false;
  
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
      debugPrint('خطأ في تحميل البيانات: $e');
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
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    
    // إظهار رسالة للمستخدم
    _showSnackBar(
      message: 'تمت إعادة تهيئة جميع الأذكار',
      icon: Icons.refresh,
    );
    
    // إعادة تعيين حالة الضغط بعد فترة وجيزة
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _isReadAgainPressed = false);
      }
    });
  }
  
  // عرض رسالة في أسفل الشاشة
  void _showSnackBar({required String message, required IconData icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: IconHelper.getCategoryColor(_loadedCategory.id),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
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
      _showSnackBar(
        message: 'تمت الإضافة إلى المفضلة',
        icon: Icons.favorite,
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
        _showSnackBar(
          message: 'تم إكمال هذا الذكر',
          icon: Icons.check_circle,
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
  void _showFadlDialog(Athkar thikr, int index) {
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
            Icon(Icons.info_outline, color: IconHelper.getCategoryColor(_loadedCategory.id)),
            const SizedBox(width: 10),
            const Text('فضل الذكر'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thikr.fadl != null)
              Text(
                thikr.fadl!,
                style: const TextStyle(
                  height: 1.6,
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 12),
            if (thikr.source != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: IconHelper.getCategoryColor(_loadedCategory.id).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'المصدر: ${thikr.source}',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: IconHelper.getCategoryColor(_loadedCategory.id),
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
              style: TextStyle(color: IconHelper.getCategoryColor(_loadedCategory.id)),
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
  void _shareThikr(Athkar thikr, int index) async {
    setState(() {
      _isSharePressed = true;
      _pressedIndex = index;
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    String text = thikr.content;
    
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
  void _copyThikr(Athkar thikr, int index) {
    setState(() {
      _isCopyPressed = true;
      _pressedIndex = index;
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    String text = thikr.content;
    
    if (thikr.source != null) {
      text += '\n\nالمصدر: ${thikr.source}';
    }
    
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      _showSnackBar(
        message: 'تم نسخ الذكر إلى الحافظة',
        icon: Icons.check_circle,
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
    Color categoryColor = IconHelper.getCategoryColor(_loadedCategory.id);
    
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
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
                  offset: const Offset(0, 8),
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
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'أحسنت!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'لقد أتممت جميع الأذكار بحمد الله',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'تقبل الله منك، وجزاك الله خيراً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                
                // زر قراءة الأذكار مرة أخرى
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.identity()..scale(_isReadAgainPressed ? 0.95 : 1.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.replay_rounded,
                      color: Colors.white,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        'قراءتها مرة أخرى',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                
                const SizedBox(height: 16),
                
                // زر العودة إلى أقسام الأذكار
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.home_rounded,
                    color: categoryColor,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'العودة إلى أقسام الأذكار',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
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
  
  // زر الإجراء محدث
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // عرض مؤشر التحميل أثناء تحميل البيانات
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            widget.category.name,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: colorScheme.primary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LoadingWidget(),
              const SizedBox(height: 20),
              Text(
                'جاري تحميل الأذكار...',
                style: TextStyle(
                  color: colorScheme.primary,
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
      backgroundColor: colorScheme.background,
      // إضافة أبار جديد لعرض العنوان والأزرار
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _loadedCategory.name,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // زر إعادة تعيين الأذكار
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: colorScheme.primary,
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
                  color: IconHelper.getCategoryColor(_loadedCategory.id).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد أذكار في هذه الفئة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: IconHelper.getCategoryColor(_loadedCategory.id),
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
        physics: const NeverScrollableScrollPhysics(),
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
            return const SizedBox.shrink();
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
  Widget _buildThikrCard(Athkar thikr, int index, bool isFavorite, int counter, bool isCompleted) {
    final bool isPressed = _isPressed && _pressedIndex == index;
    final bool isHiding = isCompleted; // هذا المتغير يستخدم لحالات الإخفاء التدريجي
    
    return Card(
      elevation: 15,
      shadowColor: IconHelper.getCategoryColor(_loadedCategory.id).withOpacity(0.3),
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
          opacity: isHiding ? 0.0 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: IconHelper.getCategoryGradient(_loadedCategory.id),
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
                      child: Icon(
                        Icons.format_quote,
                        size: 100,
                        color: Colors.white.withOpacity(0.1),
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
                                    IconHelper.getIconFromString(_loadedCategory.icon),
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
                                    thikr.content,
                                    textAlign: TextAlign.center,
                                    style: AthkarThemeManager.getThikrTextStyle(),
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