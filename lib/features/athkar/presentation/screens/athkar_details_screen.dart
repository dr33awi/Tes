// lib/features/athkar/presentation/screens/athkar_details_screen.dart
import 'package:athkar_app/app/themes/athkar_themes/athkar_card.dart';
import 'package:athkar_app/app/themes/athkar_themes/athkar_snackbar.dart';
import 'package:athkar_app/app/themes/athkar_themes/completion_message_card.dart';
import 'package:athkar_app/app/themes/athkar_themes/empty_state_widget.dart';
import 'package:athkar_app/app/themes/athkar_themes/fadl_dialog.dart';
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
  bool _isReadAgainPressed = false;
  
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
    AthkarSnackBar.showReset(
      context,
      backgroundColor: IconHelper.getCategoryColor(_loadedCategory.id),
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
    AthkarSnackBar.show(
      context: context,
      message: message,
      icon: icon,
      backgroundColor: IconHelper.getCategoryColor(_loadedCategory.id),
    );
  }
  
  // تبديل حالة المفضلة
  Future<void> _toggleFavorite(int index) async {
    setState(() {
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
      AthkarSnackBar.showFavoriteAdded(
        context,
        backgroundColor: IconHelper.getCategoryColor(_loadedCategory.id),
      );
    }
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
        AthkarSnackBar.showCompleted(
          context,
          backgroundColor: IconHelper.getCategoryColor(_loadedCategory.id),
        );
        
        // التحقق إذا كانت جميع الأذكار مكتملة
        _checkAllAthkarCompleted();
      }
    }
  }
  
  // عرض فضل الذكر في حوار
  void _showFadlDialog(Athkar thikr) {
    FadlDialog.show(
      context: context,
      fadl: thikr.fadl,
      source: thikr.source,
      accentColor: IconHelper.getCategoryColor(_loadedCategory.id),
    );
  }
  
  // مشاركة الذكر
  void _shareThikr(Athkar thikr) async {
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    String text = thikr.content;
    
    if (thikr.source != null) {
      text += '\n\nالمصدر: ${thikr.source}';
    }
    
    await Share.share(text, subject: 'ذكر من تطبيق الأذكار');
  }
  
  // نسخ الذكر
  void _copyThikr(Athkar thikr) {
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    String text = thikr.content;
    
    if (thikr.source != null) {
      text += '\n\nالمصدر: ${thikr.source}';
    }
    
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      AthkarSnackBar.showCopied(
        context,
        backgroundColor: IconHelper.getCategoryColor(_loadedCategory.id),
      );
    });
  }
  
  // رسالة إتمام الأذكار مع زر "قراءتها مرة أخرى"
  Widget _buildCompletionMessage() {
    final categoryColor = IconHelper.getCategoryColor(_loadedCategory.id);
    
    return CompletionMessageCard(
      primaryColor: categoryColor,
      onResetPressed: _resetAllAthkar,
      onBackPressed: () => Navigator.of(context).pop(),
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
    return EmptyStateWidget(
      icon: Icons.format_quote,
      iconColor: IconHelper.getCategoryColor(_loadedCategory.id),
      title: 'لا توجد أذكار في هذه الفئة',
      subtitle: 'قد يكون هناك خطأ في تحميل البيانات',
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
                          child: AthkarCard(
                            content: thikr.content,
                            source: thikr.source,
                            currentCount: counter,
                            totalCount: thikr.count,
                            isFavorite: isFavorite,
                            primaryColor: IconHelper.getCategoryColor(_loadedCategory.id),
                            onTap: () => _incrementCounter(index),
                            onFavoriteToggle: () => _toggleFavorite(index),
                            onCopy: () => _copyThikr(thikr),
                            onShare: () => _shareThikr(thikr),
                            onInfo: thikr.fadl != null ? () => _showFadlDialog(thikr) : null,
                            isCompleted: isCompleted,
                            showActions: true,
                            showCounter: true,
                            hasGradientBackground: false,
                            margin: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
  }
}