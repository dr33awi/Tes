// lib/features/athkar/presentation/widgets/athkar_grid_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../app/routes/app_router.dart';

import '../../data/datasources/athkar_service.dart';

class AthkarGridSection extends StatefulWidget {
  const AthkarGridSection({Key? key}) : super(key: key);

  @override
  State<AthkarGridSection> createState() => _AthkarGridSectionState();
}

class _AthkarGridSectionState extends State<AthkarGridSection> {
  final AthkarService _athkarService = AthkarService();
  
  // للتحكم في حالة التحميل
  bool _isLoading = true;
  List<dynamic> _featuredCategories = [];
  
  @override
  void initState() {
    super.initState();
    _loadFeaturedCategories();
  }
  
  // تحميل فئات الأذكار المميزة
  Future<void> _loadFeaturedCategories() async {
    try {
      final allCategories = await _athkarService.loadAllAthkarCategories();
      
      // حدد الفئات التي تريد عرضها في الشاشة الرئيسية
      final List<dynamic> featured = [];
      
      // إذا كانت الفئات متاحة، اختر المناسبة منها
      if (allCategories.isNotEmpty) {
        for (var category in allCategories) {
          if (['morning', 'evening', 'sleep', 'wake', 'prayer', 'quran'].contains(category.id)) {
            featured.add(category);
            if (featured.length >= 4) break; // اكتفي بأربعة فئات
          }
        }
        
        // إذا لم نجد الفئات المطلوبة، استخدم أي فئات متاحة
        if (featured.isEmpty && allCategories.length > 0) {
          featured.addAll(allCategories.take(4));
        }
      }
      
      if (mounted) {
        setState(() {
          _featuredCategories = featured;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading featured categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان القسم مع زر عرض المزيد
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الأذكار',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.athkarCategories);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('عرض الكل'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(),
            
            // محتوى القسم
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _featuredCategories.isEmpty
                    ? _buildEmptyState()
                    : _buildGridCategories(),
          ],
        ),
      ),
    );
  }
  
  // بناء حالة عدم وجود فئات
  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          'لا توجد أذكار متاحة حالياً',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
  
  // بناء شبكة الفئات المميزة
  Widget _buildGridCategories() {
    return AnimationLimiter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _featuredCategories.length,
        itemBuilder: (context, index) {
          final category = _featuredCategories[index];
          
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 400),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildCategoryCard(category),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // بناء بطاقة فئة
  Widget _buildCategoryCard(dynamic category) {
    final Color categoryColor = _getCategoryColor(category.id);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          // الانتقال إلى صفحة تفاصيل الفئة
          Navigator.pushNamed(
            context,
            AppRouter.athkarDetails,
            arguments: {
              'category': category,
            },
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                categoryColor.withOpacity(0.8),
                categoryColor.withOpacity(0.6),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconFromString(category.icon),
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        return Colors.teal; // لون افتراضي
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