// lib/features/quotes/presentation/widgets/quote_carousel.dart
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:athkar_app/features/home/models/daily_quote_model.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'quote_card.dart';


const Color kSourceTextColor = Colors.white;

class QuoteCarousel extends StatelessWidget {
  final List<HighlightItem> highlights;
  final PageController pageController;
  final ValueNotifier<int> pageIndex;
  final Function(HighlightItem)? onQuoteTap;
  
  const QuoteCarousel({
    Key? key,
    required this.highlights,
    required this.pageController,
    required this.pageIndex,
    this.onQuoteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 8,
      shadowColor: ThemeColors.primary.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [ThemeColors.primary, ThemeColors.primaryLight],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0.3, 1.0],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: pageController,
                itemCount: highlights.length,
                onPageChanged: (i) => pageIndex.value = i,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: QuoteCard(
                    text: highlights[i].quote,
                    onTap: onQuoteTap != null
                      ? () => onQuoteTap!(highlights[i])
                      : null,
                    quoteItem: highlights[i],
                    index: i,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildCarouselFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselFooter(ThemeData theme) {
    return ValueListenableBuilder<int>(
      valueListenable: pageIndex,
      builder: (_, idx, __) {
        final item = highlights[idx];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // تصميم العنوان
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(item.headerIcon, size: 18, color: kSourceTextColor),
                        const SizedBox(width: 6),
                        Text(
                          item.headerTitle,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: kSourceTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // تصميم المصدر
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      item.source,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // مؤشر الصفحات البسيط (بدون حاوية)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SmoothPageIndicator(
                controller: pageController,
                count: highlights.length,
                effect: ExpandingDotsEffect(
                  expansionFactor: 3,
                  dotHeight: 6,
                  dotWidth: 6,
                  dotColor: Colors.white.withOpacity(0.3),
                  activeDotColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}