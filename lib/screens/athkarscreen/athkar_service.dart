import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';

class AthkarService {
  // Singleton implementation
  static final AthkarService _instance = AthkarService._internal();
  factory AthkarService() => _instance;
  AthkarService._internal();

  // Cache for loaded athkar to avoid repeated file reads
  Map<String, AthkarCategory> _athkarCache = {};

  // Load athkar from JSON file
  Future<List<AthkarCategory>> loadAllAthkarCategories() async {
    try {
      // Read JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/data/athkar.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      List<AthkarCategory> categories = [];
      
      // Parse categories
      for (var categoryData in jsonData['categories']) {
        final category = _parseAthkarCategory(categoryData);
        categories.add(category);
        
        // Cache the category for faster access later
        _athkarCache[category.id] = category;
      }
      
      return categories;
    } catch (e) {
      print('Error loading athkar: $e');
      return [];
    }
  }

  // Get a specific category by ID
  Future<AthkarCategory?> getAthkarCategory(String categoryId) async {
    // Check if category is already in cache
    if (_athkarCache.containsKey(categoryId)) {
      return _athkarCache[categoryId];
    }
    
    // If not in cache, load all categories then return the specific one
    final categories = await loadAllAthkarCategories();
    final category = categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => throw Exception('Category not found: $categoryId'),
    );
    
    return category;
  }

  // Parse a single category from JSON
  AthkarCategory _parseAthkarCategory(Map<String, dynamic> data) {
    // Parse icon string to IconData
    final iconString = data['icon'] as String;
    final IconData iconData = _getIconFromString(iconString);
    
    // Parse color string to Color
    final colorString = data['color'] as String;
    final Color color = Color(_getColorFromHex(colorString));
    
    // Parse athkar list
    List<Thikr> athkarList = [];
    for (var thikrData in data['athkar']) {
      athkarList.add(Thikr(
        id: thikrData['id'],
        text: thikrData['text'],
        count: thikrData['count'],
        fadl: thikrData['fadl'],
        source: thikrData['source'],
      ));
    }
    
    // Create and return category
    return AthkarCategory(
      id: data['id'],
      title: data['title'],
      icon: iconData,
      color: color,
      description: data['description'],
      athkar: athkarList,
      notifyTime: data['notify_time'],
    );
  }
  
  // Convert hex color string to int color value
  int _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return int.parse('0x$hexColor');
  }
  
  // Convert icon string to IconData
  IconData _getIconFromString(String iconString) {
    // Map icon strings to IconData objects
    switch (iconString) {
      case 'Icons.wb_sunny': 
        return Icons.wb_sunny;
      case 'Icons.nightlight_round': 
        return Icons.nightlight_round;
      case 'Icons.bedtime': 
        return Icons.bedtime;
      case 'Icons.alarm': 
        return Icons.alarm;
      case 'Icons.mosque': 
        return Icons.mosque;
      case 'Icons.home': 
        return Icons.home;
      case 'Icons.restaurant': 
        return Icons.restaurant;
      case 'Icons.menu_book': 
        return Icons.menu_book;
      default: 
        return Icons.label_important;
    }
  }
  
  // Methods for favorites/counters
  
  // Check if a thikr is favorited
  Future<bool> isFavorite(String categoryId, int thikrIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'favorite_${categoryId}_$thikrIndex';
    return prefs.getBool(key) ?? false;
  }
  
  // Toggle favorite status
  Future<void> toggleFavorite(String categoryId, int thikrIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'favorite_${categoryId}_$thikrIndex';
    final currentValue = prefs.getBool(key) ?? false;
    await prefs.setBool(key, !currentValue);
  }
  
  // Get all favorites
  Future<List<FavoriteThikr>> getAllFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteKeys = prefs.getKeys().where((key) => key.startsWith('favorite_'));
    
    List<FavoriteThikr> favorites = [];
    
    for (final key in favoriteKeys) {
      final isFavorite = prefs.getBool(key) ?? false;
      if (isFavorite) {
        // Parse the key to get categoryId and thikrIndex
        final parts = key.split('_');
        if (parts.length >= 3) {
          final categoryId = parts[1];
          final thikrIndex = int.parse(parts[2]);
          
          // Load the category and thikr
          final category = await getAthkarCategory(categoryId);
          if (category != null && thikrIndex < category.athkar.length) {
            favorites.add(FavoriteThikr(
              category: category,
              thikr: category.athkar[thikrIndex],
              thikrIndex: thikrIndex
            ));
          }
        }
      }
    }
    
    return favorites;
  }
  
  // Get thikr count
  Future<int> getThikrCount(String categoryId, int thikrIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'count_${categoryId}_$thikrIndex';
    return prefs.getInt(key) ?? 0;
  }
  
  // Update thikr count
  Future<void> updateThikrCount(String categoryId, int thikrIndex, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'count_${categoryId}_$thikrIndex';
    await prefs.setInt(key, count);
  }

  // Get notification preferences
  Future<bool> getNotificationEnabled(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notification_${categoryId}_enabled';
    return prefs.getBool(key) ?? true; // Default to enabled
  }

  // Set notification preferences
  Future<void> setNotificationEnabled(String categoryId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notification_${categoryId}_enabled';
    await prefs.setBool(key, enabled);
  }

  // Get custom notification time (if user has set one)
  Future<String?> getCustomNotificationTime(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notification_${categoryId}_custom_time';
    return prefs.getString(key);
  }

  // Set custom notification time
  Future<void> setCustomNotificationTime(String categoryId, String time) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notification_${categoryId}_custom_time';
    await prefs.setString(key, time);
  }
}

// A class to represent a favorited thikr with its category
class FavoriteThikr {
  final AthkarCategory category;
  final Thikr thikr;
  final int thikrIndex;
  
  FavoriteThikr({
    required this.category,
    required this.thikr,
    required this.thikrIndex,
  });
}