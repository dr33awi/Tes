// lib/adhan/notification_permission_dialog.dart
import 'package:flutter/material.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart' 
    show kPrimary, kPrimaryLight;

class NotificationPermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String primaryButtonText;
  final String secondaryButtonText;
  final VoidCallback onPrimaryButtonPressed;
  final VoidCallback onSecondaryButtonPressed;
  final IconData icon;

  const NotificationPermissionDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    this.secondaryButtonText = 'إلغاء',
    required this.onPrimaryButtonPressed,
    required this.onSecondaryButtonPressed,
    this.icon = Icons.notifications_active,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono en círculo con gradiente
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary, kPrimaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 40,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Título
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Mensaje
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón secundario
              OutlinedButton(
                onPressed: onSecondaryButtonPressed,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: kPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  secondaryButtonText,
                  style: const TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Botón primario
              ElevatedButton(
                onPressed: onPrimaryButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  elevation: 2,
                ),
                child: Text(
                  primaryButtonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Función para mostrar el diálogo de forma simplificada
Future<bool> showNotificationPermissionDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String primaryButtonText,
  String secondaryButtonText = 'إلغاء',
  IconData icon = Icons.notifications_active,
}) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: NotificationPermissionDialog(
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

// Diálogos predefinidos para diferentes escenarios

/// Diálogo para solicitar permisos de notificación
Future<bool> showNotificationRequestDialog(BuildContext context) {
  return showNotificationPermissionDialog(
    context: context,
    title: 'إذن الإشعارات',
    message: 'يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بأوقات الصلاة. هل ترغب في منح الإذن؟',
    primaryButtonText: 'السماح',
    secondaryButtonText: 'ليس الآن',
    icon: Icons.notifications_active,
  );
}

/// Diálogo para explicar por qué necesitamos permisos de notificación
Future<bool> showNotificationPermissionRationaleDialog(BuildContext context) {
  return showNotificationPermissionDialog(
    context: context,
    title: 'لماذا نحتاج إذن الإشعارات؟',
    message: 'يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بأوقات الصلاة وإرسال صوت الأذان. لن يتم استخدام هذا الإذن لأي غرض آخر.',
    primaryButtonText: 'السماح',
    secondaryButtonText: 'ليس الآن',
    icon: Icons.info_outline,
  );
}

/// Diálogo para abrir la configuración de notificaciones
Future<bool> showOpenNotificationSettingsDialog(BuildContext context) {
  return showNotificationPermissionDialog(
    context: context,
    title: 'فتح إعدادات الإشعارات',
    message: 'تم رفض إذن الإشعارات. يرجى فتح إعدادات التطبيق وتمكين الإشعارات يدويًا لتلقي تنبيهات أوقات الصلاة.',
    primaryButtonText: 'فتح الإعدادات',
    secondaryButtonText: 'ليس الآن',
    icon: Icons.settings_applications,
  );
}