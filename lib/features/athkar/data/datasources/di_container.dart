// lib/services/di_container.dart - إضافة مضمنة لخدمة الأذكار

import 'package:athkar_app/features/athkar/data/datasources/athkar_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';


// استخدام نفس مثيل GetIt الذي تم إنشاؤه في ملف app/di/service_locator.dart
final serviceLocator = GetIt.instance;

// تهيئة الخدمات المطلوبة للأذكار
class ServiceLocatorAthkar {
  static void setupAthkarServices() {
    // تسجيل خدمة الأذكار إذا لم تكن مسجلة مسبقاً
    if (!serviceLocator.isRegistered<AthkarService>()) {
      serviceLocator.registerSingleton<AthkarService>(AthkarService());
      debugPrint('تم تسجيل خدمة الأذكار بنجاح');
    }
  }
}