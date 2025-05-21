import 'package:athkar_app/features/home/models/daily_quote_model.dart';
import 'package:athkar_app/features/home/presentation/quotes/services/daily_quote_service.dart';
import 'package:athkar_app/features/home/presentation/quotes/widgets/quote_carousel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../athkar/presentation/providers/athkar_provider.dart';
import '../../../prayers/presentation/providers/prayer_times_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../app/themes/loading_widget.dart';
import '../../../prayers/presentation/widgets/prayer_times_section.dart';
import '../widgets/category_grid.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // متحكمات العرض
  final PageController _pageController = PageController();
  final ValueNotifier<int> _pageIndex = ValueNotifier<int>(0);
  
  // خدمة الاقتباسات
  final DailyQuoteService _quoteService = DailyQuoteService();
  List<HighlightItem> _highlights = [];
  bool _highlightsLoaded = false;
  
  // للتحكم في حالة السحب للتحديث
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    
    // تأخير قصير لضمان تجهيز Provider
    Future.microtask(() {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final prayerTimesProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
      
      // تعيين موقع افتراضي مؤقت (سيتم استبداله بموقع المستخدم الحقيقي)
      // الإحداثيات الافتراضية لمكة المكرمة
      prayerTimesProvider.setLocation(
        latitude: 21.422510,
        longitude: 39.826168,
      );
      
      // تحميل مواقيت الصلاة إذا كانت الإعدادات جاهزة
      if (settingsProvider.settings != null) {
        prayerTimesProvider.loadTodayPrayerTimes(settingsProvider.settings!);
      }
    });
    
    // تحميل الاقتباسات اليومية
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
      debugPrint('خطأ في تحميل الاقتباسات: $e');
      if (mounted) {
        setState(() {
          _highlights = const [
            HighlightItem(
              headerTitle: 'آية اليوم',
              headerIcon: Icons.menu_book_rounded,
              quote: '﴿ الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُمْ بِذِكْرِ اللَّهِ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
              source: 'سورة الرعد – آية 28',
            ),
            HighlightItem(
              headerTitle: 'حديث اليوم',
              headerIcon: Icons.format_quote_rounded,
              quote: 'قال رسول الله ﷺ: «مَن قال سبحان الله وبحمده في يومٍ مائة مرة، حُطَّت خطاياه وإن كانت مثل زبد البحر»',
              source: 'متفق عليه',
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'المفضلة',
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.favorites);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.settingsRoute);
            },
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const LoadingWidget();
          }

          return RefreshIndicator(
            onRefresh: () async {
              // تحديث كل من البيانات
              setState(() {
                _isRefreshing = true;
                _highlightsLoaded = false;
              });
              
              // تحديث بيانات مواقيت الصلاة
              if (settingsProvider.settings != null) {
                await Provider.of<PrayerTimesProvider>(context, listen: false)
                    .refreshData(settingsProvider.settings!);
              }
              
              // تحديث الاقتباسات اليومية
              await _quoteService.refreshDailyHighlights().then((highlightsList) {
                if (mounted) {
                  setState(() {
                    _highlights = highlightsList;
                    _highlightsLoaded = true;
                    _isRefreshing = false;
                  });
                }
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قسم مواقيت الصلاة
                  const PrayerTimesSection(),
                  const SizedBox(height: 20),
                  
                  // قسم الاقتباسات اليومية
                  _buildDailyQuotesSection(context),
                  const SizedBox(height: 20),
                  
                  // عنوان قسم الفئات
                  Text(
                    'الأقسام',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // قسم شبكة الفئات
                  CustomScrollView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    slivers: [
                      const CategoryGrid(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // معلومات إضافية
                  Center(
                    child: Text(
                      '${AppConstants.appName} - ${AppConstants.appVersion}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // بناء قسم الاقتباسات اليومية
  Widget _buildDailyQuotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'اقتباسات اليوم',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        
        // عرض الاقتباسات أو مؤشر التحميل
        !_highlightsLoaded
          ? _buildLoadingHighlightsCard(context)
          : QuoteCarousel(
              highlights: _highlights,
              pageController: _pageController,
              pageIndex: _pageIndex,
              onQuoteTap: (quoteItem) => Navigator.pushNamed(
                context,
                AppRouter.quoteDetails,
                arguments: quoteItem,
              ),
            ),
      ],
    );
  }
  
  // مؤشر التحميل
  Widget _buildLoadingHighlightsCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              theme.primaryColor,
              theme.primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: const [0.3, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
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