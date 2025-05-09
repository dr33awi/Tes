// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary,kSurface;
import 'package:test_athkar_app/screens/athkarscreen/notification_settings_screen.dart';
import 'package:test_athkar_app/screens/athkarscreen/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _checkNotificationsStatus();
  }
  
  // التحقق من حالة الإشعارات
  Future<void> _checkNotificationsStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAnyNotification = prefs.getKeys().any((key) => 
        key.startsWith('notification_') && key.endsWith('_enabled') && 
        prefs.getBool(key) == true);
    
    setState(() {
      _notificationsEnabled = hasAnyNotification;
    });
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
          'الإعدادات',
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
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: AnimationLimiter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 600),
                childAnimationBuilder: (widget) => SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: widget,
                  ),
                ),
                children: [
                  // قسم عام
                  _buildSectionHeader('إعدادات عامة', Icons.settings),
                  
                  _buildSettingCard(
                    title: 'إشعارات الأذكار',
                    subtitle: _notificationsEnabled ? 'مفعّلة' : 'غير مفعّلة',
                    icon: Icons.notifications_active,
                    iconBackgroundColor: Colors.amber,
                    onTap: () async {
                      // الانتقال إلى شاشة إعدادات الإشعارات
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSettingsScreen(),
                        ),
                      );
                      
                      // تحديث حالة الإشعارات بعد العودة
                      _checkNotificationsStatus();
                    },
                  ),
                  
                  _buildSettingCard(
                    title: 'المظهر',
                    subtitle: 'سمة التطبيق والألوان',
                    icon: Icons.color_lens,
                    iconBackgroundColor: Colors.purple,
                    onTap: () {
                      // يمكن إضافة شاشة خاصة بإعدادات المظهر مستقبلاً
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('قريباً...'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: EdgeInsets.all(16),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  
                  _buildSettingCard(
                    title: 'الصوت والاهتزاز',
                    subtitle: 'إعدادات الصوت والاهتزاز في التطبيق',
                    icon: Icons.volume_up,
                    iconBackgroundColor: Colors.teal,
                    onTap: () {
                      // يمكن إضافة شاشة خاصة بإعدادات الصوت مستقبلاً
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('قريباً...'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: EdgeInsets.all(16),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // قسم البيانات
                  _buildSectionHeader('البيانات', Icons.storage),
                  
                  _buildSettingCard(
                    title: 'نسخ احتياطي',
                    subtitle: 'حفظ نسخة من بياناتك',
                    icon: Icons.backup,
                    iconBackgroundColor: Colors.blue,
                    onTap: () {
                      // يمكن إضافة وظيفة النسخ الاحتياطي مستقبلاً
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('قريباً...'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: EdgeInsets.all(16),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  
                  _buildSettingCard(
                    title: 'استعادة البيانات',
                    subtitle: 'استعادة النسخة الاحتياطية',
                    icon: Icons.restore,
                    iconBackgroundColor: Colors.orange,
                    onTap: () {
                      // يمكن إضافة وظيفة استعادة النسخة الاحتياطية مستقبلاً
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('قريباً...'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: EdgeInsets.all(16),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  
                  _buildSettingCard(
                    title: 'مسح البيانات',
                    subtitle: 'حذف جميع البيانات وإعادة ضبط التطبيق',
                    icon: Icons.delete_forever,
                    iconBackgroundColor: Colors.red,
                    onTap: () {
                      _showDeleteConfirmationDialog();
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // قسم حول التطبيق
                  _buildSectionHeader('حول التطبيق', Icons.info_outline),
                  
                  _buildSettingCard(
                    title: 'عن التطبيق',
                    subtitle: 'معلومات عن التطبيق والإصدار',
                    icon: Icons.info,
                    iconBackgroundColor: Colors.indigo,
                    onTap: () {
                      _showAboutDialog();
                    },
                  ),
                  
                  _buildSettingCard(
                    title: 'المساهمون',
                    subtitle: 'الأشخاص الذين ساهموا في تطوير التطبيق',
                    icon: Icons.people,
                    iconBackgroundColor: Colors.green,
                    onTap: () {
                      // يمكن إضافة شاشة خاصة بالمساهمين مستقبلاً
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('قريباً...'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: EdgeInsets.all(16),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  
                  _buildSettingCard(
                    title: 'تقييم التطبيق',
                    subtitle: 'قم بتقييم التطبيق على متجر التطبيقات',
                    icon: Icons.star,
                    iconBackgroundColor: Colors.amber,
                    onTap: () {
                      // يمكن إضافة رابط لتقييم التطبيق مستقبلاً
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('قريباً...'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: EdgeInsets.all(16),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // بناء عنوان القسم
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, color: kPrimary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
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
  
  // بناء بطاقة الإعداد
  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBackgroundColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconBackgroundColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // عرض مربع حوار تأكيد الحذف
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد الحذف'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف جميع البيانات وإعادة ضبط التطبيق؟ هذا الإجراء لا يمكن التراجع عنه.',
          style: TextStyle(height: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // حذف جميع البيانات
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              
              // إلغاء جميع الإشعارات
              await _notificationService.cancelAllNotifications();
              
              Navigator.pop(context);
              
              // عرض رسالة
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف جميع البيانات بنجاح'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: EdgeInsets.all(16),
                  duration: Duration(seconds: 2),
                ),
              );
              
              // تحديث حالة الإشعارات
              _checkNotificationsStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('حذف البيانات'),
          ),
        ],
      ),
    );
  }
  
  // عرض مربع حوار حول التطبيق
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: kPrimary),
            SizedBox(width: 8),
            Text('عن التطبيق'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  // إذا لم يتم العثور على الشعار، استخدم أيقونة بديلة
                  return Icon(
                    Icons.menu_book,
                    size: 80,
                    color: kPrimary.withOpacity(0.7),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Text(
              'تطبيق الأذكار',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'الإصدار 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Divider(height: 24),
            Text(
              'تطبيق لقراءة وتذكير الأذكار الإسلامية في أوقاتها المناسبة.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'تم تطويره بكل حب ❤️',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: TextStyle(color: kPrimary)),
          ),
        ],
      ),
    );
  }
}