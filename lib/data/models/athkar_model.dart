// lib/data/models/athkar_model.dart
import '../../domain/entities/athkar.dart';

class AthkarModel {
  final String id;
  final String category;
  final String title;
  final String content;
  final int count;
  final String? source;
  final String? fadl;
  final List<String>? tags;

  AthkarModel({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.count,
    this.source,
    this.fadl,
    this.tags,
  });

  // تحويل من JSON إلى نموذج
  factory AthkarModel.fromJson(Map<String, dynamic> json) {
    return AthkarModel(
      id: json['id'],
      category: json['category'],
      title: json['title'],
      content: json['content'],
      count: json['count'] ?? 1,
      source: json['source'],
      fadl: json['fadl'],
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : null,
    );
  }

  // تحويل من نموذج إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'content': content,
      'count': count,
      'source': source,
      'fadl': fadl,
      'tags': tags,
    };
  }

  // تحويل من نموذج إلى كيان
  Athkar toEntity() {
    return Athkar(
      id: id,
      category: category,
      title: title,
      content: content,
      count: count,
      source: source,
      fadl: fadl,
      tags: tags,
    );
  }
}

class AthkarCategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? icon;

  AthkarCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });

  // تحويل من JSON إلى نموذج
  factory AthkarCategoryModel.fromJson(Map<String, dynamic> json) {
    return AthkarCategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
    );
  }

  // تحويل من نموذج إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
    };
  }

  // تحويل من نموذج إلى كيان
  AthkarCategory toEntity() {
    return AthkarCategory(
      id: id,
      name: name,
      description: description,
      icon: icon,
    );
  }
}