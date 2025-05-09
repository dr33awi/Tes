// lib/screens/athkarscreen/athkar_screen.dart - محسّن
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/athkarscreen/screen/athkar_details_screen.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart' 
    show kPrimary, kPrimaryLight, kSurface;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AthkarScreen extends StatefulWidget {
  const AthkarScreen({Key? key}) : super(key: key);

  @override
  State<AthkarScreen> createState() => _AthkarScreenState();
}

class _AthkarScreenState extends State<AthkarScreen> with SingleTickerProviderStateMixin {
  // قائمة فئات الأذكار
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
  
  // متغيرات للتأثيرات البصرية
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  int? _pressedIndex;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7),
      ),
    );
    
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الأذكار',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: kPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // أزلنا action الإضافي
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // شرح وبيان أهمية الأذكار
                    AnimationConfiguration.synchronized(
                      duration: const Duration(milliseconds: 400),
                      child: SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Card(
                              elevation: 8,
                              shadowColor: kPrimary.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
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
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kPrimary.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // نمط زخرفي في الخلفية
                                    Positioned(
                                      right: -20,
                                      top: -20,
                                      child: Opacity(
                                        opacity: 0.08,
                                        child: Image.asset(
                                          'assets/images/islamic_pattern.png',
                                          width: 100,
                                          height: 100,
                                          errorBuilder: (context, error, stackTrace) {
                                            // إذا لم يتم العثور على الصورة، استخدم أيقونة بديلة
                                            return Icon(
                                              Icons.format_quote,
                                              size: 80,
                                              color: Colors.white.withOpacity(0.1),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.info_outline,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'فضل الأذكار',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.15),
                                              width: 1,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              // علامة اقتباس في البداية
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Icon(
                                                  Icons.format_quote,
                                                  size: 16,
                                                  color: Colors.white.withOpacity(0.5),
                                                ),
                                              ),
                                              
                                              Center(
                                                child: Text(
                                                  'قال رسول الله ﷺ: «مثل الذي يذكر ربه والذي لا يذكر ربه مثل الحي والميت»',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    height: 1.8,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Amiri-Bold',
                                                  ),
                                                ),
                                              ),
                                              
                                              // علامة اقتباس في النهاية
                                              Positioned(
                                                bottom: 0,
                                                left: 0,
                                                child: Transform.rotate(
                                                  angle: 3.14, // 180 درجة
                                                  child: Icon(
                                                    Icons.format_quote,
                                                    size: 16,
                                                    color: Colors.white.withOpacity(0.5),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        SizedBox(height: 8),
                                        Center(
                                          child: Container(
                                            margin: EdgeInsets.only(top: 8),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Text(
                                              'رواه البخاري',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // عنوان أقسام الأذكار
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            color: kPrimary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
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
                    
                    const SizedBox(height: 8),
                    
                    // عرض قائمة الأذكار
                    _buildAthkarList(),
                    
                    // مساحة إضافية في النهاية
                    SizedBox(height: 20),
                  ],
                ),
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
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _athkarCategories.length,
          itemBuilder: (context, index) {
            final category = _athkarCategories[index];
            
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 500),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAthkarCategoryCard(category, index),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // بناء بطاقة كل قسم من أقسام الأذكار
  Widget _buildAthkarCategoryCard(Map<String, dynamic> category, int index) {
    final bool isPressed = _isPressed && _pressedIndex == index;
    
    return GestureDetector(
      onTap: () => _onCategoryTap(category, index),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isPressed ? 0.95 : 1.0,
            child: child!,
          );
        },
        child: Card(
          elevation: 8,
          shadowColor: (category['color1'] as Color).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  category['color1'] as Color,
                  category['color2'] as Color,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: const [0.3, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // أيقونة في الخلفية
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    category['icon'] as IconData,
                    size: 100,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                
                // محتوى البطاقة
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: IntrinsicHeight( // يضمن ارتفاع متساوٍ
                    child: Row(
                      children: [
                        // دائرة الأيقونة
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
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
                              const SizedBox(height: 8),
                              if (category['description'] != null)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    category['description'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // أيقونة السهم
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
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
    );
  }

  // عند النقر على إحدى فئات الأذكار
  void _onCategoryTap(Map<String, dynamic> category, int index) {
    // تحديث حالة الضغط للحصول على تأثير النقر
    setState(() {
      _isPressed = true;
      _pressedIndex = index;
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    // تشغيل انيميشن النبض
    _animationController.reset();
    _animationController.forward();
    
    // الانتقال إلى صفحة تفاصيل الأذكار
    AthkarCategory athkarCategory = AthkarCategory(
      id: category['id'] as String,
      title: category['title'] as String,
      icon: category['icon'] as IconData,
      color: category['color1'] as Color,
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
          const SizedBox(height: 20),
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