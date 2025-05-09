// lib/services/notification_navigation.dart
import 'package:flutter/material.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/screen/athkar_details_screen.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/athkar_service.dart';

/// Helper class for handling navigation from notifications
class NotificationNavigation {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Navigate to the appropriate screen based on notification payload
  static Future<void> handleNotificationNavigation(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    
    // Extract category ID and any additional parameters
    final parts = payload.split(':');
    final categoryId = parts[0];
    
    // Get navigator context
    final context = navigatorKey.currentState?.context;
    if (context == null) return;
    
    // Load the Athkar category
    final AthkarService athkarService = AthkarService();
    final category = await athkarService.getAthkarCategory(categoryId);
    
    if (category != null) {
      // Navigate to Athkar details screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AthkarDetailsScreen(category: category),
        ),
      );
    }
  }
  
  /// Get the Athkar category icon based on ID
  static IconData getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return Icons.wb_sunny;
      case 'evening':
        return Icons.nightlight_round;
      case 'sleep':
        return Icons.bedtime;
      case 'wake':
        return Icons.alarm;
      case 'prayer':
        return Icons.mosque;
      case 'home':
        return Icons.home;
      case 'food':
        return Icons.restaurant;
      case 'quran':
        return Icons.menu_book;
      default:
        return Icons.notifications;
    }
  }
  
  /// Get the Athkar category color based on ID
  static Color getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const Color(0xFFFFD54F); // Yellow for morning
      case 'evening':
        return const Color(0xFFAB47BC); // Purple for evening
      case 'sleep':
        return const Color(0xFF5C6BC0); // Blue for sleep
      case 'wake':
        return const Color(0xFFFFB74D); // Orange for wake
      case 'prayer':
        return const Color(0xFF4DB6AC); // Teal for prayer
      case 'home':
        return const Color(0xFF66BB6A); // Green for home
      case 'food':
        return const Color(0xFFE57373); // Red for food
      case 'quran':
        return const Color(0xFF9575CD); // Light purple for Quran
      default:
        return const Color(0xFF447055); // Default app color
    }
  }
}