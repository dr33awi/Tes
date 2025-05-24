// lib/app/widgets/empty_state_widget.dart
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';


class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final double iconSize;
  final Widget? action;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.iconSize = 80,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.synchronized(
      duration: ThemeDurations.medium,
      child: SlideAnimation(
        verticalOffset: 30.0,
        child: FadeInAnimation(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(ThemeSizes.marginLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // الأيقونة
                  Icon(
                    icon,
                    size: iconSize,
                    color: iconColor ?? 
                        AppTheme.getTextColor(context, isSecondary: true).withOpacity(0.5),
                  ),
                  
                  const SizedBox(height: ThemeSizes.marginMedium),
                  
                  // العنوان
                  Text(
                    title,
                    style: AppTheme.getHeadingStyle(context, fontSize: 18).copyWith(
                      color: iconColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  // العنوان الفرعي
                  if (subtitle != null) ...[
                    const SizedBox(height: ThemeSizes.marginSmall),
                    Text(
                      subtitle!,
                      style: AppTheme.getBodyStyle(context, isSecondary: true),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  // زر الإجراء
                  if (action != null) ...[
                    const SizedBox(height: ThemeSizes.marginLarge),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}