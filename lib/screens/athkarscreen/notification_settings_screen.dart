import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_service.dart';
import 'package:test_athkar_app/screens/athkarscreen/notification_service.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final AthkarService _athkarService = AthkarService();
  final NotificationService _notificationService = NotificationService();
  
  List<AthkarCategory> _categories = [];
  Map<String, bool> _notificationEnabled = {};
  Map<String, String> _customTimes = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  
  // Load all categories and their notification settings
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load all athkar categories
      final categories = await _athkarService.loadAllAthkarCategories();
      
      // Filter to only include categories with notification times
      final notifiableCategories = categories.where(
        (cat) => cat.notifyTime != null && cat.notifyTime!.isNotEmpty
      ).toList();
      
      // Load notification settings for each category
      Map<String, bool> notificationEnabled = {};
      Map<String, String> customTimes = {};
      
      for (final category in notifiableCategories) {
        final isEnabled = await _athkarService.getNotificationEnabled(category.id);
        final customTime = await _athkarService.getCustomNotificationTime(category.id);
        
        notificationEnabled[category.id] = isEnabled;
        if (customTime != null) {
          customTimes[category.id] = customTime;
        }
      }
      
      if (mounted) {
        setState(() {
          _categories = notifiableCategories;
          _notificationEnabled = notificationEnabled;
          _customTimes = customTimes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Toggle notification setting for a category
  Future<void> _toggleNotification(String categoryId, bool value) async {
    try {
      await _notificationService.toggleCategoryNotification(categoryId, value);
      
      setState(() {
        _notificationEnabled[categoryId] = value;
      });
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'تم تفعيل الإشعارات' : 'تم إيقاف الإشعارات',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
        ),
      );
    } catch (e) {
      print('Error toggling notification: $e');
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تحديث الإعدادات'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Show time picker and update custom time
  Future<void> _showTimePicker(AthkarCategory category) async {
    // Get current time to use as initial time
    final defaultTime = category.notifyTime ?? "08:00";
    final customTime = _customTimes[category.id] ?? defaultTime;
    
    // Parse time
    final timeParts = customTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    // Show time picker
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      // Format time as "HH:MM"
      final formattedTime = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      
      try {
        // Save the custom time
        await _notificationService.setCustomNotificationTime(category.id, formattedTime);
        
        setState(() {
          _customTimes[category.id] = formattedTime;
        });
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث وقت إشعار ${category.title} إلى $formattedTime'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: kPrimary,
          ),
        );
      } catch (e) {
        print('Error setting custom time: $e');
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تحديث وقت الإشعار'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Send a test notification
  void _sendTestNotification() async {
    try {
      await _notificationService.sendTestNotification(
        'اختبار الإشعارات',
        
      );
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال إشعار تجريبي'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
        ),
      );
    } catch (e) {
      print('Error sending test notification: $e');
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء إرسال الإشعار التجريبي'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notification_add,
              color: kPrimary,
            ),
            onPressed: _sendTestNotification,
            tooltip: 'اختبار الإشعارات',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // شرح وتوضيح للإشعارات
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Card(
                      elevation: 2,
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
                            stops: const [0.3, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'حول إشعارات الأذكار',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'يمكنك تفعيل أو إيقاف إشعارات الأذكار، وكذلك تعديل وقت الإشعار لكل فئة من فئات الأذكار حسب رغبتك.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // عنوان قائمة الإشعارات
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: kPrimary,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'إعدادات إشعارات الأذكار',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // قائمة الإشعارات
                  Expanded(
                    child: _buildCategoriesList(),
                  ),
                ],
              ),
            ),
    );
  }
  
  // بناء قائمة فئات الأذكار مع إعدادات الإشعارات
  Widget _buildCategoriesList() {
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد فئات أذكار مع إشعارات متاحة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isEnabled = _notificationEnabled[category.id] ?? false;
          final notifyTime = _customTimes[category.id] ?? category.notifyTime ?? '';
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: isEnabled
                          ? Border.all(color: category.color.withOpacity(0.5), width: 1.5)
                          : null,
                    ),
                    child: Column(
                      children: [
                        // رأس البطاقة
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                category.color,
                                category.color.withOpacity(0.8),
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              topLeft: Radius.circular(16),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                category.icon,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  category.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // محتوى البطاقة
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // وصف الفئة
                              if (category.description != null)
                                Text(
                                  category.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              
                              const SizedBox(height: 16),
                              
                              // وقت الإشعار
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'وقت الإشعار:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: isEnabled ? () => _showTimePicker(category) : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isEnabled
                                            ? category.color.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isEnabled
                                              ? category.color.withOpacity(0.3)
                                              : Colors.grey.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatTimeForDisplay(notifyTime),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isEnabled
                                                  ? category.color
                                                  : Colors.grey,
                                            ),
                                          ),
                                          if (isEnabled)
                                            Icon(
                                              Icons.edit,
                                              size: 14,
                                              color: category.color,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // مفتاح تبديل الإشعار
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isEnabled ? 'الإشعارات مفعلة' : 'الإشعارات غير مفعلة',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isEnabled ? category.color : Colors.grey,
                                    ),
                                  ),
                                  Switch(
                                    value: isEnabled,
                                    onChanged: (value) => _toggleNotification(category.id, value),
                                    activeColor: category.color,
                                    activeTrackColor: category.color.withOpacity(0.3),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // تنسيق وقت العرض
  String _formatTimeForDisplay(String timeString) {
    if (timeString.isEmpty) return 'غير محدد';
    
    try {
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final String period = hour >= 12 ? 'م' : 'ص';
      final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeString;
    }
  }
  
  // مؤشر التحميل
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimary),
          SizedBox(height: 16),
          Text(
            'جاري تحميل الإعدادات...',
            style: TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}