// lib/core/services/implementations/do_not_disturb_service_impl.dart
import 'dart:async';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../interfaces/do_not_disturb_service.dart';

class DoNotDisturbServiceImpl implements DoNotDisturbService {
  static const MethodChannel _channel = MethodChannel('com.athkar.app/do_not_disturb');
  static const EventChannel _eventChannel = EventChannel('com.athkar.app/do_not_disturb_events');
  
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
        // تحسين: محاولة فتح إعدادات وضع عدم الإزعاج مباشرة بناءً على إصدار النظام
        bool opened = false;
        
        // أولاً، نحاول استخدام الطريقة المحددة في القناة
        try {
          final result = await _channel.invokeMethod<bool>('openDoNotDisturbSettings');
          opened = result ?? false;
        } catch (e) {
          debugPrint('Error opening DND settings via method channel: $e');
        }
        
        // إذا لم تنجح الطريقة الأولى، نستخدم طرق بديلة حسب إصدار Android
        if (!opened) {
          // حسب إصدار Android، نحاول فتح الصفحة المناسبة مباشرة
          final androidVersion = await _getAndroidVersion();
          
          if (androidVersion >= 12) {
            // Android 12 وما فوق - نحاول فتح صفحة الاستثناءات مباشرة
            await AppSettings.openAppSettings(type: AppSettingsType.notificationSettings);
          } else if (androidVersion >= 10) {
            // Android 10-11
            await AppSettings.openAppSettings(type: AppSettingsType.dndAccess);
          } else {
            // لإصدارات أقدم، نفتح إعدادات التطبيق العامة
            await AppSettings.openAppSettings();
          }
        }
      } else if (Platform.isIOS) {
        // في iOS، نفتح إعدادات التطبيق العامة
        await AppSettings.openAppSettings();
      }
      
      // بعد فتح الإعدادات، نعطي وقتاً للتأخير ثم نعيد التحقق من الحالة
      await Future.delayed(const Duration(seconds: 1));
      final bool isDndEnabled = await isDoNotDisturbEnabled();
      if (_onDoNotDisturbChange != null) {
        _onDoNotDisturbChange!(isDndEnabled);
      }
    } catch (e) {
      debugPrint('Error opening DND settings: $e');
      // كخطة بديلة، نفتح إعدادات التطبيق العامة
      await AppSettings.openAppSettings();
    }
  }
  
  // طريقة مساعدة للحصول على إصدار Android
  Future<int> _getAndroidVersion() async {
    try {
      if (!Platform.isAndroid) return 0;
      
      final androidVersion = await _channel.invokeMethod<String>('getAndroidVersion');
      if (androidVersion == null) return 0;
      
      // تحويل النسخة من نمط "X.Y.Z" إلى رقم
      final major = int.tryParse(androidVersion.split('.').first) ?? 0;
      return major;
    } catch (e) {
      debugPrint('Error getting Android version: $e');
      return 0; // القيمة الافتراضية
    }
  }
  
  @override
  Future<void> registerDoNotDisturbListener(Function(bool) onDoNotDisturbChange) async {
    _onDoNotDisturbChange = onDoNotDisturbChange;
    
    if (Platform.isAndroid) {
      // Configurar un receptor para cambios en el modo No molestar en Android
      _subscription = _eventChannel
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