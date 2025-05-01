// lib/screens/home_screen/home_screen.dart - تغيير شكل أيقونة التحميل عند التحديث
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart'; // إضافة المكتبة

import 'package:test_athkar_app/models/daily_quote_model.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart';
import 'package:test_athkar_app/screens/home_screen/widgets/category_grid.dart';
import 'package:test_athkar_app/screens/home_screen/widgets/quote_carousel.dart';
import 'package:test_athkar_app/screens/quote_details_screen/quote_details_screen.dart';
import 'package:test_athkar_app/services/daily_quote_service.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

// استيراد الألوان الرئيسية
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  // متحكمات العرض
  final PageController _pageController = PageController();
  final ValueNotifier<int> _pageIndex = ValueNotifier<int>(0);

  // ساعة حية
  late final ValueNotifier<DateTime> _currentTime;
  Timer? _clockTimer;

  // خدمة الاقتباسات
  final DailyQuoteService _quoteService = DailyQuoteService();
  List<HighlightItem> _highlights = [];
  bool _highlightsLoaded = false;
  
  // للتحكم في حالة السحب للتحديث
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // إعداد الساعة
    _currentTime = ValueNotifier<DateTime>(DateTime.now());
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _currentTime.value = DateTime.now();
    });

    _initQuoteService();
  }

  Future<void> _initQuoteService() async {
    if (mounted) {
      setState(() {
        _highlightsLoaded = false; // نجعل حالة التحميل نشطة عند بدء التحميل
      });
    }
    
    try {
      await _quoteService.initialize();
      final dailyHighlights = await _quoteService.getDailyHighlights();
      if (mounted) {
        setState(() {
          _highlights = dailyHighlights;
          _highlightsLoaded = true;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading quotes: $e');
      if (mounted) {
        setState(() {
          _highlights = const [
            HighlightItem(
              headerTitle: r'آية اليوم',
              headerIcon: Icons.menu_book_rounded,
              quote:
                  r'﴿ الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُمْ بِذِكْرِ اللَّهِ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
              source: r'سورة الرعد – آية 28',
            ),
            HighlightItem(
              headerTitle: r'حديث اليوم',
              headerIcon: Icons.format_quote_rounded,
              quote:
                  r'قال رسول الله ﷺ: «مَن قال سبحان الله وبحمده في يومٍ مائة مرة، حُطَّت خطاياه وإن كانت مثل زبد البحر»',
              source: r'متفق عليه',
            ),
          ];
          _highlightsLoaded = true;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageIndex.dispose();
    _clockTimer?.cancel();
    _currentTime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // إعداد سمة متناسقة مع التطبيق
    final ThemeData theme = ThemeData(
      fontFamily: GoogleFonts.cairo().fontFamily,
      colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, surface: kSurface),
      textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'تطبيق الأذكار',
            style: TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          actions: [
            // زر الإعدادات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: Icon(
                  Icons.settings,
                  color: kPrimary,
                  size: 26,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('إعدادات التطبيق قيد التطوير'),
                      backgroundColor: kPrimary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                tooltip: 'الإعدادات',
              ),
            ),
          ],
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: RefreshIndicator(
            color: kPrimary,
            backgroundColor: Colors.white,
            onRefresh: () async {
              setState(() {
                _isRefreshing = true;
                _highlightsLoaded = false; // نجعل حالة التحميل نشطة عند السحب للتحديث
              });
              await _initQuoteService();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // التاريخ الهجري
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: AnimationConfiguration.synchronized(
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 20,
                        child: FadeInAnimation(
                          child: HijriDateTimeHeader(currentTime: _currentTime),
                        ),
                      ),
                    ),
                  ),
                ),

                // عرض الاقتباسات أو مؤشر التحميل
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: AnimationConfiguration.synchronized(
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: 50,
                        child: FadeInAnimation(
                          child: !_highlightsLoaded
                              ? _buildLoadingHighlightsCard(theme)
                              : QuoteCarousel(
                                  highlights: _highlights,
                                  pageController: _pageController,
                                  pageIndex: _pageIndex,
                                  onQuoteTap: (quoteItem) => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          QuoteDetailsScreen(quoteItem: quoteItem),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                // عنوان قسم الفئات
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: AnimationConfiguration.synchronized(
                      duration: const Duration(milliseconds: 700),
                      child: SlideAnimation(
                        verticalOffset: 30,
                        child: FadeInAnimation(
                          child: Row(
                            children: [
                              Icon(
                                Icons.category_rounded,
                                color: kPrimary,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'الأقسام',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // شبكة الفئات
                const CategoryGrid(),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // مؤشر التحميل باستخدام المكتبة - يتغير حسب حالة التحديث
  Widget _buildLoadingHighlightsCard(ThemeData theme) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [kPrimary, kPrimaryLight],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0.3, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // استخدام أيقونة تحميل مختلفة عند التحديث
              _isRefreshing 
                ? LoadingAnimationWidget.fourRotatingDots(
                    color: Colors.white,
                    size: 50,
                  )
                : LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.white,
                    size: 50,
                  ),
              const SizedBox(height: 16),
              Text(
                _isRefreshing 
                    ? 'جاري تحديث المقتبسات...' 
                    : 'جاري تحميل المقتبسات...',
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}