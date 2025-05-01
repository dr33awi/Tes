import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AthkarScreen extends StatelessWidget {
  const AthkarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // قائمة أنواع الأذكار المختلفة
    final athkarCategories = [
      {'title': 'أذكار الصباح', 'icon': Icons.wb_sunny},
      {'title': 'أذكار المساء', 'icon': Icons.nightlight_round},
      {'title': 'أذكار النوم', 'icon': Icons.bedtime},
      {'title': 'أذكار الاستيقاظ', 'icon': Icons.alarm},
      {'title': 'أذكار الصلاة', 'icon': Icons.mosque},
      {'title': 'أذكار المنزل', 'icon': Icons.home},
      {'title': 'أذكار الطعام', 'icon': Icons.restaurant},
      {'title': 'أدعية قرآنية', 'icon': Icons.menu_book},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE7E8E3),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              // زر العودة وعنوان الصفحة
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF447055),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'الأذكار',
                          style: TextStyle(
                            color: Color(0xFF447055),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    // إضافة عنصر غير مرئي للتوازن
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              // باقي المحتوى كما هو
              Expanded(
                child: AnimationLimiter(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: athkarCategories.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        columnCount: 2,
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // التنقل إلى صفحة تفاصيل الذكر (ستقوم بإنشائها لاحقاً)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('تم اختيار ${athkarCategories[index]['title']}'),
                                      backgroundColor: const Color(0xFF447055),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      athkarCategories[index]['icon'] as IconData,
                                      size: 48,
                                      color: const Color(0xFF447055),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      athkarCategories[index]['title'] as String,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF447055),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}