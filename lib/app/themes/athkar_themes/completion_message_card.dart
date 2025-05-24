// lib/app/widgets/completion_message_card.dart
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/app/themes/glassmorphism_widgets.dart';
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class CompletionMessageCard extends StatelessWidget {
  final String title;
  final String message;
  final String? subMessage;
  final IconData icon;
  final Color primaryColor;
  final VoidCallback onResetPressed;
  final VoidCallback onBackPressed;
  final String resetButtonText;
  final String backButtonText;
  final IconData? resetButtonIcon;
  final IconData? backButtonIcon;

  const CompletionMessageCard({
    Key? key,
    this.title = 'أحسنت!',
    this.message = 'لقد أتممت جميع الأذكار بحمد الله',
    this.subMessage = 'تقبل الله منك، وجزاك الله خيراً',
    this.icon = Icons.check_circle_outline,
    required this.primaryColor,
    required this.onResetPressed,
    required this.onBackPressed,
    this.resetButtonText = 'قراءتها مرة أخرى',
    this.backButtonText = 'العودة إلى أقسام الأذكار',
    this.resetButtonIcon = Icons.replay_rounded,
    this.backButtonIcon = Icons.home_rounded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.synchronized(
      duration: ThemeDurations.verySlow,
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: SoftCard(
            borderRadius: ThemeSizes.borderRadiusLarge,
            hasBorder: true,
            elevation: 4,
            padding: const EdgeInsets.all(ThemeSizes.marginXLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة الإتمام
                _buildCompletionIcon(),
                const SizedBox(height: ThemeSizes.marginLarge),
                
                // العنوان
                Text(
                  title,
                  style: AppTheme.getHeadingStyle(context, fontSize: 26),
                ),
                const SizedBox(height: ThemeSizes.marginMedium),
                
                // الرسالة الرئيسية
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTheme.getBodyStyle(context, fontSize: 18),
                ),
                
                // الرسالة الفرعية
                if (subMessage != null) ...[
                  const SizedBox(height: ThemeSizes.marginSmall),
                  Text(
                    subMessage!,
                    textAlign: TextAlign.center,
                    style: AppTheme.getBodyStyle(context, fontSize: 18, isSecondary: true),
                  ),
                ],
                
                const SizedBox(height: ThemeSizes.marginLarge),
                
                // الأزرار
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        color: primaryColor,
        size: 50,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // زر إعادة القراءة
        SoftButton(
          text: resetButtonText,
          icon: resetButtonIcon,
          onPressed: onResetPressed,
          isFullWidth: true,
          backgroundColor: primaryColor,
          borderRadius: ThemeSizes.borderRadiusMedium,
        ),
        
        const SizedBox(height: ThemeSizes.marginMedium),
        
        // زر العودة
        SoftButton(
          text: backButtonText,
          icon: backButtonIcon,
          onPressed: onBackPressed,
          isOutlined: true,
          isFullWidth: true,
          borderRadius: ThemeSizes.borderRadiusMedium,
        ),
      ],
    );
  }
}