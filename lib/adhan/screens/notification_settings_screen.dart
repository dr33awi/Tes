// lib/adhan/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/services/notification/notification_manager.dart';
import 'package:test_athkar_app/adhan/services/prayer_times_service.dart';
import 'package:test_athkar_app/services/di_container.dart';
import 'package:test_athkar_app/services/permissions_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late final NotificationManager _notificationManager;
  late final PrayerTimesService _prayerService;
  late final PermissionsService _permissionsService;
  
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _hasPermissions = false;
  Map<String, bool> _prayerSettings = {};
  
  // Theme colors
  late Color kPrimary;
  late Color kPrimaryLight;
  late Color kSurface;
  
  @override
  void initState() {
    super.initState();
    _notificationManager = serviceLocator<NotificationManager>();
    _prayerService = PrayerTimesService();
    _permissionsService = serviceLocator<PermissionsService>();
    _loadSettings();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize theme colors
    kPrimary = Theme.of(context).primaryColor;
    kPrimaryLight = Theme.of(context).primaryColor.withOpacity(0.7);
    kSurface = Theme.of(context).scaffoldBackgroundColor;
  }
  
  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Check notification permissions
      _hasPermissions = await _permissionsService.checkNotificationPermission();
      
      // Load settings from notification manager
      final settings = _notificationManager.settings;
      _notificationsEnabled = settings.enabled;
      
      // Prayer names
      final prayerNames = [
        'الفجر',
        'الشروق',
        'الظهر',
        'العصر',
        'المغرب',
        'العشاء',
      ];
      
      // Load each prayer's settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      for (final prayer in prayerNames) {
        // Check if prayer notification is enabled from SharedPreferences
        final isEnabled = prefs.getBool('prayer_${prayer}_notifications_enabled') ?? true;
        _prayerSettings[prayer] = isEnabled;
      }
      
    } catch (e) {
      debugPrint('Error loading settings: $e');
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
      
      // Request notification permissions using PermissionsService
      _hasPermissions = await _permissionsService.checkAndRequestNotificationPermission();
      
      setState(() {
        _isLoading = false;
      });
      
      if (_hasPermissions) {
        _showSuccessSnackBar('تم منح إذن الإشعارات بنجاح');
        // Reschedule notifications now that we have permissions
        await _prayerService.schedulePrayerNotifications();
      } else {
        // Show dialog to explain how to grant permissions manually
        _showPermissionsGuideDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      _showErrorSnackBar('حدث خطأ أثناء طلب إذن الإشعارات');
      debugPrint('Error requesting notification permission: $e');
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
              _permissionsService.openNotificationSettings();
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
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: kPrimary))
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
                        // Show permissions banner if not granted
                        if (!_hasPermissions)
                          _buildPermissionBanner(),
                        
                        // Master notifications switch card
                        _buildMasterSwitchCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Prayer settings title
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
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Individual prayer settings
                        _buildPrayerSettingsCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Information card
                        _buildInfoCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Update notifications button
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
  
  // Permissions banner
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
            'يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بأوقات الصلاة. يرجى منح الإذن لتلقي إشعارات.',
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
  
  // Master notifications switch card
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
  
  // Handle master switch toggle
  Future<void> _toggleMasterSwitch(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    
    try {
      await _notificationManager.setNotificationsEnabled(value);
      
      if (value) {
        // Reschedule notifications when enabled
        await _prayerService.schedulePrayerNotifications();
      } else {
        // Cancel all notifications when disabled
        for (final prayer in _prayerSettings.keys) {
          await _notificationManager.cancelNotification('prayer_$prayer');
        }
      }
    } catch (e) {
      debugPrint('Error changing notification state: $e');
      _showErrorSnackBar('حدث خطأ أثناء تغيير إعدادات الإشعارات');
    }
  }
  
  // Individual prayer settings card
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
  
  // Handle individual prayer setting toggle
  Future<void> _togglePrayerSetting(String prayer, bool value) async {
    setState(() {
      _prayerSettings[prayer] = value;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('prayer_${prayer}_notifications_enabled', value);
      
      if (value) {
        // Schedule notification for this prayer
        await _prayerService.schedulePrayerNotifications();
      } else {
        // Cancel notification for this prayer
        await _notificationManager.cancelNotification('prayer_$prayer');
      }
    } catch (e) {
      debugPrint('Error changing setting for $prayer: $e');
      _showErrorSnackBar('حدث خطأ أثناء تغيير إعدادات الإشعار');
    }
  }
  
  // Icons for each prayer
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
  
  // Description for each prayer
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
  
  // Information card
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
  
  // Information item
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
  
  // Update prayer notifications
  Future<void> _updateNotifications() async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });
      
      // Check notification permissions
      if (!_hasPermissions) {
        _hasPermissions = await _permissionsService.checkAndRequestNotificationPermission();
        if (!_hasPermissions) {
          setState(() {
            _isLoading = false;
          });
          _showPermissionsGuideDialog();
          return;
        }
      }
      
      // Reschedule all notifications
      await _prayerService.schedulePrayerNotifications();
      
      if (mounted) {
        // Show success message
        _showSuccessSnackBar('تم تحديث إشعارات الصلاة بنجاح');
      }
    } catch (e) {
      debugPrint('Error updating notifications: $e');
      
      if (mounted) {
        // Show error message
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