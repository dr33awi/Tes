// lib/screens/home_screen/widgets/category_grid.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/favorites_screen/favorites_screen.dart';
import '../../hijri_date_time_header/hijri_date_time_header.dart'


    show kPrimary; // للحصول على لون الـ SnackBar

class CategoryGrid extends StatefulWidget {
  const CategoryGrid({Key? key}) : super(key: key);

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  // جاهزية الأنيميشن بعد أول فريم
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => mounted ? setState(() => _isReady = true) : null);
  }

  // قائمة الفئات المسبقة
  final List<Category> _categories = const [
    Category(title: r'التسبيح', icon: Icons.cyclone, color: Color(0xFFFFB300)),
    Category(
        title: r'الحديث',
        icon: Icons.format_quote_rounded,
        color: Color(0xFF4CAF50)),
    Category(title: r'الدعاء', icon: Icons.favorite_rounded, color: Color(0xFF9C27B0)),
    Category(
        title: r'القرآن',
        icon: Icons.menu_book_rounded,
        color: Color(0xFF009688)),
    Category(
        title: r'خلفيات', icon: Icons.wallpaper_rounded, color: Color(0xFF2196F3)),
    Category(
        title: r'تبرع',
        icon: Icons.card_giftcard_rounded,
        color: Color(0xFFFF9800)),
  Category(
    title: r'المفضلة',
    icon: Icons.favorite_rounded,
    color: Color(0xFFE91E63),
    screen: FavoritesScreen(), // صفحة المفضلة
  ),
  ];

  void _onCategoryTap(BuildContext context, Category cat) {
    if (cat.screen != null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => cat.screen!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('هذه الميزة قيد التطوير'),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 120,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
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
    final Widget btn = AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 400),
      columnCount: 3,
      child:
          ScaleAnimation(scale: 0.5, child: FadeInAnimation(child: _button(context, category))),
    );

    if (!_isReady) {
      return Container(
        decoration: BoxDecoration(
            color: category.color.withOpacity(.2),
            borderRadius: BorderRadius.circular(16)),
        child: _button(context, category),
      );
    }
    return btn;
  }

  Widget _button(BuildContext context, Category category) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onCategoryTap(context, category),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                category.color.withOpacity(.15),
                category.color.withOpacity(.35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(color: category.color, shape: BoxShape.circle),
                  child: Icon(category.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 8),
                AutoSizeText(
                  category.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  minFontSize: 10,
                  maxFontSize: 14,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium!
                      .copyWith(fontWeight: FontWeight.w700),
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
  const Category(
      {required this.title,
      required this.icon,
      required this.color,
      this.screen});

  final String title;
  final IconData icon;
  final Color color;
  final Widget? screen;
}
