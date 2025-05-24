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
import '../../../../app/themes/loading_widget.dart';
import '../../../../app/themes/theme_constants.dart';
import '../../../../app/themes/glassmorphism_widgets.dart';
import '../../../../app/themes/screen_template.dart';
import '../../../../app/themes/app_theme.dart';
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
      duration: ThemeDurations.medium,
      vsync: this,
    );
    
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ThemeCurves.smooth,
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
        duration: ThemeDurations.medium,
        curve: ThemeCurves.decelerate,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium)
        ),
        margin: const EdgeInsets.all(ThemeSizes.marginMedium),
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
    
    Future.delayed(ThemeDurations.veryFast, () {
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
    Future.delayed(ThemeDurations.veryFast, () {
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
            const SizedBox(height: ThemeSizes.marginMedium),
            if (thikr.source != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeSizes.marginMedium, 
                  vertical: ThemeSizes.marginSmall
                ),
                decoration: BoxDecoration(
                  color: IconHelper.getCategoryColor(_loadedCategory.id).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusLarge)
        ),
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
    
    Future.delayed(ThemeDurations.veryFast, () {
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
    
    Future.delayed(ThemeDurations.veryFast, () {
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
    
    Future.delayed(ThemeDurations.veryFast, () {
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
      duration: ThemeDurations.verySlow,
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: SoftCard(
            borderRadius: ThemeSizes.borderRadiusLarge,
            hasBorder: true,
            elevation: 4,
            padding: const EdgeInsets.all(ThemeSizes.marginXLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة الإتمام مع تحسين المظهر
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: categoryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: categoryColor,
                    size: 50,
                  ),
                ),
                const SizedBox(height: ThemeSizes.marginLarge),
                Text(
                  'أحسنت!',
                  style: AppTheme.getHeadingStyle(context, fontSize: 26),
                ),
                const SizedBox(height: ThemeSizes.marginMedium),
                Text(
                  'لقد أتممت جميع الأذكار بحمد الله',
                  textAlign: TextAlign.center,
                  style: AppTheme.getBodyStyle(context, fontSize: 18),
                ),
                const SizedBox(height: ThemeSizes.marginSmall),
                Text(
                  'تقبل الله منك، وجزاك الله خيراً',
                  textAlign: TextAlign.center,
                  style: AppTheme.getBodyStyle(context, fontSize: 18, isSecondary: true),
                ),
                const SizedBox(height: ThemeSizes.marginLarge),
                
                // زر قراءة الأذكار مرة أخرى
                SoftButton(
                  text: 'قراءتها مرة أخرى',
                  icon: Icons.replay_rounded,
                  onPressed: _resetAllAthkar,
                  isFullWidth: true,
                  backgroundColor: categoryColor,
                  borderRadius: ThemeSizes.borderRadiusMedium,
                ),
                
                const SizedBox(height: ThemeSizes.marginMedium),
                
                // زر العودة إلى أقسام الأذكار
                SoftButton(
                  text: 'العودة إلى أقسام الأذكار',
                  icon: Icons.home_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                  isOutlined: true,
                  isFullWidth: true,
                  borderRadius: ThemeSizes.borderRadiusMedium,
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
      duration: ThemeDurations.veryFast,
      transform: Matrix4.identity()..scale(isPressed ? 0.95 : 1.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeSizes.marginMedium,
              vertical: ThemeSizes.marginSmall,
            ),
            decoration: BoxDecoration(
              color: AppTheme.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
              border: Border.all(
                color: AppTheme.getDividerColor(context),
                width: ThemeSizes.borderWidthThin,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: AppTheme.getTextColor(context, isSecondary: true),
                  size: 18,
                ),
                const SizedBox(width: ThemeSizes.marginSmall),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context, isSecondary: true),
                    fontWeight: FontWeight.w600,
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
      return ScreenTemplate(
        title: widget.category.name,
        body: Center(
          child: LoadingWidget(
            color: IconHelper.getCategoryColor(widget.category.id),
          ),
        ),
      );
    }
    
    // استخدام قالب الشاشة للحصول على التناسق مع باقي التطبيق
    return ScreenTemplate(
      title: _loadedCategory.name,
      actions: [
        // زر إعادة تعيين الأذكار
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'إعادة تهيئة جميع الأذكار',
          onPressed: _resetAllAthkar,
        ),
      ],
      useAnimations: !_showCompletionMessage, // إيقاف الرسوم المتحركة عند ظهور رسالة الإتمام
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _showCompletionMessage
            ? Center(child: _buildCompletionMessage())
            : _buildAthkarList(),
      ),
    );
  }

  // حالة عدم وجود أذكار
  Widget _buildEmptyState() {
    return AnimationConfiguration.synchronized(
      duration: ThemeDurations.medium,
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
                const SizedBox(height: ThemeSizes.marginMedium),
                Text(
                  'لا توجد أذكار في هذه الفئة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: IconHelper.getCategoryColor(_loadedCategory.id),
                  ),
                ),
                const SizedBox(height: ThemeSizes.marginSmall),
                Text(
                  'قد يكون هناك خطأ في تحميل البيانات',
                  style: AppTheme.getBodyStyle(context, isSecondary: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // قائمة الأذكار 
  Widget _buildAthkarList() {
    return _loadedCategory.athkar.isEmpty
        ? _buildEmptyState()
        : SingleChildScrollView(
            controller: _scrollController,
            child: AnimationLimiter(
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
                    duration: ThemeDurations.medium,
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: ThemeSizes.marginMedium),
                          child: _buildThikrCard(thikr, index, isFavorite, counter, isCompleted),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
  }
  
  // بطاقة الذكر المحسنة
  Widget _buildThikrCard(Athkar thikr, int index, bool isFavorite, int counter, bool isCompleted) {
    final bool isPressed = _isPressed && _pressedIndex == index;
    final bool isHiding = isCompleted; // هذا المتغير يستخدم لحالات الإخفاء التدريجي
    final categoryColor = IconHelper.getCategoryColor(_loadedCategory.id);
    
    return SoftCard(
      elevation: 2,
      borderRadius: ThemeSizes.borderRadiusLarge,
      hasBorder: true,
      onTap: () => _incrementCounter(index),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isPressed ? _pulseAnimation.value : 1.0,
            child: AnimatedOpacity(
              duration: ThemeDurations.medium,
              opacity: isHiding ? 0.0 : 1.0,
              child: child!,
            ),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // نمط زخرفي في الخلفية
            Positioned(
              right: -15,
              top: 20,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  Icons.format_quote,
                  size: 100,
                  color: categoryColor,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(ThemeSizes.marginMedium),
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
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: ThemeSizes.marginMedium,
                          vertical: ThemeSizes.marginXSmall,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              IconHelper.getIconFromString(_loadedCategory.icon),
                              color: categoryColor,
                              size: 16,
                            ),
                            const SizedBox(width: ThemeSizes.marginSmall),
                            Text(
                              'عدد التكرار ${counter}/${thikr.count}',
                              style: TextStyle(
                                color: categoryColor,
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
                                  color: isFavorite ? ThemeColors.error : AppTheme.getTextColor(context, isSecondary: true),
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
                  
                  const SizedBox(height: ThemeSizes.marginMedium),
                  
                  // محتوى الذكر
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: ThemeSizes.marginLarge,
                      vertical: ThemeSizes.marginLarge,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
                      border: Border.all(
                        color: AppTheme.getDividerColor(context),
                        width: ThemeSizes.borderWidthThin,
                      ),
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
                            color: categoryColor.withOpacity(0.3),
                          ),
                        ),
                        
                        Column(
                          children: [
                            Text(
                              thikr.content,
                              textAlign: TextAlign.center,
                              style: AthkarThemeManager.getThikrTextStyle().copyWith(
                                color: AppTheme.getTextColor(context),
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
                              color: categoryColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: ThemeSizes.marginMedium),
                  
                  // المصدر
                  if (thikr.source != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ThemeSizes.marginMedium,
                          vertical: ThemeSizes.marginSmall,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusLarge),
                        ),
                        child: Text(
                          thikr.source!,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: ThemeSizes.marginMedium),
                  
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
                      const SizedBox(width: ThemeSizes.marginMedium),
                      
                      // زر المشاركة
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'مشاركة',
                        onPressed: () => _shareThikr(thikr, index),
                        isPressed: _isSharePressed && _pressedIndex == index,
                      ),
                      
                      // زر فضل الذكر (إضافة فاصل صغير إذا كان موجودًا)
                      if (thikr.fadl != null)
                        const SizedBox(width: ThemeSizes.marginMedium),
                      
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
    );
  }
}