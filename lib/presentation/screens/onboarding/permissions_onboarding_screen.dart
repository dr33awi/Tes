// lib/presentation/screens/onboarding/permissions_onboarding_screen.dart
import 'package:athkar_app/core/services/utils/permission_utils.dart';
import 'package:flutter/material.dart';
import '../../../app/routes/app_router.dart';

class PermissionsOnboardingScreen extends StatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  State<PermissionsOnboardingScreen> createState() => _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState extends State<PermissionsOnboardingScreen> {
  bool _notificationsGranted = false;
  bool _locationGranted = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    final permissions = await PermissionUtil.checkMainPermissions();
    
    setState(() {
      _notificationsGranted = permissions['notification'] ?? false;
      _locationGranted = permissions['location'] ?? false;
    });
  }
  
  Future<void> _requestPermission(String type) async {
    bool granted = false;
    
    if (type == 'notification') {
      granted = await PermissionUtil.requestNotification(context);
    } else if (type == 'location') {
      granted = await PermissionUtil.requestLocation(context);
    }
    
    if (type == 'notification') {
      setState(() {
        _notificationsGranted = granted;
      });
    } else if (type == 'location') {
      setState(() {
        _locationGranted = granted;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد الأذونات'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'الأذونات المطلوبة',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'يحتاج التطبيق إلى بعض الأذونات لتوفير أفضل تجربة.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // الإشعارات
            _buildPermissionItem(
              title: 'الإشعارات',
              description: 'للتذكير بمواقيت الصلاة والأذكار',
              isGranted: _notificationsGranted,
              icon: Icons.notifications,
              onRequest: () => _requestPermission('notification'),
            ),
            
            const SizedBox(height: 16),
            
            // الموقع
            _buildPermissionItem(
              title: 'الموقع',
              description: 'لتحديد اتجاه القبلة ومواقيت الصلاة',
              isGranted: _locationGranted,
              icon: Icons.location_on,
              onRequest: () => _requestPermission('location'),
            ),
            
            const Spacer(),
            
            // زر المتابعة
            ElevatedButton(
              onPressed: (_notificationsGranted && _locationGranted) 
                  ? () {
                      Navigator.pushReplacementNamed(context, AppRouter.home);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('متابعة'),
            ),
            
            const SizedBox(height: 8),
            
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRouter.home);
              },
              child: const Text('تخطي'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPermissionItem({
    required String title,
    required String description,
    required bool isGranted,
    required IconData icon,
    required VoidCallback onRequest,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isGranted ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isGranted ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: isGranted ? Colors.green : Colors.grey,
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isGranted ? Colors.green : Colors.black,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isGranted ? null : onRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: isGranted ? Colors.green : null,
              foregroundColor: isGranted ? Colors.white : null,
            ),
            child: Text(isGranted ? 'تم' : 'منح'),
          ),
        ],
      ),
    );
  }
}