// lib/features/quotes/data/services/daily_quote_service.dart
import 'dart:math';
import 'package:athkar_app/features/home/models/daily_quote_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyQuoteService {
  // مصفوفة الآيات القرآنية
  static const List<Map<String, dynamic>> _quranVerses = [
    {
      'quote': '﴿ الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُمْ بِذِكْرِ اللَّهِ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
      'source': 'سورة الرعد – آية 28',
    },
    {
      'quote': '﴿ وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ فَلْيَسْتَجِيبُوا لِي وَلْيُؤْمِنُوا بِي لَعَلَّهُمْ يَرْشُدُونَ ﴾',
      'source': 'سورة البقرة – آية 186',
    },
    {
      'quote': '﴿ رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً إِنَّكَ أَنتَ الْوَهَّابُ ﴾',
      'source': 'سورة آل عمران – آية 8',
    },
    {
      'quote': '﴿ وَاذْكُر رَّبَّكَ فِي نَفْسِكَ تَضَرُّعًا وَخِيفَةً وَدُونَ الْجَهْرِ مِنَ الْقَوْلِ بِالْغُدُوِّ وَالْآصَالِ وَلَا تَكُن مِّنَ الْغَافِلِينَ ﴾',
      'source': 'سورة الأعراف – آية 205',
    },
    {
      'quote': '﴿ يَا أَيُّهَا الَّذِينَ آمَنُوا اذْكُرُوا اللَّهَ ذِكْرًا كَثِيرًا وَسَبِّحُوهُ بُكْرَةً وَأَصِيلًا ﴾',
      'source': 'سورة الأحزاب – آية 41-42',
    },
  ];

  // مصفوفة الأحاديث النبوية
  static const List<Map<String, dynamic>> _hadiths = [
    {
      'quote': 'قال رسول الله ﷺ: «مَن قال سبحان الله وبحمده في يومٍ مائة مرة، حُطَّت خطاياه وإن كانت مثل زبد البحر»',
      'source': 'متفق عليه',
    },
    {
      'quote': 'قال رسول الله ﷺ: «إن لله تسعة وتسعين اسماً، مائة إلا واحداً، من أحصاها دخل الجنة»',
      'source': 'متفق عليه',
    },
    {
      'quote': 'قال رسول الله ﷺ: «كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن: سبحان الله وبحمده، سبحان الله العظيم»',
      'source': 'متفق عليه',
    },
    {
      'quote': 'قال رسول الله ﷺ: «من قال لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير، في يوم مائة مرة، كانت له عدل عشر رقاب، وكتبت له مائة حسنة، ومحيت عنه مائة سيئة، وكانت له حرزاً من الشيطان يومه ذلك حتى يمسي، ولم يأت أحد بأفضل مما جاء به، إلا رجل عمل أكثر منه»',
      'source': 'متفق عليه',
    },
    {
      'quote': 'قال رسول الله ﷺ: «لأن أقول سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر، أحب إلي مما طلعت عليه الشمس»',
      'source': 'رواه مسلم',
    },
  ];

  // مصفوفة الأدعية
  static const List<Map<String, dynamic>> _prayers = [
    {
      'quote': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي',
      'source': 'دعاء العافية',
    },
    {
      'quote': 'اللهم اغفر لي ذنبي كله، دقه وجله، وأوله وآخره، وعلانيته وسره',
      'source': 'دعاء المغفرة',
    },
  ];

  bool _isInitialized = false;
  SharedPreferences? _prefs;
  Random _random = Random();

  // الاقتباسات اليومية
  HighlightItem? _dailyQuranVerse;
  HighlightItem? _dailyHadith;

  // مفاتيح التخزين المحلي
  static const String _lastUpdateDateKey = 'last_update_date';
  static const String _dailyQuranVerseKey = 'daily_quran_verse';
  static const String _dailyHadithKey = 'daily_hadith';

  // تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _updateDailyHighlights();
    _isInitialized = true;
  }

  // تحديث الاقتباسات اليومية إذا كان اليوم جديدًا
  Future<void> _updateDailyHighlights() async {
    final prefs = _prefs!;
    
    // التحقق مما إذا كان اليوم جديدًا
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final String? lastUpdateDate = prefs.getString(_lastUpdateDateKey);

    if (lastUpdateDate != today) {
      // اختيار آية جديدة
      final int quranIndex = _random.nextInt(_quranVerses.length);
      _dailyQuranVerse = HighlightItem(
        headerTitle: 'آية اليوم',
        headerIcon: Icons.menu_book_rounded,
        quote: _quranVerses[quranIndex]['quote'],
        source: _quranVerses[quranIndex]['source'],
      );

      // اختيار حديث جديد
      final int hadithIndex = _random.nextInt(_hadiths.length);
      _dailyHadith = HighlightItem(
        headerTitle: 'حديث اليوم',
        headerIcon: Icons.format_quote_rounded,
        quote: _hadiths[hadithIndex]['quote'],
        source: _hadiths[hadithIndex]['source'],
      );

      // حفظ الاقتباسات الجديدة
      await prefs.setString(_lastUpdateDateKey, today);
      await prefs.setString(_dailyQuranVerseKey, _dailyQuranVerse!.quote);
      await prefs.setString(_dailyHadithKey, _dailyHadith!.quote);
    } else {
      // استرداد الاقتباسات المحفوظة
      final String? savedQuranVerse = prefs.getString(_dailyQuranVerseKey);
      final String? savedHadith = prefs.getString(_dailyHadithKey);

      if (savedQuranVerse != null) {
        _dailyQuranVerse = _getHighlightByQuote(savedQuranVerse, true);
      } else {
        // اختيار آية افتراضية إذا لم يتم حفظ أي آية
        final int quranIndex = _random.nextInt(_quranVerses.length);
        _dailyQuranVerse = HighlightItem(
          headerTitle: 'آية اليوم',
          headerIcon: Icons.menu_book_rounded,
          quote: _quranVerses[quranIndex]['quote'],
          source: _quranVerses[quranIndex]['source'],
        );
      }

      if (savedHadith != null) {
        _dailyHadith = _getHighlightByQuote(savedHadith, false);
      } else {
        // اختيار حديث افتراضي إذا لم يتم حفظ أي حديث
        final int hadithIndex = _random.nextInt(_hadiths.length);
        _dailyHadith = HighlightItem(
          headerTitle: 'حديث اليوم',
          headerIcon: Icons.format_quote_rounded,
          quote: _hadiths[hadithIndex]['quote'],
          source: _hadiths[hadithIndex]['source'],
        );
      }
    }
  }

  // البحث عن اقتباس بواسطة نصه
  HighlightItem _getHighlightByQuote(String quote, bool isQuran) {
    if (isQuran) {
      for (var verse in _quranVerses) {
        if (verse['quote'] == quote) {
          return HighlightItem(
            headerTitle: 'آية اليوم',
            headerIcon: Icons.menu_book_rounded,
            quote: verse['quote'],
            source: verse['source'],
          );
        }
      }
      // إذا لم يتم العثور على الآية، استخدم الأولى
      return HighlightItem(
        headerTitle: 'آية اليوم',
        headerIcon: Icons.menu_book_rounded,
        quote: _quranVerses[0]['quote'],
        source: _quranVerses[0]['source'],
      );
    } else {
      for (var hadith in _hadiths) {
        if (hadith['quote'] == quote) {
          return HighlightItem(
            headerTitle: 'حديث اليوم',
            headerIcon: Icons.format_quote_rounded,
            quote: hadith['quote'],
            source: hadith['source'],
          );
        }
      }
      // إذا لم يتم العثور على الحديث، استخدم الأول
      return HighlightItem(
        headerTitle: 'حديث اليوم',
        headerIcon: Icons.format_quote_rounded,
        quote: _hadiths[0]['quote'],
        source: _hadiths[0]['source'],
      );
    }
  }

  // الحصول على قائمة الاقتباسات اليومية
  Future<List<HighlightItem>> getDailyHighlights() async {
    if (!_isInitialized) {
      await initialize();
    }

    List<HighlightItem> highlights = [];

    // إضافة آية اليوم
    if (_dailyQuranVerse != null) {
      highlights.add(_dailyQuranVerse!);
    }

    // إضافة حديث اليوم
    if (_dailyHadith != null) {
      highlights.add(_dailyHadith!);
    }

    // إضافة دعاء عشوائي
    if (_prayers.isNotEmpty) {
      final int prayerIndex = _random.nextInt(_prayers.length);
      highlights.add(
        HighlightItem(
          headerTitle: 'دعاء اليوم',
          headerIcon: Icons.healing_rounded,
          quote: _prayers[prayerIndex]['quote'],
          source: _prayers[prayerIndex]['source'],
        ),
      );
    }

    return highlights;
  }

  // تحديث الاقتباسات اليومية
  Future<List<HighlightItem>> refreshDailyHighlights() async {
    if (!_isInitialized) {
      await initialize();
      return await getDailyHighlights();
    }

    // تعيين تاريخ التحديث الأخير إلى تاريخ سابق للتأكد من تحديث الاقتباسات
    await _prefs!.setString(_lastUpdateDateKey, '2000-01-01');
    await _updateDailyHighlights();
    return await getDailyHighlights();
  }
}