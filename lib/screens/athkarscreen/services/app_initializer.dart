// lib/services/app_initializer.dart
import 'package:flutter/material.dart';

import 'package:test_athkar_app/screens/athkarscreen/services/notification_navigation.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/notification_service.dart';


/// Helper class to initialize app services
class AppInitializer {
  /// Initialize all app services
  static Future<void> initialize() async {
    // Initialize notification service
    await _initializeNotifications();
    
    // Initialize notification navigation
    await NotificationNavigation.initialize();
  }
  
  /// Initialize notification service
  static Future<void> _initializeNotifications() async {
    final notificationService = NotificationService();
    await notificationService.initialize();
  }
  
  /// Get navigator key for app
  static GlobalKey<NavigatorState> getNavigatorKey() {
    return NotificationNavigation.navigatorKey;
  }
}