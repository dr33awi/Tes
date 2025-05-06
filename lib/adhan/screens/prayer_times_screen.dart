// lib/adhan/screens/prayer_times_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/adhan/models/prayer_time_model.dart';
import 'package:test_athkar_app/adhan/services/prayer_times_service.dart';
import 'package:test_athkar_app/screens/home_screen/widgets/common/app_loading_indicator.dart';
import 'package:test_athkar_app/adhan/screens/prayer_settings_screen.dart';
import 'package:test_athkar_app/adhan/screens/notification_settings_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({Key? key}) : super(key: key);

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> with WidgetsBindingObserver {
  final PrayerTimesService _prayerService = PrayerTimesService();
  
  // حالة البيانات
  List<PrayerTimeModel>? _prayerTimes;
  String? _locationName;
  bool _isLoading = true;
  bool _isRefreshing = false; 
  bool _hasLocationPermission = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // بيانات المخزن المؤقت
  bool _hasCache = false;
  DateTime? _lastLoadTime;
  
  // مدة صلاحية البيانات المخزنة (5 دقائق)
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // للتأثيرات اللمسية
  int? _pressedIndex;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initService();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_lastLoadTime != null && 
          DateTime.now().difference(_lastLoadTime!) > _cacheDuration) {
        _loadPrayerTimes();
      }
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prayerService.setContext(context);
  }
  
  // التحقق من إذن الموقع
  Future<bool> _checkLocationPermission() async {
    return await Permission.location.status.isGranted;
  }

  // طلب إذن الموقع
  Future<bool> _requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    
    if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog();
      return false;
    }
    
    return status.isGranted;
  }

  // عرض حوار فتح الإعدادات
  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إذن الموقع مطلوب'),
        content: const Text(
          'تم رفض إذن الموقع بشكل دائم. يرجى فتح إعدادات التطبيق وتفعيل إذن الموقع يدويًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
            ),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
  
  // تهيئة الخدمة
  Future<void> _initService() async {
    try {
      // تهيئة خدمة مواقيت الصلاة
      await _prayerService.initialize();
      
      // التحقق من إذن الموقع
      _hasLocationPermission = await _checkLocationPermission();
      
      // إذا لم يكن هناك إذن، حاول طلبه
      if (!_hasLocationPermission) {
        _hasLocationPermission = await _requestLocationPermission();
      }
      
      // تحميل البيانات المخزنة مؤقتًا ثم البيانات المحدثة
      _loadCachedData();
      _loadPrayerTimes();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'خطأ في تهيئة خدمة مواقيت الصلاة';
        });
      }
    }
  }
  
  // تحميل البيانات المخزنة مؤقتًا
  void _loadCachedData() {
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
      debugPrint('خطأ أثناء تحميل البيانات المخزنة: $e');
    }
  }

  // تحميل مواقيت الصلاة
  Future<void> _loadPrayerTimes({bool forceRefresh = false}) async {
    if (_isLoading && !_hasCache) return;
    
    if (!forceRefresh && _hasCache && _lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _cacheDuration) {
      return;
    }
    
    setState(() {
      if (forceRefresh) {
        _isLoading = true;
        _hasCache = false;
      } else {
        if (_hasCache) {
          _isRefreshing = true;
        } else {
          _isLoading = true;
        }
      }
      _hasError = false;
    });

    try {
      _hasLocationPermission = await _checkLocationPermission();
      
      if (!_hasLocationPermission) {
        _hasLocationPermission = await _requestLocationPermission();
      }

      if (forceRefresh) {
        await _prayerService.recalculatePrayerTimes();
      }

      const int maxRetries = 2;
      int retryCount = 0;
      bool success = false;
      List<PrayerTimeModel>? prayerTimes;
      
      while (retryCount < maxRetries && !success) {
        try {
          prayerTimes = await _prayerService.getPrayerTimesFromAPI(
            useDefaultLocationIfNeeded: true
          );
          success = true;
        } catch (apiError) {
          retryCount++;
          debugPrint('خطأ في الحصول على مواقيت الصلاة (المحاولة $retryCount): $apiError');
          
          if (retryCount < maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
          } else {
            debugPrint('استخدام الطريقة المحلية بعد فشل جميع المحاولات');
            prayerTimes = _prayerService.getPrayerTimesLocally();
          }
        }
      }
      
      if (mounted && prayerTimes != null) {
        setState(() {
          _prayerTimes = prayerTimes;
          _locationName = _prayerService.locationName ?? 'الموقع الافتراضي';
          _isLoading = false;
          _isRefreshing = false;
          _lastLoadTime = DateTime.now();
          _hasCache = true;
        });
      }
      
      try {
        await _prayerService.schedulePrayerNotifications();
      } catch (notifError) {
        debugPrint('خطأ في جدولة الإشعارات: $notifError');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _hasError = !_hasCache;
          _errorMessage = 'حدث خطأ أثناء تحميل أوقات الصلاة';
        });
        
        debugPrint('تفاصيل الخطأ أثناء تحميل مواقيت الصلاة: $e');
        
        if (_hasCache) {
          _showErrorSnackBar('حدث خطأ أثناء تحديث البيانات. جارٍ استخدام البيانات المخزنة.');
        }
      }
    }
  }
  
  // عرض رسالة خطأ
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: _loadPrayerTimes,
        ),
      ),
    );
  }

  // عرض رسالة نجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kPrimary,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: kPrimary,
            ),
            onPressed: _navigateToNotificationSettings,
            tooltip: 'إعدادات الإشعارات',
          ),
          _isRefreshing 
            ? Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(12),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kPrimary,
                ),
              )
            : IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: kPrimary,
                ),
                onPressed: () => _loadPrayerTimes(forceRefresh: true),
                tooltip: 'تحديث',
              ),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: kPrimary,
            ),
            onPressed: _navigateToPrayerSettings,
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
  
  // الانتقال إلى شاشة إعدادات الإشعارات
  Future<void> _navigateToNotificationSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
    
    // تحديث مواقيت الصلاة بعد العودة
    _loadPrayerTimes();
  }
  
  // الانتقال إلى شاشة إعدادات الصلاة
  Future<void> _navigateToPrayerSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrayerSettingsScreen(),
      ),
    );
    
    if (result == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _loadPrayerTimes(forceRefresh: true);
        
        _showSuccessSnackBar('تم تحديث مواقيت الصلاة وفقًا للإعدادات الجديدة');
      } catch (e) {
        debugPrint('خطأ أثناء إعادة تحميل المواقيت بعد تغيير الإعدادات: $e');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('حدث خطأ أثناء تحديث المواقيت، يرجى المحاولة مرة أخرى'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: _loadPrayerTimes,
            ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // بناء محتوى رئيسي
  Widget _buildMainContent() {
    if (_isLoading && !_hasCache) {
      return _buildLoadingIndicator();
    }

    if (_hasError && !_hasCache) {
      return _buildErrorWidget();
    }

    if (_prayerTimes == null || _prayerTimes!.isEmpty) {
      return _buildEmptyStateWidget();
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
            if (_isRefreshing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(
                  backgroundColor: kPrimary.withOpacity(0.1),
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 4,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // بطاقة معلومات فضل معرفة مواقيت الصلاة
            _buildInfoCard(),
            
            // بطاقة الموقع
            _buildLocationCard(),
            
            // تحذير إذن الموقع إذا كان يستخدم الموقع الافتراضي
            if (!_hasLocationPermission)
              _buildLocationPermissionWarning(),
              
            const SizedBox(height: 24),
            
            // عنوان أقسام الصلوات
            Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  color: kPrimary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'أقسام الصلوات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // عرض أقسام الصلوات بالتصميم الجديد
            _buildPrayerCategoriesGrid(),
            
            const SizedBox(height: 24),
            
            // أزرار الإجراءات
            _buildActionButtons(),
            
            const SizedBox(height: 24),
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
            'جاري تحميل مواقيت الصلاة...',
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
  
  // بناء حالة فارغة
  Widget _buildEmptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time,
              size: 50,
              color: kPrimary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا تتوفر مواقيت صلاة للعرض',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _loadPrayerTimes(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
  
  // بناء محتوى صفحة الخطأ
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'لا يمكن تحميل أوقات الصلاة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _getFormattedErrorMessage(_errorMessage),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _loadPrayerTimes(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                if (!_hasLocationPermission)
                  OutlinedButton.icon(
                    onPressed: _useDefaultLocation,
                    icon: const Icon(Icons.location_city),
                    label: const Text(
                      'استخدام الموقع الافتراضي',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimary,
                      side: BorderSide(color: kPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
            if (!_hasLocationPermission) ... [
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _requestLocationPermission,
                icon: const Icon(Icons.location_on),
                label: const Text(
                  'منح إذن الموقع',
                  style: TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade800),
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

  // بناء بطاقة معلومات فضل معرفة مواقيت الصلاة
  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimary, kPrimaryLight],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              stops: [0.3, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'فضل المحافظة على الصلاة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'قال تعالى: ﴿حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَىٰ وَقُومُوا لِلَّهِ قَانِتِينَ﴾ [البقرة: 238]',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'قال رسول الله ﷺ: «الصلوات الخمس، والجمعة إلى الجمعة، كفارة لما بينهن، ما لم تُغش الكبائر» رواه مسلم',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        if (_lastLoadTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'آخر تحديث: ${_formatLastUpdateTime(_lastLoadTime!)}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.white.withOpacity(0.9),
                        size: 22,
                      ),
                      onPressed: () => _loadPrayerTimes(forceRefresh: true),
                      tooltip: 'تحديث الموقع',
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
  
  // بناء تحذير إذن الموقع
  Widget _buildLocationPermissionWarning() {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 400),
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade800,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
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
                ElevatedButton(
                  onPressed: _requestLocationPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'منح الإذن',
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
      ),
    );
  }
  
  // تنسيق وقت آخر تحديث
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
  
  // بناء أزرار الإجراءات مع نفس تصميم صفحة الأذكار
  Widget _buildActionButtons() {
    return Column(
      children: [
        // عنوان الإعدادات
        Row(
          children: [
            Icon(
              Icons.settings,
              color: kPrimary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'الإعدادات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // أزرار في صف
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _navigateToNotificationSettings,
                icon: const Icon(Icons.notifications_active),
                label: const Text('إعدادات الإشعارات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // زر إعدادات الحساب
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _navigateToPrayerSettings,
                icon: const Icon(Icons.tune),
                label: const Text('إعدادات الحساب'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  side: BorderSide(color: kPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // بناء شبكة أقسام الصلوات مشابه لشاشة الأذكار
  Widget _buildPrayerCategoriesGrid() {
    // قائمة أقسام الصلوات
    List<Map<String, dynamic>> prayerCategories = [];
    
    // إضافة الصلوات المتاحة إلى القائمة
    if (_prayerTimes != null && _prayerTimes!.isNotEmpty) {
      for (var prayer in _prayerTimes!) {
        prayerCategories.add({
          'name': prayer.name,
          'englishName': prayer.englishName,
          'icon': prayer.icon,
          'color': prayer.color,
          'time': prayer.formattedTime,
          'remainingTime': prayer.remainingTime,
          'isPassed': prayer.isPassed,
          'isNext': prayer.isNext,
        });
      }
    }
    
    return AnimationLimiter(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: prayerCategories.length,
        itemBuilder: (context, index) {
          final prayer = prayerCategories[index];
          final bool isPressed = _isPressed && _pressedIndex == index;
          
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 500),
            columnCount: 2,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: GestureDetector(
                  onTapDown: (_) {
                    setState(() {
                      _isPressed = true;
                      _pressedIndex = index;
                    });
                  },
                  onTapUp: (_) {
                    setState(() {
                      _isPressed = false;
                      _pressedIndex = null;
                    });
                  },
                  onTapCancel: () {
                    setState(() {
                      _isPressed = false;
                      _pressedIndex = null;
                    });
                  },
                  child: Transform.scale(
                    scale: isPressed ? 0.95 : 1.0,
                    child: _buildPrayerCategoryCard(prayer, index),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // بناء بطاقة قسم الصلاة
  Widget _buildPrayerCategoryCard(Map<String, dynamic> prayer, int index) {
    final Color color = prayer['color'];
    final bool isNext = prayer['isNext'];
    final bool isPassed = prayer['isPassed'];
    
    return Card(
      elevation: isNext ? 8 : 4,
      shadowColor: color.withOpacity(isNext ? 0.4 : 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isNext
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.7),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: const [0.3, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // أيقونة زخرفية في الخلفية
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                prayer['icon'],
                size: 80,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // اسم الصلاة مع أيقونة
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          prayer['icon'],
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prayer['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // وقت الصلاة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          prayer['time'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // الحالة
// بناء بطاقة قسم الصلاة
  Widget _buildPrayerCategoryCard(Map<String, dynamic> prayer, int index) {
    final Color color = prayer['color'];
    final bool isNext = prayer['isNext'];
    final bool isPassed = prayer['isPassed'];
    
    return Card(
      elevation: isNext ? 8 : 4,
      shadowColor: color.withOpacity(isNext ? 0.4 : 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isNext
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.7),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: const [0.3, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // أيقونة زخرفية في الخلفية
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                prayer['icon'],
                size: 80,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // اسم الصلاة مع أيقونة
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          prayer['icon'],
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prayer['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // وقت الصلاة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          prayer['time'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // الحالة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
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
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPassed
                              ? 'انتهى'
                              : isNext
                                  ? 'الصلاة التالية: ${prayer['remainingTime']}'
                                  : 'متبقي: ${prayer['remainingTime']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // علامة خاصة للصلاة التالية
            if (isNext)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'التالية',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Method for using default location
  Future<void> _useDefaultLocation() async {
    try {
      await _prayerService.setDefaultLocation();
      final prayerTimes = _prayerService.getPrayerTimesLocally();
      
      setState(() {
        _prayerTimes = prayerTimes;
        _locationName = _prayerService.locationName;
        _hasError = false;
        _isLoading = false;
        _hasCache = true;
        _lastLoadTime = DateTime.now();
      });
      
      _showSuccessSnackBar('تم استخدام الموقع الافتراضي بنجاح');
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل استخدام الموقع الافتراضي';
        _hasError = true;
      });
    }
  }

  // Method to format error messages
  String _getFormattedErrorMessage(String errorMessage) {
    if (errorMessage.contains('Exception')) {
      return 'حدث خطأ أثناء الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت الخاص بك والمحاولة مرة أخرى.';
    } else if (errorMessage.contains('Permission')) {
      return 'لم يتم منح الأذونات المطلوبة. يرجى منح إذن الوصول للموقع للحصول على مواقيت دقيقة.';
    } else if (errorMessage.contains('Timeout')) {
      return 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت الخاص بك والمحاولة مرة أخرى.';
    } else if (errorMessage.isEmpty) {
      return 'حدث خطأ غير معروف. يرجى المحاولة مرة أخرى.';
    }
    
    return errorMessage;
  }