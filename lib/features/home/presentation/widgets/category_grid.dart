// lib/features/home/presentation/widgets/category_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../prayers/presentation/screens/prayer_times_screen.dart';
import '../../../athkar/presentation/screens/athkar_screen.dart';
import '../../../home/favorites/presentation/screens/favorites_screen.dart';
class CategoryGrid extends StatefulWidget {
  const CategoryGrid({Key? key}) : super(key: key);

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> with SingleTickerProviderStateMixin {
  // جاهزية الأنيميشن بعد أول فريم
  bool _isReady = false;
  
  // لتأثيرات الضغط على الأزرار
  int? _pressedIndex;
  bool _isPressed = false;
  
  // للتحكم في تأثير النبض
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => mounted ? setState(() => _isReady = true) : null);
    
    // إعداد تأثير النبض
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7),
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Updated category list - now with Athkar button
  final List<Category> _categories = const [
    Category(
      title: 'مواقيت الصلاة',
      icon: Icons.access_time,
      color: Color(0xFF00BCD4),
      gradientColors: [Color(0xFF00BCD4), Color(0xFF80DEEA)],
      screen: PrayerTimesScreen(),
    ),
    Category(
      title: 'الأذكار',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF2E7D32),
      gradientColors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      routeName: '/athkar',
    ),
    Category(
      title: 'القرآن',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF00695C),
      gradientColors: [Color(0xFF00695C), Color(0xFF4DB6AC)],
    ),
        Category(
      title: 'المفضلة',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF2E7D32),
      gradientColors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      routeName: 'FavoritesScreen',
    ),
    Category(
      title: 'الدعاء',
      icon: Icons.healing,
      color: Color(0xFF6A1B9A),
      gradientColors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
    ),
  ];

  void _onCategoryTap(BuildContext context, Category cat, int index) {
    // تحديث مؤشر الضغط
    setState(() {
      _isPressed = true;
      _pressedIndex = index;
    });
    
    // تشغيل تأثير النبض
    _animationController.reset();
    _animationController.forward();
    
    if (cat.screen != null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => cat.screen!));
    } else if (cat.routeName != null) {
      Navigator.pushNamed(context, cat.routeName!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Text('هذه الميزة قيد التطوير'),
            ],
          ),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
    }
    
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

  @override
  Widget build(BuildContext context) {
    // تعديل حجم الشبكة
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 عناصر في الصف
          crossAxisSpacing: 10, // تقليل المسافة بين العناصر
          mainAxisSpacing: 10,
          childAspectRatio: 1.0, // نسبة العرض للارتفاع
        ),
        delegate: SliverChildBuilderDelegate(
          (context, int index) =>
              _buildCategoryItem(context, _categories[index], index),
          childCount: _categories.length,
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
      BuildContext context, Category category, int index) {
    final bool isPressed = _isPressed && _pressedIndex == index;
    
    final Widget btn = AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 600),
      columnCount: 3,
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Transform.scale(
            scale: isPressed ? 0.95 : 1.0,
            child: _button(context, category, index),
          ),
        ),
      ),
    );

    if (!_isReady) {
      return Container(
        decoration: BoxDecoration(
            color: category.color.withOpacity(.2),
            borderRadius: BorderRadius.circular(16)),
        child: _button(context, category, index),
      );
    }
    return btn;
  }

  Widget _button(BuildContext context, Category category, int index) {
    // تصميم على غرار بطاقات صفحة المفضلة
    return Card(
      elevation: 8, // زيادة الظل مثل صفحة المفضلة
      shadowColor: category.color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18), // زيادة انحناء الحواف قليلا
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _onCategoryTap(context, category, index),
          child: Container(
            decoration: BoxDecoration(
              // تدرج لوني مشابه للتدرج في صفحة المفضلة
              gradient: LinearGradient(
                colors: category.gradientColors,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: const [0.3, 1.0], // نفس قيم التوقف كما في صفحة المفضلة
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: category.color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            // توسيط العناصر
            child: Stack(
              children: [
                // أيقونة زخرفية كبيرة في الخلفية (مشابهة لصفحة المفضلة)
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    category.icon,
                    size: 80, // حجم كبير للأيقونة الخلفية مثل صفحة المفضلة
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                
                // المحتوى الأساسي
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // حاوية دائرية للأيقونة
                        Container(
                          width: 45, // زيادة حجم الدائرة ليناسب صفحة المفضلة
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              category.icon, 
                              color: Colors.white, 
                              size: 25, // زيادة حجم الأيقونة
                            ),
                          ),
                        ),
                        const SizedBox(height: 6), // زيادة المسافة قليلا
                        
                        // نص العنوان (أكبر من قبل)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            category.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13, // زيادة حجم الخط
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
}

// نموذج الفئة
class Category {
  const Category({
    required this.title,
    required this.icon,
    required this.color,
    required this.gradientColors,
    this.screen,
    this.routeName,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  final Widget? screen;
  final String? routeName;
}