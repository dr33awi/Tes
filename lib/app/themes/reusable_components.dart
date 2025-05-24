// lib/app/themes/reusable_components.dart
import 'package:athkar_app/app/themes/glassmorphism_widgets.dart';
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// عنوان قسم متناسق مع الثيم
class ThemedSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onActionPressed;
  final IconData? actionIcon;
  final String? actionText;
  
  const ThemedSectionHeader({
    Key? key,
    required this.title,
    this.icon,
    this.onActionPressed,
    this.actionIcon,
    this.actionText,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSizes.marginSmall, 
        vertical: ThemeSizes.marginMedium,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
              ),
              child: Icon(
                icon,
                color: AppTheme.getPrimaryColor(context),
                size: 20,
              ),
            ),
            const SizedBox(width: ThemeSizes.marginMedium),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTheme.getHeadingStyle(context, fontSize: 18),
            ),
          ),
          if (onActionPressed != null) 
            TextButton.icon(
              icon: Icon(
                actionIcon ?? Icons.arrow_forward,
                size: 18,
              ),
              label: Text(actionText ?? ''),
              onPressed: () {
                HapticFeedback.lightImpact();
                onActionPressed!();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.getAccentColor(context),
                textStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// بطاقة معلومات أنيقة
class ThemedInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;
  
  const ThemedInfoCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.trailing,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(ThemeSizes.marginMedium),
      borderRadius: ThemeSizes.borderRadiusLarge,
      hasBorder: true,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (iconColor ?? AppTheme.getPrimaryColor(context)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppTheme.getPrimaryColor(context),
              size: 26,
            ),
          ),
          const SizedBox(width: ThemeSizes.marginMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.getBodyStyle(context, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ThemeSizes.marginXSmall),
                Text(
                  subtitle,
                  style: AppTheme.getBodyStyle(context, 
                    fontSize: 14, 
                    isSecondary: true,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) 
            trailing!
          else if (onTap != null)
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.getTextColor(context, isSecondary: true),
              size: 16,
            ),
        ],
      ),
    );
  }
}

/// زر شائع للتطبيق
class ThemedActionButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  
  const ThemedActionButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SoftButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      isOutlined: isOutlined,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}

/// قائمة عناصر مع تصميم أنيق
class ThemedListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  
  const ThemedListItem({
    Key? key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.trailing,
    this.iconColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// مؤشر التحميل المتوافق مع الثيم
class ThemedLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  
  const ThemedLoadingIndicator({
    Key? key,
    this.message,
    this.size = 40,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: AppTheme.getPrimaryColor(context),
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: ThemeSizes.marginLarge),
            Text(
              message!,
              style: AppTheme.getBodyStyle(context, isSecondary: true),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// أيقونة مع خلفية دائرية
class ThemedCircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  
  const ThemedCircleIcon({
    Key? key,
    required this.icon,
    this.size = 44,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppTheme.getPrimaryColor(context).withOpacity(0.1);
    final fgColor = iconColor ?? AppTheme.getPrimaryColor(context);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: fgColor,
        size: size * 0.5,
      ),
    );
  }
}

/// فاصل مع نص في المنتصف
class ThemedDividerWithText extends StatelessWidget {
  final String text;
  
  const ThemedDividerWithText({
    Key? key,
    required this.text,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ThemeSizes.marginMedium),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppTheme.getDividerColor(context),
              thickness: ThemeSizes.borderWidthThin,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ThemeSizes.marginMedium),
            child: Text(
              text,
              style: AppTheme.getCaptionStyle(context),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppTheme.getDividerColor(context),
              thickness: ThemeSizes.borderWidthThin,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة معلومات إحصائية
class ThemedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  
  const ThemedStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SoftStatCard(
      label: title,
      value: value,
      icon: icon,
      color: color ?? AppTheme.getPrimaryColor(context),
    );
  }
}

/// رسالة فارغة
class ThemedEmptyMessage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;
  
  const ThemedEmptyMessage({
    Key? key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.action,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ThemeSizes.marginLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ThemedCircleIcon(
              icon: icon,
              size: 80,
              backgroundColor: AppTheme.getSurfaceColor(context),
              iconColor: AppTheme.getTextColor(context, isSecondary: true),
            ),
            const SizedBox(height: ThemeSizes.marginLarge),
            Text(
              title,
              style: AppTheme.getHeadingStyle(context, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: ThemeSizes.marginSmall),
              Text(
                subtitle!,
                style: AppTheme.getBodyStyle(context, isSecondary: true),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: ThemeSizes.marginLarge),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// شريط التقدم الخطي
class ThemedLinearProgress extends StatelessWidget {
  final double value;
  final double height;
  final Color? backgroundColor;
  final Color? valueColor;
  final String? label;
  
  const ThemedLinearProgress({
    Key? key,
    required this.value,
    this.height = 8,
    this.backgroundColor,
    this.valueColor,
    this.label,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: AppTheme.getCaptionStyle(context),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: AppTheme.getCaptionStyle(context),
              ),
            ],
          ),
          const SizedBox(height: ThemeSizes.marginSmall),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: backgroundColor ?? AppTheme.getDividerColor(context),
            valueColor: AlwaysStoppedAnimation<Color>(
              valueColor ?? AppTheme.getPrimaryColor(context),
            ),
          ),
        ),
      ],
    );
  }
}

/// بطاقة التنبيه
class ThemedAlertCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;
  final VoidCallback? onClose;
  
  const ThemedAlertCard({
    Key? key,
    required this.message,
    required this.icon,
    this.color,
    this.onClose,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final alertColor = color ?? ThemeColors.info;
    
    return Container(
      padding: const EdgeInsets.all(ThemeSizes.marginMedium),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        border: Border.all(
          color: alertColor.withOpacity(0.3),
          width: ThemeSizes.borderWidthThin,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: alertColor,
            size: 24,
          ),
          const SizedBox(width: ThemeSizes.marginMedium),
          Expanded(
            child: Text(
              message,
              style: AppTheme.getBodyStyle(context, fontSize: 14),
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(
                Icons.close,
                color: AppTheme.getTextColor(context, isSecondary: true),
                size: 20,
              ),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}