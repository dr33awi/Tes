// lib/features/athkar/data/utils/icon_helper.dart
import 'package:flutter/material.dart';

/// مساعد للتعامل مع الأيقونات والألوان في تطبيق الأذكار
/// يوفر هذا الصف طرقًا ثابتة للحصول على الأيقونات والألوان المستخدمة في التطبيق
/// ويجب استخدامه في كل مكان بدلاً من تكرار التعريفات
class IconHelper {
  // منع إنشاء نسخة من الصف
  IconHelper._();
  
  // تخزين مؤقت للأيقونات - تحسين الأداء
  static final Map<String, IconData> _iconCache = {};
  
  // تخزين مؤقت للألوان - تحسين الأداء
  static final Map<String, Color> _colorCache = {};
  
  // تخزين مؤقت للتدرجات اللونية - تحسين الأداء
  static final Map<String, List<Color>> _gradientCache = {};
  
  // تخزين مؤقت للأوقات الافتراضية - تحسين الأداء
  static final Map<String, TimeOfDay> _defaultTimeCache = {};
  
  /// خريطة ثابتة للأيقونات
  /// هذه الخريطة تحتوي على كل الأيقونات المستخدمة في التطبيق
  static final Map<String, IconData> _iconMap = {
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

  /// خريطة للألوان الأساسية المستخدمة لكل فئة
  /// تُستخدم في تحديد لون الفئة في واجهة المستخدم
  static final Map<String, Color> _categoryColors = {
    'morning': const Color(0xFFFFD54F),    // أصفر للصباح
    'evening': const Color(0xFFAB47BC),    // بنفسجي للمساء
    'sleep': const Color(0xFF5C6BC0),      // أزرق للنوم
    'wake': const Color(0xFFFFB74D),       // برتقالي للاستيقاظ
    'prayer': const Color(0xFF4DB6AC),     // أخضر مزرق للصلاة
    'home': const Color(0xFF66BB6A),       // أخضر للمنزل
    'food': const Color(0xFFE57373),       // أحمر للطعام
    'quran': const Color(0xFF9575CD),      // بنفسجي فاتح للقرآن
    'default': const Color(0xFF00897B),    // لون افتراضي
  };
  
  /// خريطة للتدرجات اللونية لكل فئة
  /// تُستخدم في تحديد التدرج اللوني في خلفية البطاقات
  static final Map<String, List<Color>> _categoryGradients = {
    'morning': [const Color(0xFFFFD54F), const Color(0xFFFFA000)],    // تدرج أصفر للصباح
    'evening': [const Color(0xFFAB47BC), const Color(0xFF7B1FA2)],    // تدرج بنفسجي للمساء
    'sleep': [const Color(0xFF5C6BC0), const Color(0xFF3949AB)],      // تدرج أزرق للنوم
    'wake': [const Color(0xFFFFB74D), const Color(0xFFFF9800)],       // تدرج برتقالي للاستيقاظ
    'prayer': [const Color(0xFF4DB6AC), const Color(0xFF00695C)],     // تدرج أخضر مزرق للصلاة
    'home': [const Color(0xFF66BB6A), const Color(0xFF2E7D32)],       // تدرج أخضر للمنزل
    'food': [const Color(0xFFE57373), const Color(0xFFC62828)],       // تدرج أحمر للطعام
    'quran': [const Color(0xFF9575CD), const Color(0xFF512DA8)],      // تدرج بنفسجي فاتح للقرآن
    'default': [const Color(0xFF00897B), const Color(0xFF00695C)],    // تدرج افتراضي
  };
  
  /// خريطة للأوقات الافتراضية لكل فئة
  /// تُستخدم في تحديد الوقت الافتراضي لإشعارات كل فئة
  static final Map<String, TimeOfDay> _categoryDefaultTimes = {
    'morning': const TimeOfDay(hour: 6, minute: 0),      // 06:00 صباحًا
    'evening': const TimeOfDay(hour: 18, minute: 0),     // 06:00 مساءً
    'sleep': const TimeOfDay(hour: 22, minute: 0),       // 10:00 مساءً
    'wake': const TimeOfDay(hour: 5, minute: 30),        // 05:30 صباحًا
    'wakeup': const TimeOfDay(hour: 5, minute: 30),      // 05:30 صباحًا (اسم بديل)
    'prayer': const TimeOfDay(hour: 12, minute: 0),      // 12:00 ظهرًا
    'home': const TimeOfDay(hour: 18, minute: 0),        // 06:00 مساءً
    'food': const TimeOfDay(hour: 13, minute: 0),        // 01:00 مساءً
    'default': const TimeOfDay(hour: 8, minute: 0),      // 08:00 صباحًا
  };

  /// الحصول على أيقونة من نص
  /// @param iconString نص الأيقونة (مثال: 'Icons.wb_sunny')
  /// @return كائن [IconData] المناسب
  static IconData getIconFromString(String iconString) {
    // تحقق من التخزين المؤقت أولاً
    if (_iconCache.containsKey(iconString)) {
      return _iconCache[iconString]!;
    }
    
    // إذا لم تكن في التخزين المؤقت، ابحث في الخريطة
    final icon = _iconMap[iconString] ?? Icons.label_important;
    
    // حفظ في التخزين المؤقت للاستخدام المستقبلي
    _iconCache[iconString] = icon;
    
    return icon;
  }
  
  /// تحويل IconData إلى نص
  /// @param icon كائن الأيقونة
  /// @return نص يمثل الأيقونة
  static String iconToString(IconData icon) {
    // البحث في الخريطة بشكل عكسي
    for (var entry in _iconMap.entries) {
      if (entry.value == icon) {
        return entry.key;
      }
    }
    
    // إرجاع قيمة افتراضية إذا لم يتم العثور على الأيقونة
    return 'Icons.label_important';
  }
  
  /// الحصول على لون من نص هيكس
  /// @param hexColor نص اللون الست عشري (مثال: '#FFFFFF')
  /// @return كائن [Color] المناسب
  static Color getColorFromHex(String hexColor) {
    // تحقق من التخزين المؤقت أولاً
    if (_colorCache.containsKey(hexColor)) {
      return _colorCache[hexColor]!;
    }
    
    try {
      // تنظيف النص
      hexColor = hexColor.replaceAll('#', '');
      
      // إضافة قناة ألفا إذا لم تكن موجودة
      if (hexColor.length == 6) {
        hexColor = 'FF' + hexColor;
      }
      
      // تحويل النص إلى لون
      final color = Color(int.parse('0x$hexColor'));
      
      // حفظ في التخزين المؤقت للاستخدام المستقبلي
      _colorCache[hexColor] = color;
      
      return color;
    } catch (e) {
      debugPrint('خطأ في تحويل اللون الست عشري: $e');
      
      // لون افتراضي في حالة حدوث خطأ
      final defaultColor = const Color(0xFF447055);
      
      // حفظ في التخزين المؤقت للاستخدام المستقبلي
      _colorCache[hexColor] = defaultColor;
      
      return defaultColor;
    }
  }
  
  /// تحويل لون إلى نص هيكس
  /// @param color كائن اللون
  /// @return نص هيكس يمثل اللون
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
  
  /// الحصول على لون للفئة
  /// @param categoryId معرف الفئة
  /// @return لون الفئة
  static Color getCategoryColor(String categoryId) {
    // تحقق من التخزين المؤقت أولاً
    final cacheKey = 'color_$categoryId';
    if (_colorCache.containsKey(cacheKey)) {
      return _colorCache[cacheKey]!;
    }
    
    // الحصول على اللون من الخريطة
    final color = _categoryColors[categoryId] ?? _categoryColors['default']!;
    
    // حفظ في التخزين المؤقت للاستخدام المستقبلي
    _colorCache[cacheKey] = color;
    
    return color;
  }
  
  /// الحصول على تدرج لوني للفئة
  /// @param categoryId معرف الفئة
  /// @return قائمة الألوان للتدرج
  static List<Color> getCategoryGradient(String categoryId) {
    // تحقق من التخزين المؤقت أولاً
    if (_gradientCache.containsKey(categoryId)) {
      return _gradientCache[categoryId]!;
    }
    
    // الحصول على التدرج من الخريطة
    final gradient = _categoryGradients[categoryId] ?? _categoryGradients['default']!;
    
    // حفظ في التخزين المؤقت للاستخدام المستقبلي
    _gradientCache[categoryId] = gradient;
    
    return gradient;
  }
  
  /// الحصول على الوقت الافتراضي لكل فئة
  /// @param categoryId معرف الفئة
  /// @return وقت اليوم الافتراضي للفئة
  static TimeOfDay getDefaultTimeForCategory(String categoryId) {
    // تحقق من التخزين المؤقت أولاً
    if (_defaultTimeCache.containsKey(categoryId)) {
      return _defaultTimeCache[categoryId]!;
    }
    
    // الحصول على الوقت الافتراضي من الخريطة
    final defaultTime = _categoryDefaultTimes[categoryId] ?? _categoryDefaultTimes['default']!;
    
    // حفظ في التخزين المؤقت للاستخدام المستقبلي
    _defaultTimeCache[categoryId] = defaultTime;
    
    return defaultTime;
  }
  
  /// الحصول على لون داكن مناسب للفئة
  /// @param categoryId معرف الفئة
  /// @return لون داكن مناسب للفئة
  static Color getDarkCategoryColor(String categoryId) {
    final gradient = getCategoryGradient(categoryId);
    return gradient[1]; // الوصول إلى اللون الثاني (الداكن) في التدرج
  }
  
  /// الحصول على لون فاتح مناسب للفئة
  /// @param categoryId معرف الفئة
  /// @return لون فاتح مناسب للفئة
  static Color getLightCategoryColor(String categoryId) {
    final gradient = getCategoryGradient(categoryId);
    return gradient[0]; // الوصول إلى اللون الأول (الفاتح) في التدرج
  }
  
  /// الحصول على تباين لون النص المناسب (أبيض أو أسود) بناءً على لون الخلفية
  /// @param backgroundColor لون الخلفية
  /// @return لون النص المناسب (أبيض أو أسود)
  static Color getTextColorForBackground(Color backgroundColor) {
    // حساب درجة السطوع للون
    final brightness = backgroundColor.computeLuminance();
    
    // إذا كان اللون فاتحًا، استخدم النص الأسود، وإلا استخدم النص الأبيض
    return brightness > 0.5 ? Colors.black : Colors.white;
  }
  
  /// الحصول على خبرة مستخدم متناسقة للون الفئة
  /// يوفر مجموعة من الألوان المشتقة من لون الفئة
  /// @param categoryId معرف الفئة
  /// @return خريطة بالألوان المشتقة
  static Map<String, Color> getCategoryColorScheme(String categoryId) {
    final baseColor = getCategoryColor(categoryId);
    final darkColor = getDarkCategoryColor(categoryId);
    
    return {
      'primary': baseColor,
      'dark': darkColor,
      'light': baseColor.withOpacity(0.7),
      'background': baseColor.withOpacity(0.1),
      'surface': baseColor.withOpacity(0.05),
      'onPrimary': getTextColorForBackground(baseColor),
      'onDark': getTextColorForBackground(darkColor),
    };
  }
  
  /// تنظيف التخزين المؤقت
  /// يُستخدم لتحرير الذاكرة عند الحاجة
  static void clearCaches() {
    _iconCache.clear();
    _colorCache.clear();
    _gradientCache.clear();
    _defaultTimeCache.clear();
  }
}