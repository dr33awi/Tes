// lib/domain/entities/athkar.dart
class Athkar {
  final String id;
  final String category;
  final String title;
  final String content;
  final int count;
  final String? source;
  final String? fadl; // فضل الذكر
  final List<String>? tags;

  Athkar({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.count,
    this.source,
    this.fadl,
    this.tags,
  });
}

class AthkarCategory {
  final String id;
  final String name;
  final String? description;
  final String? icon;

  AthkarCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });
}