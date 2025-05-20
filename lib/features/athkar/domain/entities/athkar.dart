// lib/features/athkar/domain/entities/athkar.dart

/// كيان ذكر
///
/// يمثل هذا الصف كيان ذكر واحد في النظام
class Athkar {
  /// المعرف الفريد للذكر
  final String id;
  
  /// عنوان الذكر
  final String title;
  
  /// نص الذكر
  final String content;
  
  /// عدد مرات تكرار الذكر
  final int count;
  
  /// معرف الفئة التي ينتمي إليها الذكر
  final String categoryId;
  
  /// مصدر الذكر (حديث، قرآن، إلخ)
  final String? source;
  
  /// ملاحظات إضافية حول الذكر
  final String? notes;
  
  /// فضل الذكر
  final String? fadl;
  
  /// حالة المفضلة للذكر
  final bool isFavorite;
  
  /// تاريخ آخر إكمال للذكر
  final DateTime? lastCompletionDate;
  
  /// عدد مرات إكمال الذكر
  final int completionCount;
  
  /// المُنشئ
  const Athkar({
    required this.id,
    required this.title,
    required this.content,
    required this.count,
    required this.categoryId,
    this.source,
    this.notes,
    this.fadl,
    this.isFavorite = false,
    this.lastCompletionDate,
    this.completionCount = 0,
  });
  
  /// إنشاء نسخة جديدة من الكيان مع تعديلات
  ///
  /// تُستخدم هذه الطريقة لإنشاء نسخة جديدة من الكيان مع تعديل بعض الخصائص
  Athkar copyWith({
    String? id,
    String? title,
    String? content,
    int? count,
    String? categoryId,
    String? source,
    String? notes,
    String? fadl,
    bool? isFavorite,
    DateTime? lastCompletionDate,
    int? completionCount,
  }) {
    return Athkar(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      count: count ?? this.count,
      categoryId: categoryId ?? this.categoryId,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      fadl: fadl ?? this.fadl,
      isFavorite: isFavorite ?? this.isFavorite,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      completionCount: completionCount ?? this.completionCount,
    );
  }
  
  /// التحقق من تساوي كائنين
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Athkar &&
      other.id == id &&
      other.title == title &&
      other.content == content &&
      other.count == count &&
      other.categoryId == categoryId &&
      other.source == source &&
      other.notes == notes &&
      other.fadl == fadl &&
      other.isFavorite == isFavorite &&
      other.lastCompletionDate == lastCompletionDate &&
      other.completionCount == completionCount;
  }

  /// حساب قيمة الهاش للكائن
  @override
  int get hashCode {
    return id.hashCode ^
      title.hashCode ^
      content.hashCode ^
      count.hashCode ^
      categoryId.hashCode ^
      source.hashCode ^
      notes.hashCode ^
      fadl.hashCode ^
      isFavorite.hashCode ^
      lastCompletionDate.hashCode ^
      completionCount.hashCode;
  }
  
  /// تحويل الكيان إلى نص مقروء
  @override
  String toString() {
    return 'Athkar(id: $id, title: $title, categoryId: $categoryId, count: $count, isFavorite: $isFavorite)';
  }
}

/// كيان فئة الأذكار
///
/// يمثل هذا الصف كيان فئة من فئات الأذكار في النظام
class AthkarCategory {
  /// المعرف الفريد للفئة
  final String id;
  
  /// اسم الفئة
  final String name;
  
  /// وصف الفئة
  final String description;
  
  /// أيقونة الفئة كنص
  final String icon;
  
  /// هل الإشعارات مفعلة للفئة
  final bool notificationsEnabled;
  
  /// وقت الإشعار المخصص للفئة
  final String? customNotificationTime;
  
  /// المُنشئ
  const AthkarCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.notificationsEnabled = true,
    this.customNotificationTime,
  });
  
  /// إنشاء نسخة جديدة من الكيان مع تعديلات
  ///
  /// تُستخدم هذه الطريقة لإنشاء نسخة جديدة من الكيان مع تعديل بعض الخصائص
  AthkarCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    bool? notificationsEnabled,
    String? customNotificationTime,
  }) {
    return AthkarCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      customNotificationTime: customNotificationTime ?? this.customNotificationTime,
    );
  }
  
  /// التحقق من تساوي كائنين
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is AthkarCategory &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.icon == icon &&
      other.notificationsEnabled == notificationsEnabled &&
      other.customNotificationTime == customNotificationTime;
  }

  /// حساب قيمة الهاش للكائن
  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      icon.hashCode ^
      notificationsEnabled.hashCode ^
      customNotificationTime.hashCode;
  }
  
  /// تحويل الكيان إلى نص مقروء
  @override
  String toString() {
    return 'AthkarCategory(id: $id, name: $name)';
  }
}

/// إحصائيات فئة الأذكار
///
/// يمثل هذا الصف إحصائيات فئة من فئات الأذكار
class CategoryStats {
  /// إجمالي عدد مرات الإكمال
  final int totalCompletions;
  
  /// إجمالي عدد الأذكار في الفئة
  final int totalThikrs;
  
  /// عدد الأذكار المكتملة في الفئة
  final int completedThikrs;
  
  /// تاريخ آخر إكمال
  final DateTime? lastCompletionDate;
  
  /// المُنشئ
  const CategoryStats({
    required this.totalCompletions,
    required this.totalThikrs,
    required this.completedThikrs,
    this.lastCompletionDate,
  });
  
  /// نسبة الإكمال (٪)
  double get completionPercentage => 
    totalThikrs > 0 ? (completedThikrs / totalThikrs) * 100 : 0;
  
  /// التحقق من تساوي كائنين
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is CategoryStats &&
      other.totalCompletions == totalCompletions &&
      other.totalThikrs == totalThikrs &&
      other.completedThikrs == completedThikrs &&
      other.lastCompletionDate == lastCompletionDate;
  }

  /// حساب قيمة الهاش للكائن
  @override
  int get hashCode {
    return totalCompletions.hashCode ^
      totalThikrs.hashCode ^
      completedThikrs.hashCode ^
      lastCompletionDate.hashCode;
  }
  
  /// تحويل الكيان إلى نص مقروء
  @override
  String toString() {
    return 'CategoryStats(totalCompletions: $totalCompletions, completedThikrs: $completedThikrs/$totalThikrs, completionPercentage: ${completionPercentage.toStringAsFixed(1)}%)';
  }
}

/// ذكر في المفضلة
///
/// يمثل هذا الصف ذكر في المفضلة مع معلومات إضافية
class FavoriteThikr {
  /// كيان الفئة
  final AthkarCategory category;
  
  /// كيان الذكر
  final Athkar thikr;
  
  /// فهرس الذكر في الفئة
  final int thikrIndex;
  
  /// تاريخ الإضافة للمفضلة
  final DateTime dateAdded;
  
  /// المُنشئ
  const FavoriteThikr({
    required this.category,
    required this.thikr,
    required this.thikrIndex,
    required this.dateAdded,
  });
  
  /// التحقق من تساوي كائنين
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is FavoriteThikr &&
      other.category == category &&
      other.thikr == thikr &&
      other.thikrIndex == thikrIndex &&
      other.dateAdded == dateAdded;
  }

  /// حساب قيمة الهاش للكائن
  @override
  int get hashCode {
    return category.hashCode ^
      thikr.hashCode ^
      thikrIndex.hashCode ^
      dateAdded.hashCode;
  }
  
  /// تحويل الكيان إلى نص مقروء
  @override
  String toString() {
    return 'FavoriteThikr(category: ${category.name}, thikr: ${thikr.title})';
  }
}