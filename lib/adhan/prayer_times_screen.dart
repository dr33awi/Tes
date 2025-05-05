// lib/screens/prayer_times_screen/prayer_times_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/adhan/prayer_times_model.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;
import 'package:test_athkar_app/adhan/prayer_times_service.dart';
import 'package:test_athkar_app/screens/home_screen/widgets/common/app_loading_indicator.dart';
import 'package:test_athkar_app/adhan/prayer_settings_screen.dart';
import 'package:test_athkar_app/adhan/notification_settings_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({Key? key}) : super(key: key);

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> with WidgetsBindingObserver {
  final PrayerTimesService _prayerService = PrayerTimesService();
  List<PrayerTimeModel>? _prayerTimes;
  String? _locationName;
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // إضافة متغير للتخزين المؤقت
  bool _hasCache = false;
  DateTime? _lastLoadTime;
  
  // المدة المسموح بها لإعادة استخدام البيانات المخزنة مؤقتًا (5 دقائق)
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  @override
  void initState() {
    super.initState();
    // إضافة مراقب دورة حياة التطبيق
    WidgetsBinding.instance.addObserver(this);
    _initService();
  }
  
  @override
  void dispose() {
    // إزالة المراقب عند التخلص من الشاشة
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // إعادة تحميل البيانات عند العودة للتطبيق
    if (state == AppLifecycleState.resumed) {
      // إذا كانت البيانات قديمة (أكثر من 5 دقائق)، قم بإعادة تحميلها
      if (_lastLoadTime != null && 
          DateTime.now().difference(_lastLoadTime!) > _cacheDuration) {
        _loadPrayerTimes();
      }
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تعيين السياق في الخدمة للحوارات
    _prayerService.setContext(context);
  }
  
  Future<void> _initService() async {
    try {
      await _prayerService.initialize();
      
      // محاولة تحميل البيانات المخزنة مؤقتًا أولاً لزيادة سرعة الاستجابة
      _loadCachedData();
      
      // ثم تحميل البيانات المحدثة
      _loadPrayerTimes();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'خطأ في تهيئة خدمة مواقيت الصلاة: $e';
        });
        
        // عرض معلومات الخطأ التفصيلية في وضع التصحيح
        debugPrint('تفاصيل خطأ التهيئة: $e');
      }
    }
  }
  
  // دالة جديدة لتحميل البيانات المخزنة مؤقتًا
  void _loadCachedData() {
    // تنفيذ عملية تحميل البيانات من التخزين المؤقت هنا
    // ويمكن تنفيذها باستخدام SharedPreferences
    
    // لمحاكاة عملية تحميل البيانات المخزنة مؤقتًا، نستخدم البيانات المحلية
    if (_hasCache) return;
    
    try {
      final cachedTimes = _prayerService.getPrayerTimesLocally();
      
      if (mounted) {
        setState(() {
          _prayerTimes = cachedTimes;
          _locationName = _prayerService.locationName ?? 'الموقع المخزن مؤقتًا';
          _isLoading = false;
          _hasCache = true;
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات المخزنة مؤقتًا: $e');
      // لا نعرض الخطأ للمستخدم هنا لأننا سنحاول التحميل من الإنترنت لاحقًا
    }
  }

  // تحسين دالة تحميل أوقات الصلاة
  Future<void> _loadPrayerTimes() async {
    // إذا كان هناك تحميل جارٍ بالفعل، تجاهل الطلب
    if (_isLoading && !_hasCache) return;
    
    // إذا كانت البيانات مخزنة مؤقتًا وتم تحميلها مؤخرًا، تجاهل الطلب
    if (_hasCache && _lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _cacheDuration) {
      return;
    }
    
    setState(() {
      // إذا كان لدينا بيانات مخزنة مؤقتًا، لا نظهر شاشة التحميل
      _isLoading = !_hasCache;
      _hasError = false;
    });

    try {
      // التحقق من أذونات الموقع
      _hasLocationPermission = await _prayerService.checkLocationPermission();
      
      if (!_hasLocationPermission) {
        // محاولة طلب الأذونات
        _hasLocationPermission = await _prayerService.requestLocationPermission();
      }

      // عدد المحاولات الأقصى
      const int maxRetries = 2;
      int retryCount = 0;
      bool success = false;
      List<PrayerTimeModel>? prayerTimes;
      
      // محاولة الحصول على بيانات من API مع إعادة المحاولة في حالة الفشل
      while (retryCount < maxRetries && !success) {
        try {
          prayerTimes = await _prayerService.getPrayerTimesFromAPI(
            useDefaultLocationIfNeeded: true
          );
          success = true;
        } catch (apiError) {
          retryCount++;
          debugPrint('فشل الحصول على مواقيت الصلاة من API (محاولة $retryCount): $apiError');
          
          if (retryCount < maxRetries) {
            // انتظار قبل إعادة المحاولة
            await Future.delayed(const Duration(seconds: 2));
          } else {
            // استخدام طريقة احتياطية محلية في حالة فشل جميع المحاولات
            debugPrint('استخدام طريقة محلية بعد فشل جميع المحاولات');
            prayerTimes = _prayerService.getPrayerTimesLocally();
          }
        }
      }
      
      if (mounted && prayerTimes != null) {
        setState(() {
          _prayerTimes = prayerTimes;
          _locationName = _prayerService.locationName ?? 'الموقع الافتراضي';
          _isLoading = false;
          _lastLoadTime = DateTime.now();
          _hasCache = true;
        });
      }
      
      // محاولة جدولة الإشعارات بعد تحميل البيانات بنجاح
      try {
        await _prayerService.schedulePrayerNotifications();
      } catch (notifError) {
        debugPrint('خطأ في جدولة الإشعارات: $notifError');
        // عدم عرض هذا الخطأ للمستخدم لأنه غير حرج
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // إذا كان لدينا بيانات مخزنة مؤقتًا، نستمر في عرضها حتى مع وجود خطأ
          _isLoading = false;
          _hasError = !_hasCache;
          _errorMessage = 'حدث خطأ أثناء تحميل أوقات الصلاة: $e';
        });
        
        // عرض رسالة خطأ مختصرة للمستخدم وتفاصيل أكثر في سجل التصحيح
        debugPrint('تفاصيل خطأ تحميل أوقات الصلاة: $e');
        
        // عرض شريط إشعار في أسفل الشاشة في حالة الخطأ مع وجود بيانات مخزنة
        if (_hasCache) {
          _showErrorSnackBar('حدث خطأ أثناء تحديث البيانات. جارٍ استخدام البيانات المخزنة.');
        }
      }
    }
  }
  
  // دالة جديدة لعرض شريط إشعار خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: _loadPrayerTimes,
        ),
      ),
    );
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
          'مواقيت الصلاة',
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
          // زر إعدادات الإشعارات
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: kPrimary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              ).then((_) => _loadPrayerTimes());
            },
            tooltip: 'إعدادات الإشعارات',
          ),
          // عرض مؤشر تحميل بجانب زر التحديث عند التحميل
          _isLoading && _hasCache 
            ? IconButton(
                icon: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kPrimary,
                  ),
                ),
                onPressed: null,
              )
            : IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: kPrimary,
                ),
                onPressed: _loadPrayerTimes,
                tooltip: 'تحديث',
              ),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: kPrimary,
            ),
            onPressed: () async {
              // الانتقال إلى صفحة الإعدادات وانتظار النتيجة
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrayerSettingsScreen(),
                ),
              );
              
              // إذا تم تغيير الإعدادات، أعد تحميل المواقيت
              if (result == true) {
                _loadPrayerTimes();
              }
            },
            tooltip: 'الإعدادات',
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading && !_hasCache) {
      return const AppLoadingIndicator(
        message: 'جاري تحميل أوقات الصلاة...',
        loadingType: LoadingType.staggeredDotsWave,
      );
    }

    if (_hasError && !_hasCache) {
      return _buildErrorWidget();
    }

    if (_prayerTimes == null || _prayerTimes!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              size: 70,
              color: kPrimary.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا تتوفر أوقات صلاة للعرض',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPrayerTimes,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _loadPrayerTimes,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // في حالة التحميل مع وجود بيانات مخزنة، نعرض مؤشر تحميل خفيف
            if (_isLoading && _hasCache)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: LinearProgressIndicator(
                    backgroundColor: kPrimary.withOpacity(0.1),
                    color: kPrimary,
                  ),
                ),
              ),
            
            // بطاقة الموقع
            _buildLocationCard(),
            
            // تحذير بشأن أذونات الموقع إذا كنا نستخدم موقعًا افتراضيًا
            if (!_hasLocationPermission)
              _buildLocationPermissionWarning(),
              
            const SizedBox(height: 20),

            // أوقات الصلاة - تحسين عرض القائمة لتقليل استهلاك الموارد
            // استخدام ListView.builder بدلاً من AnimationLimiter لتحسين الأداء
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildPrayerTimesList(),
            ),
            
            // زر إعدادات الإشعارات
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  ).then((_) => _loadPrayerTimes());
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('إعدادات إشعارات الأذان'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  // دالة منفصلة لعرض قائمة أوقات الصلاة
  Widget _buildPrayerTimesList() {
    return AnimationLimiter(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _prayerTimes!.length,
        itemBuilder: (context, index) {
          final prayer = _prayerTimes![index];
          
          // تحسين الأداء: استخدام مفتاح فريد لكل عنصر
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            // تقليل مدة الأنيميشن لتحسين الأداء
            delay: Duration(milliseconds: 50 * index),
            key: ValueKey('prayer-${prayer.name}'),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildPrayerTimeCard(prayer),
              ),
            ),
          );
        },
      ),
    );
  }

  // تحذير بشأن أذونات الموقع
  Widget _buildLocationPermissionWarning() {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 400),
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تنبيه: يتم استخدام موقع افتراضي',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'لم يتم منح إذن الوصول للموقع. نستخدم حاليًا موقعًا افتراضيًا لحساب مواقيت الصلاة.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final hasPermission = await _prayerService.requestLocationPermission();
                    if (hasPermission) {
                      _loadPrayerTimes();
                    }
                  },
                  child: Text(
                    'منح الإذن',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الموقع الحالي',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locationName ?? 'الموقع الافتراضي',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        
                        // إضافة تفاصيل عن وقت آخر تحديث
                        if (_lastLoadTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'آخر تحديث: ${_formatLastUpdateTime(_lastLoadTime!)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    onPressed: _loadPrayerTimes,
                    tooltip: 'تحديث الموقع',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // دالة جديدة لتنسيق وقت آخر تحديث
  String _formatLastUpdateTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'منذ أقل من دقيقة';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  Widget _buildPrayerTimeCard(PrayerTimeModel prayer) {
    final bool isPassed = prayer.isPassed;
    final bool isNext = prayer.isNext;
    
    // تحسين الأداء: استخدام Hero widget للانتقالات السلسة بين الشاشات
    return Hero(
      tag: 'prayer-${prayer.name}',
      child: Card(
        elevation: isNext ? 8 : 4,
        shadowColor: prayer.color.withOpacity(isNext ? 0.4 : 0.2),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isNext
              ? BorderSide(color: prayer.color, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isNext
                ? LinearGradient(
                    colors: [
                      prayer.color.withOpacity(0.15),
                      prayer.color.withOpacity(0.05),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // أيقونة الصلاة
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        prayer.color,
                        prayer.color.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: prayer.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    prayer.icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                
                // تفاصيل الصلاة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            prayer.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isNext ? prayer.color : Colors.black87,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            prayer.formattedTime,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isNext ? prayer.color : Colors.black87,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // الوقت المتبقي للصلاة
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? Colors.grey.withOpacity(0.2)
                              : isNext
                                  ? prayer.color.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPassed
                                  ? Icons.check_circle
                                  : isNext
                                      ? Icons.access_time_filled
                                      : Icons.access_time,
                              color: isPassed
                                  ? Colors.grey
                                  : isNext
                                      ? prayer.color
                                      : Colors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isPassed
                                  ? 'انتهى'
                                  : isNext
                                      ? 'الصلاة التالية: ${prayer.remainingTime}'
                                      : 'متبقي: ${prayer.remainingTime}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPassed
                                    ? Colors.grey
                                    : isNext
                                        ? prayer.color
                                        : Colors.blue,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'لا يمكن تحميل أوقات الصلاة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // عرض رسالة خطأ أكثر ودية للمستخدم
            Text(
              _getFormattedErrorMessage(_errorMessage),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _loadPrayerTimes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                
                // زر استخدام الموقع الافتراضي
                if (!_hasLocationPermission)
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        // الحصول على أوقات الصلاة باستخدام الموقع الافتراضي
                        final prayerTimes = _prayerService.getPrayerTimesLocally();
                        
                        setState(() {
                          _prayerTimes = prayerTimes;
                          _locationName = _prayerService.locationName;
                          _hasError = false;
                          _isLoading = false;
                          _hasCache = true;
                          _lastLoadTime = DateTime.now();
                        });
                      } catch (e) {
                        setState(() {
                          _errorMessage = 'فشل استخدام الموقع الافتراضي: $e';
                        });
                        
                        // عرض رسالة خطأ أكثر تفصيلاً في سجل التصحيح
                        debugPrint('تفاصيل خطأ استخدام الموقع الافتراضي: $e');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'استخدام الموقع الافتراضي',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
            if (!_hasLocationPermission) ... [
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final hasPermission = await _prayerService.requestLocationPermission();
                  if (hasPermission) {
                    _loadPrayerTimes();
                  }
                },
                icon: const Icon(Icons.location_on),
                label: const Text(
                  'منح إذن الموقع',
                  style: TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: kPrimary),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // دالة جديدة لتنسيق رسائل الخطأ لتكون أكثر ودية للمستخدم
  String _getFormattedErrorMessage(String errorMessage) {
    // تبسيط رسائل الخطأ التقنية
    if (errorMessage.contains('Exception')) {
      return 'حدث خطأ أثناء الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت الخاص بك والمحاولة مرة أخرى.';
    } else if (errorMessage.contains('Permission')) {
      return 'لم يتم منح الأذونات المطلوبة. يرجى منح إذن الوصول للموقع للحصول على مواقيت دقيقة.';
    } else if (errorMessage.contains('Timeout')) {
      return 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت الخاص بك والمحاولة مرة أخرى.';
    } else if (errorMessage.isEmpty) {
      return 'حدث خطأ غير معروف. يرجى المحاولة مرة أخرى.';
    }
    
    // إرجاع رسالة الخطأ الأصلية إذا لم تكن تقنية جدًا
    return errorMessage;
  }
}