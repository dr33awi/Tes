// lib/core/services/implementations/do_not_disturb_service_impl.dart
import 'dart:async';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../interfaces/do_not_disturb_service.dart';

class DoNotDisturbServiceImpl implements DoNotDisturbService {
  static const MethodChannel _channel = MethodChannel('com.athkar.app/do_not_disturb');
  StreamSubscription<dynamic>? _subscription;
  Function(bool)? _onDoNotDisturbChange;
  bool _isDoNotDisturbEnabled = false;
  
  @override
  Future<bool> isDoNotDisturbEnabled() async {
    try {
      if (Platform.isAndroid) {
        final bool? isDndEnabled = await _channel.invokeMethod<bool>('isDoNotDisturbEnabled');
        _isDoNotDisturbEnabled = isDndEnabled ?? false;
        return _isDoNotDisturbEnabled;
      } else if (Platform.isIOS) {
        // En iOS, no se puede acceder directamente al modo No molestar
        // Podemos usar métodos alternativos como verificar si las notificaciones están permitidas
        final bool? canSendNotifications = await _channel.invokeMethod<bool>('canSendNotifications');
        _isDoNotDisturbEnabled = !(canSendNotifications ?? true);
        return _isDoNotDisturbEnabled;
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint('Error checking DND status: ${e.message}');
      return false;
    }
  }
  
  @override
  Future<bool> requestDoNotDisturbPermission() async {
    try {
      if (Platform.isAndroid) {
        final bool? granted = await _channel.invokeMethod<bool>('requestDoNotDisturbPermission');
        return granted ?? false;
      } else {
        // iOS no necesita un permiso específico para el modo No molestar
        return true;
      }
    } on PlatformException catch (e) {
      debugPrint('Error requesting DND permission: ${e.message}');
      return false;
    }
  }
  
  @override
  Future<void> openDoNotDisturbSettings() async {
    try {
      if (Platform.isAndroid) {
        // Primero intenta usar el método del canal para abrir la configuración específica
        final bool? opened = await _channel.invokeMethod<bool>('openDoNotDisturbSettings');
        
        // Si no funciona, usa AppSettings
        if (!(opened ?? false)) {
          await AppSettings.openAppSettings(type: AppSettingsType.notification);
        }
      } else if (Platform.isIOS) {
        // En iOS, abre la configuración general de la aplicación
        await AppSettings.openAppSettings();
      }
      
      // Después de abrir la configuración, damos un pequeño delay
      // y luego verificamos nuevamente el estado
      await Future.delayed(const Duration(seconds: 1));
      final bool isDndEnabled = await isDoNotDisturbEnabled();
      if (_onDoNotDisturbChange != null) {
        _onDoNotDisturbChange!(isDndEnabled);
      }
    } catch (e) {
      debugPrint('Error opening DND settings: $e');
      // Como fallback, abre la configuración general de la app
      await AppSettings.openAppSettings();
    }
  }
  
  @override
  Future<void> registerDoNotDisturbListener(Function(bool) onDoNotDisturbChange) async {
    _onDoNotDisturbChange = onDoNotDisturbChange;
    
    if (Platform.isAndroid) {
      // Configurar un receptor para cambios en el modo No molestar en Android
      _subscription = const EventChannel('com.athkar.app/do_not_disturb_events')
          .receiveBroadcastStream()
          .listen((dynamic event) {
        if (event is bool) {
          _isDoNotDisturbEnabled = event;
          if (_onDoNotDisturbChange != null) {
            _onDoNotDisturbChange!(event);
          }
        }
      }, onError: (Object error) {
        debugPrint('Error in DND listener: $error');
      });
    } else if (Platform.isIOS) {
      // En iOS, podemos observar cambios en la configuración del centro de notificaciones
      _subscription = const EventChannel('com.athkar.app/notification_settings_events')
          .receiveBroadcastStream()
          .listen((dynamic event) {
        if (event is bool) {
          _isDoNotDisturbEnabled = event;
          if (_onDoNotDisturbChange != null) {
            _onDoNotDisturbChange!(event);
          }
        }
      }, onError: (Object error) {
        debugPrint('Error in iOS DND listener: $error');
      });
    }
    
    // Obtener el estado inicial
    final currentStatus = await isDoNotDisturbEnabled();
    if (_onDoNotDisturbChange != null && currentStatus != _isDoNotDisturbEnabled) {
      _isDoNotDisturbEnabled = currentStatus;
      _onDoNotDisturbChange!(currentStatus);
    }
  }
  
  @override
  Future<void> unregisterDoNotDisturbListener() async {
    await _subscription?.cancel();
    _subscription = null;
    _onDoNotDisturbChange = null;
  }
  
  @override
  Future<bool> shouldOverrideDoNotDisturb(DoNotDisturbOverrideType type) async {
    // Verificar si debemos anular el modo No molestar según el tipo de notificación
    if (!_isDoNotDisturbEnabled) {
      return true; // El modo No molestar está desactivado, se pueden enviar notificaciones
    }
    
    switch (type) {
      case DoNotDisturbOverrideType.none:
        return false; // No anular
      case DoNotDisturbOverrideType.prayer:
        return true; // Anular para notificaciones de oración
      case DoNotDisturbOverrideType.importantAthkar:
        return true; // Anular para adhkar importantes
      case DoNotDisturbOverrideType.critical:
        return true; // Anular para notificaciones críticas
      default:
        return false;
    }
  }
}