import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_athkar_app/models/daily_quote_model.dart';
import 'package:test_athkar_app/screens/favorites_screen/favorites_screen.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;

class QuoteDetailsScreen extends StatelessWidget {
  const QuoteDetailsScreen({super.key, required this.quoteItem});

  final HighlightItem quoteItem;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quote Details',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
      ],
      home: Builder(builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        
        return Scaffold(
          backgroundColor: kSurface,
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SlideAnimation(
                        verticalOffset: 60,
                        child: FadeInAnimation(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kPrimary, kPrimaryLight],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  quoteItem.quote,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyLarge?.copyWith(
                                    height: 1.9,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  quoteItem.source,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SlideAnimation(
                        verticalOffset: 30,
                        child: FadeInAnimation(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: () => _shareQuote(context),
                                icon: const Icon(Icons.share),
                              ),
                              IconButton(
                                onPressed: () => _copyQuote(context),
                                icon: const Icon(Icons.copy),
                              ),
                              IconButton(
                                onPressed: () => _addToFavorites(context),
                                icon: const Icon(Icons.favorite_border),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // إجراء النسخ
  void _copyQuote(BuildContext context) {
    final copyText = '${quoteItem.quote}\n\n${quoteItem.source}';
    Clipboard.setData(ClipboardData(text: copyText)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم النسخ إلى الحافظة'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
        ),
      );
    });
  }

  // إجراء المشاركة
  void _shareQuote(BuildContext context) async {
    final text = '${quoteItem.quote}\n\n${quoteItem.source}';
    await Share.share(text, subject: 'اقتباس من تطبيق أذكار');
  }

  // إضافة للمفضلة
  void _addToFavorites(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavoritesScreen(
          newFavoriteQuote: quoteItem,
        ),
      ),
    );
    Navigator.pop(context);
  }
}