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
  
  /// نوع التدرج اللوني للخلفية
  final Gradient? backgroundGradient;

  const ScreenTemplate({
    Key? key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.onBackPressed,
    this.useAnimations = true,
    this.isScrollable = true,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 20, 16, 16),
    this.backgroundGradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // تعيين نمط شريط الحالة
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // تكوين الخلفية المخصصة أو استخدام الخلفية الافتراضية
    final Gradient gradient = backgroundGradient ?? ThemeEffects.backgroundGradient;
    
    // الخلفية
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  // بناء شريط العنوان الزجاجي
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return GlassmorphicAppBar(
      title: title,
      actions: actions,
      leading: showBackButton 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackPressed ?? () {
                // تأثير اهتزاز خفيف عند الضغط
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            )
          : null,
    );
  }

  // بناء محتوى الشاشة مع تأثيرات اختيارية
  Widget _buildBody() {
    // المحتوى الأساسي
    Widget content = isScrollable
        ? SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: contentPadding,
            child: body,
          )
        : Padding(
            padding: contentPadding,
            child: body,
          );

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

class _AnimatedContentState extends State<_AnimatedContent> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد التحريك
    _animationController = AnimationController(
      duration: ThemeDurations.medium,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ThemeCurves.emphasize,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ThemeCurves.emphasize,
      ),
    );
    
    // بدء التحريك بعد ظهور الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}