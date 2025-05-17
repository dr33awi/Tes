// lib/core/services/implementations/do_not_disturb_service_impl.dart
import 'dart:async';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';
import '../interfaces/do_not_disturb_service.dart';

class DoNotDisturbServiceImpl implements DoNotDisturbService {
  static const MethodChannel _channel = MethodChannel('com.athkar.app/do_not_disturb');
  StreamSubscription<dynamic>? _subscription;
  Function(bool)? _onDoNotDisturbChange;
  
  @override
  Future<bool> isDoNotDisturbEnabled() async {
    try {
      if (Platform.isAndroid) {
        final bool? isDndEnabled = await _channel.invokeMethod<bool>('isDoNotDisturbEnabled');
        return isDndEnabled ?? false;
      } else if (Platform.isIOS) {
        // في نظام iOS، لا يمكن الوصول مباشرة لوضع عدم الإزعاج
        // يمكن استخدام طرق بديلة مثل معرفة إذا كان النظام يسمح بالإشعارات
        final bool? canSendNotifications = await _channel.invokeMethod<bool>('canSendNotifications');
        return !(canSendNotifications ?? true);
      }
      return false;
    } on PlatformException catch (_) {
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
        // iOS لا يحتاج إذن خاص لوضع عدم الإزعاج
        return true;
      }
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  @override
  Future<void> openDoNotDisturbSettings() async {
    if (Platform.isAndroid) {
      // استخدام الطريقة المناسبة في إصدار app_settings الحالي
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } else if (Platform.isIOS) {
      await AppSettings.openAppSettings();
    }
  }
  
  @override
  Future<void> registerDoNotDisturbListener(Function(bool) onDoNotDisturbChange) async {
    _onDoNotDisturbChange = onDoNotDisturbChange;
    
    if (Platform.isAndroid) {
      // إعداد مستمع لتغييرات وضع عدم الإزعاج في نظام Android
      _subscription = const EventChannel('com.athkar.app/do_not_disturb_events')
          .receiveBroadcastStream()
          .listen((dynamic event) {
        if (event is bool && _onDoNotDisturbChange != null) {
          _onDoNotDisturbChange!(event);
        }
      });
    } else if (Platform.isIOS) {
      // في iOS، يمكننا استخدام المستمع من خلال مراقبة حالة مركز الإشعارات
      _subscription = const EventChannel('com.athkar.app/notification_settings_events')
          .receiveBroadcastStream()
          .listen((dynamic event) {
        if (event is bool && _onDoNotDisturbChange != null) {
          _onDoNotDisturbChange!(event);
        }
      });
    }
  }
  
  @override
  Future<void> unregisterDoNotDisturbListener() async {
    await _subscription?.cancel();
    _subscription = null;
    _onDoNotDisturbChange = null;
  }
}