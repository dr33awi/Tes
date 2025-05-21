// lib/features/athkar/presentation/screens/athkar_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../app/di/service_locator.dart';
import '../../data/datasources/athkar_service.dart';
import '../../domain/entities/athkar.dart';
import '../../../../app/themes/loading_widget.dart';
import 'athkar_details_screen.dart';

class AthkarCategoriesScreen extends StatefulWidget {
  const AthkarCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<AthkarCategoriesScreen> createState() => _AthkarCategoriesScreenState();
}

class _AthkarCategoriesScreenState extends State<AthkarCategoriesScreen> with SingleTickerProviderStateMixin {
  // استخدام AthkarService مباشرة
  final AthkarService _athkarService = AthkarService();
  
  // للتحكم في حالة التحميل
  bool _isLoading = true;
  List<dynamic> _categories = [];
  String? _error;
  
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
    
    _loadCategories();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // تحميل فئات الأذكار
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final categories = await _athkarService.loadAllAthkarCategories();
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ أثناء تحميل البيانات: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الأذكار',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _error != null
              ? _buildErrorWidget()
              : _buildCategoriesList(),
    );
  }

  // عرض خطأ
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ أثناء تحميل البيانات',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // بناء قائمة الفئات
  Widget _buildCategoriesList() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimationLimiter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 500),
                columnCount: 2,
                child: ScaleAnimation(
                  scale: 0.9,
                  child: FadeInAnimation(
                    child: _buildCategoryCard(context, category, index),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // بناء بطاقة الفئة
  Widget _buildCategoryCard(BuildContext context, dynamic category, int index) {
    final bool isPressed = _isPressed && _pressedIndex == index;
    final Color categoryColor = _getCategoryColor(category.id);
    
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
          shadowColor: categoryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor,
                  categoryColor.withOpacity(0.7),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة الفئة
                  Icon(
                    _getIconFromString(category.icon),
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  // اسم الفئة
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // وصف الفئة (إذا وجد)
                  if (category.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // عند النقر على الفئة
  void _onCategoryTap(dynamic category, int index) {
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
    Navigator.pushNamed(
      context,
      '/athkar-details',
      arguments: {
        'category': category,
      },
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

  // الحصول على لون للفئة
  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const Color(0xFFFFD54F); // أصفر للصباح
      case 'evening':
        return const Color(0xFFAB47BC); // بنفسجي للمساء
      case 'sleep':
        return const Color(0xFF5C6BC0); // أزرق للنوم
      case 'wake':
        return const Color(0xFFFFB74D); // برتقالي للاستيقاظ
      case 'prayer':
        return const Color(0xFF4DB6AC); // أخضر مزرق للصلاة
      case 'home':
        return const Color(0xFF66BB6A); // أخضر للمنزل
      case 'food':
        return const Color(0xFFE57373); // أحمر للطعام
      case 'quran':
        return const Color(0xFF9575CD); // بنفسجي فاتح للقرآن
      default:
        return Theme.of(context).primaryColor; // لون افتراضي
    }
  }
  
  // تحويل نص الأيقونة إلى IconData
  IconData _getIconFromString(String iconString) {
    // تعيين نصوص الأيقونة إلى كائنات IconData
    Map<String, IconData> iconMap = {
      'Icons.wb_sunny': Icons.wb_sunny,
      'Icons.nightlight_round': Icons.nightlight_round,
      'Icons.bedtime': Icons.bedtime,
      'Icons.alarm': Icons.alarm,
      'Icons.mosque': Icons.mosque,
      'Icons.home': Icons.home,
      'Icons.restaurant': Icons.restaurant,
      'Icons.menu_book': Icons.menu_book,
      'Icons.favorite': Icons.favorite,
      'Icons.star': Icons.star,
      'Icons.water_drop': Icons.water_drop,
      'Icons.insights': Icons.insights,
      'Icons.travel_explore': Icons.travel_explore,
      'Icons.healing': Icons.healing,
      'Icons.family_restroom': Icons.family_restroom,
      'Icons.school': Icons.school,
      'Icons.work': Icons.work,
      'Icons.emoji_events': Icons.emoji_events,
      'Icons.auto_awesome': Icons.auto_awesome,
      'Icons.label_important': Icons.label_important,
    };
    
    return iconMap[iconString] ?? Icons.label_important;
  }
}