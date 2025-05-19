// lib/features/athkar/data/utils/icon_helper.dart
import 'package:flutter/material.dart';

/// ملف مساعد للتعامل مع الأيقونات والألوان في التطبيق
class IconHelper {
  // تعيين نصوص الأيقونة إلى كائنات IconData
  static IconData getIconFromString(String iconString) {
    final Map<String, IconData> iconMap = {
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
      'Icons.auto_awesome': Icons.auto_awesome,
      'Icons.label_important': Icons.label_important,
    };
    
    return iconMap[iconString] ?? Icons.label_important;
  }
  
  // تحويل IconData إلى نص
  static String iconToString(IconData icon) {
    if (icon == Icons.wb_sunny) return 'Icons.wb_sunny';
    if (icon == Icons.nightlight_round) return 'Icons.nightlight_round';
    if (icon == Icons.bedtime) return 'Icons.bedtime';
    if (icon == Icons.alarm) return 'Icons.alarm';
    if (icon == Icons.mosque) return 'Icons.mosque';
    if (icon == Icons.home) return 'Icons.home';
    if (icon == Icons.restaurant) return 'Icons.restaurant';
    if (icon == Icons.menu_book) return 'Icons.menu_book';
    if (icon == Icons.favorite) return 'Icons.favorite';
    if (icon == Icons.star) return 'Icons.star';
    if (icon == Icons.water_drop) return 'Icons.water_drop';
    if (icon == Icons.insights) return 'Icons.insights';
    if (icon == Icons.travel_explore) return 'Icons.travel_explore';
    if (icon == Icons.healing) return 'Icons.healing';
    if (icon == Icons.family_restroom) return 'Icons.family_restroom';
    if (icon == Icons.school) return 'Icons.school';
    if (icon == Icons.work) return 'Icons.work';
    if (icon == Icons.emoji_events) return 'Icons.emoji_events';
    if (icon == Icons.auto_awesome) return 'Icons.auto_awesome';
    return 'Icons.label_important';
  }
  
  // الحصول على لون من نص هيكس
  static Color getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF' + hexColor;
      }
      return Color(int.parse('0x$hexColor'));
    } catch (e) {
      return const Color(0xFF447055); // لون افتراضي في حالة حدوث خطأ
    }
  }
  
  // تحويل لون إلى نص هيكس
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
  
  // الحصول على لون للفئة
  static Color getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const Color(0xFFFFD54F); // أصفر للصباح
      case 'evening':
        return const Color(0xFFAB47BC); // بنفسجي للمساء
      case 'sleep':
        return const Color(0xFF5C6BC0); // أزرق للنوم
      case 'wake':
        return const Color(0xFFFFB74D); // برتقالي للاستيقاظ
      case 'prayer':
        return const Color(0xFF4DB6AC); // أخضر مزرق للصلاة
      case 'home':
        return const Color(0xFF66BB6A); // أخضر للمنزل
      case 'food':
        return const Color(0xFFE57373); // أحمر للطعام
      case 'quran':
        return const Color(0xFF9575CD); // بنفسجي فاتح للقرآن
      default:
        return const Color(0xFF00897B); // لون افتراضي
    }
  }
  
  // الحصول على تدرج لوني للفئة
  static List<Color> getCategoryGradient(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return [
          const Color(0xFFFFD54F), // أصفر فاتح
          const Color(0xFFFFA000), // أصفر داكن
        ];
      case 'evening':
        return [
          const Color(0xFFAB47BC), // بنفسجي فاتح
          const Color(0xFF7B1FA2), // بنفسجي داكن
        ];
      case 'sleep':
        return [
          const Color(0xFF5C6BC0), // أزرق فاتح
          const Color(0xFF3949AB), // أزرق داكن
        ];
      case 'wake':
        return [
          const Color(0xFFFFB74D), // برتقالي فاتح
          const Color(0xFFFF9800), // برتقالي داكن
        ];
      case 'prayer':
        return [
          const Color(0xFF4DB6AC), // أخضر مزرق فاتح
          const Color(0xFF00695C), // أخضر مزرق داكن
        ];
      case 'home':
        return [
          const Color(0xFF66BB6A), // أخضر فاتح
          const Color(0xFF2E7D32), // أخضر داكن
        ];
      case 'food':
        return [
          const Color(0xFFE57373), // أحمر فاتح
          const Color(0xFFC62828), // أحمر داكن
        ];
      case 'quran':
        return [
          const Color(0xFF9575CD), // بنفسجي فاتح
          const Color(0xFF512DA8), // بنفسجي داكن
        ];
      default:
        return [
          const Color(0xFF00897B), // تيل فاتح
          const Color(0xFF00695C), // تيل داكن
        ];
    }
  }
  
  // الحصول على الوقت الافتراضي لكل فئة
  static TimeOfDay getDefaultTimeForCategory(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const TimeOfDay(hour: 6, minute: 0);
      case 'evening':
        return const TimeOfDay(hour: 18, minute: 0);
      case 'sleep':
        return const TimeOfDay(hour: 22, minute: 0);
      case 'wakeup':
      case 'wake':
        return const TimeOfDay(hour: 5, minute: 30);
      case 'prayer':
        return const TimeOfDay(hour: 12, minute: 0);
      case 'home':
        return const TimeOfDay(hour: 18, minute: 0);
      case 'food':
        return const TimeOfDay(hour: 13, minute: 0);
      default:
        return const TimeOfDay(hour: 8, minute: 0);
    }
  }
}