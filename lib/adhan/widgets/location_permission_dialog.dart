// lib/prayer/widgets/location_permission_dialog.dart
import 'package:flutter/material.dart';

class LocationPermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String primaryButtonText;
  final String secondaryButtonText;
  final VoidCallback onPrimaryButtonPressed;
  final VoidCallback onSecondaryButtonPressed;
  final IconData icon;

  const LocationPermissionDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    this.secondaryButtonText = 'إلغاء',
    required this.onPrimaryButtonPressed,
    required this.onSecondaryButtonPressed,
    this.icon = Icons.location_on,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final kPrimary = Theme.of(context).primaryColor;
    final kPrimaryLight = Theme.of(context).primaryColor.withOpacity(0.7);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with gradient and shadow effect
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary, kPrimaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 44,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title with improved style
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kPrimary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Message with better readability
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Buttons with improved design
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Secondary button
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondaryButtonPressed,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      secondaryButtonText,
                      style: TextStyle(
                        color: kPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Primary button with gradient
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimary, kPrimaryLight],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: onPrimaryButtonPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        primaryButtonText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showLocationPermissionDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String primaryButtonText,
  String secondaryButtonText = 'إلغاء',
  IconData icon = Icons.location_on,
}) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: LocationPermissionDialog(
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        icon: icon,
        onPrimaryButtonPressed: () => Navigator.of(context).pop(true),
        onSecondaryButtonPressed: () => Navigator.of(context).pop(false),
      ),
    ),
  ) ?? false;
}

Future<bool> showLocationServiceDialog(BuildContext context) {
  return showLocationPermissionDialog(
    context: context,
    title: 'تفعيل خدمة الموقع',
    message: 'تحتاج مواقيت الصلاة إلى تفعيل خدمة الموقع للحصول على أوقات دقيقة للصلاة في موقعك الحالي. هل ترغب في فتح إعدادات الموقع؟',
    primaryButtonText: 'فتح الإعدادات',
    secondaryButtonText: 'ليس الآن',
    icon: Icons.location_on,
  );
}

Future<bool> showLocationPermissionRationaleDialog(BuildContext context) {
  return showLocationPermissionDialog(
    context: context,
    title: 'إذن الوصول للموقع',
    message: 'يحتاج التطبيق إلى إذن الوصول لموقعك للحصول على مواقيت الصلاة الدقيقة في منطقتك. لن يتم مشاركة موقعك مع أي طرف ثالث.',
    primaryButtonText: 'السماح',
    secondaryButtonText: 'ليس الآن',
    icon: Icons.info_outline,
  );
}

Future<bool> showOpenAppSettingsDialog(BuildContext context) {
  return showLocationPermissionDialog(
    context: context,
    title: 'تغيير إعدادات التطبيق',
    message: 'تم رفض إذن الوصول للموقع بشكل دائم. يرجى فتح إعدادات التطبيق وتفعيل إذن الموقع يدوياً.',
    primaryButtonText: 'فتح الإعدادات',
    secondaryButtonText: 'ليس الآن',
    icon: Icons.settings,
  );
}

Future<bool> showDefaultLocationDialog(BuildContext context) {
  return showLocationPermissionDialog(
    context: context,
    title: 'استخدام الموقع الافتراضي',
    message: 'سيتم استخدام موقع افتراضي (مكة المكرمة) لحساب مواقيت الصلاة. هل تريد المحاولة مرة أخرى للحصول على موقعك الحالي؟',
    primaryButtonText: 'محاولة مرة أخرى',
    secondaryButtonText: 'استخدام الافتراضي',
    icon: Icons.location_city,
  );
}