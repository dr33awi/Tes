// lib/core/utils/permission_util.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utilidad simple para gestionar permisos
class PermissionUtil {
  /// Solicita permiso de notificaciones
  static Future<bool> requestNotification(BuildContext context) async {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      final shouldOpen = await _showOpenSettingsDialog(
        context,
        'إذن الإشعارات',
        'تم رفض إذن الإشعارات بشكل دائم. يرجى فتح إعدادات التطبيق وتفعيل الإذن يدويًا.',
      );
      
      if (shouldOpen) {
        await openAppSettings();
      }
    }
    return status.isGranted;
  }
  
  /// Solicita permiso de ubicación
  static Future<bool> requestLocation(BuildContext context) async {
    final status = await Permission.location.request();
    if (status.isPermanentlyDenied) {
      final shouldOpen = await _showOpenSettingsDialog(
        context,
        'إذن الموقع',
        'تم رفض إذن الموقع بشكل دائم. يرجى فتح إعدادات التطبيق وتفعيل الإذن يدويًا.',
      );
      
      if (shouldOpen) {
        await openAppSettings();
      }
    }
    return status.isGranted;
  }
  
  /// Verifica el estado de los permisos principales
  static Future<Map<String, bool>> checkMainPermissions() async {
    return {
      'notification': await Permission.notification.isGranted,
      'location': await Permission.location.isGranted,
    };
  }
  
  /// Muestra un diálogo para abrir la configuración
  static Future<bool> _showOpenSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    ) ?? false;
  }
}