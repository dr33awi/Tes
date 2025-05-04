// lib/screens/prayer_times_screen/prayer_times_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/models/prayer_times_model.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;
import 'package:test_athkar_app/services/prayer_times_service.dart';
import 'package:test_athkar_app/screens/home_screen/widgets/common/app_loading_indicator.dart';
import 'package:test_athkar_app/screens/prayer_times_screen/prayer_settings_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({Key? key}) : super(key: key);

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final PrayerTimesService _prayerService = PrayerTimesService();
  List<PrayerTimeModel>? _prayerTimes;
  String? _locationName;
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initService();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pasar el contexto actual al servicio para mostrar diálogos
    _prayerService.setContext(context);
  }
  
  Future<void> _initService() async {
    await _prayerService.initialize();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Verificar permisos de ubicación
      _hasLocationPermission = await _prayerService.checkLocationPermission();
      
      if (!_hasLocationPermission) {
        // Intentar solicitar permisos
        _hasLocationPermission = await _prayerService.requestLocationPermission();
      }

      // Obtener horarios de oración - usará ubicación predeterminada si es necesario
      final prayerTimes = await _prayerService.getPrayerTimesFromAPI(
        useDefaultLocationIfNeeded: true
      );
      
      if (mounted) {
        setState(() {
          _prayerTimes = prayerTimes;
          _locationName = _prayerService.locationName ?? 'موقعك الحالي';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'حدث خطأ أثناء تحميل أوقات الصلاة: $e';
        });
      }
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
        title: Text(
          'مواقيت الصلاة',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: kPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: kPrimary,
            ),
            onPressed: _loadPrayerTimes,
            tooltip: 'تحديث',
          ),
          IconButton(
            icon: Icon(
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
    if (_isLoading) {
      return const AppLoadingIndicator(
        message: 'جاري تحميل أوقات الصلاة...',
        loadingType: LoadingType.staggeredDotsWave,
      );
    }

    if (_hasError) {
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
            Text(
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
            // información de ubicación
            _buildLocationCard(),
            
            // Mensaje sobre permisos de ubicación si estamos usando ubicación predeterminada
            if (!_hasLocationPermission)
              _buildLocationPermissionWarning(),
              
            const SizedBox(height: 20),

            // tiempos de oración
            AnimationLimiter(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _prayerTimes!.length,
                itemBuilder: (context, index) {
                  final prayer = _prayerTimes![index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildPrayerTimeCard(prayer),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget para advertencia sobre permisos de ubicación
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
                          _locationName ?? 'غير معروف',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
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

  Widget _buildPrayerTimeCard(PrayerTimeModel prayer) {
    final bool isPassed = prayer.isPassed;
    final bool isNext = prayer.isNext;
    
    return Card(
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
            Text(
              _errorMessage,
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
                // Botón para usar ubicación predeterminada
                if (!_hasLocationPermission)
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        // Obtener horarios usando ubicación predeterminada
                        final prayerTimes = await _prayerService.getPrayerTimesLocally();
                        
                        setState(() {
                          _prayerTimes = prayerTimes;
                          _locationName = _prayerService.locationName;
                          _hasError = false;
                          _isLoading = false;
                        });
                      } catch (e) {
                        setState(() {
                          _errorMessage = 'فشل استخدام الموقع الافتراضي: $e';
                        });
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
}