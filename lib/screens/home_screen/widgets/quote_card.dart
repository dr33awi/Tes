import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/models/daily_quote_model.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart' show kSurface;

const Color kQuoteTextColor = Color(0xFF2F5943);

class QuoteCard extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final HighlightItem quoteItem;
  final int index;

  const QuoteCard({
    Key? key,
    required this.text,
    this.onTap,
    required this.quoteItem,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 400),
      child: FadeInAnimation(
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(onTap == null ? .06 : .1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textSpan = TextSpan(
                  text: text,
                  style: const TextStyle(
                    fontFamily: 'Amiri-Bold',
                    fontSize: 14,
                    height: 1.9,
                    fontWeight: FontWeight.w700,
                    color: kQuoteTextColor,
                  ),
                );
                final textPainter = TextPainter(
                  text: textSpan,
                  textDirection: TextDirection.rtl,
                  maxLines: 5,
                );
                textPainter.layout(maxWidth: constraints.maxWidth - 48);

                if (textPainter.didExceedMaxLines) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: ScrollbarTheme(
                      data: ScrollbarThemeData(
                        thumbColor: MaterialStateProperty.all(kQuoteTextColor.withOpacity(0.5)),
                        thickness: MaterialStateProperty.all(4),
                        radius: const Radius.circular(8),
                      ),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Amiri-Bold',
                              fontSize: 14,
                              height: 1.9,
                              fontWeight: FontWeight.w700,
                              color: kQuoteTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: AutoSizeText(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Amiri-Bold',
                          fontSize: 14,
                          height: 1.9,
                          fontWeight: FontWeight.w700,
                          color: kQuoteTextColor,
                        ),
                        maxLines: 5,
                        wrapWords: true,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}