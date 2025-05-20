// lib/features/prayers/presentation/screens/enhanced_qibla_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/services/interfaces/qibla_service.dart';
import '../providers/prayer_times_provider.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/loading_widget.dart';

class EnhancedQiblaScreen extends StatefulWidget {
  const EnhancedQiblaScreen({super.key});

  @override
  State<EnhancedQiblaScreen> createState() => _EnhancedQiblaScreenState();
}

class _EnhancedQiblaScreenState extends State<EnhancedQiblaScreen> with SingleTickerProviderStateMixin {
  StreamSubscription<double>? _qiblaSubscription;
  double _direction = 0.0;
  double _animationAngle = 0.0;
  bool _compassAvailable = false;
  bool _isLoading = true;
  bool _isCalibrating = false;

  // للتحكم في الرسوم المتحركة
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
    
    _checkCompassAvailability();
    _initQiblaDirection();
  }

  @override
  void dispose() {
    _qiblaSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkCompassAvailability() async {
    // في التطبيق الحقيقي، يجب استخدام خدمة QiblaService لفحص توفر البوصلة
    // هنا نفترض أنها متوفرة للتبسيط
    setState(() {
      _compassAvailable = true;
      _isLoading = false;
    });
  }

  Future<void> _initQiblaDirection() async {
    final provider = Provider.of<PrayerTimesProvider>(context, listen: false);
    
    if (!provider.hasLocation) {
      // تعيين موقع افتراضي مؤقت (مكة المكرمة)
      provider.setLocation(
        latitude: 21.422510,
        longitude: 39.826168,
      );
    }
    
    // تحميل اتجاه القبلة
    if (provider.qiblaDirection == null) {
      await provider.loadQiblaDirection();
    }
    
    // في التطبيق الحقيقي، يمكننا استخدام QiblaService للحصول على تدفق بيانات البوصلة
    // هنا، سنقوم بمحاكاة تغيير الاتجاه لأغراض التوضيح
    
    // محاكاة وجود بوصلة باستخدام مؤقت
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _direction = (_direction + 1) % 360;
          // تحريك الإبرة بسلاسة أكثر
          _animationAngle = _animationAngle * 0.9 + _direction * 0.1;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startCalibration() {
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    setState(() {
      _isCalibrating = true;
    });
    
    // نبض متكرر أثناء المعايرة
    _animationController.repeat(reverse: true);
    
    // محاكاة انتهاء المعايرة بعد 3 ثوانٍ
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isCalibrating = false;
        });
        _animationController.stop();
        _animationController.reset();
        
        // تأثير اهتزاز بعد الانتهاء
        HapticFeedback.mediumImpact();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('تمت معايرة البوصلة بنجاح'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'اتجاه القبلة',
        transparent: true,
        actions: [
          // زر المعايرة
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'معايرة البوصلة',
            onPressed: _startCalibration,
          ),
          // زر الإعدادات
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'معلومات عن القبلة',
            onPressed: _showQiblaInfo,
          ),
        ],
      ),
      body: Consumer<PrayerTimesProvider>(
        builder: (context, provider, child) {
          if (_isLoading || provider.isLoading) {
            return _buildLoadingWidget();
          }
          
          if (!provider.hasLocation) {
            return _buildLocationRequestWidget(provider);
          }
          
          if (!_compassAvailable) {
            return _buildCompassNotAvailableWidget();
          }
          
          if (provider.qiblaDirection == null) {
            return _buildNoQiblaDataWidget(provider);
          }
          
          return _buildQiblaCompassWidget(provider);
        },
      ),
    );
  }
  
  // عرض مؤشر التحميل
  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.5),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingWidget(),
            SizedBox(height: 20),
            Text(
              'جاري تحميل اتجاه القبلة...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // طلب الموقع
  Widget _buildLocationRequestWidget(PrayerTimesProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: AnimationLimiter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 600),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_off,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'يرجى السماح بالوصول إلى الموقع',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'نحتاج إلى موقعك الحالي لتحديد اتجاه القبلة بدقة',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      // تعيين موقع افتراضي مؤقت (مكة المكرمة)
                      provider.setLocation(
                        latitude: 21.422510,
                        longitude: 39.826168,
                      );
                      provider.loadQiblaDirection();
                      setState(() {
                        _isLoading = true;
                      });
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('استخدام موقع افتراضي'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // البوصلة غير متوفرة
  Widget _buildCompassNotAvailableWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: AnimationLimiter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 600),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.compass_calibration_outlined,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'البوصلة غير متوفرة',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'يرجى التأكد من أن جهازك يحتوي على مستشعر البوصلة وأنه مفعل',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('العودة'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // لا توجد بيانات اتجاه القبلة
  Widget _buildNoQiblaDataWidget(PrayerTimesProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: AnimationLimiter(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                const Text(
                  'لم يتم تحميل اتجاه القبلة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    provider.loadQiblaDirection().then((_) {
                      setState(() {
                        _isLoading = false;
                      });
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحميل اتجاه القبلة'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  // بوصلة القبلة
  Widget _buildQiblaCompassWidget(PrayerTimesProvider provider) {
    final qiblaDirection = provider.qiblaDirection!;
    final actualDirection = (qiblaDirection - _animationAngle) % 360;
    final primaryColor = Theme.of(context).primaryColor;
    final kaaba = const Color(0xFF3E2723);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withOpacity(0.8),
            primaryColor.withOpacity(0.5),
          ],
        ),
      ),
      child: Column(
        children: [
          // المساحة الفارغة في الأعلى للـ AppBar
          const SizedBox(height: 100),
          
          AnimationConfiguration.synchronized(
            duration: const Duration(milliseconds: 800),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'اتجاه القبلة: ${qiblaDirection.toStringAsFixed(1)}°',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // وصف الاستخدام
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'قم بتوجيه الجزء العلوي من الهاتف نحو القبلة',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: AnimationConfiguration.synchronized(
              duration: const Duration(milliseconds: 1200),
              child: SlideAnimation(
                verticalOffset: 100.0,
                child: FadeInAnimation(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isCalibrating ? _pulseAnimation.value : 1.0,
                          child: child,
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // الدائرة الخارجية والشمال
                          Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 5,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // إشارات الاتجاهات
                                ...List.generate(4, (index) {
                                  final angle = index * 90.0;
                                  final label = _getDirectionLabel(angle);
                                  return Positioned(
                                    top: 150 + 120 * math.sin(math.pi * 2 * angle / 360) - 15,
                                    left: 150 + 120 * math.cos(math.pi * 2 * angle / 360) - 15,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.2),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                
                                // درجات البوصلة
                                ...List.generate(24, (index) {
                                  if (index % 3 == 0) return const SizedBox.shrink();
                                  final angle = index * 15.0;
                                  return Transform.rotate(
                                    angle: math.pi * 2 * angle / 360,
                                    child: Align(
                                      alignment: const Alignment(0, -0.9),
                                      child: Container(
                                        height: 10,
                                        width: 2,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          
                          // عقرب القبلة
                          Transform.rotate(
                            angle: math.pi * 2 * actualDirection / 360,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // الظل
                                Container(
                                  width: 230,
                                  height: 230,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                                // البوصلة الداخلية
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.15),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                
                                // صورة الكعبة
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: kaaba,
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.amber.shade600,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.home,
                                      size: 40,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                                
                                // مؤشر القبلة
                                Align(
                                  alignment: const Alignment(0, -0.7),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // خط القبلة
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    width: 4,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(4),
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
          
          // معلومات القبلة
          AnimationConfiguration.synchronized(
            duration: const Duration(milliseconds: 1500),
            child: SlideAnimation(
              verticalOffset: 100.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'معلومات المعايرة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'لضبط البوصلة بشكل صحيح، قم بتحريك الهاتف في شكل رقم 8 في الهواء',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _startCalibration,
                        icon: const Icon(Icons.refresh),
                        label: const Text('بدء المعايرة'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: primaryColor,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // إضافة الدالة المفقودة _getDirectionLabel
  String _getDirectionLabel(double angle) {
    if (angle == 0) return 'ش';
    if (angle == 90) return 'ش';
    if (angle == 180) return 'ج';
    if (angle == 270) return 'غ';
    return '';
  }
  
  // إضافة الدالة المفقودة _showQiblaInfo
  void _showQiblaInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('معلومات عن القبلة'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'القبلة هي الاتجاه الذي يتوجه إليه المسلمون في صلاتهم، وهي تشير إلى الكعبة المشرفة في مكة المكرمة.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                'استخدم هذه البوصلة لتحديد اتجاه القبلة بناءً على موقعك الحالي.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                'للحصول على أفضل دقة:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text('• ضع الهاتف على سطح مستوٍ', style: TextStyle(fontSize: 14)),
              Text('• ابتعد عن المعادن والأجهزة الإلكترونية', style: TextStyle(fontSize: 14)),
              Text('• قم بمعايرة البوصلة بانتظام', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً، فهمت'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}