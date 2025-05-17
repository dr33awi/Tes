// lib/data/models/athkar_model.dart
import '../../domain/entities/athkar.dart';

class AthkarModel {
  final String id;
  final String title;
  final String content;
  final int count;
  final String categoryId;
  final String? source;
  final String? notes;
  final String? fadl;  // أضفنا حقل فضل الذكر
  
  AthkarModel({
    required this.id,
    required this.title,
    required this.content,
    required this.count,
    required this.categoryId,
    this.source,
    this.notes,
    this.fadl,
  });
  
  factory AthkarModel.fromJson(Map<String, dynamic> json) {
    return AthkarModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      count: json['count'],
      categoryId: json['categoryId'],
      source: json['source'],
      notes: json['notes'],
      fadl: json['fadl'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'count': count,
      'categoryId': categoryId,
      'source': source,
      'notes': notes,
      'fadl': fadl,
    };
  }
  
  Athkar toEntity() {
    return Athkar(
      id: id,
      title: title,
      content: content,
      count: count,
      categoryId: categoryId,
      source: source,
      notes: notes,
      fadl: fadl,
    );
  }
}

class AthkarCategoryModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  
  AthkarCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
  
  factory AthkarCategoryModel.fromJson(Map<String, dynamic> json) {
    return AthkarCategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'auto_awesome',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
    };
  }
  
  AthkarCategory toEntity() {
    return AthkarCategory(
      id: id,
      name: name,
      description: description,
      icon: icon,
    );
  }
}