import 'package:flutter/material.dart';

/// نموذج لتمثيل "المقتبس اليومي" (آية أو حديث)
class DailyQuote {
  final String text;
  final String source;
  final String type; // 'quran' أو 'hadith'
  
  const DailyQuote({
    required this.text,
    required this.source,
    required this.type,
  });
  
  factory DailyQuote.fromJson(Map<String, dynamic> json, String type) {
    return DailyQuote(
      text: json['text'],
      source: json['source'],
      type: type,
    );
  }
  
  /// معلومات العنوان بناءً على النوع
  String get headerTitle => type == 'quran' ? 'آية اليوم' : 'حديث اليوم';
  
  /// أيقونة العنوان بناءً على النوع
  IconData get headerIcon => 
    type == 'quran' ? Icons.menu_book_rounded : Icons.format_quote_rounded;
}

/// نموذج لمجموعة المقتبسات اليومية (من الملف JSON)
class DailyQuotesCollection {
  final List<Map<String, dynamic>> quranVerses;
  final List<Map<String, dynamic>> hadiths;
  
  DailyQuotesCollection({
    required this.quranVerses,
    required this.hadiths,
  });
  
  factory DailyQuotesCollection.fromJson(Map<String, dynamic> json) {
    return DailyQuotesCollection(
      quranVerses: List<Map<String, dynamic>>.from(json['quran_verses']),
      hadiths: List<Map<String, dynamic>>.from(json['hadiths']),
    );
  }
}

/// نموذج بطاقة المقتبس (متوافق مع الكود الأصلي)
class HighlightItem {
  const HighlightItem({
    required this.headerTitle,
    required this.headerIcon,
    required this.quote,
    required this.source,
  });
  final String headerTitle;
  final IconData headerIcon;
  final String quote;
  final String source;
  
  Map<String, dynamic> toJson() => {
    'headerTitle': headerTitle,
    'headerIcon': headerIcon.codePoint,
    'quote': quote,
    'source': source,
  };
 
  factory HighlightItem.fromJson(Map<String, dynamic> json) => HighlightItem(
    headerTitle: json['headerTitle'],
    headerIcon: IconData(json['headerIcon'], fontFamily: 'MaterialIcons'),
    quote: json['quote'],
    source: json['source'],
  );
}