// lib/presentation/screens/onboarding/permissions_onboarding_screen.dart
import 'package:flutter/material.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/routes/app_router.dart';
import '../../../core/services/permission_manager.dart';
import '../../../core/services/interfaces/permission_service.dart';

class PermissionsOnboardingScreen extends StatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  State<PermissionsOnboardingScreen> createState() => _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState extends State<PermissionsOnboardingScreen> {
  final PermissionManager _permissionManager = getIt<PermissionManager>();
  
  bool _notificationsGranted = false;
  bool _locationGranted = false;
  bool _batteryOptGranted = false;
  bool _dndGranted = false;
  
  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }
  
  Future<void> _checkInitialPermissions() async {
    final permissions = await _permissionManager.checkPermissions();
    
    setState(() {
      _notificationsGranted = permissions[AppPermissionType.notification] == AppPermissionStatus.granted;
      _locationGranted = permissions[AppPermissionType.location] == AppPermissionStatus.granted;
      _batteryOptGranted = permissions[AppPermissionType.batteryOptimization] == AppPermissionStatus.granted;
      _dndGranted = permissions[AppPermissionType.doNotDisturb] == AppPermissionStatus.granted;
    });
  }
  
  @override
  Widget build(BuildContext context) {
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
                onRequest: () async {
                  final result = await _permissionManager.requestOptionalPermissions(context);
                  setState(() {
                    _dndGranted = result[AppPermissionType.doNotDisturb] ?? false;
                  });
                },
              ),
              
              const Spacer(),
              
              // زر المتابعة للشاشة الرئيسية
              ElevatedButton(
                onPressed: _notificationsGranted && _locationGranted
                    ? () {
                        Navigator.pushReplacementNamed(context, AppRouter.home);
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
              
              // خيار تخطي بعض الأذونات
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
                              Navigator.pushReplacementNamed(context, AppRouter.home);
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