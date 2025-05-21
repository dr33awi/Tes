// lib/app/themes/reusable_components.dart
import 'package:athkar_app/app/themes/glassmorphism_widgets.dart';
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:athkar_app/app/themes/theme_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// عنوان قسم متناسق مع الثيم
class ThemedSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onActionPressed;
  final IconData? actionIcon;
  
  const ThemedSectionHeader({
    Key? key,
    required this.title,
    this.icon,
    this.onActionPressed,
    this.actionIcon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: ThemeSizes.marginSmall),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (onActionPressed != null && actionIcon != null)
            IconButton(
              icon: Icon(
                actionIcon,
                color: Colors.white.withOpacity(0.8),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                onActionPressed!();
              },
            ),
        ],
      ),
    );
  }
}

/// بطاقة معلومات زجاجية
class ThemedInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  
  const ThemedInfoCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AdvancedGlassmorphicCard(
      opacity: 0.1,
      borderRadius: ThemeSizes.borderRadiusLarge,
      elevation: 4,
      onTap: onTap != null ? () {
        HapticFeedback.lightImpact();
        onTap!();
      } : null,
      child: Padding(
        padding: const EdgeInsets.all(ThemeSizes.marginMedium),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: ThemeSizes.marginMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

/// زر شائع للتطبيق
class ThemedActionButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool isOutlined;
  final bool isLoading;
  final bool isFullWidth;
  
  const ThemedActionButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.color,
    this.isOutlined = false,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AdvancedGlassmorphicButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      isOutlined: isOutlined,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      opacity: 0.2,
      borderRadius: ThemeSizes.borderRadiusMedium,
      blur: 5.0,
    );
  }
}

/// قائمة عناصر مع تأثير زجاجي
class ThemedListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  
  const ThemedListItem({
    Key? key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.trailing,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GlassmorphicListItem(
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
      trailing: trailing,
      onTap: onTap,
      opacity: 0.15,
    );
  }
}

/// مؤشر التحميل المتوافق مع الثيم
class ThemedLoadingIndicator extends StatelessWidget {
  final String? message;
  
  const ThemedLoadingIndicator({
    Key? key,
    this.message,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: ThemeSizes.marginMedium),
            Text(
              message!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: iconColor ?? Colors.white,
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
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withOpacity(0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ThemeSizes.marginMedium),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

/// بطاقة معلومات إحصائية
class ThemedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  
  const ThemedStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? ThemeColors.primary;
    
    return AdvancedGlassmorphicCard(
      opacity: 0.15,
      borderRadius: ThemeSizes.borderRadiusLarge,
      borderColor: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(ThemeSizes.marginMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: ThemeSizes.marginSmall),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ThemeSizes.marginMedium),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}