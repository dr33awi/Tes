// lib/app/themes/widgets/glassmorphism_widgets.dart
import 'dart:ui';
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// بطاقة زجاجية متطورة مع تأثير الضبابية
class AdvancedGlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color borderColor;
  final double elevation;
  final VoidCallback? onTap;

  const AdvancedGlassmorphicCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = ThemeSizes.borderRadiusMedium,
    this.blur = 10.0,
    this.opacity = 0.15,
    this.borderColor = Colors.white,
    this.elevation = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias, // هام للحفاظ على تأثير الضبابية
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blur,
              sigmaY: blur,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor.withOpacity(0.3),
                  width: ThemeSizes.borderWidthNormal,
                ),
              ),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// حاوية للتأثير الزجاجي الكامل
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color borderColor;
  final Color? backgroundColor;
  final double opacity;
  final bool border;

  const GlassmorphicContainer({
    Key? key,
    required this.child,
    required this.width,
    required this.height,
    this.borderRadius = ThemeSizes.borderRadiusMedium,
    this.blur = 10,
    this.padding = const EdgeInsets.all(8.0),
    this.margin = EdgeInsets.zero,
    this.borderColor = Colors.white,
    this.backgroundColor,
    this.opacity = 0.2,
    this.border = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color bgColor = backgroundColor ?? Colors.white;
    
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: bgColor.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border
                  ? Border.all(
                      color: borderColor.withOpacity(0.2),
                      width: 1.0,
                    )
                  : null,
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// زر زجاجي محسن
class AdvancedGlassmorphicButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isOutlined;
  final bool isLoading;
  final bool isFullWidth;
  final double blur;

  const AdvancedGlassmorphicButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.opacity = 0.2,
    this.borderRadius = ThemeSizes.borderRadiusMedium,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.isOutlined = false,
    this.isLoading = false,
    this.isFullWidth = false,
    this.blur = 5.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        if (isLoading) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    if (isOutlined) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.5)),
              padding: padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              backgroundColor: Colors.transparent,
              minimumSize: isFullWidth
                  ? const Size(double.infinity, ThemeSizes.buttonHeight)
                  : null,
            ),
            child: buttonContent,
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(opacity),
              padding: padding,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              minimumSize: isFullWidth
                  ? const Size(double.infinity, ThemeSizes.buttonHeight)
                  : null,
            ),
            child: buttonContent,
          ),
        ),
      );
    }
  }
}

/// شريط عنوان زجاجي مع تأثير الضبابية
class GlassmorphicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final double elevation;
  final double blur;
  final double opacity;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const GlassmorphicAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.elevation = 0,
    this.blur = 10.0,
    this.opacity = 0.15,
    this.systemOverlayStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: AppBar(
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: actions,
          leading: leading,
          elevation: elevation,
          backgroundColor: Colors.white.withOpacity(opacity),
          systemOverlayStyle: systemOverlayStyle ??
              const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// تأثير ضبابي للخلفية
class BlurredBackground extends StatelessWidget {
  final Widget child;
  final double blur;
  
  const BlurredBackground({
    Key? key,
    required this.child,
    this.blur = 10.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // الطبقة الخلفية - خلفية متدرجة
        Container(
          decoration: BoxDecoration(
            gradient: ThemeEffects.backgroundGradient,
          ),
        ),
        // طبقة الضبابية
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
          ),
          child: Container(
            color: Colors.transparent,
          ),
        ),
        // محتوى الشاشة
        child,
      ],
    );
  }
}