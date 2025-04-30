import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/models/daily_quote_model.dart';

class DailyQuoteService {
  static const String _assetPath = 'assets/data/daily_quotes.json';
  static const String _lastUpdateDateKey = 'last_quote_update_date';
  static const String _currentQuranIndexKey = 'current_quran_index';
  static const String _currentHadithIndexKey = 'current_hadith_index';
  
  late DailyQuotesCollection _quotesCollection;
  
  static final DailyQuoteService _instance = DailyQuoteService._internal();
  factory DailyQuoteService() => _instance;
  
  DailyQuoteService._internal();
  
  Future<void> initialize() async {
    try {
      final String jsonString = await rootBundle.loadString(_assetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _quotesCollection = DailyQuotesCollection.fromJson(jsonData);
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات: $e');
      _quotesCollection = DailyQuotesCollection(
        quranVerses: [
          {
            'text': '﴿ الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُمْ بِذِكْرِ اللَّهِ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
            'source': 'سورة الرعد – آية 28'
          }
        ],
        hadiths: [
          {
            'text': 'قال رسول الله ﷺ: «مَن قال سبحان الله وبحمده في يومٍ مائة مرة، حُطَّت خطاياه وإن كانت مثل زبد البحر»',
            'source': 'متفق عليه'
          }
        ],
      );
    }
  }
  
  Future<List<HighlightItem>> getDailyHighlights() async {
    await _checkAndUpdateQuotes();
    
    final prefs = await SharedPreferences.getInstance();
    final quranIndex = prefs.getInt(_currentQuranIndexKey) ?? 0;
    final hadithIndex = prefs.getInt(_currentHadithIndexKey) ?? 0;
    
    final safeQuranIndex = quranIndex % _quotesCollection.quranVerses.length;
    final safeHadithIndex = hadithIndex % _quotesCollection.hadiths.length;
    
    final quranQuote = DailyQuote.fromJson(
      _quotesCollection.quranVerses[safeQuranIndex], 'quran');
    final hadithQuote = DailyQuote.fromJson(
      _quotesCollection.hadiths[safeHadithIndex], 'hadith');
    
    return [
      HighlightItem(
        headerTitle: quranQuote.headerTitle,
        headerIcon: quranQuote.headerIcon,
        quote: quranQuote.text,
        source: quranQuote.source,
      ),
      HighlightItem(
        headerTitle: hadithQuote.headerTitle,
        headerIcon: hadithQuote.headerIcon,
        quote: hadithQuote.text,
        source: hadithQuote.source,
      ),
    ];
  }
  
  Future<void> _checkAndUpdateQuotes() async {
    final today = _getDateString(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final lastUpdateDate = prefs.getString(_lastUpdateDateKey);
    
    if (lastUpdateDate != today) {
      int quranIndex = prefs.getInt(_currentQuranIndexKey) ?? -1;
      int hadithIndex = prefs.getInt(_currentHadithIndexKey) ?? -1;
      
      quranIndex = (quranIndex + 1) % _quotesCollection.quranVerses.length;
      hadithIndex = (hadithIndex + 1) % _quotesCollection.hadiths.length;
      
      await prefs.setInt(_currentQuranIndexKey, quranIndex);
      await prefs.setInt(_currentHadithIndexKey, hadithIndex);
      await prefs.setString(_lastUpdateDateKey, today);
    }
  }
  
  String _getDateString(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}