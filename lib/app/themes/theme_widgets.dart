// lib/app/themes/widgets/theme_widgets.dart
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// حاوية خلفية متدرجة للشاشات
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool useAppBar;
  final List<Widget>? actions;
  final String? title;
  final Widget? floatingActionButton;

  const GradientBackground({
    Key? key,
    required this.child,
    this.useAppBar = true,
    this.actions,
    this.title,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: useAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: title != null ? Text(title!) : null,
              centerTitle: true,
              actions: actions,
            )
          : null,
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

  const GlassmorphicButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.opacity = 0.2,
    this.borderRadius = ThemeSizes.borderRadiusMedium,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.5)),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            backgroundColor: Colors.transparent,
          )
        : ElevatedButton.styleFrom(
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
          );

    return icon != null
        ? ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact(); // تأثير اهتزاز متوسط عند الضغط
              onPressed();
            },
            icon: Icon(icon),
            label: Text(text),
            style: buttonStyle,
          )
        : ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact(); // تأثير اهتزاز متوسط عند الضغط
              onPressed();
            },
            style: buttonStyle,
            child: Text(text),
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

  const GlassmorphicListItem({
    Key? key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.opacity = 0.15,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: ThemeSizes.marginSmall / 2,
        horizontal: ThemeSizes.marginMedium,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: ListTile(
        onTap: onTap != null ? () {
          HapticFeedback.selectionClick(); // تأثير اهتزاز عند النقر
          onTap!();
        } : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginMedium,
          vertical: ThemeSizes.marginSmall / 2,
        ),
        leading: leadingIcon != null
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  leadingIcon,
                  color: Colors.white,
                  size: 22,
                ),
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              )
            : null,
        trailing: trailing,
      ),
    );
  }
}

/// قسم مع عنوان
class SectionWithTitle extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool withDivider;

  const SectionWithTitle({
    Key? key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(ThemeSizes.marginMedium),
    this.withDivider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSizes.marginMedium,
            vertical: ThemeSizes.marginSmall,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (withDivider)
          Divider(
            color: Colors.white.withOpacity(0.2),
            thickness: 1,
            indent: ThemeSizes.marginMedium,
            endIndent: ThemeSizes.marginMedium,
          ),
        Padding(
          padding: padding,
          child: child,
        ),
      ],
    );
  }
}

/// بطاقة للصلاة مع تأثيرات خاصة
class PrayerTimeCard extends StatelessWidget {
  final String prayerName;
  final String prayerTime;
  final bool isCurrentPrayer;
  final bool isNextPrayer;
  final IconData icon;

  const PrayerTimeCard({
    Key? key,
    required this.prayerName,
    required this.prayerTime,
    this.isCurrentPrayer = false,
    this.isNextPrayer = false,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: ThemeSizes.marginSmall / 2,
        horizontal: ThemeSizes.marginMedium,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isCurrentPrayer ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(isCurrentPrayer ? 0.5 : 0.3),
          width: isCurrentPrayer ? 1.5 : 0.5,
        ),
        boxShadow: isCurrentPrayer
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginMedium,
          vertical: ThemeSizes.marginMedium,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: ThemeSizes.marginMedium),
                Text(
                  prayerName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: isCurrentPrayer ? FontWeight.bold : FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ThemeSizes.marginMedium,
                vertical: ThemeSizes.marginSmall,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
              ),
              child: Text(
                prayerTime,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}