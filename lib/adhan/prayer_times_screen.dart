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
  
  // Variables de estado
  List<PrayerTimeModel>? _prayerTimes;
  String? _locationName;
  bool _isLoading = true;
  bool _isRefreshing = false; // Para recargas en segundo plano
  bool _hasLocationPermission = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Variables para caché
  bool _hasCache = false;
  DateTime? _lastLoadTime;
  
  // Duración permitida para reutilizar datos en caché (5 minutos)
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  @override
  void initState() {
    super.initState();
    // Añadir observador de ciclo de vida de la aplicación
    WidgetsBinding.instance.addObserver(this);
    _initService();
  }
  
  @override
  void dispose() {
    // Remover observador al descartar la pantalla
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recargar datos al volver a la aplicación
    if (state == AppLifecycleState.resumed) {
      // Si los datos son antiguos (más de 5 minutos), recargarlos
      if (_lastLoadTime != null && 
          DateTime.now().difference(_lastLoadTime!) > _cacheDuration) {
        _loadPrayerTimes();
      }
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Establecer contexto en el servicio para diálogos
    _prayerService.setContext(context);
  }
  
  Future<void> _initService() async {
    try {
      await _prayerService.initialize();
      
      // Primero cargar datos en caché para mejorar tiempo de respuesta
      _loadCachedData();
      
      // Luego cargar datos actualizados
      _loadPrayerTimes();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'خطأ في تهيئة خدمة مواقيت الصلاة';
        });
        
        // Mostrar información detallada del error en modo debug
        debugPrint('Error de inicialización detallado: $e');
      }
    }
  }
  
  // Cargar datos de caché
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
      debugPrint('Error al cargar datos en caché: $e');
      // No mostrar error al usuario aquí ya que intentaremos cargar desde internet
    }
  }

  // Cargar tiempos de oración con opción de forzar recarga
  Future<void> _loadPrayerTimes({bool forceRefresh = false}) async {
    // Si hay una carga en curso (sin caché), ignorar solicitud
    if (_isLoading && !_hasCache) return;
    
    // Si los datos están en caché y se cargaron recientemente, y no es una recarga forzada,
    // ignorar solicitud
    if (!forceRefresh && _hasCache && _lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _cacheDuration) {
      return;
    }
    
    setState(() {
      // Si hay fuerza de recarga, siempre mostrar pantalla de carga completa
      if (forceRefresh) {
        _isLoading = true;
        _hasCache = false; // Ignorar caché existente
      } else {
        // Si tenemos datos en caché, no mostrar pantalla de carga completa
        if (_hasCache) {
          _isRefreshing = true;
        } else {
          _isLoading = true;
        }
      }
      _hasError = false;
    });

    try {
      // Verificar permisos de ubicación
      _hasLocationPermission = await _prayerService.checkLocationPermission();
      
      if (!_hasLocationPermission) {
        // Intentar solicitar permisos
        _hasLocationPermission = await _prayerService.requestLocationPermission();
      }

      // Si es una recarga forzada, limpiar la caché del servicio
      if (forceRefresh) {
        await _prayerService.recalculatePrayerTimes();
      }

      // Número máximo de reintentos
      const int maxRetries = 2;
      int retryCount = 0;
      bool success = false;
      List<PrayerTimeModel>? prayerTimes;
      
      // Intentar obtener datos de API con reintentos en caso de fallo
      while (retryCount < maxRetries && !success) {
        try {
          prayerTimes = await _prayerService.getPrayerTimesFromAPI(
            useDefaultLocationIfNeeded: true
          );
          success = true;
        } catch (apiError) {
          retryCount++;
          debugPrint('Error al obtener tiempos de oración de API (intento $retryCount): $apiError');
          
          if (retryCount < maxRetries) {
            // Esperar antes de reintentar
            await Future.delayed(const Duration(seconds: 2));
          } else {
            // Usar método de respaldo local si fallan todos los intentos
            debugPrint('Usando método local después de fallar todos los intentos');
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
      
      // Intentar programar notificaciones después de cargar datos exitosamente
      try {
        await _prayerService.schedulePrayerNotifications();
      } catch (notifError) {
        debugPrint('Error al programar notificaciones: $notifError');
        // No mostrar este error al usuario ya que no es crítico
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _hasError = !_hasCache;
          _errorMessage = 'حدث خطأ أثناء تحميل أوقات الصلاة';
        });
        
        // Mostrar mensaje de error resumido al usuario y detalles en el registro
        debugPrint('Detalles del error al cargar tiempos de oración: $e');
        
        // Mostrar barra de notificación en caso de error con datos en caché
        if (_hasCache) {
          _showErrorSnackBar('حدث خطأ أثناء تحديث البيانات. جارٍ استخدام البيانات المخزنة.');
        }
      }
    }
  }
  
  // Mostrar barra de notificación de error
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
      appBar: _buildAppBar(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildMainContent(),
      ),
    );
  }
  
  // Barra de aplicación
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
        // Botón de configuración de notificaciones
        IconButton(
          icon: const Icon(
            Icons.notifications,
            color: kPrimary,
          ),
          onPressed: () => _navigateToNotificationSettings(),
          tooltip: 'إعدادات الإشعارات',
        ),
        // Mostrar indicador de carga junto al botón de actualización durante carga
        _isRefreshing 
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
          onPressed: () => _navigateToPrayerSettings(),
          tooltip: 'الإعدادات',
        ),
      ],
    );
  }
  
  // Navegación a pantalla de configuración de notificaciones
  Future<void> _navigateToNotificationSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
    
    // Recargar datos al volver
    _loadPrayerTimes();
  }
  
  // Navegación a pantalla de configuración de parámetros de cálculo
  Future<void> _navigateToPrayerSettings() async {
    // Ir a pantalla de configuración y esperar resultado
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrayerSettingsScreen(),
      ),
    );
    
    // Si se cambiaron los ajustes, recargar tiempos inmediatamente
    if (result == true) {
      setState(() {
        _isLoading = true; // Mostrar indicador de carga
      });
      
      try {
        // Cargar tiempos con la nueva configuración, forzando recarga
        await _loadPrayerTimes(forceRefresh: true);
        
        // Mostrar notificación de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('تم تحديث مواقيت الصلاة وفقًا للإعدادات الجديدة'),
                ),
              ],
            ),
            backgroundColor: kPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        debugPrint('Error al recargar tiempos después de cambiar configuración: $e');
        
        // Mostrar notificación de error
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

  // Contenido principal
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
            // Durante carga con datos en caché, mostrar indicador de carga suave
            if (_isRefreshing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(
                  backgroundColor: kPrimary.withOpacity(0.1),
                  color: kPrimary,
                ),
              ),
            
            // Tarjeta de ubicación
            _buildLocationCard(),
            
            // Advertencia sobre permisos de ubicación si estamos usando ubicación predeterminada
            if (!_hasLocationPermission)
              _buildLocationPermissionWarning(),
              
            const SizedBox(height: 20),

            // Tiempos de oración - mejora en la visualización de lista para reducir consumo de recursos
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildPrayerTimesList(),
            ),
            
            // Botón de configuración de notificaciones
            Center(
              child: ElevatedButton.icon(
                onPressed: _navigateToNotificationSettings,
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
  
  // Widget para estado vacío
  Widget _buildEmptyStateWidget() {
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
  
  // Lista de tiempos de oración
  Widget _buildPrayerTimesList() {
    return AnimationLimiter(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _prayerTimes!.length,
        itemBuilder: (context, index) {
          final prayer = _prayerTimes![index];
          
          // Optimización: usar key única para cada elemento
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
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

  // Advertencia sobre permisos de ubicación
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
                  onPressed: _requestLocationPermission,
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
  
  // Solicitar permisos de ubicación
  Future<void> _requestLocationPermission() async {
    final hasPermission = await _prayerService.requestLocationPermission();
    if (hasPermission) {
      _loadPrayerTimes(forceRefresh: true);
    }
  }

  // Tarjeta de ubicación
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
                        
                        // Añadir detalles sobre la última actualización
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
                    onPressed: () => _loadPrayerTimes(forceRefresh: true),
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
  
  // Formatear tiempo de última actualización
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

  // Tarjeta de tiempo de oración
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
              // Icono de oración
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
              
              // Detalles de la oración
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
                    
                    // Tiempo restante hasta la oración
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

  // Widget de error
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
            // Mostrar mensaje de error más amigable
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
                  onPressed: () => _loadPrayerTimes(forceRefresh: true),
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
                    onPressed: _useDefaultLocation,
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
                onPressed: _requestLocationPermission,
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
  
  // Usar ubicación predeterminada
  Future<void> _useDefaultLocation() async {
    try {
      // Obtener tiempos de oración con ubicación predeterminada
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
        _errorMessage = 'فشل استخدام الموقع الافتراضي';
      });
      
      // Mostrar mensaje de error más detallado en registro de depuración
      debugPrint('Error detallado al usar ubicación predeterminada: $e');
    }
  }
  
  // Formatear mensaje de error para ser más amigable
  String _getFormattedErrorMessage(String errorMessage) {
    // Simplificar mensajes de error técnicos
    if (errorMessage.contains('Exception')) {
      return 'حدث خطأ أثناء الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت الخاص بك والمحاولة مرة أخرى.';
    } else if (errorMessage.contains('Permission')) {
      return 'لم يتم منح الأذونات المطلوبة. يرجى منح إذن الوصول للموقع للحصول على مواقيت دقيقة.';
    } else if (errorMessage.contains('Timeout')) {
      return 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت الخاص بك والمحاولة مرة أخرى.';
    } else if (errorMessage.isEmpty) {
      return 'حدث خطأ غير معروف. يرجى المحاولة مرة أخرى.';
    }
    
    // Devolver mensaje de error original si no es demasiado técnico
    return errorMessage;
  }
}