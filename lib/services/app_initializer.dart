// lib/screens/athkarscreen/services/app_initializer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_athkar_app/services/notification_navigation.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/notification_service.dart';


/// Helper class to initialize app services
class AppInitializer {
  /// Initialize all app services
  static Future<void> initialize() async {
    try {
      // Set screen orientation
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // Initialize notification service
      await _initializeNotifications();
      
      // Initialize notification navigation
      await NotificationNavigation.initialize();
      
      print("App initialization completed successfully");
    } catch (e) {
      print("Error initializing app: $e");
    }
  }
  
  /// Initialize notification service
  static Future<void> _initializeNotifications() async {
    try {
      print("Initializing notification services...");
      
      final notificationService = NotificationService();
      final initialized = await notificationService.initialize();
      
      if (initialized) {
        print("Notification service initialized successfully");
        
        // Re-schedule all saved notifications to ensure they're working
        await notificationService.scheduleAllSavedNotifications();
        
        // Check for pending notifications (debug info)
        final pendingNotifications = await notificationService.getPendingNotifications();
        print("Number of pending notifications: ${pendingNotifications.length}");
      } else {
        print("Failed to initialize notification service");
      }
    } catch (e) {
      print("Error initializing notifications: $e");
    }
  }
  
  /// Get navigator key for app
  static GlobalKey<NavigatorState> getNavigatorKey() {
    return NotificationNavigation.navigatorKey;
  }
  
  /// Check and reschedule notifications if needed
  static Future<void> checkAndRescheduleNotifications() async {
    try {
      print("Checking notification schedules...");
      
      final notificationService = NotificationService();
      await notificationService.scheduleAllSavedNotifications();
      
      print("Notification check completed");
    } catch (e) {
      print("Error checking notifications: $e");
    }
  }
}