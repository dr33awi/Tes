import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق الأذكار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF447055),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF447055),
          secondary: const Color(0xFF447055),
        ),
        fontFamily: 'Cairo',
      ),
      home: const PermissionsExample(),
    );
  }
}

class PermissionsExample extends StatefulWidget {
  const PermissionsExample({Key? key}) : super(key: key);

  @override
  State<PermissionsExample> createState() => _PermissionsExampleState();
}

class _PermissionsExampleState extends State<PermissionsExample> {
  // Estado de los permisos
  bool _hasLocationPermission = false;
  bool _hasNotificationPermission = false;
  String _statusMessage = 'لم يتم التحقق من الأذونات بعد';

  @override
  void initState() {
    super.initState();
    // Verificar los permisos al iniciar
    _checkPermissions();
  }

  // Verificar ambos permisos
  Future<void> _checkPermissions() async {
    bool locationStatus = await checkLocationPermission();
    bool notificationStatus = await checkNotificationPermission();
    
    setState(() {
      _hasLocationPermission = locationStatus;
      _hasNotificationPermission = notificationStatus;
      _updateStatusMessage();
    });
  }

  // Actualizar el mensaje de estado
  void _updateStatusMessage() {
    if (_hasLocationPermission && _hasNotificationPermission) {
      _statusMessage = 'تم منح جميع الأذونات المطلوبة';
    } else if (_hasLocationPermission) {
      _statusMessage = 'تم منح إذن الموقع فقط';
    } else if (_hasNotificationPermission) {
      _statusMessage = 'تم منح إذن الإشعارات فقط';
    } else {
      _statusMessage = 'لم يتم منح أي أذونات';
    }
  }

  // Verificar permiso de ubicación
  Future<bool> checkLocationPermission() async {
    return await Permission.location.status.isGranted;
  }

  // Solicitar permiso de ubicación
  Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    
    // Si el permiso fue denegado permanentemente, sugerir abrir configuración
    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        'إذن الموقع',
        'لقد رفضت إذن الموقع بشكل دائم. يرجى فتح إعدادات التطبيق ومنح الإذن يدويًا.',
        true
      );
      return false;
    }
    
    return status.isGranted;
  }

  // Verificar permiso de notificaciones
  Future<bool> checkNotificationPermission() async {
    return await Permission.notification.status.isGranted;
  }

  // Solicitar permiso de notificaciones
  Future<bool> requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();
    
    // Si el permiso fue denegado permanentemente, sugerir abrir configuración
    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        'إذن الإشعارات',
        'لقد رفضت إذن الإشعارات بشكل دائم. يرجى فتح إعدادات التطبيق ومنح الإذن يدويًا.',
        true
      );
      return false;
    }
    
    return status.isGranted;
  }

  // Mostrar un diálogo para permisos denegados
  Future<void> _showPermissionDialog(String title, String message, bool openSettings) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          if (openSettings)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('فتح الإعدادات'),
            ),
        ],
      ),
    );
  }

  // Solicitar todos los permisos
  Future<void> _requestAllPermissions() async {
    // Solicitar permiso de ubicación
    bool locationGranted = await requestLocationPermission();
    
    // Solicitar permiso de notificaciones
    bool notificationGranted = await requestNotificationPermission();
    
    setState(() {
      _hasLocationPermission = locationGranted;
      _hasNotificationPermission = notificationGranted;
      _updateStatusMessage();
    });
    
    // Mostrar resultado
    if (locationGranted && notificationGranted) {
      _showSnackBar('تم منح جميع الأذونات بنجاح');
    } else {
      _showSnackBar('لم يتم منح بعض الأذونات، يرجى المحاولة مرة أخرى');
    }
  }

  // Mostrar SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال على الأذونات'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tarjeta de estado
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'حالة الأذونات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_statusMessage),
                      const SizedBox(height: 16),
                      // Indicadores de estado
                      _buildPermissionStatus('إذن الموقع', _hasLocationPermission, primaryColor),
                      const SizedBox(height: 8),
                      _buildPermissionStatus('إذن الإشعارات', _hasNotificationPermission, primaryColor),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botones de permisos individuales
              ElevatedButton.icon(
                onPressed: () async {
                  bool granted = await requestLocationPermission();
                  setState(() {
                    _hasLocationPermission = granted;
                    _updateStatusMessage();
                  });
                  _showSnackBar(granted ? 'تم منح إذن الموقع' : 'لم يتم منح إذن الموقع');
                },
                icon: const Icon(Icons.location_on),
                label: const Text('طلب إذن الموقع'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              
              const SizedBox(height: 12),
              
              ElevatedButton.icon(
                onPressed: () async {
                  bool granted = await requestNotificationPermission();
                  setState(() {
                    _hasNotificationPermission = granted;
                    _updateStatusMessage();
                  });
                  _showSnackBar(granted ? 'تم منح إذن الإشعارات' : 'لم يتم منح إذن الإشعارات');
                },
                icon: const Icon(Icons.notifications),
                label: const Text('طلب إذن الإشعارات'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botón para solicitar todos los permisos
              OutlinedButton.icon(
                onPressed: _requestAllPermissions,
                icon: const Icon(Icons.security),
                label: const Text('طلب جميع الأذونات'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              
              const Spacer(),
              
              // Información sobre permisos
              Card(
                elevation: 2,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'معلومات عن الأذونات',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'إذن الموقع: مطلوب لحساب مواقيت الصلاة الدقيقة بناءً على موقعك الحالي',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'إذن الإشعارات: مطلوب لإرسال تنبيهات لك عند حلول وقت الصلاة',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Widget para mostrar el estado de un permiso
  Widget _buildPermissionStatus(String permissionName, bool isGranted, Color primaryColor) {
    return Row(
      children: [
        Icon(
          isGranted ? Icons.check_circle : Icons.cancel,
          color: isGranted ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          permissionName,
          style: TextStyle(
            color: isGranted ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          isGranted ? 'ممنوح' : 'غير ممنوح',
          style: TextStyle(
            color: isGranted ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}