// lib/screens/athkarscreen/screen/athkar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/athkarscreen/screen/athkar_details_screen.dart';
import 'package:test_athkar_app/screens/athkarscreen/model/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/screen/notification_settings_screen.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart' 
    show kPrimary, kSurface;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:test_athkar_app/services/di_container.dart';
import 'package:test_athkar_app/services/notification/notification_manager.dart';
import 'package:test_athkar_app/services/permissions_service.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/athkar_service.dart';

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
      'color1': const Color(0xFFFFD54F),
      'color2': const Color(0xFFFFA000),
      'defaultTime': '06:00',
    },
    {
      'id': 'evening',
      'title': 'أذكار المساء',
      'icon': Icons.nightlight_round,
      'color1': const Color(0xFFAB47BC),
      'color2': const Color(0xFF7B1FA2),
      'defaultTime': '17:00',
    },
    {
      'id': 'sleep',
      'title': 'أذكار النوم',
      'icon': Icons.bedtime,
      'color1': const Color(0xFF5C6BC0),
      'color2': const Color(0xFF3949AB),
      'defaultTime': '22:00',
    },
    {
      'id': 'wake',
      'title': 'أذكار الاستيقاظ',
      'icon': Icons.alarm,
      'color1': const Color(0xFFFFB74D),
      'color2': const Color(0xFFFF9800),
      'defaultTime': '05:30',
    },
    {
      'id': 'prayer',
      'title': 'أذكار الصلاة',
      'icon': Icons.mosque,
      'color1': const Color(0xFF4DB6AC),
      'color2': const Color(0xFF00695C),
      'defaultTime': '07:00',
    },
    {
      'id': 'home',
      'title': 'أذكار المنزل',
      'icon': Icons.home,
      'color1': const Color(0xFF66BB6A),
      'color2': const Color(0xFF2E7D32),
      'defaultTime': '08:00',
    },
    {
      'id': 'food',
      'title': 'أذكار الطعام',
      'icon': Icons.restaurant,
      'color1': const Color(0xFFE57373),
      'color2': const Color(0xFFC62828),
      'defaultTime': '12:00',
    },
  ];
  
  // للتحكم في حالة التحميل
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  
  // متغيرات للتأثيرات البصرية
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  int? _pressedIndex;
  bool _isPressed = false;

  // خدمات النظام
  late final NotificationManager _notificationManager;
  late final PermissionsService _permissionsService;
  late final AthkarService _athkarService;

  @override
  void initState() {
    super.initState();
    
    // تهيئة الخدمات
    _notificationManager = serviceLocator<NotificationManager>();
    _permissionsService = serviceLocator<PermissionsService>();
    _athkarService = AthkarService();
    
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
    
    // تحميل البيانات وتفعيل الإشعارات
    _initializeScreen();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // تهيئة الشاشة وتفعيل الإشعارات
  Future<void> _initializeScreen() async {
    try {
      // التحقق من حالة الإشعارات
      await _checkNotificationsStatus();
      
      // إذا كانت هذه هي المرة الأولى، قم بتفعيل الإشعارات الافتراضية
      await _setupDefaultNotificationsIfNeeded();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('خطأ في تهيئة الشاشة: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // التحقق من حالة الإشعارات
  Future<void> _checkNotificationsStatus() async {
    try {
      // التحقق من أي إشعارات مفعلة
      bool anyNotificationEnabled = false;
      for (final category in _athkarCategories) {
        final isEnabled = await _notificationManager.isNotificationEnabled(category['id']);
        if (isEnabled) {
          anyNotificationEnabled = true;
          break;
        }
      }
      
      setState(() {
        _notificationsEnabled = anyNotificationEnabled;
      });
    } catch (e) {
      print('خطأ في التحقق من حالة الإشعارات: $e');
    }
  }

  // إعداد الإشعارات الافتراضية إذا لزم الأمر
  Future<void> _setupDefaultNotificationsIfNeeded() async {
    try {
      // التحقق من الأذونات أولاً
      final hasPermission = await _permissionsService.checkNotificationsPermissions(
        context,
        showDialogs: false,
      );
      
      if (!hasPermission) {
        // طلب الأذونات إذا لم تكن موجودة
        await Future.delayed(Duration(seconds: 1));
        if (mounted) {
          final granted = await _permissionsService.showNotificationPermissionDialog(context);
          if (!granted) return;
        }
      }
      
      // التحقق من وجود إشعارات مجدولة
      final pendingNotifications = await _notificationManager.getPendingNotifications();
      final hasAthkarNotifications = pendingNotifications.any(
        (notification) => notification.payload?.contains('athkar_') ?? false,
      );
      
      if (!hasAthkarNotifications) {
        // جدولة الإشعارات الافتراضية لجميع أقسام الأذكار
        for (final category in _athkarCategories) {
          final timeParts = category['defaultTime'].split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final time = TimeOfDay(hour: hour, minute: minute);
          
          final result = await _notificationManager.scheduleAthkarNotifications(
            categoryId: category['id'] as String,
            categoryTitle: category['title'] as String,
            times: [time],
            customTitle: 'حان وقت ${category['title']}',
            customBody: 'اضغط هنا لقراءة ${category['title']}',
            color: category['color1'] as Color,
          );
          
          if (result.success) {
            print('تم جدولة إشعار ${category['title']}');
          }
        }
        
        setState(() {
          _notificationsEnabled = true;
        });
        
        // عرض رسالة نجاح
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text('تم تفعيل إشعارات الأذكار تلقائياً'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('خطأ في إعداد الإشعارات الافتراضية: $e');
    }
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
        // إضافة أيقونة إشعارات مع مؤشر الحالة
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  _notificationsEnabled 
                    ? Icons.notifications_active 
                    : Icons.notifications_off,
                  color: kPrimary,
                ),
                tooltip: 'إعدادات الإشعارات',
                onPressed: () => _navigateToNotificationSettings(),
              ),
              if (_notificationsEnabled)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kSurface,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
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
                              elevation: 15,
                              shadowColor: kPrimary.withOpacity(0.3),
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
                                      kPrimary,
                                      Color(0xFF2D6852), // لون غامق لمزيد من العمق
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
                                          child: Text(
                                            'فضل الأذكار',
                                            style: const TextStyle(
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
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                                              child: Text(
                                                'قال رسول الله ﷺ: مثل الذي يذكر ربه والذي لا يذكر ربه مثل الحي والميت',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
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
                                          child: Text(
                                            'رواه البخاري',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // إضافة تنبيه الإشعارات إذا لم تكن مفعلة
                                      if (!_notificationsEnabled)
                                        Container(
                                          margin: EdgeInsets.only(top: 12),
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.orange.withOpacity(0.4),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.notifications_off,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'الإشعارات غير مفعلة. اضغط على أيقونة الإشعارات في الأعلى للتفعيل.',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
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
                    ),
                    
                    const SizedBox(height: 12),
                    
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

  // التنقل إلى شاشة إعدادات الإشعارات
  void _navigateToNotificationSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
    
    // تحديث حالة الإشعارات بعد العودة
    if (result != null || true) {
      await _checkNotificationsStatus();
    }
  }

  // بناء قائمة الأذكار المحسنة
  Widget _buildAthkarList() {
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
              duration: const Duration(milliseconds: 500),
              columnCount: 2,
              child: ScaleAnimation(
                scale: 0.9,
                child: FadeInAnimation(
                  child: _buildAthkarCategoryCard(category, index),
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
                    padding: const EdgeInsets.all(16),
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
                                offset: Offset(0, 2),
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
      description: '', // قيمة فارغة للوصف حيث تم إزالته
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