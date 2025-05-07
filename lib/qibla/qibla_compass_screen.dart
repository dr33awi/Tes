// lib/adhan/screens/qibla_compass_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/adhan/services/prayer_times_service.dart';
import 'package:test_athkar_app/qibla/services/prayer_times_service_extension.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({Key? key}) : super(key: key);

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> with TickerProviderStateMixin {
  // القيم الثابتة والمتغيرات
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;
  
  // متغيرات الحالة
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _direction = 0;
  double _qiblaDirection = 0;
  bool _hasPermission = false;
  bool _isLoading = true;
  bool _isCalibrating = false;
  bool _compassAvailable = false;
  bool _needsCalibration = false;
  
  // خدمة مواقيت الصلاة (للاستفادة من إعدادات الموقع)
  final PrayerTimesService _prayerService = PrayerTimesService();
  
  // متغيرات الرسوم المتحركة
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // معلومات الموقع
  double? _userLatitude;
  double? _userLongitude;
  String? _locationName;
  double _distance = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    // إعداد محركات الرسوم المتحركة
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeOutBack)
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
    
    // بدء تهيئة الخدمات والبيانات
    _initCompass();
  }
  
  @override
  void dispose() {
    _compassSubscription?.cancel();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  // تهيئة البوصلة
  Future<void> _initCompass() async {
    try {
      _compassAvailable = await FlutterCompass.events != null;
      
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      
      if (_compassAvailable) {
        // التحقق من الأذونات اللازمة
        await _checkPermissions();
        
        // تهيئة خدمة مواقيت الصلاة للاستفادة من الموقع
        await _prayerService.initialize();
        
        // الحصول على الموقع
        await _getUserLocation();
        
        // حساب اتجاه القبلة
        if (_userLatitude != null && _userLongitude != null) {
          _calculateQiblaDirection();
        }
        
        // الاشتراك في حدث البوصلة
        _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
          double? newDirection = event.heading;
          
          // التحقق من صحة القراءة
          if (newDirection != null) {
            if (mounted) {
              setState(() {
                _direction = newDirection;
                
                // Check if accuracy is available and in the proper range
                _needsCalibration = (event.accuracy ?? 0) <= 0 || (event.accuracy ?? 100) >= 20;
                _isCalibrating = false;
                _isLoading = false;
              });
            }
          } else {
            // في حالة عدم توفر قراءة (قد تكون البوصلة تحتاج معايرة)
            if (mounted) {
              setState(() {
                _needsCalibration = true;
              });
            }
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('خطأ في تهيئة البوصلة: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // التحقق من الأذونات اللازمة
  Future<void> _checkPermissions() async {
    bool locationPermission = await Permission.location.status.isGranted;
    
    // في بعض الأجهزة قد نحتاج أيضًا لإذن المستشعرات
    bool sensorsPermission = true;
    
    if (await Permission.sensors.status.isDenied) {
      sensorsPermission = await Permission.sensors.request().isGranted;
    }
    
    setState(() {
      _hasPermission = locationPermission && sensorsPermission;
    });
    
    if (!_hasPermission) {
      // طلب الأذونات إذا لم تكن ممنوحة
      if (!locationPermission) {
        locationPermission = await _requestLocationPermission();
      }
      
      setState(() {
        _hasPermission = locationPermission && sensorsPermission;
      });
    }
  }
  
  // طلب إذن الموقع
  Future<bool> _requestLocationPermission() async {
    try {
      final PermissionStatus status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('خطأ أثناء طلب إذن الموقع: $e');
      return false;
    }
  }
  
  // الحصول على موقع المستخدم
  Future<void> _getUserLocation() async {
    try {
      if (!_hasPermission) {
        return;
      }
      
      // محاولة الحصول على إحداثيات من موفر الموقع
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _locationName = 'موقعك الحالي';
        
        // حفظ الموقع الجديد في خدمة مواقيت الصلاة لاستخدامه لاحقًا
        await _prayerService.saveLocation(position.latitude, position.longitude, _locationName!);
      } catch (locationError) {
        debugPrint('خطأ في الحصول على الموقع الحالي: $locationError');
        
        // محاولة استخدام الموقع المخزن في خدمة مواقيت الصلاة
        final savedLocation = await _prayerService.getSavedLocation();
        if (savedLocation != null) {
          _userLatitude = savedLocation['latitude'];
          _userLongitude = savedLocation['longitude'];
          _locationName = savedLocation['name'] ?? 'الموقع المحفوظ';
        }
      }
      
      // حساب المسافة إلى الكعبة
      _calculateDistanceToKaaba();
      
    } catch (e) {
      debugPrint('خطأ في الحصول على الموقع: $e');
      
      // إذا فشل الحصول على الموقع، نستخدم الموقع الافتراضي (مكة)
      _userLatitude = 21.4225;
      _userLongitude = 39.8262;
      _locationName = 'الموقع الافتراضي (مكة المكرمة)';
    }
  }
  
  // حساب اتجاه القبلة
  void _calculateQiblaDirection() {
    if (_userLatitude != null && _userLongitude != null) {
      // تحويل الإحداثيات إلى راديان
      double latK = vector_math.radians(kaabaLatitude);
      double longK = vector_math.radians(kaabaLongitude);
      double latU = vector_math.radians(_userLatitude!);
      double longU = vector_math.radians(_userLongitude!);
      
      // صيغة المثلثات الكروية
      double y = sin(longK - longU);
      double x = cos(latU) * tan(latK) - sin(latU) * cos(longK - longU);
      
      // الزاوية بالراديان
      double angle = atan2(y, x);
      
      // تحويل الزاوية إلى درجات
      double angleDegrees = vector_math.degrees(angle);
      
      // التأكد من أن الزاوية بين 0 و 360 درجة
      _qiblaDirection = (angleDegrees + 360) % 360;
      
      // تشغيل الرسوم المتحركة
      _rotationController.reset();
      _rotationController.forward();
    }
  }
  
  // حساب المسافة إلى الكعبة بالكيلومترات
  void _calculateDistanceToKaaba() {
    if (_userLatitude != null && _userLongitude != null) {
      double distance = Geolocator.distanceBetween(
        _userLatitude!,
        _userLongitude!,
        kaabaLatitude,
        kaabaLongitude,
      );
      
      // تحويل المسافة من متر إلى كيلومتر
      _distance = distance / 1000;
    }
  }
  
  // إعادة معايرة البوصلة
  void _calibrateCompass() {
    setState(() {
      _isCalibrating = true;
    });
    
    // عرض إرشادات المعايرة
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معايرة البوصلة'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.screen_rotation_outlined, size: 48, color: kPrimary),
            SizedBox(height: 16),
            Text(
              'لمعايرة البوصلة، قم بتحريك هاتفك في شكل رقم 8 في الهواء عدة مرات.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسنًا'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
  
  // إعادة تحميل البيانات
  Future<void> _refreshCompass() async {
    setState(() {
      _isLoading = true;
    });
    
    // إعادة تهيئة البوصلة والموقع
    await _initCompass();
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
          'بوصلة القبلة',
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
        actions: [
          // زر إعادة تحميل البوصلة
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: kPrimary,
            ),
            onPressed: _refreshCompass,
            tooltip: 'تحديث',
          ),
          
          // زر معايرة البوصلة
          if (_compassAvailable && _hasPermission && !_isLoading)
            IconButton(
              icon: const Icon(
                Icons.settings_overscan,
                color: kPrimary,
              ),
              onPressed: _calibrateCompass,
              tooltip: 'معايرة البوصلة',
            ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading 
          ? _buildLoadingIndicator()
          : !_compassAvailable 
            ? _buildCompassNotAvailableMessage()
            : !_hasPermission 
              ? _buildPermissionDeniedMessage()
              : Stack(
                  children: [
                    // الشاشة الرئيسية مع البوصلة
                    RefreshIndicator(
                      color: kPrimary,
                      onRefresh: _refreshCompass,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // معلومات الموقع
                              _buildLocationCard(),
                              
                              const SizedBox(height: 24),
                              
                              // البوصلة
                              _buildCompassWidget(),
                              
                              const SizedBox(height: 24),
                              
                              // معلومات إضافية
                              _buildInfoCard(),
                              
                              const SizedBox(height: 24),
                              
                              // إرشادات الاستخدام
                              _buildInstructionsCard(),
                              
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // تنبيه المعايرة
                    if (_needsCalibration && !_isCalibrating)
                      _buildCalibrationWarning(),
                    
                    // مؤشر المعايرة
                    if (_isCalibrating)
                      _buildCalibratingIndicator(),
                  ],
                ),
      ),
    );
  }
  
  // بناء مؤشر التحميل
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: kPrimary,
            size: 50,
          ),
          const SizedBox(height: 24),
          const Text(
            'جاري تهيئة بوصلة القبلة...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  // بناء رسالة عدم توفر البوصلة
  Widget _buildCompassNotAvailableMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compass_calibration_outlined,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'البوصلة غير متوفرة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'جهازك لا يحتوي على مستشعر للبوصلة أو أن المستشعر غير متاح حاليًا',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshCompass,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // بناء رسالة عدم وجود صلاحيات
  Widget _buildPermissionDeniedMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_disabled,
              size: 80,
              color: Colors.orange.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'لم يتم منح الأذونات اللازمة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'تحتاج بوصلة القبلة إلى إذن الوصول لموقعك لتحديد الاتجاه الصحيح للقبلة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                bool granted = await _requestLocationPermission();
                if (granted) {
                  _refreshCompass();
                }
              },
              icon: const Icon(Icons.location_on),
              label: const Text('منح الإذن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('فتح إعدادات التطبيق'),
              style: TextButton.styleFrom(
                foregroundColor: kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // بناء بطاقة الموقع
  Widget _buildLocationCard() {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 400),
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: Card(
            elevation: 8,
            shadowColor: kPrimary.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimary, kPrimaryLight],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  stops: [0.3, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'موقعك الحالي',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locationName ?? 'غير معروف',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              size: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'المسافة إلى الكعبة: ${_distance.toStringAsFixed(0)} كم',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
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
    );
  }
  
  // بناء البوصلة
  Widget _buildCompassWidget() {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Column(
            children: [
              // المؤشر العلوي
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_downward,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'اتجاه القبلة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // البوصلة نفسها
              SizedBox(
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // الإطار الخارجي
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    
                    // حلقة الاتجاهات الرئيسية
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // حيث ن = الشمال، ج = الجنوب، ش = الشرق، غ = الغرب
                          _buildDirectionIndicator(0, 'ش'), // N
                          _buildDirectionIndicator(90, 'ش'), // E
                          _buildDirectionIndicator(180, 'ج'), // S
                          _buildDirectionIndicator(270, 'غ'), // W
                        ],
                      ),
                    ),
                    
                    // قرص البوصلة الدوار
                    Transform.rotate(
                      angle: vector_math.radians(-_direction),
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.white,
                              Colors.grey.shade50,
                            ],
                            stops: const [0.7, 1.0],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // علامات الدرجات
                            for (int i = 0; i < 360; i += 15)
                              i % 90 == 0
                                  ? Container() // الاتجاهات الرئيسية مضافة بالفعل
                                  : _buildDegreeMarker(i, i % 45 == 0),
                            
                            // سهم الشمال
                            Positioned(
                              top: 20,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                    Text(
                                      'N',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
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
                    
                    // سهم اتجاه القبلة
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: vector_math.radians(
                            _qiblaDirection * _rotationAnimation.value - _direction
                          ),
                          child: child,
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // خط الاتجاه
                              Positioned(
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        kPrimary,
                                        kPrimary.withOpacity(0.6),
                                        kPrimary.withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.5, 0.8, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              
                              // سهم الاتجاه
                              Positioned(
                                top: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: kPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // رمز الكعبة في المركز
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: kPrimary.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.account_balance,
                                  color: kPrimary,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // مؤشر الاتجاه باللفظ والدرجات
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: kPrimary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.explore,
                      color: kPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'اتجاه القبلة: ${_qiblaDirection.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        color: kPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // بناء علامة اتجاه رئيسي (ش، ج، ش، غ)
  Widget _buildDirectionIndicator(double degrees, String label) {
    return Positioned(
      left: 140 + 130 * cos(vector_math.radians(degrees)),
      top: 140 + 130 * sin(vector_math.radians(degrees)),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 1,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
  
  // بناء علامات الدرجات
  Widget _buildDegreeMarker(double degrees, bool isLarge) {
    return Positioned(
      left: 130 + 120 * cos(vector_math.radians(degrees)),
      top: 130 + 120 * sin(vector_math.radians(degrees)),
      child: Container(
        width: isLarge ? 8 : 4,
        height: isLarge ? 8 : 4,
        decoration: BoxDecoration(
          color: isLarge ? Colors.black54 : Colors.black38,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
  
  // تحذير المعايرة
  Widget _buildCalibrationWarning() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.orange.shade500,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: SafeArea(
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'البوصلة تحتاج إلى معايرة للحصول على دقة أفضل',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: _calibrateCompass,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'معايرة الآن',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // مؤشر المعايرة
  Widget _buildCalibratingIndicator() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.newtonCradle(
                  color: kPrimary,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'جاري معايرة البوصلة...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'حرك هاتفك في شكل رقم 8 في الهواء',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCalibrating = false;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // بناء بطاقة معلومات
  Widget _buildInfoCard() {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: Card(
            elevation: 4,
            shadowColor: kPrimary.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary, kPrimaryLight],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  stops: const [0.3, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'معلومات مهمة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    Icons.compass_calibration,
                    'دقة البوصلة قد تختلف من جهاز لآخر، قم بمعايرتها للحصول على أفضل النتائج'
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.location_on,
                    'اتجاه القبلة يعتمد على موقعك الحالي، تأكد من تفعيل خدمة الموقع'
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.phone_android,
                    'حافظ على هاتفك في وضع مستوٍ أفقي للحصول على قراءة دقيقة'
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // عنصر معلومات
  Widget _buildInfoItem(IconData icon, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // بناء بطاقة الإرشادات
  Widget _buildInstructionsCard() {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 700),
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: Card(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: kPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'كيفية استخدام بوصلة القبلة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionStep(
                    '1',
                    'ضع الهاتف في وضع أفقي (مستوٍ) على سطح مستوٍ أو أمسكه بشكل أفقي',
                  ),
                  _buildInstructionStep(
                    '2',
                    'قم بمعايرة البوصلة بتحريك الهاتف على شكل رقم 8 في الهواء',
                  ),
                  _buildInstructionStep(
                    '3',
                    'اتبع السهم الأخضر الذي يشير إلى اتجاه القبلة',
                  ),
                  _buildInstructionStep(
                    '4',
                    'عندما يشير السهم الأخضر إلى الأعلى، فأنت تتجه نحو القبلة',
                    isLast: true
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // خطوة إرشادية
  Widget _buildInstructionStep(String number, String content, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: kPrimary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              if (!isLast)
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 10, left: 0),
                  height: 20,
                  width: 1,
                  color: kPrimary.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ],
    );
  }
}