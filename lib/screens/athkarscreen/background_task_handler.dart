// lib/services/background_task_handler.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/screen/athkar_details_screen.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/athkar_service.dart';

/// Simple handler for background notifications and navigation
class BackgroundTaskHandler {
  /// Check if the app was opened from a notification
  static Future<bool> checkNotificationOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('opened_from_notification') ?? false;
    } catch (e) {
      print('Error checking notification open: $e');
      return false;
    }
  }
  
  /// Get the notification payload that opened the app
  static Future<String?> getNotificationPayload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('notification_payload');
    } catch (e) {
      print('Error getting notification payload: $e');
      return null;
    }
  }
  
  /// Clear notification open data
  static Future<void> clearNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('opened_from_notification', false);
      await prefs.remove('notification_payload');
    } catch (e) {
      print('Error clearing notification data: $e');
    }
  }
  
  /// Navigate to the appropriate screen based on notification payload
  static Future<void> handleNotificationNavigation(
      BuildContext context, String payload) async {
    try {
      // Extract category ID
      final parts = payload.split(':');
      final categoryId = parts[0];
      
      // Load athkar category
      final athkarService = AthkarService();
      final category = await athkarService.getAthkarCategory(categoryId);
      
      if (category != null) {
        // Navigate to athkar details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AthkarDetailsScreen(category: category),
          ),
        );
      }
    } catch (e) {
      print('Error handling notification navigation: $e');
    }
  }
}