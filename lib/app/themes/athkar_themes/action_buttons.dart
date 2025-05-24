// lib/app/themes/athkar_themes/action_buttons.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme_constants.dart';
import '../app_theme.dart';

/// زر إجراء قابل لإعادة الاستخدام مع خلفية شفافة
class ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final Color? backgroundColor;
  final bool isGradientBackground;
  final double iconSize;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool showBorder;
  final double borderOpacity;

  const ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.isGradientBackground = false,
    this.iconSize = 18,
    this.fontSize = 13,
    this.padding,
    this.borderRadius = ThemeSizes.borderRadiusCircular,
    this.showBorder = true,
    this.borderOpacity = 0.2,
  }) : super(key: key);

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
      setState(() => _isPressed = false);
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final Color effectiveColor = widget.color ?? 
        (widget.isGradientBackground ? Colors.white : AppTheme.getPrimaryColor(context));
    
    final Color effectiveBackgroundColor = widget.backgroundColor ??
        (widget.isGradientBackground 
            ? Colors.white.withOpacity(0.15) 
            : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)));

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              splashColor: effectiveColor.withOpacity(0.2),
              highlightColor: effectiveColor.withOpacity(0.1),
              child: Container(
                padding: widget.padding ?? const EdgeInsets.symmetric(
                  horizontal: ThemeSizes.marginMedium,
                  vertical: ThemeSizes.marginSmall,
                ),
                decoration: BoxDecoration(
                  color: effectiveBackgroundColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: widget.showBorder ? Border.all(
                    color: effectiveColor.withOpacity(widget.borderOpacity),
                    width: 1,
                  ) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      size: widget.iconSize,
                      color: effectiveColor,
                    ),
                    const SizedBox(width: ThemeSizes.marginSmall),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: effectiveColor,
                        fontWeight: FontWeight.w600,
                        fontSize: widget.fontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// مجموعة أزرار الإجراءات الخاصة بالأذكار
class AthkarActionButtons extends StatelessWidget {
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onInfo;
  final Color? color;
  final bool isGradientBackground;
  final MainAxisAlignment alignment;
  final double spacing;

  const AthkarActionButtons({
    Key? key,
    this.onCopy,
    this.onShare,
    this.onInfo,
    this.color,
    this.isGradientBackground = false,
    this.alignment = MainAxisAlignment.center,
    this.spacing = ThemeSizes.marginMedium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = [];

    if (onCopy != null) {
      buttons.add(
        ActionButton(
          icon: Icons.copy,
          label: 'نسخ',
          onPressed: onCopy!,
          color: color,
          isGradientBackground: isGradientBackground,
        ),
      );
    }

    if (onShare != null) {
      if (buttons.isNotEmpty) {
        buttons.add(SizedBox(width: spacing));
      }
      buttons.add(
        ActionButton(
          icon: Icons.share,
          label: 'مشاركة',
          onPressed: onShare!,
          color: color,
          isGradientBackground: isGradientBackground,
        ),
      );
    }

    if (onInfo != null) {
      if (buttons.isNotEmpty) {
        buttons.add(SizedBox(width: spacing));
      }
      buttons.add(
        ActionButton(
          icon: Icons.info_outline,
          label: 'فضل الذكر',
          onPressed: onInfo!,
          color: color,
          isGradientBackground: isGradientBackground,
        ),
      );
    }

    return Row(
      mainAxisAlignment: alignment,
      children: buttons,
    );
  }
}

/// زر دائري للإجراءات
class CircularActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;
  final bool showShadow;

  const CircularActionButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 48,
    this.tooltip,
    this.showShadow = true,
  }) : super(key: key);

  @override
  State<CircularActionButton> createState() => _CircularActionButtonState();
}

class _CircularActionButtonState extends State<CircularActionButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final Color effectiveColor = widget.color ?? AppTheme.getPrimaryColor(context);
    final Color effectiveBackgroundColor = widget.backgroundColor ??
        (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05));

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              shape: BoxShape.circle,
              boxShadow: widget.showShadow ? [
                BoxShadow(
                  color: effectiveColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _handleTap,
                customBorder: const CircleBorder(),
                splashColor: effectiveColor.withOpacity(0.3),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: effectiveColor,
                    size: widget.size * 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// شريط أزرار عائم
class FloatingActionBar extends StatelessWidget {
  final List<FloatingAction> actions;
  final Color? backgroundColor;
  final double height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool showShadow;

  const FloatingActionBar({
    Key? key,
    required this.actions,
    this.backgroundColor,
    this.height = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: ThemeSizes.marginMedium),
    this.borderRadius = ThemeSizes.borderRadiusCircular,
    this.showShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final Color effectiveBackgroundColor = backgroundColor ??
        (isDark 
            ? Colors.black.withOpacity(0.8) 
            : Colors.white.withOpacity(0.95));

    return Container(
      height: height,
      margin: padding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: actions.map((action) {
            return Expanded(
              child: InkWell(
                onTap: action.onPressed,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: ThemeSizes.marginSmall),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        action.icon,
                        color: action.isActive 
                            ? (action.activeColor ?? AppTheme.getPrimaryColor(context))
                            : AppTheme.getTextColor(context, isSecondary: true),
                        size: 24,
                      ),
                      if (action.label != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          action.label!,
                          style: TextStyle(
                            fontSize: 10,
                            color: action.isActive 
                                ? (action.activeColor ?? AppTheme.getPrimaryColor(context))
                                : AppTheme.getTextColor(context, isSecondary: true),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// نموذج بيانات لأزرار الشريط العائم
class FloatingAction {
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final bool isActive;
  final Color? activeColor;

  const FloatingAction({
    required this.icon,
    required this.onPressed,
    this.label,
    this.isActive = false,
    this.activeColor,
  });
}