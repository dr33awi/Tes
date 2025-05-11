// lib/models/notification_model.dart
import 'dart:convert';
import 'package:flutter/material.dart';

/// نموذج بيانات الإشعار الموحد
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? channelId;
  final String? channelName;
  final String? icon;
  final String? payload;
  final String? category;
  final int? color;
  final int? ledColor;
  final bool isRecurring;
  final bool isImportant;
  final bool bypassDnd;
  final List<NotificationTime>? scheduledTimes;
  final String? soundName;
  final Map<String, dynamic>? extraData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.channelId,
    this.channelName,
    this.icon,
    this.payload,
    this.category,
    this.color,
    this.ledColor,
    this.isRecurring = false,
    this.isImportant = false,
    this.bypassDnd = false,
    this.scheduledTimes,
    this.soundName,
    this.extraData,
    this.createdAt,
    this.updatedAt,
  });

  // إنشاء نسخة معدلة من النموذج
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? channelId,
    String? channelName,
    String? icon,
    String? payload,
    String? category,
    int? color,
    int? ledColor,
    bool? isRecurring,
    bool? isImportant,
    bool? bypassDnd,
    List<NotificationTime>? scheduledTimes,
    String? soundName,
    Map<String, dynamic>? extraData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      icon: icon ?? this.icon,
      payload: payload ?? this.payload,
      category: category ?? this.category,
      color: color ?? this.color,
      ledColor: ledColor ?? this.ledColor,
      isRecurring: isRecurring ?? this.isRecurring,
      isImportant: isImportant ?? this.isImportant,
      bypassDnd: bypassDnd ?? this.bypassDnd,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      soundName: soundName ?? this.soundName,
      extraData: extraData ?? this.extraData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'channelId': channelId,
      'channelName': channelName,
      'icon': icon,
      'payload': payload,
      'category': category,
      'color': color,
      'ledColor': ledColor,
      'isRecurring': isRecurring,
      'isImportant': isImportant,
      'bypassDnd': bypassDnd,
      'scheduledTimes': scheduledTimes?.map((time) => time.toJson()).toList(),
      'soundName': soundName,
      'extraData': extraData,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // إنشاء من JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    List<NotificationTime>? times;
    if (json['scheduledTimes'] != null) {
      times = (json['scheduledTimes'] as List)
          .map((timeJson) => NotificationTime.fromJson(timeJson))
          .toList();
    }

    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      channelId: json['channelId'],
      channelName: json['channelName'],
      icon: json['icon'],
      payload: json['payload'],
      category: json['category'],
      color: json['color'],
      ledColor: json['ledColor'],
      isRecurring: json['isRecurring'] ?? false,
      isImportant: json['isImportant'] ?? false,
      bypassDnd: json['bypassDnd'] ?? false,
      scheduledTimes: times,
      soundName: json['soundName'],
      extraData: json['extraData'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // تحويل إلى سلسلة نصية
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // إنشاء من سلسلة نصية
  factory NotificationModel.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return NotificationModel.fromJson(json);
  }
  
  // للمقارنة والتصحيح
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NotificationModel &&
        other.id == id &&
        other.title == title &&
        other.body == body;
  }
  
  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ body.hashCode;
}

/// نموذج وقت الإشعار
class NotificationTime {
  final int hour;
  final int minute;
  final List<int>? days; // أيام الأسبوع (1-7 حيث 1 = الأحد)
  final DateTime? specificDate; // تاريخ محدد للإشعار لمرة واحدة

  NotificationTime({
    required this.hour,
    required this.minute,
    this.days,
    this.specificDate,
  });
  
  // تحويل إلى TimeOfDay
  TimeOfDay toTimeOfDay() {
    return TimeOfDay(hour: hour, minute: minute);
  }
  
  // تحويل من TimeOfDay
  factory NotificationTime.fromTimeOfDay(TimeOfDay time) {
    return NotificationTime(
      hour: time.hour,
      minute: time.minute,
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'days': days,
      'specificDate': specificDate?.toIso8601String(),
    };
  }

  // إنشاء من JSON
  factory NotificationTime.fromJson(Map<String, dynamic> json) {
    List<int>? daysOfWeek;
    if (json['days'] != null) {
      daysOfWeek = List<int>.from(json['days']);
    }

    return NotificationTime(
      hour: json['hour'],
      minute: json['minute'],
      days: daysOfWeek,
      specificDate: json['specificDate'] != null ? DateTime.parse(json['specificDate']) : null,
    );
  }
  
  // تحويل إلى سلسلة نصية
  String toTimeString() {
    final String hourStr = hour.toString().padLeft(2, '0');
    final String minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }
  
  // إنشاء من سلسلة نصية
  factory NotificationTime.fromTimeString(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return NotificationTime(hour: hour, minute: minute);
    }
    return NotificationTime(hour: 0, minute: 0);
  }
  
  // للمقارنة والتصحيح
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NotificationTime &&
        other.hour == hour &&
        other.minute == minute;
  }
  
  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

/// مدير الإشعارات المسجلة
class NotificationRegistry {
  final Map<String, NotificationModel> _notifications = {};
  
  // إضافة إشعار إلى السجل
  void addNotification(NotificationModel notification) {
    _notifications[notification.id] = notification;
  }
  
  // الحصول على إشعار من السجل
  NotificationModel? getNotification(String id) {
    return _notifications[id];
  }
  
  // إزالة إشعار من السجل
  void removeNotification(String id) {
    _notifications.remove(id);
  }
  
  // الحصول على جميع الإشعارات المسجلة
  List<NotificationModel> getAllNotifications() {
    return _notifications.values.toList();
  }
  
  // الحصول على الإشعارات حسب الفئة
  List<NotificationModel> getNotificationsByCategory(String category) {
    return _notifications.values
        .where((notification) => notification.category == category)
        .toList();
  }
  
  // مسح جميع الإشعارات المسجلة
  void clearAllNotifications() {
    _notifications.clear();
  }
  
  // الحصول على عدد الإشعارات المسجلة
  int get count => _notifications.length;
  
  // حفظ السجل في التخزين
  Future<void> saveToStorage() async {
    // يمكن تنفيذ هذا باستخدام SharedPreferences أو Hive أو أي وسيلة تخزين أخرى
  }
  
  // استعادة السجل من التخزين
  Future<void> loadFromStorage() async {
    // يمكن تنفيذ هذا باستخدام SharedPreferences أو Hive أو أي وسيلة تخزين أخرى
  }
}