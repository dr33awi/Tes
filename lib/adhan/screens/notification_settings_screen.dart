// lib/adhan/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/adhan/services/prayer_notification_service.dart';
import 'package:test_athkar_app/adhan/services/prayer_times_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final PrayerNotificationService _notificationService = PrayerNotificationService();
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
      
      // التحقق من أذونات الإشعارات
      _hasPermissions = await _notificationService.checkNotificationPermission();
      
      // تحميل الإعدادات من الخدمة
      _notificationsEnabled = _notificationService.isNotificationEnabled;
      _prayerSettings = Map.from(_notificationService.prayerNotificationSettings);
    } catch (e) {
      debugPrint('خطأ أثناء تحميل الإعدادات: $e');
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
      
      // طلب أذونات الإشعارات
      _hasPermissions = await _notificationService.requestNotificationPermission();
      
      setState(() {
        _isLoading = false;
      });
      
      if (_hasPermissions) {
        _showSuccessSnackBar('تم منح إذن الإشعارات بنجاح');
        // إعادة جدولة الإشعارات بعد الحصول على الأذونات
        await _prayerService.schedulePrayerNotifications();
      } else {
        // عرض مربع حوار لشرح كيفية منح الأذونات يدويًا
        _showPermissionsGuideDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      _showErrorSnackBar('حدث خطأ أثناء طلب إذن الإشعارات');
      debugPrint('خطأ أثناء طلب أذونات الإشعارات: $e');
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
  
  // وظيفة فتح إعدادات التطبيق
  void openAppSettings() {
    try {
      // استخدام الطريقة القياسية لفتح إعدادات التطبيق في فلاتر
      debugPrint('جاري فتح إعدادات التطبيق...');
      // إخطار المستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تمكين الإشعارات في إعدادات التطبيق'),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('خطأ أثناء فتح الإعدادات: $e');
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
      ),
      body: _isLoading 
        ? _buildLoader()
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
                        // عرض شريط الأذونات إذا لم يتم منحها
                        if (!_hasPermissions)
                          _buildPermissionBanner(),
                        
                        // بطاقة تفعيل الإشعارات
                        _buildMasterSwitchCard(),
                        
                        const SizedBox(height: 24),
                        
                        // عنوان إعدادات الصلوات
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: kPrimary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
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
                        
                        // إعدادات كل صلاة على حدة 
                        _buildPrayerSettingsCard(),
                        
                        const SizedBox(height: 24),
                        
                        // معلومات توضيحية
                        _buildInfoCard(),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // مؤشر التحميل المحسن
  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: kPrimary,
            size: 50,
          ),
          const SizedBox(height: 20),
          Text(
            'جاري تحميل إعدادات الإشعارات...',
            style: TextStyle(
              fontSize: 18,
              color: kPrimary,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
  
  // شريط الأذونات
  Widget _buildPermissionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade800,
            Colors.orange.shade600,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // أيقونة الخلفية
          Positioned(
            bottom: -15,
            right: -15,
            child: Icon(
              Icons.notifications_off,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_off,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'إذن الإشعارات غير ممنوح',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بأوقات الصلاة. يرجى منح الإذن لتلقي إشعارات.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _requestNotificationPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange.shade800,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Colors.orange.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'منح إذن الإشعارات',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
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
    );
  }
  
  // بطاقة تفعيل/تعطيل الإشعارات
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
        child: Stack(
          children: [
            // أيقونة الخلفية
            Positioned(
              bottom: -30,
              right: -30,
              child: Icon(
                Icons.notifications_active,
                size: 120,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            
            Row(
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
                  child: Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: _hasPermissions ? _toggleMasterSwitch : null,
                    activeColor: Colors.white,
                    activeTrackColor: kPrimary,
                    inactiveThumbColor: Colors.grey.shade300,
                    inactiveTrackColor: Colors.grey.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // طريقة التعامل مع تفعيل/تعطيل الرئيسي
  Future<void> _toggleMasterSwitch(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    
    try {
      _notificationService.isNotificationEnabled = value;
      
      if (value) {
        // إعادة جدولة الإشعارات عند تفعيلها
        await _prayerService.schedulePrayerNotifications();
        _showSuccessSnackBar('تم تفعيل إشعارات الصلاة بنجاح');
      } else {
        // إلغاء جميع الإشعارات عند تعطيلها
        await _notificationService.cancelAllNotifications();
        _showSuccessSnackBar('تم إيقاف إشعارات الصلاة');
      }
    } catch (e) {
      debugPrint('خطأ أثناء تغيير حالة الإشعارات: $e');
      _showErrorSnackBar('حدث خطأ أثناء تغيير إعدادات الإشعارات');
    }
  }
  
  // بطاقة إعدادات الصلوات الفردية
  Widget _buildPrayerSettingsCard() {
    return AnimationLimiter(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _prayerSettings.entries.length,
        itemBuilder: (context, index) {
          final entry = _prayerSettings.entries.elementAt(index);
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildPrayerSettingItem(entry.key, entry.value, index),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // عنصر إعداد الصلاة
  Widget _buildPrayerSettingItem(String prayer, bool isEnabled, int index) {
    Color cardColor = _getPrayerColor(prayer).withOpacity(isEnabled ? 1.0 : 0.6);
    
    return Card(
      elevation: isEnabled ? 4 : 2,
      shadowColor: cardColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cardColor,
              cardColor.withOpacity(0.7),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // أيقونة الخلفية
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                _getPrayerIcon(prayer),
                size: 70,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getPrayerIcon(prayer),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                prayer,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                _getPrayerDescription(prayer),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              trailing: Transform.scale(
                scale: 1.1,
                child: Switch(
                  value: isEnabled,
                  onChanged: _notificationsEnabled && _hasPermissions
                      ? (value) => _togglePrayerSetting(prayer, value)
                      : null,
                  activeColor: Colors.white,
                  activeTrackColor: cardColor.withOpacity(0.5),
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: Colors.white30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // طريقة التعامل مع تفعيل/تعطيل فردي
  Future<void> _togglePrayerSetting(String prayer, bool value) async {
    setState(() {
      _prayerSettings[prayer] = value;
    });
    
    try {
      await _notificationService.setPrayerNotificationEnabled(prayer, value);
      await _prayerService.schedulePrayerNotifications();
      
      _showSuccessSnackBar(value 
        ? 'تم تفعيل إشعارات $prayer بنجاح' 
        : 'تم إيقاف إشعارات $prayer');
    } catch (e) {
      debugPrint('خطأ أثناء تغيير إعدادات $prayer: $e');
      _showErrorSnackBar('حدث خطأ أثناء تغيير إعدادات الإشعار');
    }
  }
  
  // أيقونات لكل صلاة
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
  
  // ألوان لكل صلاة
  Color _getPrayerColor(String prayer) {
    switch (prayer) {
      case 'الفجر':
        return const Color(0xFF5C6BC0); // أزرق داكن
      case 'الشروق':
        return const Color(0xFFFFB74D); // برتقالي فاتح
      case 'الظهر':
        return const Color(0xFFFFA000); // برتقالي داكن
      case 'العصر':
        return const Color(0xFF66BB6A); // أخضر
      case 'المغرب':
        return const Color(0xFF7B1FA2); // أرجواني
      case 'العشاء':
        return const Color(0xFF3949AB); // أزرق غامق
      default:
        return const Color(0xFF4DB6AC); // فيروزي
    }
  }
  
  // وصف لكل صلاة
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
  
  // بطاقة المعلومات
  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: kPrimary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kPrimary,
              kPrimaryLight,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
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
                  'معلومات عن إشعارات الصلاة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              Icons.notifications_active,
              'سيتم إرسال إشعارات للصلوات المفعلة في وقتها المحدد. تأكد من السماح للتطبيق بالعمل في الخلفية وعدم إيقافه من قبل نظام التشغيل.'
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              Icons.update,
              'يتم تحديث الإشعارات تلقائياً عند تغيير الموقع الجغرافي أو تغيير إعدادات حساب مواقيت الصلاة.'
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              Icons.settings,
              'يمكنك تخصيص إعدادات الإشعارات لكل صلاة على حدة حسب احتياجاتك اليومية.'
            ),
          ],
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
}