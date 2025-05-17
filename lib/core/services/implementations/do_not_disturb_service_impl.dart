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
  bool _isDoNotDisturbEnabled = false;
  
  @override
  Future<bool> isDoNotDisturbEnabled() async {
    try {
      if (Platform.isAndroid) {
        final bool? isDndEnabled = await _channel.invokeMethod<bool>('isDoNotDisturbEnabled');
        _isDoNotDisturbEnabled = isDndEnabled ?? false;
        return _isDoNotDisturbEnabled;
      } else if (Platform.isIOS) {
        // في نظام iOS، لا يمكن الوصول مباشرة لوضع عدم الإزعاج
        // يمكن استخدام طرق بديلة مثل معرفة إذا كان النظام يسمح بالإشعارات
        final bool? canSendNotifications = await _channel.invokeMethod<bool>('canSendNotifications');
        _isDoNotDisturbEnabled = !(canSendNotifications ?? true);
        return _isDoNotDisturbEnabled;
      }
      return false;
    } on PlatformException catch (e) {
      print('Error checking DND status: ${e.message}');
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
    } on PlatformException catch (e) {
      print('Error requesting DND permission: ${e.message}');
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
        if (event is bool) {
          _isDoNotDisturbEnabled = event;
          if (_onDoNotDisturbChange != null) {
            _onDoNotDisturbChange!(event);
          }
        }
      }, onError: (Object error) {
        print('Error in DND listener: $error');
      });
    } else if (Platform.isIOS) {
      // في iOS، يمكننا استخدام المستمع من خلال مراقبة حالة مركز الإشعارات
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
        print('Error in iOS DND listener: $error');
      });
    }
    
    // التأكد من وجود القيمة الأولية
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
    // التحقق مما إذا كان يجب تجاوز وضع عدم الإزعاج بناءً على نوع الإشعار
    if (!_isDoNotDisturbEnabled) {
      return true; // وضع عدم الإزعاج غير مفعل، يمكن إرسال الإشعار
    }
    
    switch (type) {
      case DoNotDisturbOverrideType.none:
        return false; // لا تجاوز
      case DoNotDisturbOverrideType.prayer:
        return true; // تجاوز لإشعارات الصلاة
      case DoNotDisturbOverrideType.importantAthkar:
        return true; // تجاوز للأذكار المهمة
      case DoNotDisturbOverrideType.critical:
        return true; // تجاوز للإشعارات الحرجة
      default:
        return false;
    }
  }
}