// lib/app/themes/widgets/theme_widgets.dart
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:athkar_app/app/themes/glassmorphism_widgets.dart'; // Import glassmorphism widgets

/// حاوية خلفية متدرجة للشاشات
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool useAppBar;
  final List<Widget>? actions;
  final String? title;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar; // Added appBar directly

  const GradientBackground({
    Key? key,
    required this.child,
    this.useAppBar = true,
    this.actions,
    this.title,
    this.floatingActionButton,
    this.appBar, // Initialize appBar
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar ?? (useAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: title != null ? Text(title!) : null,
              centerTitle: true,
              actions: actions,
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
              titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
            )
          : null),
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeEffects.backgroundGradient,
        ),
        child: child,
      ),
    );
  }
}

/// زر بتأثير زجاجي
class GlassmorphicButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isOutlined;
  final bool isLoading; // Added isLoading
  final bool isFullWidth; // Added isFullWidth

  const GlassmorphicButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.opacity = 0.2,
    this.borderRadius = ThemeSizes.borderRadiusMedium,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.isOutlined = false,
    this.isLoading = false,
    this.isFullWidth = false, // Default to false for better flexibility
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdvancedGlassmorphicButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      opacity: opacity,
      borderRadius: borderRadius,
      padding: padding,
      isOutlined: isOutlined,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      blur: 5.0, // Consistent blur
      buttonColor: Theme.of(context).colorScheme.primary, // Use theme primary color
    );
  }
}

/// عنصر قائمة بالتأثير الزجاجي
class GlassmorphicListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double opacity;
  final Color? tileColor; // New parameter for list item background

  const GlassmorphicListItem({
    Key? key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.opacity = 0.15,
    this.tileColor, // Initialize tileColor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdvancedGlassmorphicCard( // Replaced Container with AdvancedGlassmorphicCard
      opacity: opacity,
      borderRadius: ThemeSizes.borderRadiusMedium,
      elevation: 0, // No elevation, handled by GlassmorphicCard if needed
      onTap: onTap != null ? () {
        HapticFeedback.selectionClick();
        onTap!();
      } : null,
      backgroundColor: tileColor, // Pass the background color
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginMedium,
          vertical: ThemeSizes.marginSmall / 2,
        ),
        child: Row(
          children: [
            if (leadingIcon != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.2), // Consistent surface color
                  borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusSmall),
                ),
                child: Icon(
                  leadingIcon,
                  color: Theme.of(context).iconTheme.color,
                  size: 24,
                ),
              ),
            if (leadingIcon != null) const SizedBox(width: ThemeSizes.marginMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: ThemeSizes.marginSmall),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}