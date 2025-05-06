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
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
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
          // Icono con gradiente y sombra
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
          
          // Título con estilo mejorado
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kPrimary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Mensaje con mejor legibilidad
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
          
          // Botones con diseño mejorado
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón secundario
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
                    style: const TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Botón primario con gradiente
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