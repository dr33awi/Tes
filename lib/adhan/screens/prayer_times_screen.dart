// lib/adhan/screens/prayer_times_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/adhan/models/prayer_time_model.dart';
import 'package:test_athkar_app/adhan/services/prayer_times_service.dart';
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
  
  // منع استدعاءات متكررة
  bool _isInitializing = false;
  bool _isLoadingPrayerTimes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // تأخير استدعاء _initService للتأكد من اكتمال بناء Widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initService();
    });
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
    
    // Only update context in service if needed
    if (mounted && context != null) {
      _prayerService.setContext(context);
    }
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
    // منع الاستدعاءات المتكررة
    if (_isInitializing) return;
    _isInitializing = true;
    
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
      debugPrint('خطأ في تهيئة خدمة مواقيت الصلاة: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'خطأ في تهيئة خدمة مواقيت الصلاة';
        });
      }
    } finally {
      _isInitializing = false;
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
    // منع الاستدعاءات المتكررة
    if (_isLoadingPrayerTimes) return;
    if (_isLoading && !_hasCache) return;
    
    if (!forceRefresh && _hasCache && _lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _cacheDuration) {
      return;
    }
    
    _isLoadingPrayerTimes = true;
    
    try {
      if (mounted) {
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
      }

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
      debugPrint('تفاصيل الخطأ أثناء تحميل مواقيت الصلاة: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _hasError = !_hasCache;
          _errorMessage = 'حدث خطأ أثناء تحميل أوقات الصلاة';
        });
        
        if (_hasCache) {
          _showErrorSnackBar('حدث خطأ أثناء تحديث البيانات. جارٍ استخدام البيانات المخزنة.');
        }
      }
    } finally {
      _isLoadingPrayerTimes = false;
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
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      
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

            // عرض أقسام الصلوات بالتصميم الجديد مشابه لأقسام الأذكار
            _buildPrayerCategoriesList(),
            
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
            'يرجى التحقق من اتصال الإنترنت الخاص بك والمحاولة مرة أخرى',
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
  
  // بناء قائمة أقسام الصلوات
  Widget _buildPrayerCategoriesList() {
    if (_prayerTimes == null || _prayerTimes!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _prayerTimes!.length,
        itemBuilder: (context, index) {
          final prayer = _prayerTimes![index];
          final bool isPressed = _isPressed && _pressedIndex == index;
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildPrayerCategoryCard(prayer, index, isPressed),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // بناء بطاقة قسم الصلاة
  Widget _buildPrayerCategoryCard(PrayerTimeModel prayer, int index, bool isPressed) {
    return GestureDetector(
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(isPressed ? 0.95 : 1.0),
        child: Card(
          elevation: prayer.isNext ? 4 : 2,
          shadowColor: prayer.color.withOpacity(prayer.isNext ? 0.4 : 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: prayer.isNext
                ? BorderSide(color: prayer.color, width: 1.5)
                : BorderSide.none,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  prayer.color,
                  prayer.color.withOpacity(0.7),
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // أيقونة في الخلفية
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    prayer.icon,
                    size: 60,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                
                // محتوى البطاقة
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      // دائرة الأيقونة
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            prayer.icon,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // معلومات الصلاة
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              prayer.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        prayer.formattedTime,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        prayer.isPassed
                                            ? Icons.check_circle
                                            : prayer.isNext
                                                ? Icons.access_time_filled
                                                : Icons.access_time,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        prayer.isPassed
                                            ? 'انتهى'
                                            : prayer.isNext
                                                ? 'التالية: ${prayer.remainingTime}'
                                                : '${prayer.remainingTime}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // أيقونة السهم للانتقال
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                    ],
                  ),
                ),
                
                // علامة خاصة للصلاة التالية
                if (prayer.isNext)
                  Positioned(
                    top: 0,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        'التالية',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: prayer.color,
                        ),
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

  // استخدام الموقع الافتراضي
  void _useDefaultLocation() {
    try {
      _prayerService.setDefaultLocation();
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

  // تنسيق رسائل الخطأ
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
}