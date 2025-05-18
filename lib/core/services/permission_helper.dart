// lib/core/services/permission_helper.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

/// Clase auxiliar para manejar permisos de manera simple
class PermissionHelper {
  /// Solicita permiso de notificaciones con diálogo explicativo
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    // Verificar si ya tenemos el permiso
    PermissionStatus status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }
    
    // Mostrar diálogo explicativo
    bool shouldRequest = await _showPermissionDialog(
      context,
      title: 'إذن الإشعارات',
      message: 'يحتاج التطبيق إلى إذن الإشعارات لإرسال تنبيهات بأوقات الصلاة والأذكار.',
      importance: 'بدون هذا الإذن، لن تتلقى تذكيرات بمواعيد الصلاة والأذكار اليومية.',
    );
    
    if (!shouldRequest) {
      return false;
    }
    
    // Solicitar permiso
    status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Solicita permiso de ubicación con diálogo explicativo
  static Future<bool> requestLocationPermission(BuildContext context) async {
    // Verificar si ya tenemos el permiso
    PermissionStatus status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    }
    
    // Mostrar diálogo explicativo
    bool shouldRequest = await _showPermissionDialog(
      context,
      title: 'إذن الموقع',
      message: 'يحتاج التطبيق إلى إذن الموقع لتحديد اتجاه القبلة ومواقيت الصلاة بدقة.',
      importance: 'بدون هذا الإذن، سيتم استخدام موقع افتراضي أقل دقة.',
    );
    
    if (!shouldRequest) {
      return false;
    }
    
    // Solicitar permiso
    status = await Permission.location.request();
    return status.isGranted;
  }
  
  /// Verifica el estado actual de un permiso específico
  static Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return await permission.status;
  }
  
  /// Abre la configuración de la aplicación para permisos
  static Future<void> openAppSettings() async {
    await AppSettings.openAppSettings();
  }
  
  /// Abre la configuración de ubicación
  static Future<void> openLocationSettings() async {
    await AppSettings.openLocationSettings();
  }
  
  /// Abre la configuración de notificaciones
  static Future<void> openNotificationSettings() async {
    await AppSettings.openNotificationSettings();
  }
  
  /// Muestra un diálogo explicando por qué se necesita un permiso
  static Future<bool> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String importance,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Text(
              importance,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لاحقًا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('السماح'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Verifica el estado de todos los permisos importantes
  static Future<Map<String, PermissionStatus>> checkAllPermissions() async {
    return {
      'notification': await Permission.notification.status,
      'location': await Permission.location.status,
      'battery': await Permission.ignoreBatteryOptimizations.status,
      'doNotDisturb': await Permission.accessNotificationPolicy.status,
    };
  }
}