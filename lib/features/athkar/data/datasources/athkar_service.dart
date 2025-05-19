// lib/features/athkar/data/datasources/athkar_service.dart
import 'dart:convert';
import 'package:athkar_app/features/athkar/presentation/screens/athkar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/services/interfaces/notification_service.dart';
import '../../../../core/services/utils/notification_scheduler.dart';
import '../../domain/entities/athkar.dart';
import '../models/athkar_model.dart';
import '../utils/icon_helper.dart';

class AthkarService {
  // Singleton implementation
  static final AthkarService _instance = AthkarService._internal();
  factory AthkarService() => _instance;
  
  // مزود خدمة الإشعارات
  late final NotificationService _notificationService;
  late final NotificationScheduler _notificationScheduler;
  
  AthkarService._internal() {
    try {
      _notificationService = getIt<NotificationService>();
      _notificationScheduler = getIt<NotificationScheduler>();
    } catch (e) {
      debugPrint('Error initializing notification services: $e');
    }
  }

  // ذاكرة التخزين المؤقت للأذكار لتجنب القراءة المتكررة من الملفات
  final Map<String, AthkarScreen> _athkarCache = {};

  // تحميل الأذكار من ملف JSON
  Future<List<AthkarScreen>> loadAllAthkarCategories() async {
    try {
      // استخدام الكاش إذا كان موجودًا بالفعل
      if (_athkarCache.isNotEmpty) {
        return _athkarCache.values.toList();
      }
      
      // قراءة ملف JSON من الأصول
      final String jsonString = await rootBundle.loadString('assets/data/athkar.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      List<AthkarScreen> categories = [];
      
      // تحليل الفئات
      for (var categoryData in jsonData['categories']) {
        final category = _parseAthkarCategory(categoryData);
        categories.add(category);
        
        // تخزين مؤقت للفئة للوصول السريع لاحقًا
        _athkarCache[category.id] = category;
      }
      
      return categories;
    } catch (e) {
      debugPrint('Error loading athkar: $e');
      return [];
    }
  }

  // الحصول على فئة محددة حسب المعرف مع تحسين التخزين المؤقت
  Future<AthkarScreen?> getAthkarCategory(String categoryId) async {
    // التحقق مما إذا كانت الفئة موجودة بالفعل في ذاكرة التخزين المؤقت
    if (_athkarCache.containsKey(categoryId)) {
      return _athkarCache[categoryId];
    }
    
    try {
      // إذا لم تكن موجودة في ذاكرة التخزين المؤقت، قم بتحميل جميع الفئات ثم إرجاع الفئة المحددة
      final categories = await loadAllAthkarCategories();
      for (var category in categories) {
        if (category.id == categoryId) {
          return category;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting category $categoryId: $e');
      return null;
    }
  }

  // تحليل فئة واحدة من JSON مع تحسين معالجة الأيقونة واللون
  AthkarScreen _parseAthkarCategory(Map<String, dynamic> data) {
    // تحليل نص الأيقونة إلى IconData
    final iconString = data['icon'] as String;
    final IconData iconData = IconHelper.getIconFromString(iconString);
    
    // تحليل نص اللون إلى Color
    final colorString = data['color'] as String? ?? '#447055';
    final Color color = IconHelper.getColorFromHex(colorString);
    
    // تحليل قائمة الأذكار
    List<Athkar> athkarList = [];
    if (data['athkar'] != null) {
      for (var thikrData in data['athkar']) {
        athkarList.add(Athkar(
          id: thikrData['id'] ?? '',
          title: thikrData['title'] ?? '',
          content: thikrData['text'] ?? '',
          count: thikrData['count'] ?? 1,
          categoryId: data['id'],
          source: thikrData['source'],
          notes: thikrData['notes'],
          fadl: thikrData['fadl'],
        ));
      }
    }
    
    // إنشاء وإرجاع الفئة
    return AthkarScreen(
      id: data['id'],
      name: data['title'],
      description: data['description'] ?? '',
      icon: iconString,
      athkar: athkarList,
    );
  }
  
  // طرق للمفضلة/العدادات
  
  // التحقق مما إذا كان الذكر مفضلاً
  Future<bool> isFavorite(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favorite_${categoryId}_$thikrIndex';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      return false;
    }
  }
  
  // تبديل حالة المفضلة
  Future<void> toggleFavorite(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favorite_${categoryId}_$thikrIndex';
      final currentValue = prefs.getBool(key) ?? false;
      
      // تبديل القيمة
      await prefs.setBool(key, !currentValue);
      
      // إذا تمت إضافته إلى المفضلة، احفظ تاريخ الإضافة
      if (!currentValue) {
        await saveFavoriteAddedDate(categoryId, thikrIndex);
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }
  
  // الحصول على جميع المفضلات مع تحسين الترتيب
  Future<List<FavoriteThikr>> getAllFavorites({String? sortBy}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteKeys = prefs.getKeys().where(
        (key) => key.startsWith('favorite_') && !key.startsWith('favorite_date_')
      );
      
      List<FavoriteThikr> favorites = [];
      
      for (final key in favoriteKeys) {
        final isFavorite = prefs.getBool(key) ?? false;
        if (isFavorite) {
          // تحليل المفتاح للحصول على categoryId و thikrIndex
          final parts = key.split('_');
          if (parts.length >= 3) {
            try {
              final categoryId = parts[1];
              final thikrIndex = int.parse(parts[2]);
              
              // تحميل الفئة والذكر
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
              debugPrint('Error parsing favorite key $key: $e');
              continue;
            }
          }
        }
      }
      
      // ترتيب المفضلات استنادًا إلى معلمة الترتيب
      if (sortBy != null) {
        switch (sortBy) {
          case 'category':
            favorites.sort((a, b) => a.category.name.compareTo(b.category.name));
            break;
          case 'date_added_newest':
            favorites.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
            break;
          case 'date_added_oldest':
            favorites.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
            break;
          case 'length':
            favorites.sort((a, b) => a.thikr.content.length.compareTo(b.thikr.content.length));
            break;
          case 'count':
            favorites.sort((a, b) => a.thikr.count.compareTo(b.thikr.count));
            break;
        }
      }
      
      return favorites;
    } catch (e) {
      debugPrint('Error getting all favorites: $e');
      return [];
    }
  }
  
  // حفظ التاريخ عندما تمت إضافة ذكر إلى المفضلة
  Future<void> saveFavoriteAddedDate(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favorite_date_${categoryId}_$thikrIndex';
      await prefs.setString(key, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving favorite added date: $e');
    }
  }
  
  // الحصول على التاريخ عندما تمت إضافة ذكر إلى المفضلة
  Future<DateTime?> getFavoriteAddedDate(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favorite_date_${categoryId}_$thikrIndex';
      final dateString = prefs.getString(key);
      return dateString != null ? DateTime.parse(dateString) : null;
    } catch (e) {
      debugPrint('Error getting favorite added date: $e');
      return null;
    }
  }
  
  // الحصول على عدد مرات الذكر
  Future<int> getThikrCount(String categoryId, int thikrIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'count_${categoryId}_$thikrIndex';
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      debugPrint('Error getting thikr count: $e');
      return 0;
    }
  }
  
  // تحديث عدد مرات الذكر
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
      debugPrint('Error updating thikr count: $e');
    }
  }

  // تحسين نظام إعدادات الإشعارات - متوافق مع النظام الموحد
  
  // الحصول على إعدادات الإشعارات الكاملة لفئة معينة
  Future<AthkarNotificationSettings> getNotificationSettings(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على الإعدادات الأساسية
      final enabled = prefs.getBool('notification_${categoryId}_enabled') ?? true;
      final customTime = prefs.getString('notification_${categoryId}_time');
      final vibrate = prefs.getBool('notification_${categoryId}_vibrate') ?? true;
      
      // استرجاع أهمية الإشعار
      final importance = prefs.getInt('notification_${categoryId}_importance') ?? 4;
      
      return AthkarNotificationSettings(
        isEnabled: enabled,
        customTime: customTime,
        vibrate: vibrate,
        importance: importance,
      );
    } catch (e) {
      debugPrint('Error getting notification settings: $e');
      return AthkarNotificationSettings();
    }
  }
  
  // حفظ إعدادات الإشعارات الكاملة لفئة معينة
  Future<void> saveNotificationSettings(String categoryId, AthkarNotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('notification_${categoryId}_enabled', settings.isEnabled);
      
      if (settings.customTime != null) {
        await prefs.setString('notification_${categoryId}_time', settings.customTime!);
      } else {
        await prefs.remove('notification_${categoryId}_time');
      }
      
      await prefs.setBool('notification_${categoryId}_vibrate', settings.vibrate);
      
      await prefs.setInt('notification_${categoryId}_importance', settings.importance ?? 4);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }
  
  // تبسيط - الحصول على حالة تفعيل الإشعار
  Future<bool> getNotificationEnabled(String categoryId) async {
    try {
      final settings = await getNotificationSettings(categoryId);
      return settings.isEnabled;
    } catch (e) {
      debugPrint('Error checking if notification is enabled: $e');
      return false;
    }
  }
  
  // تبسيط - ضبط حالة تفعيل الإشعار
  Future<void> setNotificationEnabled(String categoryId, bool enabled) async {
    try {
      final settings = await getNotificationSettings(categoryId);
      await saveNotificationSettings(
        categoryId, 
        settings.copyWith(isEnabled: enabled)
      );
    } catch (e) {
      debugPrint('Error setting notification enabled status: $e');
    }
  }
  
  // تبسيط - الحصول على وقت الإشعار المخصص
  Future<String?> getCustomNotificationTime(String categoryId) async {
    try {
      final settings = await getNotificationSettings(categoryId);
      return settings.customTime;
    } catch (e) {
      debugPrint('Error getting custom notification time: $e');
      return null;
    }
  }
  
  // تبسيط - ضبط وقت الإشعار المخصص
  Future<void> setCustomNotificationTime(String categoryId, String time) async {
    try {
      final settings = await getNotificationSettings(categoryId);
      await saveNotificationSettings(
        categoryId, 
        settings.copyWith(customTime: time)
      );
    } catch (e) {
      debugPrint('Error setting custom notification time: $e');
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
          debugPrint('Error decoding additional times: $e');
        }
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting additional notification times: $e');
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
      debugPrint('Error saving additional notification times: $e');
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
      debugPrint('Error adding additional notification time: $e');
    }
  }
  
  // حذف وقت إشعار إضافي
  Future<void> removeAdditionalNotificationTime(String categoryId, String time) async {
    try {
      final times = await getAdditionalNotificationTimes(categoryId);
      times.remove(time);
      await saveAdditionalNotificationTimes(categoryId, times);
    } catch (e) {
      debugPrint('Error removing additional notification time: $e');
    }
  }

  // دوال للتكامل مع النظام الموحد للإشعارات
  
  // جدولة إشعارات فئة كاملة مع النظام الموحد
  Future<void> scheduleCategoryNotifications(String categoryId) async {
    try {
      final category = await getAthkarCategory(categoryId);
      if (category == null) return;
      
      // الحصول على إعدادات الإشعارات
      final settings = await getNotificationSettings(categoryId);
      if (!settings.isEnabled) return;
      
      // تحديد الأوقات
      List<TimeOfDay> times = [];
      
      // الوقت المخصص أو الافتراضي
      if (settings.customTime != null) {
        final parts = settings.customTime!.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          times.add(TimeOfDay(hour: hour, minute: minute));
        }
      }
      
      // إضافة أوقات إضافية
      final additionalTimes = await getAdditionalNotificationTimes(categoryId);
      for (final timeStr in additionalTimes) {
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          times.add(TimeOfDay(hour: hour, minute: minute));
        }
      }
      
      if (times.isEmpty) {
        // وقت افتراضي
        times.add(IconHelper.getDefaultTimeForCategory(categoryId));
      }
      
      // دمج مع نظام الإشعارات الموحد
      final notifyTitle = '${category.name} 📌';
      final notifyBody = 'حان وقت قراءة أذكار ${category.name}';
      
      // جدولة الإشعارات باستخدام NotificationScheduler
      await _scheduleNotificationUsingAthkarSettings(
        categoryId: categoryId, 
        title: notifyTitle, 
        body: notifyBody,
        times: times,
        settings: settings
      );
      
      // حفظ حالة التفعيل
      await setNotificationEnabled(categoryId, true);
    } catch (e) {
      debugPrint('Error scheduling category notifications: $e');
    }
  }
  
  // إلغاء إشعارات فئة
  Future<void> cancelCategoryNotifications(String categoryId) async {
    try {
      // حدد معرفات الإشعارات المرتبطة بهذه الفئة
      List<int> notificationIds = [];
      
      // تحديد هوية الإشعار الرئيسي، نفترض أنه categoryId + 1000 كمثال
      int baseId = 1000 + categoryId.hashCode % 1000;
      notificationIds.add(baseId);
      
      // الحصول على الأوقات الإضافية وتحديد معرفات الإشعارات الإضافية
      final additionalTimes = await getAdditionalNotificationTimes(categoryId);
      for (int i = 0; i < additionalTimes.length; i++) {
        notificationIds.add(baseId + i + 1);
      }
      
      // إلغاء الإشعارات
      await _notificationService.cancelNotificationsByIds(notificationIds);
      
      // تحديث الإعدادات
      await setNotificationEnabled(categoryId, false);
    } catch (e) {
      debugPrint('Error canceling category notifications: $e');
    }
  }
  
  // دالة مساعدة لجدولة الإشعارات باستخدام إعدادات الأذكار
  Future<void> _scheduleNotificationUsingAthkarSettings({
    required String categoryId,
    required String title,
    required String body,
    required List<TimeOfDay> times,
    required AthkarNotificationSettings settings,
  }) async {
    try {
      // بناء الـ payload
      final Map<String, dynamic> payload = {
        'type': 'athkar',
        'category': categoryId,
        'route': '/athkar-details',
        'arguments': {
          'categoryId': categoryId,
          'categoryName': title,
        }
      };
      
      // تحديد أولوية الإشعار استنادًا إلى إعدادات الأذكار
      NotificationPriority priority;
      switch (settings.importance) {
        case 1:
          priority = NotificationPriority.low;
          break;
        case 3:
          priority = NotificationPriority.high;
          break;
        case 5:
          priority = NotificationPriority.critical;
          break;
        default:
          priority = NotificationPriority.normal;
      }
      
      // إنشاء معرف إشعار فريد لكل وقت
      int baseId = 1000 + categoryId.hashCode % 1000;
      
      // جدولة كل وقت
      for (int i = 0; i < times.length; i++) {
        final time = times[i];
        
        // تحديد تاريخ الإشعار
        final now = DateTime.now();
        DateTime scheduledDate = DateTime(
          now.year, 
          now.month, 
          now.day, 
          time.hour, 
          time.minute,
        );
        
        // إذا كان الوقت في الماضي، جدولة لليوم التالي
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        
        // إنشاء بيانات الإشعار
        final notificationData = NotificationData(
          id: baseId + i,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          repeatInterval: NotificationRepeatInterval.daily,
          notificationTime: _mapTimeToNotificationTime(time),
          priority: priority,
          respectBatteryOptimizations: true,
          respectDoNotDisturb: false, // نسمح لإشعارات الأذكار بالظهور حتى في وضع عدم الإزعاج
          channelId: 'athkar_channel',
          payload: payload,
        );
        
        // جدولة الإشعار المتكرر
        await _notificationService.scheduleRepeatingNotification(notificationData);
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }
  
  // تحويل TimeOfDay إلى NotificationTime
  NotificationTime _mapTimeToNotificationTime(TimeOfDay time) {
    // تبسيط: فقط تخمين NotificationTime استنادًا إلى الوقت
    if (time.hour >= 5 && time.hour < 12) {
      return NotificationTime.morning;
    } else if (time.hour >= 12 && time.hour < 17) {
      return NotificationTime.custom;
    } else if (time.hour >= 17 && time.hour < 20) {
      return NotificationTime.evening;
    } else {
      return NotificationTime.custom;
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
      debugPrint('Error getting thikr completion count: $e');
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
      debugPrint('Error getting thikr first completion date: $e');
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
      debugPrint('Error getting thikr last completion date: $e');
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
      debugPrint('Error getting category stats: $e');
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
      debugPrint('Error getting all categories stats: $e');
      return {};
    }
  }
  
  // مسح الإعدادات وبدء من جديد
  Future<void> resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // تخزين حالة إشعارات الأذكار مؤقتا
      Map<String, bool> notificationStates = {};
      
      // حفظ حالة إشعارات الأذكار
      for (final key in prefs.getKeys()) {
        if (key.startsWith('notification_') && key.endsWith('_enabled')) {
          final categoryId = key.replaceAll('notification_', '').replaceAll('_enabled', '');
          notificationStates[categoryId] = prefs.getBool(key) ?? false;
        }
      }
      
      // مسح جميع البيانات
      await prefs.clear();
      
      // إعادة تفعيل الإشعارات إذا كانت مفعلة سابقا
      for (final entry in notificationStates.entries) {
        if (entry.value) {
          await setNotificationEnabled(entry.key, true);
          await scheduleCategoryNotifications(entry.key);
        }
      }
    } catch (e) {
      debugPrint('Error resetting all data: $e');
    }
  }
}

// فئة تمثل ذكر مفضل مع فئته
class FavoriteThikr {
  final AthkarScreen category;
  final Athkar thikr;
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