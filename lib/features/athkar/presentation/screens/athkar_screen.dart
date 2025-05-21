// lib/features/athkar/presentation/screens/athkar_screen.dart
import 'package:athkar_app/features/athkar/data/datasources/di_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../screens/notification_settings_screen.dart';

import '../../../../core/services/utils/notification_scheduler.dart';
import '../../data/datasources/athkar_service.dart';
import '../../domain/entities/athkar.dart';
import '../../../../app/themes/loading_widget.dart';


class AthkarScreen extends StatefulWidget {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<Athkar> athkar;

  const AthkarScreen({
    Key? key,
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.athkar = const [],
  }) : super(key: key);

  @override
  State<AthkarScreen> createState() => _AthkarScreenState();
}

class _AthkarScreenState extends State<AthkarScreen> with SingleTickerProviderStateMixin {
  // Service to manage athkar data
  final AthkarService _athkarService = AthkarService();
  
  // قائمة فئات الأذكار
  final List<Map<String, dynamic>> _athkarCategories = [
    {
      'id': 'morning',
      'title': 'أذكار الصباح',
      'icon': Icons.wb_sunny,
      'color1': const Color(0xFFFFD54F),
      'color2': const Color(0xFFFFA000),
    },
    {
      'id': 'evening',
      'title': 'أذكار المساء',
      'icon': Icons.nightlight_round,
      'color1': const Color(0xFFAB47BC),
      'color2': const Color(0xFF7B1FA2),
    },
    {
      'id': 'sleep',
      'title': 'أذكار النوم',
      'icon': Icons.bedtime,
      'color1': const Color(0xFF5C6BC0),
      'color2': const Color(0xFF3949AB),
    },
    {
      'id': 'wake',
      'title': 'أذكار الاستيقاظ',
      'icon': Icons.alarm,
      'color1': const Color(0xFFFFB74D),
      'color2': const Color(0xFFFF9800),
    },
    {
      'id': 'prayer',
      'title': 'أذكار الصلاة',
      'icon': Icons.mosque,
      'color1': const Color(0xFF4DB6AC),
      'color2': const Color(0xFF00695C),
    },
    {
      'id': 'home',
      'title': 'أذكار المنزل',
      'icon': Icons.home,
      'color1': const Color(0xFF66BB6A),
      'color2': const Color(0xFF2E7D32),
    },
    {
      'id': 'food',
      'title': 'أذكار الطعام',
      'icon': Icons.restaurant,
      'color1': const Color(0xFFE57373),
      'color2': const Color(0xFFC62828),
    },
  ];
  
  // متغيرات للتأثيرات البصرية
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  int? _pressedIndex;
  bool _isPressed = false;
  
  // Get notification scheduler from service locator
  late final NotificationScheduler _notificationScheduler;

  @override
  void initState() {
    super.initState();
    
    try {
      _notificationScheduler = serviceLocator<NotificationScheduler>();
    } catch (e) {
      debugPrint('Error loading notification scheduler: $e');
      // Provide fallback if service locator is not available in testing
    }
    
    // إعداد الأنيميشن - تم تسريع الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
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
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        title: Text(
          widget.name,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // زر إعدادات الإشعارات
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_active,
              color: colorScheme.primary,
            ),
            tooltip: 'إشعارات',
            onPressed: () => _navigateToNotificationSettings(),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // شرح وبيان أهمية الأذكار
              _buildHeaderCard(context, colorScheme),
              
              const SizedBox(height: 12),
              
              // عرض قائمة الأذكار
              _buildAthkarList(context),
              
              // مساحة إضافية في النهاية
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // التنقل إلى شاشة إعدادات الإشعارات
  void _navigateToNotificationSettings() async {
    // فتح صفحة إعدادات الإشعارات
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }
  
  // بناء بطاقة المعلومات في الأعلى
  Widget _buildHeaderCard(BuildContext context, ColorScheme colorScheme) {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 300),
      child: SlideAnimation(
        verticalOffset: 30.0,
        child: FadeInAnimation(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Card(
              elevation: 15,
              shadowColor: colorScheme.primary.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.7),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عنوان فضل الأذكار على اليمين
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'فضل الأذكار',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      
                      // قسم الاقتباس
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // علامة اقتباس في البداية
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Icon(
                                Icons.format_quote,
                                size: 16,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            
                            // نص الحديث
                            const Padding(
                              padding: EdgeInsets.fromLTRB(6, 6, 6, 6),
                              child: Text(
                                'قال رسول الله ﷺ: مثل الذي يذكر ربه والذي لا يذكر ربه مثل الحي والميت',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  height: 1.8,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Amiri-Bold',
                                ),
                              ),
                            ),
                            
                            // علامة اقتباس في النهاية
                            Positioned(
                              bottom: -4,
                              left: -4,
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
                      
                      // المصدر
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'رواه البخاري',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // بناء قائمة الأذكار المحسنة
  Widget _buildAthkarList(BuildContext context) {
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _athkarCategories.length,
          itemBuilder: (context, index) {
            final category = _athkarCategories[index];
            
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 350),
              columnCount: 2,
              child: ScaleAnimation(
                scale: 0.9,
                child: FadeInAnimation(
                  child: _buildAthkarCategoryCard(context, category, index),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // بناء بطاقة كل قسم من أقسام الأذكار
  Widget _buildAthkarCategoryCard(BuildContext context, Map<String, dynamic> category, int index) {
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
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    category['icon'] as IconData,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                
                // محتوى البطاقة
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // دائرة الأيقونة
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              category['icon'] as IconData,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // نص العنوان
                        Text(
                          category['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
  void _onCategoryTap(Map<String, dynamic> category, int index) async {
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
    
    try {
      // تحميل فئة الأذكار باستخدام AthkarService
      final athkarCategory = await _athkarService.getAthkarCategory(category['id'] as String);
      
      if (athkarCategory != null && mounted) {
        // الانتقال إلى صفحة تفاصيل الأذكار
        Navigator.pushNamed(
          context,
          '/athkar-details',
          arguments: {
            'category': athkarCategory,
          },
        );
      } else {
        // في حالة عدم وجود البيانات، استخدام البيانات المحلية
        final String categoryId = category['id'] as String;
        final String categoryTitle = category['title'] as String;
        
        Navigator.pushNamed(
          context,
          '/athkar-details',
          arguments: {
            'categoryId': categoryId,
            'categoryName': categoryTitle,
            'description': '',
            'icon': _iconDataToString(category['icon'] as IconData),
          },
        );
      }
    } catch (e) {
      debugPrint('Error loading category: $e');
      // إظهار رسالة للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحميل الأذكار: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
    
    // إعادة ضبط حالة الضغط بعد فترة قصيرة
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
          _pressedIndex = null;
        });
      }
    });
  }
  
  // تحويل IconData إلى نص
  String _iconDataToString(IconData iconData) {
    if (iconData == Icons.wb_sunny) return 'Icons.wb_sunny';
    if (iconData == Icons.nightlight_round) return 'Icons.nightlight_round';
    if (iconData == Icons.bedtime) return 'Icons.bedtime';
    if (iconData == Icons.alarm) return 'Icons.alarm';
    if (iconData == Icons.mosque) return 'Icons.mosque';
    if (iconData == Icons.home) return 'Icons.home';
    if (iconData == Icons.restaurant) return 'Icons.restaurant';
    return 'Icons.auto_awesome';
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