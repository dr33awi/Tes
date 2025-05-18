// lib/presentation/screens/onboarding/permissions_onboarding_screen.dart
// Actualización para manejar proveedores correctamente
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../core/services/permission_manager.dart';
import '../../../../core/services/interfaces/permission_service.dart';
import '../../../../core/services/interfaces/do_not_disturb_service.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class PermissionsOnboardingScreen extends StatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  State<PermissionsOnboardingScreen> createState() => _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState extends State<PermissionsOnboardingScreen> {
  late final PermissionManager _permissionManager;
  late final DoNotDisturbService _doNotDisturbService;
  
  bool _notificationsGranted = false;
  bool _locationGranted = false;
  bool _batteryOptGranted = false;
  bool _dndGranted = false;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initServices();
  }
  
  // تهيئة الخدمات المطلوبة
  Future<void> _initServices() async {
    try {
      _permissionManager = getIt<PermissionManager>();
      _doNotDisturbService = getIt<DoNotDisturbService>();
      _isInitialized = true;
      
      // التحقق من الأذونات الأولية
      await _checkInitialPermissions();
    } catch (e) {
      debugPrint('خطأ في تهيئة الخدمات: $e');
      // إظهار رسالة خطأ إذا تعذر تهيئة الخدمات
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تهيئة الخدمات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // التحقق من حالة الأذونات الأولية
  Future<void> _checkInitialPermissions() async {
    if (!_isInitialized) return;
    
    try {
      final permissions = await _permissionManager.checkPermissions();
      
      if (mounted) {
        setState(() {
          _notificationsGranted = permissions[AppPermissionType.notification] == AppPermissionStatus.granted;
          _locationGranted = permissions[AppPermissionType.location] == AppPermissionStatus.granted;
          _batteryOptGranted = permissions[AppPermissionType.batteryOptimization] == AppPermissionStatus.granted;
          _dndGranted = permissions[AppPermissionType.doNotDisturb] == AppPermissionStatus.granted;
        });
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من الأذونات الأولية: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // نتأكد أن إعدادات التطبيق متاحة قبل البناء - وهذا يصلح مشكلة Provider
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد الأذونات'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'مرحبًا بك في تطبيق الأذكار',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'يرجى منح الأذونات التالية لضمان عمل التطبيق بشكل صحيح:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // الأذونات الأساسية
              _buildPermissionCard(
                icon: Icons.notifications,
                title: 'الإشعارات',
                description: 'للتذكير بمواقيت الصلاة والأذكار',
                isGranted: _notificationsGranted,
                isRequired: true,
                onRequest: () async {
                  final result = await _permissionManager.requestEssentialPermissions(context);
                  setState(() {
                    _notificationsGranted = result[AppPermissionType.notification] ?? false;
                  });
                },
              ),
              
              _buildPermissionCard(
                icon: Icons.location_on,
                title: 'الموقع',
                description: 'لتحديد اتجاه القبلة ومواقيت الصلاة',
                isGranted: _locationGranted,
                isRequired: true,
                onRequest: () async {
                  final result = await _permissionManager.requestLocationPermission(context);
                  setState(() {
                    _locationGranted = result;
                  });
                },
              ),
              
              // الأذونات الاختيارية
              _buildPermissionCard(
                icon: Icons.battery_charging_full,
                title: 'استثناء تحسينات البطارية',
                description: 'لضمان عمل الإشعارات بشكل موثوق',
                isGranted: _batteryOptGranted,
                isRequired: false,
                onRequest: () async {
                  final result = await _permissionManager.requestOptionalPermissions(context);
                  setState(() {
                    _batteryOptGranted = result[AppPermissionType.batteryOptimization] ?? false;
                  });
                },
              ),
              
              _buildPermissionCard(
                icon: Icons.do_not_disturb_on,
                title: 'وضع عدم الإزعاج',
                description: 'لإظهار إشعارات الصلاة في وضع عدم الإزعاج',
                isGranted: _dndGranted,
                isRequired: false,
                onRequest: _requestDoNotDisturbPermission,
              ),
              
              // فاصل لدفع زر المتابعة للأسفل
              const Spacer(),
              
              // زر المتابعة مع تحسين التنقل
              ElevatedButton(
                onPressed: _notificationsGranted && _locationGranted
                    ? () {
                        // استخدام طريقة أفضل للتنقل وتنظيف المسار
                        // قبل التنقل، نتأكد من تحديث إعدادات التطبيق
                        settingsProvider.rescheduleAllNotifications();
                        
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRouter.home,
                          (route) => false,
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'متابعة',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              
              // خيار تخطي الأذونات
              if (!_notificationsGranted || !_locationGranted)
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('تأكيد'),
                        content: const Text(
                          'بعض الأذونات المطلوبة غير ممنوحة. قد لا تعمل بعض ميزات التطبيق بشكل صحيح.\n\nهل تريد المتابعة على أي حال؟',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('إلغاء'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // استخدام نفس طريقة التنقل المحسنة
                              // نتأكد من تحديث إعدادات التطبيق قبل التنقل
                              settingsProvider.rescheduleAllNotifications();
                              
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRouter.home,
                                (route) => false,
                              );
                            },
                            child: const Text('متابعة على أي حال'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('تخطي'),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // طريقة محسنة لطلب إذن عدم الإزعاج
  Future<void> _requestDoNotDisturbPermission() async {
    if (!_isInitialized) {
      debugPrint('الخدمات غير مهيأة، لا يمكن طلب أذونات وضع عدم الإزعاج');
      return;
    }
    
    try {
      // أولاً، طلب الإذن
      final result = await _permissionManager.requestOptionalPermissions(context);
      setState(() {
        _dndGranted = result[AppPermissionType.doNotDisturb] ?? false;
      });
      
      // إذا لم يتم منح الإذن، نقدم خيار فتح الإعدادات
      if (!_dndGranted && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('إذن وضع عدم الإزعاج'),
            content: const Text('هذا الإذن مطلوب للسماح بظهور إشعارات الصلاة حتى في وضع عدم الإزعاج. هل تريد فتح الإعدادات لمنح الإذن؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('لاحقاً'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // فتح إعدادات وضع عدم الإزعاج مباشرة
                  _doNotDisturbService.openDoNotDisturbSettings();
                },
                child: const Text('فتح الإعدادات'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('خطأ في طلب إذن وضع عدم الإزعاج: $e');
      // إظهار رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في طلب الإذن: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // بناء بطاقة الإذن
  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required bool isRequired,
    required VoidCallback onRequest,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isGranted ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isGranted ? Colors.green : Colors.grey,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'مطلوب',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: isGranted ? null : onRequest,
              child: Text(
                isGranted ? 'ممنوح' : 'منح الإذن',
                style: TextStyle(
                  color: isGranted ? Colors.green : Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}