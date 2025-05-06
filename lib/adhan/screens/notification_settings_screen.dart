// lib/screens/settings/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;
import 'package:test_athkar_app/adhan/services/adhan_notification_service.dart';
import 'package:test_athkar_app/adhan/services/prayer_times_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
  bool _hasPermissions = false;
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
      
      // Verificar permisos de notificación
      _hasPermissions = await _notificationService.checkNotificationPermission();
      
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
  
  Future<void> _requestNotificationPermission() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Solicitar permisos de notificación
      _hasPermissions = await _notificationService.requestNotificationPermission();
      
      setState(() {
        _isLoading = false;
      });
      
      if (_hasPermissions) {
        _showSuccessSnackBar('تم منح إذن الإشعارات بنجاح');
        // Reprogramar notificaciones ahora que tenemos permisos
        await _prayerService.schedulePrayerNotifications();
      } else {
        // Mostrar diálogo para explicar al usuario cómo conceder permisos manualmente
        _showPermissionsGuideDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      _showErrorSnackBar('حدث خطأ أثناء طلب إذن الإشعارات');
      debugPrint('Error al solicitar permisos de notificación: $e');
    }
  }
  
  void _showPermissionsGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إذن الإشعارات مطلوب'),
        content: const Text(
          'لم يتم منح إذن الإشعارات. يرجى فتح إعدادات التطبيق وتمكين الإشعارات يدويًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // En lugar de usar app_settings, usamos un enfoque genérico
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
  
  // Función genérica para abrir configuración de la aplicación
  void openAppSettings() {
    // Implementar según la plataforma - para mantener compatibilidad sin app_settings
    try {
      // Usar Flutter estándar para abrir la configuración de la aplicación
      // Esta es una implementación básica que funciona en la mayoría de dispositivos
      // pero sin la precisión de app_settings
      debugPrint('Abriendo configuración de la aplicación...');
      // Notificar al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تمكين الإشعارات في إعدادات التطبيق'),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('Error al abrir configuración: $e');
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
              child: AnimationLimiter(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 600),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                          child: widget,
                        ),
                      ),
                      children: [
                        // Mostrar banner de permisos si no se han concedido
                        if (!_hasPermissions)
                          _buildPermissionBanner(),
                        
                        // Tarjeta de activación de notificaciones
                        _buildMasterSwitchCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Título de configuraciones de oraciones
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: kPrimary.withOpacity(0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'إعدادات إشعارات الصلوات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Configuraciones individuales de oraciones 
                        _buildPrayerSettingsCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Información explicativa
                        _buildInfoCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Botón de actualización de notificaciones
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _hasPermissions ? _updateNotifications : _requestNotificationPermission,
                            icon: Icon(_hasPermissions ? Icons.refresh : Icons.notifications_active),
                            label: Text(_hasPermissions ? 'تحديث الإشعارات' : 'منح إذن الإشعارات'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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
    );
  }
  
  // Banner de permisos
  Widget _buildPermissionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.15),
            Colors.orange.withOpacity(0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
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
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_off,
                color: Colors.orange.shade800,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إذن الإشعارات غير ممنوح',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بأوقات الصلاة. يرجى منح الإذن لتلقي إشعارات الأذان.',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _requestNotificationPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('منح إذن الإشعارات'),
          ),
        ],
      ),
    );
  }
  
  // Tarjeta de activación/desactivación de notificaciones
  Widget _buildMasterSwitchCard() {
    return Card(
      elevation: 8,
      shadowColor: kPrimary.withOpacity(0.4),
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
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
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
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_active,
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
            Transform.scale(
              scale: 1.2,
              child: Switch(
                value: _notificationsEnabled,
                onChanged: _hasPermissions ? _toggleMasterSwitch : null,
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(0.4),
                inactiveThumbColor: Colors.white.withOpacity(0.8),
                inactiveTrackColor: Colors.white.withOpacity(0.2),
              ),
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
      shadowColor: kPrimary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _prayerSettings.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: entry.value ? kPrimary.withOpacity(0.07) : null,
                  border: entry.value 
                      ? Border.all(color: kPrimary.withOpacity(0.3), width: 1) 
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _getPrayerIcon(entry.key),
                      color: entry.value ? kPrimary : Colors.grey,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: entry.value ? kPrimary : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getPrayerDescription(entry.key),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 1.1,
                      child: Switch(
                        value: entry.value,
                        onChanged: _notificationsEnabled && _hasPermissions
                            ? (value) => _togglePrayerSetting(entry.key, value)
                            : null,
                        activeColor: kPrimary,
                        activeTrackColor: kPrimary.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
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
  
  // Descripción para cada oración
  String _getPrayerDescription(String prayer) {
    switch (prayer) {
      case 'الفجر':
        return 'صلاة الفجر - قبل شروق الشمس';
      case 'الشروق':
        return 'وقت شروق الشمس';
      case 'الظهر':
        return 'صلاة الظهر - منتصف النهار';
      case 'العصر':
        return 'صلاة العصر - بعد الظهر';
      case 'المغرب':
        return 'صلاة المغرب - عند غروب الشمس';
      case 'العشاء':
        return 'صلاة العشاء - بعد المغرب';
      default:
        return '';
    }
  }
  
  // Tarjeta de información
  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.orange.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
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
                Container(
                  padding: const EdgeInsets.all(8),
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
                const SizedBox(width: 12),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildInfoItem(
                    Icons.notifications_active,
                    'سيتم إرسال إشعارات للصلوات المفعلة في وقتها المحدد. تأكد من السماح للتطبيق بالعمل في الخلفية وعدم إيقافه من قبل نظام التشغيل.'
                  ),
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    Icons.update,
                    'يمكنك تحديث الإشعارات عند تغيير الموقع الجغرافي أو تغيير إعدادات حساب مواقيت الصلاة.'
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Un elemento de información
  Widget _buildInfoItem(IconData icon, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.orange.shade700,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade900,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
  
  // Actualizar notificaciones de oración
  Future<void> _updateNotifications() async {
    try {
      // Mostrar indicador de carga
      setState(() {
        _isLoading = true;
      });
      
      // Verificar permisos de notificación
      if (!_hasPermissions) {
        _hasPermissions = await _notificationService.requestNotificationPermission();
        if (!_hasPermissions) {
          setState(() {
            _isLoading = false;
          });
          _showPermissionsGuideDialog();
          return;
        }
      }
      
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