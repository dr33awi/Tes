// lib/screens/settings/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;
import 'package:test_athkar_app/adhan/adhan_notification_service.dart';
import 'package:test_athkar_app/adhan/prayer_times_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final AdhanNotificationService _notificationService = AdhanNotificationService();
  final PrayerTimesService _prayerService = PrayerTimesService();
  
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  Map<String, bool> _prayerSettings = {};
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Cargar configuración del servicio
      _notificationsEnabled = _notificationService.isNotificationEnabled;
      _prayerSettings = Map.from(_notificationService.prayerNotificationSettings);
    } catch (e) {
      // Manejar errores
      debugPrint('Error al cargar configuración: $e');
      _showErrorSnackBar('حدث خطأ أثناء تحميل الإعدادات');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
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
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
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
        backgroundColor: kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
          'إعدادات الإشعارات',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kPrimary))
        : Directionality(
            textDirection: TextDirection.rtl,
            child: RefreshIndicator(
              color: kPrimary,
              onRefresh: _loadSettings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de activación de notificaciones
                    _buildMasterSwitchCard(),
                    
                    const SizedBox(height: 20),
                    
                    // Título de configuraciones de oraciones
                    const Text(
                      'إعدادات إشعارات الصلوات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Configuraciones individuales de oraciones 
                    _buildPrayerSettingsCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Información explicativa
                    _buildInfoCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Botón de actualización de notificaciones
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _updateNotifications,
                        icon: const Icon(Icons.refresh),
                        label: const Text('تحديث الإشعارات'),
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
                  ],
                ),
              ),
            ),
          ),
    );
  }
  
  // Tarjeta de activación/desactivación de notificaciones
  Widget _buildMasterSwitchCard() {
    return Card(
      elevation: 4,
      shadowColor: kPrimary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryLight],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تفعيل إشعارات مواقيت الصلاة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'استلم إشعارات عند حلول أوقات الصلاة',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _notificationsEnabled,
              onChanged: _toggleMasterSwitch,
              activeColor: Colors.white,
              activeTrackColor: Colors.white.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
  
  // Método separado para manejar la activación/desactivación principal
  Future<void> _toggleMasterSwitch(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    
    try {
      _notificationService.isNotificationEnabled = value;
      
      if (value) {
        // Reprogramar notificaciones al activarlas
        await _prayerService.schedulePrayerNotifications();
      } else {
        // Cancelar todas las notificaciones al desactivarlas
        await _notificationService.cancelAllNotifications();
      }
    } catch (e) {
      debugPrint('Error al cambiar estado de notificaciones: $e');
      _showErrorSnackBar('حدث خطأ أثناء تغيير إعدادات الإشعارات');
    }
  }
  
  // Tarjeta de configuraciones individuales de oraciones
  Widget _buildPrayerSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _prayerSettings.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    _getPrayerIcon(entry.key),
                    color: kPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Switch(
                    value: entry.value,
                    onChanged: _notificationsEnabled
                        ? (value) => _togglePrayerSetting(entry.key, value)
                        : null,
                    activeColor: kPrimary,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  // Método separado para manejar la activación/desactivación individual
  Future<void> _togglePrayerSetting(String prayer, bool value) async {
    setState(() {
      _prayerSettings[prayer] = value;
    });
    
    try {
      await _notificationService.setPrayerNotificationEnabled(prayer, value);
      await _prayerService.schedulePrayerNotifications();
    } catch (e) {
      debugPrint('Error al cambiar configuración de $prayer: $e');
      _showErrorSnackBar('حدث خطأ أثناء تغيير إعدادات الإشعار');
    }
  }
  
  // Iconos para cada oración
  IconData _getPrayerIcon(String prayer) {
    switch (prayer) {
      case 'الفجر':
        return Icons.brightness_2;
      case 'الشروق':
        return Icons.wb_sunny_outlined;
      case 'الظهر':
        return Icons.wb_sunny;
      case 'العصر':
        return Icons.wb_twighlight;
      case 'المغرب':
        return Icons.nights_stay_outlined;
      case 'العشاء':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }
  
  // Tarjeta de información
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.1),
              Colors.amber.withOpacity(0.05),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade800,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'معلومات عن إشعارات الصلاة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'سيتم إرسال إشعارات للصلوات المفعلة في وقتها المحدد. تأكد من السماح للتطبيق بالعمل في الخلفية وعدم إيقافه من قبل نظام التشغيل.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك تحديث الإشعارات عند تغيير الموقع الجغرافي أو تغيير إعدادات حساب مواقيت الصلاة.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Actualizar notificaciones de oración
  Future<void> _updateNotifications() async {
    try {
      // Mostrar indicador de carga
      setState(() {
        _isLoading = true;
      });
      
      // Reprogramar todas las notificaciones
      await _prayerService.schedulePrayerNotifications();
      
      if (mounted) {
        // Mostrar mensaje de confirmación
        _showSuccessSnackBar('تم تحديث إشعارات الصلاة بنجاح');
      }
    } catch (e) {
      debugPrint('Error al actualizar notificaciones: $e');
      
      if (mounted) {
        // Mostrar mensaje de error
        _showErrorSnackBar('حدث خطأ أثناء تحديث الإشعارات');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}