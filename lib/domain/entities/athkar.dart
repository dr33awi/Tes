// lib/domain/entities/athkar.dart
class Athkar {
  final String id;
  final String title;
  final String content;
  final int count;
  final String categoryId;
  final String? source;
  final String? notes;
  final String? fadl;  // أضفنا حقل فضل الذكر
  
  Athkar({
    required this.id,
    required this.title,
    required this.content,
    required this.count,
    required this.categoryId,
    this.source,
    this.notes,
    this.fadl,
  });
}

class AthkarCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  
  AthkarCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}