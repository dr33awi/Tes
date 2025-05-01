// lib/models/athkar_model.dart
import 'package:flutter/material.dart';

/// نموذج يمثل ذكر واحد
class Thikr {
  final String text; // نص الذكر
  final String? fadl; // فضل الذكر (اختياري)
  final String? source; // المصدر (اختياري)
  final int count; // عدد مرات الذكر
  final int? countDone; // عدد المرات التي تم إكمالها (للتتبع)
  final bool isFavorite; // هل هو مفضل؟

  Thikr({
    required this.text,
    this.fadl,
    this.source,
    required this.count,
    this.countDone = 0,
    this.isFavorite = false,
  });

  // نسخة جديدة من الذكر مع تعديل بعض الخصائص
  Thikr copyWith({
    String? text,
    String? fadl,
    String? source,
    int? count,
    int? countDone,
    bool? isFavorite,
  }) {
    return Thikr(
      text: text ?? this.text,
      fadl: fadl ?? this.fadl,
      source: source ?? this.source,
      count: count ?? this.count,
      countDone: countDone ?? this.countDone,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // تحويل الذكر إلى Map لتخزينه
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'fadl': fadl,
      'source': source,
      'count': count,
      'countDone': countDone,
      'isFavorite': isFavorite,
    };
  }

  // إنشاء ذكر من Map
  factory Thikr.fromJson(Map<String, dynamic> json) {
    return Thikr(
      text: json['text'],
      fadl: json['fadl'],
      source: json['source'],
      count: json['count'],
      countDone: json['countDone'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}

/// نموذج يمثل فئة من الأذكار
class AthkarCategory {
  final String id; // معرف الفئة
  final String title; // عنوان الفئة
  final IconData icon; // أيقونة الفئة
  final Color color; // لون الفئة
  final String? description; // وصف الفئة (اختياري)
  final List<Thikr> athkar; // قائمة الأذكار في هذه الفئة

  const AthkarCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.description,
    required this.athkar,
  });

  // تحويل الفئة إلى Map لتخزينها
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'color': color.value,
      'description': description,
      'athkar': athkar.map((thikr) => thikr.toJson()).toList(),
    };
  }

  // إنشاء فئة من Map
  factory AthkarCategory.fromJson(Map<String, dynamic> json) {
    return AthkarCategory(
      id: json['id'],
      title: json['title'],
      icon: IconData(json['iconCodePoint'], fontFamily: json['iconFontFamily']),
      color: Color(json['color']),
      description: json['description'],
      athkar: (json['athkar'] as List)
          .map((item) => Thikr.fromJson(item))
          .toList(),
    );
  }
}