// lib/app/themes/screen_template.dart
import 'package:athkar_app/app/themes/glassmorphism_widgets.dart';
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// قالب الشاشة الأساسي للتطبيق مع دعم الثيم الموحد
class ScreenTemplate extends StatelessWidget {
  /// عنوان الشاشة
  final String title;
  
  /// محتوى الشاشة
  final Widget body;
  
  /// ما إذا كان يجب إظهار زر العودة
  final bool showBackButton;
  
  /// أزرار إضافية في شريط العنوان
  final List<Widget>? actions;
  
  /// زر العمل الطائر
  final Widget? floatingActionButton;
  
  /// موقع زر العمل الطائر
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  
  /// قاع الشاشة
  final Widget? bottomNavigationBar;
  
  /// سلوك عند الضغط على زر الرجوع
  final VoidCallback? onBackPressed;
  
  /// ما إذا كان يجب استخدام تأثيرات الرسوم المتحركة
  final bool useAnimations;
  
  /// ما إذا كان المحتوى قابل للتمرير
  final bool isScrollable;

  /// تباعد المحتوى الداخلي
  final EdgeInsetsGeometry contentPadding;
  
  /// ما إذا كان يجب استخدام خلفية ملونة
  final bool useGradientBackground;
  
  /// لون خلفية مخصص
  final Color? backgroundColor;
  
  /// ما إذا كان يجب وضع الجسم خلف شريط التطبيق
  final bool extendBodyBehindAppBar;

  const ScreenTemplate({
    Key? key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.onBackPressed,
    this.useAnimations = true,
    this.isScrollable = true,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
    this.useGradientBackground = false,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // تعيين نمط شريط الحالة
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: backgroundColor ?? 
            (isDark ? ThemeColors.darkBackground : ThemeColors.lightBackground),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    Widget scaffold = Scaffold(
      backgroundColor: backgroundColor ?? 
          (isDark ? ThemeColors.darkBackground : ThemeColors.lightBackground),
      appBar: _buildAppBar(context),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: _buildBody(context),
    );
    
    // إضافة خلفية متدرجة إذا لزم الأمر
    if (useGradientBackground) {
      return Container(
        decoration: BoxDecoration(
          gradient: ThemeEffects.backgroundGradient,
        ),
        child: scaffold,
      );
    }
    
    return scaffold;
  }

  // بناء شريط العنوان
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return SoftAppBar(
      title: title,
      actions: actions,
      leading: showBackButton 
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: Theme.of(context).textTheme.titleLarge!.color,
              ),
              onPressed: onBackPressed ?? () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            )
          : null,
      backgroundColor: extendBodyBehindAppBar ? Colors.transparent : null,
    );
  }

  // بناء محتوى الشاشة مع تأثيرات اختيارية
  Widget _buildBody(BuildContext context) {
    Widget content = isScrollable
        ? SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: extendBodyBehindAppBar 
                ? EdgeInsets.only(
                    top: contentPadding.vertical / 2 + kToolbarHeight + MediaQuery.of(context).padding.top,
                    left: contentPadding.horizontal / 2,
                    right: contentPadding.horizontal / 2,
                    bottom: contentPadding.vertical / 2,
                  )
                : contentPadding,
            child: body,
          )
        : Padding(
            padding: extendBodyBehindAppBar 
                ? EdgeInsets.only(
                    top: contentPadding.vertical / 2 + kToolbarHeight + MediaQuery.of(context).padding.top,
                    left: contentPadding.horizontal / 2,
                    right: contentPadding.horizontal / 2,
                    bottom: contentPadding.vertical / 2,
                  )
                : contentPadding,
            child: body,
          );
    
    // إضافة SafeArea إذا لم يكن الجسم خلف شريط التطبيق
    if (!extendBodyBehindAppBar) {
      content = SafeArea(child: content);
    }

    // إضافة تأثيرات الرسوم المتحركة إذا كانت مفعلة
    if (useAnimations) {
      return _AnimatedContent(child: content);
    }
    
    return content;
  }
}

/// مكون مساعد لإضافة تأثيرات الحركة للمحتوى
class _AnimatedContent extends StatefulWidget {
  final Widget child;

  const _AnimatedContent({required this.child});

  @override
  State<_AnimatedContent> createState() => _AnimatedContentState();
}

class _AnimatedContentState extends State<_AnimatedContent> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد التحريك
    _animationController = AnimationController(
      duration: ThemeDurations.medium,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ThemeCurves.smooth,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ThemeCurves.smooth,
    ));
    
    // بدء التحريك
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// قالب شاشة مع خلفية نمطية
class PatternScreenTemplate extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final String? patternAsset;
  final double patternOpacity;

  const PatternScreenTemplate({
    Key? key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.patternAsset,
    this.patternOpacity = 0.05,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        // خلفية نمطية
        if (patternAsset != null)
          Positioned.fill(
            child: Opacity(
              opacity: patternOpacity,
              child: Image.asset(
                patternAsset!,
                repeat: ImageRepeat.repeat,
                color: isDark ? ThemeColors.primaryLight : ThemeColors.primary,
              ),
            ),
          ),
        
        // المحتوى الأساسي
        ScreenTemplate(
          title: title,
          body: body,
          showBackButton: showBackButton,
          actions: actions,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
          backgroundColor: Colors.transparent,
        ),
      ],
    );
  }
}