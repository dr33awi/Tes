// lib/screens/home_screen/home_screen.dart
import 'dart:async';


import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:test_athkar_app/models/daily_quote_model.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart';
import 'package:test_athkar_app/screens/home_screen/widgets/category_grid.dart';   // ← الاستدعاء الوحيد للقائمة
import 'package:test_athkar_app/screens/home_screen/widgets/quote_carousel.dart';
import 'package:test_athkar_app/screens/quote_details_screen/quote_details_screen.dart';
import 'package:test_athkar_app/services/daily_quote_service.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

// Palette & constants
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;

const Color kQuoteTextColor = Color(0xFF2F5943);
const Color kSourceTextColor = Colors.white;

class HijriDateText extends StatelessWidget {
  const HijriDateText({super.key, required this.currentTime});

  final ValueListenable<DateTime> currentTime;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: currentTime,
      builder: (_, now, __) {
        return HijriDateTimeHeader(currentTime: currentTime);
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  // Controllers
  final PageController _pageController = PageController();
  final ValueNotifier<int> _pageIndex = ValueNotifier<int>(0);

  // Live clock notifier
  late final ValueNotifier<DateTime> _currentTime;
  Timer? _clockTimer;

  // Quote service
  final DailyQuoteService _quoteService = DailyQuoteService();
  List<HighlightItem> _highlights = [];
  bool _highlightsLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // clock
    _currentTime = ValueNotifier<DateTime>(DateTime.now());
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _currentTime.value = DateTime.now();
    });

    _initQuoteService();
  }

  Future<void> _initQuoteService() async {
    try {
      await _quoteService.initialize();
      final dailyHighlights = await _quoteService.getDailyHighlights();
      if (mounted) {
        setState(() {
          _highlights = dailyHighlights;
          _highlightsLoaded = true;
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
    final ThemeData theme = ThemeData(
      fontFamily: GoogleFonts.cairo().fontFamily,
      colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, surface: kSurface),
      textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Date text
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: AnimationConfiguration.synchronized(
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 20,
                        child: FadeInAnimation(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: HijriDateText(currentTime: _currentTime),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Quote carousel
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: AnimationConfiguration.synchronized(
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: 50,
                        child: FadeInAnimation(
                          child: _highlightsLoaded
                              ? QuoteCarousel(
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
                                )
                              : _buildLoadingHighlightsCard(theme),
                        ),
                      ),
                    ),
                  ),
                ),

                // *** القائمة (Grid) أصبحت مجرد استدعاء واحد ***
                const CategoryGrid(),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Loading placeholder
  Widget _buildLoadingHighlightsCard(ThemeData theme) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [kPrimary, kPrimaryLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.12),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text('جاري تحميل المقتبسات...',
                style: theme.textTheme.bodyLarge!.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
