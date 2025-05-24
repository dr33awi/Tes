// lib/app/widgets/athkar_snackbar.dart
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:flutter/material.dart';


class AthkarSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    required IconData icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    EdgeInsetsGeometry? margin,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        ),
        margin: margin ?? const EdgeInsets.all(ThemeSizes.marginMedium),
        duration: duration,
      ),
    );
  }

  // رسائل جاهزة شائعة الاستخدام
  static void showSuccess({
    required BuildContext context,
    required String message,
    Color? backgroundColor,
  }) {
    show(
      context: context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: backgroundColor ?? Colors.green,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
  }) {
    show(
      context: context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Colors.red,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Color? backgroundColor,
  }) {
    show(
      context: context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: backgroundColor,
    );
  }

  static void showFavoriteAdded(BuildContext context, {Color? backgroundColor}) {
    show(
      context: context,
      message: 'تمت الإضافة إلى المفضلة',
      icon: Icons.favorite,
      backgroundColor: backgroundColor,
    );
  }

  static void showFavoriteRemoved(BuildContext context, {Color? backgroundColor}) {
    show(
      context: context,
      message: 'تمت الإزالة من المفضلة',
      icon: Icons.favorite_border,
      backgroundColor: backgroundColor,
    );
  }

  static void showCopied(BuildContext context, {Color? backgroundColor}) {
    show(
      context: context,
      message: 'تم نسخ الذكر إلى الحافظة',
      icon: Icons.check_circle,
      backgroundColor: backgroundColor,
    );
  }

  static void showCompleted(BuildContext context, {Color? backgroundColor}) {
    show(
      context: context,
      message: 'تم إكمال هذا الذكر',
      icon: Icons.check_circle,
      backgroundColor: backgroundColor,
    );
  }

  static void showReset(BuildContext context, {Color? backgroundColor}) {
    show(
      context: context,
      message: 'تمت إعادة تهيئة جميع الأذكار',
      icon: Icons.refresh,
      backgroundColor: backgroundColor,
    );
  }
}