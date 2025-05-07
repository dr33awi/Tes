// lib/screens/athkarscreen/athkar_screen.dart - تصحيح خطأ Color
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_details_screen.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart' 
    show kPrimary, kPrimaryLight, kSurface;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AthkarScreen extends StatefulWidget {
  const AthkarScreen({Key? key}) : super(key: key);

  @override
  State<AthkarScreen> createState() => _AthkarScreenState();
}

class _AthkarScreenState extends State<AthkarScreen> {
  // تصحيح المشكلة: استخدام List<Color> بدلاً من List<dynamic> للألوان
  final List<Map<String, dynamic>> _athkarCategories = [
    {
      'id': 'morning',
      'title': 'أذكار الصباح',
      'icon': Icons.wb_sunny,
      'description': 'الأذكار التي تقال في الصباح بعد صلاة الفجر حتى الضحى',
      'color1': const Color(0xFFFFD54F), 
      'color2': const Color(0xFFFFA000),
    },
    {
      'id': 'evening',
      'title': 'أذكار المساء',
      'icon': Icons.nightlight_round,
      'description': 'الأذكار التي تقال في المساء بعد صلاة العصر حتى صلاة العشاء',
      'color1': const Color(0xFFAB47BC), 
      'color2': const Color(0xFF7B1FA2),
    },
    {
      'id': 'sleep',
      'title': 'أذكار النوم',
      'icon': Icons.bedtime,
      'description': 'الأذكار التي تقال عند النوم',
      'color1': const Color(0xFF5C6BC0), 
      'color2': const Color(0xFF3949AB),
    },
    {
      'id': 'wake',
      'title': 'أذكار الاستيقاظ',
      'icon': Icons.alarm,
      'description': 'الأذكار التي تقال عند الاستيقاظ من النوم',
      'color1': const Color(0xFFFFB74D), 
      'color2': const Color(0xFFFF9800),
    },
    {
      'id': 'prayer',
      'title': 'أذكار الصلاة',
      'icon': Icons.mosque,
      'description': 'الأذكار التي تقال بعد الصلاة',
      'color1': const Color(0xFF4DB6AC), 
      'color2': const Color(0xFF00695C),
    },
    {
      'id': 'home',
      'title': 'أذكار المنزل',
      'icon': Icons.home,
      'description': 'الأذكار التي تقال عند دخول المنزل والخروج منه',
      'color1': const Color(0xFF66BB6A), 
      'color2': const Color(0xFF2E7D32),
    },
    {
      'id': 'food',
      'title': 'أذكار الطعام',
      'icon': Icons.restaurant,
      'description': 'الأذكار التي تقال قبل الطعام وبعده',
      'color1': const Color(0xFFE57373), 
      'color2': const Color(0xFFC62828),
    },
    {
      'id': 'quran',
      'title': 'أدعية قرآنية',
      'icon': Icons.menu_book,
      'description': 'أدعية من القرآن الكريم',
      'color1': const Color(0xFF9575CD), 
      'color2': const Color(0xFF512DA8),
    },
  ];
  
  // للتحكم في حالة التحميل
  bool _isLoading = true;
  
  // للتحكم في تأثيرات اللمس
  int? _pressedIndex;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // محاكاة تحميل البيانات
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'الأذكار',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: kPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // شرح وبيان أهمية الأذكار
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimary, kPrimaryLight],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            stops: const [0.3, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'فضل الأذكار',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'قال رسول الله ﷺ: «مثل الذي يذكر ربه والذي لا يذكر ربه مثل الحي والميت» [رواه البخاري]',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // عنوان أقسام الأذكار
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.category_rounded,
                          color: kPrimary,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'أقسام الأذكار',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // عرض قائمة الأذكار
                  Expanded(
                    child: _buildAthkarList(),
                  ),
                ],
              ),
            ),
    );
  }

  // بناء قائمة الأذكار المحسنة
  Widget _buildAthkarList() {
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: _athkarCategories.length,
          itemBuilder: (context, index) {
            final category = _athkarCategories[index];
            final bool isPressed = _isPressed && _pressedIndex == index;
            
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 500),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAthkarCategoryCard(category, index, isPressed),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // بناء بطاقة كل قسم من أقسام الأذكار - تصحيح استخدام الألوان
  Widget _buildAthkarCategoryCard(Map<String, dynamic> category, int index, bool isPressed) {
    return GestureDetector(
      onTap: () => _onCategoryTap(category, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(isPressed ? 0.95 : 1.0),
        child: Card(
          elevation: 3,
          // تصحيح استخدام Color
          shadowColor: (category['color1'] as Color).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  category['color1'] as Color, // صحيح: استخدام as Color
                  category['color2'] as Color,
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // أيقونة في الخلفية
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    category['icon'] as IconData,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                
                // محتوى البطاقة
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // دائرة الأيقونة
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            category['icon'] as IconData,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // نص العنوان والوصف
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (category['description'] != null)
                              Text(
                                category['description'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // أيقونة السهم
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // عند النقر على إحدى فئات الأذكار - تصحيح استخدام الألوان
  void _onCategoryTap(Map<String, dynamic> category, int index) {
    // تحديث حالة الضغط للحصول على تأثير النقر
    setState(() {
      _isPressed = true;
      _pressedIndex = index;
    });
    
    // الانتقال إلى صفحة تفاصيل الأذكار
    // قم بإنشاء كائن AthkarCategory من البيانات
    AthkarCategory athkarCategory = AthkarCategory(
      id: category['id'] as String,
      title: category['title'] as String,
      icon: category['icon'] as IconData,
      color: category['color1'] as Color, // تصحيح هنا
      description: category['description'] as String,
      athkar: [], // سيتم تحميل الأذكار في صفحة التفاصيل
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AthkarDetailsScreen(category: athkarCategory),
      ),
    );
    
    // إعادة ضبط حالة الضغط بعد فترة قصيرة
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
          _pressedIndex = null;
        });
      }
    });
  }

  // مؤشر التحميل
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: kPrimary,
            size: 50,
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل الأذكار...',
            style: TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}