// lib/app/themes/glassmorphism_widgets.dart
import 'dart:ui';
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// بطاقة ناعمة مع ظلال خفيفة
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final double elevation;
  final VoidCallback? onTap;
  final bool hasBorder;

  const SoftCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.borderRadius = ThemeSizes.borderRadiusMedium,
    this.backgroundColor,
    this.elevation = 0,
    this.onTap,
    this.hasBorder = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? 
        (isDark ? ThemeColors.darkCardBackground : ThemeColors.lightCardBackground);
    
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(
                color: isDark 
                    ? ThemeColors.primaryLight.withOpacity(0.1)
                    : ThemeColors.dividerColor,
                width: ThemeSizes.borderWidthThin,
              )
            : null,
        boxShadow: elevation > 0 ? ThemeEffects.lightCardShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap!();
                }
              : null,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: ThemeColors.primary.withOpacity(0.05),
          highlightColor: ThemeColors.primary.withOpacity(0.03),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// حاوية ناعمة مع تأثير خفيف
class SoftContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final bool hasShadow;
  final bool hasBorder;
  final Gradient? gradient;

  const SoftContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = ThemeSizes.borderRadiusMedium,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.hasShadow = false,
    this.hasBorder = false,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? 
            (isDark ? ThemeColors.darkCardBackground : ThemeColors.surface)) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(
                color: isDark 
                    ? ThemeColors.primaryLight.withOpacity(0.1)
                    : ThemeColors.dividerColor,
                width: ThemeSizes.borderWidthThin,
              )
            : null,
        boxShadow: hasShadow ? ThemeEffects.lightCardShadow : null,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// زر ناعم وأنيق
class SoftButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  final bool isOutlined;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final double? height;

  const SoftButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.isOutlined = false,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = ThemeSizes.borderRadiusMedium,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark ? ThemeColors.primaryLight : ThemeColors.primary;
    final defaultFgColor = isDark ? ThemeColors.darkBackground : Colors.white;
    
    Widget buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: foregroundColor ?? (isOutlined ? defaultBgColor : defaultFgColor),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? defaultBgColor,
          side: BorderSide(
            color: backgroundColor ?? defaultBgColor,
            width: ThemeSizes.borderWidthNormal,
          ),
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          minimumSize: isFullWidth
              ? Size(double.infinity, height ?? ThemeSizes.buttonHeight)
              : Size.zero,
        ),
        child: buttonContent,
      );
    } else {
      return ElevatedButton(
        onPressed: isLoading ? null : () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: foregroundColor ?? defaultFgColor,
          backgroundColor: backgroundColor ?? defaultBgColor,
          padding: padding,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          minimumSize: isFullWidth
              ? Size(double.infinity, height ?? ThemeSizes.buttonHeight)
              : Size.zero,
        ),
        child: buttonContent,
      );
    }
  }
}

/// شريط عنوان ناعم مع تأثير الشفافية
class SoftAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final double elevation;
  final Color? backgroundColor;
  final bool centerTitle;
  final double? titleSpacing;

  const SoftAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.elevation = 0,
    this.backgroundColor,
    this.centerTitle = true,
    this.titleSpacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
        ),
      ),
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      actions: actions,
      leading: leading,
      elevation: elevation,
      backgroundColor: backgroundColor ?? 
          (isDark ? ThemeColors.darkBackground : ThemeColors.lightBackground),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// بطاقة قائمة ناعمة
class SoftListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool dense;
  final Color? backgroundColor;
  final double borderRadius;

  const SoftListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leading,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.dense = false,
    this.backgroundColor,
    this.borderRadius = ThemeSizes.borderRadiusMedium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: ThemeSizes.marginXSmall,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? 
            (isDark ? ThemeColors.darkCardBackground : ThemeColors.surface),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark 
              ? ThemeColors.primaryLight.withOpacity(0.1)
              : ThemeColors.dividerColor,
          width: ThemeSizes.borderWidthThin,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap != null ? () {
            HapticFeedback.selectionClick();
            onTap!();
          } : null,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: ThemeColors.primary.withOpacity(0.05),
          highlightColor: ThemeColors.primary.withOpacity(0.03),
          child: ListTile(
            dense: dense,
            contentPadding: contentPadding ?? const EdgeInsets.symmetric(
              horizontal: ThemeSizes.marginMedium,
              vertical: ThemeSizes.marginSmall,
            ),
            leading: leading ?? (leadingIcon != null
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ThemeColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      leadingIcon,
                      color: ThemeColors.primary,
                      size: 22,
                    ),
                  )
                : null),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                    ),
                  )
                : null,
            trailing: trailing,
          ),
        ),
      ),
    );
  }
}

/// بطاقة معلومات احصائية ناعمة
class SoftStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final double? width;
  final double? height;

  const SoftStatCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? ThemeColors.primary;
    
    return SoftContainer(
      width: width,
      height: height,
      padding: const EdgeInsets.all(ThemeSizes.marginMedium),
      backgroundColor: isDark ? ThemeColors.darkCardBackground : Colors.white,
      hasBorder: true,
      borderRadius: ThemeSizes.borderRadiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
            ),
            child: Icon(
              icon,
              color: cardColor,
              size: 24,
            ),
          ),
          const SizedBox(height: ThemeSizes.marginMedium),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: ThemeSizes.marginXSmall),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// مؤشر تقدم دائري ناعم
class SoftCircularProgress extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? valueColor;
  final Widget? child;

  const SoftCircularProgress({
    Key? key,
    required this.value,
    this.size = 80,
    this.strokeWidth = 8,
    this.backgroundColor,
    this.valueColor,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor ?? 
                (isDark 
                    ? ThemeColors.primaryLight.withOpacity(0.2)
                    : ThemeColors.dividerColor),
            valueColor: AlwaysStoppedAnimation<Color>(
              valueColor ?? ThemeColors.primary,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// شريحة (Chip) ناعمة
class SoftChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool selected;
  final Color? backgroundColor;
  final Color? selectedColor;

  const SoftChip({
    Key? key,
    required this.label,
    this.icon,
    this.onPressed,
    this.selected = false,
    this.backgroundColor,
    this.selectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed != null ? () {
          HapticFeedback.lightImpact();
          onPressed!();
        } : null,
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusCircular),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSizes.marginMedium,
            vertical: ThemeSizes.marginSmall,
          ),
          decoration: BoxDecoration(
            color: selected 
                ? (selectedColor ?? ThemeColors.primary)
                : (backgroundColor ?? 
                    (isDark ? ThemeColors.darkCardBackground : ThemeColors.surface)),
            borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusCircular),
            border: Border.all(
              color: selected 
                  ? (selectedColor ?? ThemeColors.primary)
                  : (isDark 
                      ? ThemeColors.primaryLight.withOpacity(0.2)
                      : ThemeColors.dividerColor),
              width: ThemeSizes.borderWidthThin,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected 
                      ? Colors.white
                      : (isDark 
                          ? ThemeColors.darkTextPrimary 
                          : ThemeColors.lightTextPrimary),
                ),
                const SizedBox(width: ThemeSizes.marginSmall),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected 
                      ? Colors.white
                      : (isDark 
                          ? ThemeColors.darkTextPrimary 
                          : ThemeColors.lightTextPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// حقل إدخال ناعم
class SoftTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const SoftTextField({
    Key? key,
    this.labelText,
    this.hintText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16,
        color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: isDark 
                    ? ThemeColors.darkTextSecondary 
                    : ThemeColors.lightTextSecondary,
              )
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? ThemeColors.darkCardBackground : ThemeColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: BorderSide(
            color: isDark 
                ? ThemeColors.primaryLight.withOpacity(0.2)
                : ThemeColors.dividerColor,
            width: ThemeSizes.borderWidthThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: BorderSide(
            color: isDark 
                ? ThemeColors.primaryLight.withOpacity(0.2)
                : ThemeColors.dividerColor,
            width: ThemeSizes.borderWidthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: BorderSide(
            color: ThemeColors.primary,
            width: ThemeSizes.borderWidthNormal,
          ),
        ),
      ),
    );
  }
}