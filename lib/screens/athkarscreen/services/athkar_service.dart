// lib/screens/athkarscreen/services/athkar_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/screens/athkarscreen/model/athkar_model.dart';
import 'package:test_athkar_app/services/notification_facade.dart';

class AthkarService {
  // Singleton implementation
  static final AthkarService _instance = AthkarService._internal();
  factory AthkarService() => _instance;
  AthkarService._internal();

  // Cache for loaded athkar to avoid repeated file reads
  Map<String, AthkarCategory> _athkarCache = {};
  
  // استخدام NotificationFacade
  final NotificationFacade _notificationFacade = NotificationFacade.instance;

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

  // Get a specific category by ID with improved caching
  Future<AthkarCategory?> getAthkarCategory(String categoryId) async {
    // Check if category is already in cache
    if (_athkarCache.containsKey(categoryId)) {
      return _athkarCache[categoryId];
    }
    
    try {
      // If not in cache, load all categories then return the specific one
      final categories = await loadAllAthkarCategories();
      final category = categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => throw Exception('Category not found: $categoryId'),
      );
      
      return category;
    } catch (e) {
      print('Error getting category $categoryId: $e');
      return null;
    }
  }

  // Parse a single category from JSON with enhanced icon and color handling
  AthkarCategory _parseAthkarCategory(Map<String, dynamic> data) {
    // Parse icon string to IconData
    final iconString = data['icon'] as String;
    final IconData iconData = _getIconFromString(iconString);
    
    // Parse color string to Color
    final colorString = data['color'] as String;
    final Color color = Color(_getColorFromHex(colorString));
    
    // Parse athkar list
    List<Thikr> athkarList = [];
    if (data['athkar'] != null) {
      for (var thikrData in data['athkar']) {
        athkarList.add(Thikr(
          id: thikrData['id'],
          text: thikrData['text'],
          count: thikrData['count'],
          fadl: thikrData['fadl'],
          source: thikrData['source'],
          isQuranVerse: thikrData['is_quran_verse'] ?? false,
          surahName: thikrData['surah_name'],
          verseNumbers: thikrData['verse_numbers'],
          audioUrl: thikrData['audio_url'],
        ));
      }
    }
    
    // Create and return category with notification properties
    return AthkarCategory(
      id: data['id'],
      title: data['title'],
      icon: iconData,
      color: color,
      description: data['description'],
      athkar: athkarList,
      notifyTime: data['notify_time'],
      notifyTitle: data['notify_title'],
      notifyBody: data['notify_body'],
      hasMultipleReminders: data['has_multiple_reminders'] ?? false,
      additionalNotifyTimes: data['additional_notify_times'] != null 
        ? List<String>.from(data['additional_notify_times']) 
        : null,
    );
  }
  
  // Convert hex color string to int color value with better error handling
  int _getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF' + hexColor;
      }
      return int.parse('0x$hexColor');
    } catch (e) {
      print('Error parsing color: $e');
      return 0xFF447055; // Default to app primary color if there's an error
    }
  }
  
  // Enhanced icon mapping with more options
  IconData _getIconFromString(String iconString) {
    // Map icon strings to IconData objects
    Map<String, IconData> iconMap = {
      'Icons.wb_sunny': Icons.wb_sunny,
      'Icons.nightlight_round': Icons.nightlight_round,
      'Icons.bedtime': Icons.bedtime,
      'Icons.alarm': Icons.alarm,
      'Icons.mosque': Icons.mosque,
      'Icons.home': Icons.home,
      'Icons.restaurant': Icons.restaurant,
      'Icons.menu_book': Icons.menu_book,
      'Icons.favorite': Icons.favorite,
      'Icons.star': Icons.star,
      'Icons.water_drop': Icons.water_drop,
      'Icons.insights': Icons.insights,
      'Icons.travel_explore': Icons.travel_explore,
      'Icons.healing': Icons.healing,
      'Icons.family_restroom': Icons.family_restroom,
      'Icons.school': Icons.school,
      'Icons.work': Icons.work,
      'Icons.emoji_events': Icons.emoji_events,
    };
    
    return iconMap[iconString] ?? Icons.label_important;
  }
  
  // Methods for favorites/counters
  
  // Check if a thikr is favorited
  Future<bool> isFavorite(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favorite_${categoryId}_$thikrIndex';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }
  
  // Toggle favorite status
  Future<void> toggleFavorite(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favorite_${categoryId}_$thikrIndex';
      final currentValue = prefs.getBool(key) ?? false;
      
      // Toggle the value
      await prefs.setBool(key, !currentValue);
      
      // If it's being added to favorites, save the date
      if (!currentValue) {
        await saveFavoriteAddedDate(categoryId, thikrIndex);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }
  
  // Get all favorites with improved sorting
  Future<List<FavoriteThikr>> getAllFavorites({String? sortBy}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteKeys = prefs.getKeys().where((key) => key.startsWith('favorite_') && !key.startsWith('favorite_date_'));
      
      List<FavoriteThikr> favorites = [];
      
      for (final key in favoriteKeys) {
        final isFavorite = prefs.getBool(key) ?? false;
        if (isFavorite) {
          // Parse the key to get categoryId and thikrIndex
          final parts = key.split('_');
          if (parts.length >= 3) {
            try {
              final categoryId = parts[1];
              final thikrIndex = int.parse(parts[2]);
              
              // Load the category and thikr
              final category = await getAthkarCategory(categoryId);
              if (category != null && thikrIndex < category.athkar.length) {
                favorites.add(FavoriteThikr(
                  category: category,
                  thikr: category.athkar[thikrIndex],
                  thikrIndex: thikrIndex,
                  dateAdded: await getFavoriteAddedDate(categoryId, thikrIndex) ?? DateTime.now(),
                ));
              }
            } catch (e) {
              print('Error parsing favorite key $key: $e');
              continue;
            }
          }
        }
      }
      
      // Sort favorites based on sortBy parameter
      if (sortBy != null) {
        switch (sortBy) {
          case 'category':
            favorites.sort((a, b) => a.category.title.compareTo(b.category.title));
            break;
          case 'date_added_newest':
            favorites.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
            break;
          case 'date_added_oldest':
            favorites.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
            break;
          case 'length':
            favorites.sort((a, b) => a.thikr.text.length.compareTo(b.thikr.text.length));
            break;
          case 'count':
            favorites.sort((a, b) => a.thikr.count.compareTo(b.thikr.count));
            break;
        }
      }
      
      return favorites;
    } catch (e) {
      print('Error getting all favorites: $e');
      return [];
    }
  }
  
  // Save the date when a thikr was added to favorites
  Future<void> saveFavoriteAddedDate(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favorite_date_${categoryId}_$thikrIndex';
      await prefs.setString(key, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving favorite added date: $e');
    }
  }
  
  // Get the date when a thikr was added to favorites
  Future<DateTime?> getFavoriteAddedDate(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favorite_date_${categoryId}_$thikrIndex';
      final dateString = prefs.getString(key);
      return dateString != null ? DateTime.parse(dateString) : null;
    } catch (e) {
      print('Error getting favorite added date: $e');
      return null;
    }
  }
  
  // Get thikr count
  Future<int> getThikrCount(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'count_${categoryId}_$thikrIndex';
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      print('Error getting thikr count: $e');
      return 0;
    }
  }
  
  // Update thikr count
  Future<void> updateThikrCount(String categoryId, int thikrIndex, int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'count_${categoryId}_$thikrIndex';
      await prefs.setInt(key, count);
      
      // إذا كان هذا هو أول إكمال للذكر، قم بتسجيل تاريخ الإكمال
      if (count > 0) {
        final completionCountKey = 'completion_count_${categoryId}_$thikrIndex';
        final currentCompletions = prefs.getInt(completionCountKey) ?? 0;
        
        if (currentCompletions == 0) {
          // تسجيل تاريخ أول إكمال
          final firstCompletionKey = 'first_completion_${categoryId}_$thikrIndex';
          await prefs.setString(firstCompletionKey, DateTime.now().toIso8601String());
        }
        
        // زيادة عدد مرات الإكمال
        await prefs.setInt(completionCountKey, currentCompletions + 1);
        
        // تسجيل تاريخ آخر إكمال
        final lastCompletionKey = 'last_completion_${categoryId}_$thikrIndex';
        await prefs.setString(lastCompletionKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Error updating thikr count: $e');
    }
  }

  // =============== طرق الإشعارات الجديدة باستخدام NotificationFacade ===============
  
  // جدولة إشعار لفئة أذكار
  Future<bool> scheduleAthkarNotification(String categoryId, TimeOfDay time) async {
    try {
      final category = await getAthkarCategory(categoryId);
      if (category == null) return false;

      final result = await _notificationFacade.scheduleAthkarNotifications(
        categoryId: categoryId,
        categoryTitle: category.title,
        times: [time],
        customTitle: category.notifyTitle,
        customBody: category.notifyBody,
        color: category.color,
      );

      return result.success;
    } catch (e) {
      print('Error scheduling athkar notification: $e');
      return false;
    }
  }

  // جدولة إشعارات متعددة لفئة أذكار
  Future<bool> scheduleMultipleAthkarNotifications(String categoryId, List<TimeOfDay> times) async {
    try {
      final category = await getAthkarCategory(categoryId);
      if (category == null) return false;

      final result = await _notificationFacade.scheduleAthkarNotifications(
        categoryId: categoryId,
        categoryTitle: category.title,
        times: times,
        customTitle: category.notifyTitle,
        customBody: category.notifyBody,
        color: category.color,
      );

      return result.success;
    } catch (e) {
      print('Error scheduling multiple athkar notifications: $e');
      return false;
    }
  }

  // إلغاء إشعارات فئة أذكار
  Future<bool> cancelAthkarNotification(String categoryId) async {
    try {
      return await _notificationFacade.cancelAthkarNotifications(categoryId);
    } catch (e) {
      print('Error canceling athkar notification: $e');
      return false;
    }
  }

  // التحقق مما إذا كانت الإشعارات مفعلة لفئة معينة
  Future<bool> isNotificationEnabled(String categoryId) async {
    try {
      final status = await _notificationFacade.getAthkarNotificationStatus(categoryId);
      return status.isEnabled;
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  // الحصول على أوقات الإشعارات لفئة معينة
  Future<List<TimeOfDay>> getNotificationTimes(String categoryId) async {
    try {
      final status = await _notificationFacade.getAthkarNotificationStatus(categoryId);
      return status.scheduledTimes;
    } catch (e) {
      print('Error getting notification times: $e');
      return [];
    }
  }

  // الحصول على قائمة الأوقات الإضافية للإشعارات
  Future<List<String>> getAdditionalNotificationTimes(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notification_${categoryId}_additional_times';
      final jsonList = prefs.getString(key);
      
      if (jsonList != null) {
        try {
          final List<dynamic> decoded = json.decode(jsonList);
          return decoded.map((item) => item.toString()).toList();
        } catch (e) {
          print('Error decoding additional times: $e');
        }
      }
      
      return [];
    } catch (e) {
      print('Error getting additional notification times: $e');
      return [];
    }
  }
  
  // حفظ قائمة الأوقات الإضافية للإشعارات
  Future<void> saveAdditionalNotificationTimes(String categoryId, List<String> times) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notification_${categoryId}_additional_times';
      await prefs.setString(key, json.encode(times));
    } catch (e) {
      print('Error saving additional notification times: $e');
    }
  }
  
  // إضافة وقت إشعار إضافي
  Future<void> addAdditionalNotificationTime(String categoryId, String time) async {
    try {
      final times = await getAdditionalNotificationTimes(categoryId);
      if (!times.contains(time)) {
        times.add(time);
        await saveAdditionalNotificationTimes(categoryId, times);
      }
    } catch (e) {
      print('Error adding additional notification time: $e');
    }
  }
  
  // حذف وقت إشعار إضافي
  Future<void> removeAdditionalNotificationTime(String categoryId, String time) async {
    try {
      final times = await getAdditionalNotificationTimes(categoryId);
      times.remove(time);
      await saveAdditionalNotificationTimes(categoryId, times);
    } catch (e) {
      print('Error removing additional notification time: $e');
    }
  }

  // إحصائيات الأذكار
  
  // الحصول على عدد مرات إكمال ذكر معين
  Future<int> getThikrCompletionCount(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'completion_count_${categoryId}_$thikrIndex';
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      print('Error getting thikr completion count: $e');
      return 0;
    }
  }
  
  // الحصول على تاريخ أول إكمال لذكر معين
  Future<DateTime?> getThikrFirstCompletionDate(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'first_completion_${categoryId}_$thikrIndex';
      final dateString = prefs.getString(key);
      return dateString != null ? DateTime.parse(dateString) : null;
    } catch (e) {
      print('Error getting thikr first completion date: $e');
      return null;
    }
  }
  
  // الحصول على تاريخ آخر إكمال لذكر معين
  Future<DateTime?> getThikrLastCompletionDate(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'last_completion_${categoryId}_$thikrIndex';
      final dateString = prefs.getString(key);
      return dateString != null ? DateTime.parse(dateString) : null;
    } catch (e) {
      print('Error getting thikr last completion date: $e');
      return null;
    }
  }
  
  // الحصول على إحصائيات إكمال لفئة كاملة
  Future<CategoryStats> getCategoryStats(String categoryId) async {
    try {
      final category = await getAthkarCategory(categoryId);
      if (category == null) {
        return CategoryStats(
          totalCompletions: 0,
          totalThikrs: 0,
          completedThikrs: 0,
          lastCompletionDate: null,
        );
      }
      
      int totalCompletions = 0;
      int completedThikrs = 0;
      DateTime? lastCompletionDate;
      
      for (int i = 0; i < category.athkar.length; i++) {
        final completions = await getThikrCompletionCount(categoryId, i);
        totalCompletions += completions;
        
        if (completions > 0) {
          completedThikrs++;
          
          final date = await getThikrLastCompletionDate(categoryId, i);
          if (date != null && (lastCompletionDate == null || date.isAfter(lastCompletionDate))) {
            lastCompletionDate = date;
          }
        }
      }
      
      return CategoryStats(
        totalCompletions: totalCompletions,
        totalThikrs: category.athkar.length,
        completedThikrs: completedThikrs,
        lastCompletionDate: lastCompletionDate,
      );
    } catch (e) {
      print('Error getting category stats: $e');
      return CategoryStats(
        totalCompletions: 0,
        totalThikrs: 0,
        completedThikrs: 0,
        lastCompletionDate: null,
      );
    }
  }
  
  // الحصول على إحصائيات إكمال لجميع الفئات
  Future<Map<String, CategoryStats>> getAllCategoriesStats() async {
    try {
      final categories = await loadAllAthkarCategories();
      final Map<String, CategoryStats> stats = {};
      
      for (final category in categories) {
        stats[category.id] = await getCategoryStats(category.id);
      }
      
      return stats;
    } catch (e) {
      print('Error getting all categories stats: $e');
      return {};
    }
  }
  
  // مسح الإعدادات وبدء من جديد
  Future<void> resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error resetting all data: $e');
    }
  }
}

// A class to represent a favorited thikr with its category
class FavoriteThikr {
  final AthkarCategory category;
  final Thikr thikr;
  final int thikrIndex;
  final DateTime dateAdded;
  
  FavoriteThikr({
    required this.category,
    required this.thikr,
    required this.thikrIndex,
    required this.dateAdded,
  });
}

// إحصائيات فئة الأذكار
class CategoryStats {
  final int totalCompletions;
  final int totalThikrs;
  final int completedThikrs;
  final DateTime? lastCompletionDate;
  
  CategoryStats({
    required this.totalCompletions,
    required this.totalThikrs,
    required this.completedThikrs,
    this.lastCompletionDate,
  });
  
  // نسبة الأذكار المكتملة
  double get completionPercentage => 
    totalThikrs > 0 ? (completedThikrs / totalThikrs) * 100 : 0;
}