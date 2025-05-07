import 'package:flutter/material.dart';

class AthkarCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String? description;
  final List<Thikr> athkar;
  final String? notifyTime; // Added for notification time (format: "HH:MM")

  AthkarCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.description,
    required this.athkar,
    this.notifyTime,
  });
}

class Thikr {
  final int id;
  final String text;
  final int count;
  final String? fadl;
  final String? source;

  Thikr({
    required this.id,
    required this.text,
    required this.count,
    this.fadl,
    this.source,
  });
}