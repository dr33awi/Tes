// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/services/interfaces/notification_service.dart';
import '../../../core/services/interfaces/battery_service.dart';
import '../../../core/services/interfaces/do_not_disturb_service.dart';
import '../../../core/services/interfaces/permission_service.dart';
import '../../../core/services/permission_manager.dart';
import '../../blocs/prayers/prayer_times_provider.dart';
import '../../blocs/settings/settings_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';

// Define the enums directly in this file to avoid import issues
enum LocalPermissionType {
  notification,
  location,
  batteryOptimization,
  doNotDisturb,
}

enum LocalPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = getIt<NotificationService>();
  final BatteryService _batteryService = getIt<BatteryService>();
  final DoNotDisturbService _doNotDisturbService = getIt<DoNotDisturbService>();
  final PermissionManager _permissionManager = getIt<PermissionManager>();
  
  int _batteryLevel = 100;
  bool _isCharging = false;
  bool _isPowerSaveMode = false;
  bool _isDoNotDisturbEnabled = false;
  
  // نضيف حالة الأذونات مباشرة في الكلاس
  Map<LocalPermissionType, LocalPermissionStatus> _permissions = {
    LocalPermissionType.notification: LocalPermissionStatus.denied,
    LocalPermissionType.location: LocalPermissionStatus.denied,
    LocalPermissionType.batteryOptimization: LocalPermissionStatus.denied,
    LocalPermissionType.doNotDisturb: LocalPermissionStatus.denied,
  };
  bool _loadingPermissions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBatteryInfo();
    _loadDoNotDisturbStatus();
    _updatePermissionsStatus(); // تحميل حالة الأذونات عند البدء
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // تحديث حالة الأذونات
  Future<void> _updatePermissionsStatus() async {
    if (mounted) {
      setState(() {
        _loadingPermissions = true;
      });
    }
    
    try {
      final permissionsStatus = await _permissionManager.checkPermissions();
      
      final updatedPermissions = <LocalPermissionType, LocalPermissionStatus>{
        LocalPermissionType.notification: _convertToLocalStatus(
          permissionsStatus[AppPermissionType.notification] ?? AppPermissionStatus.denied
        ),
        LocalPermissionType.location: _convertToLocalStatus(
          permissionsStatus[AppPermissionType.location] ?? AppPermissionStatus.denied
        ),
        LocalPermissionType.batteryOptimization: _convertToLocalStatus(
          permissionsStatus[AppPermissionType.batteryOptimization] ?? AppPermissionStatus.denied
        ),
        LocalPermissionType.doNotDisturb: _convertToLocalStatus(
          permissionsStatus[AppPermissionType.doNotDisturb] ?? AppPermissionStatus.denied
        ),
      };
      
      if (mounted) {
        setState(() {
          _permissions = updatedPermissions;
          _loadingPermissions = false;
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحديث حالة الأذونات: $e');
      if (mounted) {
        setState(() {
          _loadingPermissions = false;
        });
      }
    }
  }
  
  // تحويل حالة الإذن من نوع التطبيق إلى النوع المحلي
  LocalPermissionStatus _convertToLocalStatus(AppPermissionStatus status) {
    switch (status) {
      case AppPermissionStatus.granted:
        return LocalPermissionStatus.granted;
      case AppPermissionStatus.permanentlyDenied:
        return LocalPermissionStatus.permanentlyDenied;
      case AppPermissionStatus.restricted:
        return LocalPermissionStatus.restricted;
      case AppPermissionStatus.limited:
        return LocalPermissionStatus.limited;
      default:
        return LocalPermissionStatus.denied;
    }
  }
  
  Future<void> _loadBatteryInfo() async {
    final batteryLevel = await _batteryService.getBatteryLevel();
    final isCharging = await _batteryService.isCharging();
    final isPowerSaveMode = await _batteryService.isPowerSaveMode();
    
    if (mounted) {
      setState(() {
        _batteryLevel = batteryLevel;
        _isCharging = isCharging;
        _isPowerSaveMode = isPowerSaveMode;
      });
    }
    
    // الاستماع لتغييرات البطارية
    _batteryService.getBatteryStateStream().listen((state) {
      if (mounted) {
        setState(() {
          _batteryLevel = state.level;
          _isCharging = state.isCharging;
          _isPowerSaveMode = state.isPowerSaveMode;
        });
      }
    });
  }
  
  Future<void> _loadDoNotDisturbStatus() async {
    final isDndEnabled = await _doNotDisturbService.isDoNotDisturbEnabled();
    
    if (mounted) {
      setState(() {
        _isDoNotDisturbEnabled = isDndEnabled;
      });
    }
    
    // تسجيل مراقب لتغييرات وضع عدم الإزعاج
    await _doNotDisturbService.registerDoNotDisturbListener((enabled) {
      if (mounted) {
        setState(() {
          _isDoNotDisturbEnabled = enabled;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'عام', icon: Icon(Icons.settings)),
            Tab(text: 'الإشعارات', icon: Icon(Icons.notifications)),
            Tab(text: 'مواقيت الصلاة', icon: Icon(Icons.access_time)),
            Tab(text: 'الأذونات', icon: Icon(Icons.security)),
          ],
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: LoadingWidget());
          }
          
          if (provider.settings == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('حدث خطأ في تحميل الإعدادات'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadSettings(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildGeneralSettingsTab(provider),
              _buildNotificationSettingsTab(provider),
              _buildPrayerSettingsTab(provider),
              _buildPermissionsTab(),
            ],
          );
        },
      ),
    );
  }
  
  // علامة تبويب الإعدادات العامة
  Widget _buildGeneralSettingsTab(SettingsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'إعدادات التطبيق'),
          _buildThemeSettings(provider),
          _buildLanguageSettings(provider),
          
          const SizedBox(height: 16),
          
          // معلومات حول النظام
          _buildSystemInfoCard(),
        ],
      ),
    );
  }
  
  // علامة تبويب إعدادات الإشعارات
  Widget _buildNotificationSettingsTab(SettingsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'إعدادات الإشعارات'),
          _buildBasicNotificationSettings(provider),
          
          const SizedBox(height: 16),
          
          _buildSectionTitle(context, 'إعدادات البطارية وعدم الإزعاج'),
          _buildBatteryAndDndSettingsCard(provider),
        ],
      ),
    );
  }
  
  // علامة تبويب إعدادات مواقيت الصلاة
  Widget _buildPrayerSettingsTab(SettingsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'إعدادات مواقيت الصلاة'),
          _buildPrayerSettings(provider),
        ],
      ),
    );
  }
  
  // علامة تبويب الأذونات الجديدة
  Widget _buildPermissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'إدارة الأذونات'),
          _buildPermissionSettingsCard(),
          
          const SizedBox(height: 16),
          
          // شرح عن أهمية الأذونات
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أهمية الأذونات',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  const Text(
                    'يحتاج التطبيق إلى عدة أذونات لتقديم أفضل تجربة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• إذن الإشعارات: للتذكير بمواقيت الصلاة والأذكار في الأوقات المحددة',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• إذن الموقع: لتحديد اتجاه القبلة بدقة وضبط مواقيت الصلاة حسب موقعك',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• إذن عدم الإزعاج: للسماح بظهور إشعارات الصلاة حتى في وضع عدم الإزعاج',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• استثناء البطارية: للسماح بعمل الإشعارات بشكل موثوق حتى مع تفعيل وضع توفير الطاقة',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
  
  Widget _buildThemeSettings(SettingsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SwitchListTile(
          title: const Text('الوضع الداكن'),
          subtitle: const Text('تفعيل المظهر الداكن للتطبيق'),
          value: provider.settings!.enableDarkMode,
          secondary: Icon(
            provider.settings!.enableDarkMode 
                ? Icons.dark_mode 
                : Icons.light_mode,
            color: Theme.of(context).primaryColor,
          ),
          onChanged: (value) {
            provider.updateSetting(key: 'enableDarkMode', value: value);
          },
        ),
      ),
    );
  }
  
  Widget _buildLanguageSettings(SettingsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: const Text('لغة التطبيق'),
          subtitle: Text(
            provider.settings!.language == 'ar' ? 'العربية' : 'الإنجليزية'
          ),
          leading: const Icon(Icons.language),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            _showLanguageDialog(provider);
          },
        ),
      ),
    );
  }
  
  Widget _buildSystemInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات النظام',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildSystemInfoRow(
              'البطارية',
              '$_batteryLevel% ${_isCharging ? "(قيد الشحن)" : ""}',
              icon: _getBatteryIcon(),
            ),
            _buildSystemInfoRow(
              'وضع توفير الطاقة',
              _isPowerSaveMode ? 'مفعل' : 'معطل',
              icon: Icons.battery_saver,
            ),
            _buildSystemInfoRow(
              'وضع عدم الإزعاج',
              _isDoNotDisturbEnabled ? 'مفعل' : 'معطل',
              icon: Icons.do_not_disturb_on,
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getBatteryIcon() {
    if (_isCharging) {
      return Icons.battery_charging_full;
    }
    
    if (_batteryLevel >= 90) {
      return Icons.battery_full;
    } else if (_batteryLevel >= 60) {
      return Icons.battery_6_bar;
    } else if (_batteryLevel >= 30) {
      return Icons.battery_3_bar;
    } else {
      return Icons.battery_alert;
    }
  }
  
  Widget _buildSystemInfoRow(String title, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
  
  Widget _buildBasicNotificationSettings(SettingsProvider provider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('إشعارات التطبيق'),
            subtitle: const Text('تفعيل أو تعطيل جميع الإشعارات'),
            value: provider.settings!.enableNotifications,
            secondary: Icon(
              Icons.notifications,
              color: Theme.of(context).primaryColor,
            ),
            onChanged: (value) async {
              if (value) {
                // طلب إذن الإشعارات
                final hasPermission = await _permissionManager.requestEssentialPermissions(context);
                if (hasPermission[AppPermissionType.notification] ?? false) {
                  provider.updateSetting(key: 'enableNotifications', value: value);
                  // تحديث حالة الأذونات
                  _updatePermissionsStatus();
                } else {
                  // إظهار رسالة تنبيه بأنه لا يمكن تفعيل الإشعارات
                  if (mounted) {
                    _showPermissionDeniedDialog();
                  }
                }
              } else {
                provider.updateSetting(key: 'enableNotifications', value: value);
              }
            },
          ),
          if (provider.settings!.enableNotifications) ...[
            const Divider(),
            SwitchListTile(
              title: const Text('إشعارات الأذكار'),
              subtitle: const Text('تلقي إشعارات لأذكار الصباح والمساء'),
              value: provider.settings!.enableAthkarNotifications,
              secondary: const Icon(Icons.auto_awesome),
              onChanged: provider.settings!.enableNotifications
                  ? (value) {
                      provider.updateSetting(
                        key: 'enableAthkarNotifications', 
                        value: value,
                      );
                    }
                  : null,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('إشعارات مواقيت الصلاة'),
              subtitle: const Text('تلقي إشعارات بأوقات الصلوات'),
              value: provider.settings!.enablePrayerTimesNotifications,
              secondary: const Icon(Icons.access_time),
              onChanged: provider.settings!.enableNotifications
                  ? (value) {
                      provider.updateSetting(
                        key: 'enablePrayerTimesNotifications', 
                        value: value,
                      );
                    }
                  : null,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildBatteryAndDndSettingsCard(SettingsProvider provider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('احترام تحسينات البطارية'),
            subtitle: const Text('لا يتم إرسال الإشعارات عندما تكون البطارية منخفضة ووضع توفير الطاقة مفعل'),
            value: provider.settings!.respectBatteryOptimizations,
            secondary: const Icon(Icons.battery_saver),
            onChanged: (value) {
              provider.updateSetting(key: 'respectBatteryOptimizations', value: value);
              _notificationService.setRespectBatteryOptimizations(value);
            },
          ),
          
          if (provider.settings!.respectBatteryOptimizations) ...[
            ListTile(
              title: const Text('حد البطارية المنخفضة'),
              subtitle: Text('${provider.settings!.lowBatteryThreshold}%'),
              leading: const Icon(Icons.battery_alert),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () {
                _showLowBatteryThresholdDialog(provider);
              },
            ),
          ],
          
          const Divider(),
          
          SwitchListTile(
            title: const Text('احترام وضع عدم الإزعاج'),
            subtitle: const Text('لا يتم إرسال الإشعارات عندما يكون وضع عدم الإزعاج مفعلاً'),
            value: provider.settings!.respectDoNotDisturb,
            secondary: const Icon(Icons.do_not_disturb_on),
            onChanged: (value) {
              provider.updateSetting(key: 'respectDoNotDisturb', value: value);
              _notificationService.setRespectDoNotDisturb(value);
            },
          ),
          
          const Divider(),
          
          SwitchListTile(
            title: const Text('أولوية عالية لإشعارات الصلاة'),
            subtitle: const Text('تظهر إشعارات الصلاة حتى في وضع عدم الإزعاج'),
            value: provider.settings!.enableHighPriorityForPrayers,
            secondary: const Icon(Icons.priority_high),
            onChanged: (value) {
              provider.updateSetting(key: 'enableHighPriorityForPrayers', value: value);
            },
          ),
          
          const Divider(),
          
          SwitchListTile(
            title: const Text('الوضع الصامت'),
            subtitle: const Text('لا يصدر التطبيق أي صوت للإشعارات'),
            value: provider.settings!.enableSilentMode,
            secondary: const Icon(Icons.volume_off),
            onChanged: (value) {
              provider.updateSetting(key: 'enableSilentMode', value: value);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrayerSettings(SettingsProvider provider) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('طريقة حساب مواقيت الصلاة'),
            subtitle: Text(_getCalculationMethodName(provider.settings!.calculationMethod)),
            leading: const Icon(Icons.calculate),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showCalculationMethodDialog(provider);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('طريقة حساب العصر'),
            subtitle: Text(
              provider.settings!.asrMethod == 0 
                  ? 'مذهب الشافعي (المعيار)' 
                  : 'مذهب الحنفي',
            ),
            leading: const Icon(Icons.sunny),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showAsrMethodDialog(provider);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('إعادة تحميل مواقيت الصلاة'),
            subtitle: const Text('تحديث مواقيت الصلاة حسب الإعدادات الحالية'),
            leading: const Icon(Icons.refresh),
            onTap: () {
              final prayerProvider = Provider.of<PrayerTimesProvider>(
                context, 
                listen: false,
              );
              
              if (prayerProvider.hasLocation) {
                prayerProvider.refreshData(provider.settings!);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث مواقيت الصلاة'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى تحديد الموقع أولًا'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // بناء قسم الأذونات المحسن باستخدام البيانات المخزنة مسبقًا
  Widget _buildPermissionSettingsCard() {
    if (_loadingPermissions) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حالة الأذونات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            
            _buildPermissionItem(
              context,
              title: 'إشعارات',
              type: LocalPermissionType.notification,
              status: _permissions[LocalPermissionType.notification]!,
              icon: Icons.notifications,
              onTap: () async {
                await _requestSpecificPermission(LocalPermissionType.notification);
              },
            ),
            
            _buildPermissionItem(
              context,
              title: 'الموقع',
              type: LocalPermissionType.location,
              status: _permissions[LocalPermissionType.location]!,
              icon: Icons.location_on,
              onTap: () async {
                await _requestSpecificPermission(LocalPermissionType.location);
              },
            ),
            
            _buildPermissionItem(
              context,
              title: 'استثناء البطارية',
              type: LocalPermissionType.batteryOptimization,
              status: _permissions[LocalPermissionType.batteryOptimization]!,
              icon: Icons.battery_charging_full,
              onTap: () async {
                await _requestSpecificPermission(LocalPermissionType.batteryOptimization);
              },
            ),
            
            _buildPermissionItem(
              context,
              title: 'وضع عدم الإزعاج',
              type: LocalPermissionType.doNotDisturb,
              status: _permissions[LocalPermissionType.doNotDisturb]!,
              icon: Icons.do_not_disturb_on,
              onTap: () async {
                await _requestSpecificPermission(LocalPermissionType.doNotDisturb);
              },
            ),
            
            const SizedBox(height: 16),
            
            // زر لإعادة تعيين جميع الأذونات
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  // طلب جميع الأذونات
                  await _permissionManager.requestEssentialPermissions(context);
                  await _permissionManager.requestOptionalPermissions(context);
                  // تحديث حالة الأذونات
                  await _updatePermissionsStatus();
                },
                icon: const Icon(Icons.security),
                label: const Text('تحديث جميع الأذونات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // طريقة محسنة لطلب الأذونات بشكل أفضل
  Future<void> _requestSpecificPermission(LocalPermissionType permissionType) async {
    switch (permissionType) {
      case LocalPermissionType.notification:
        await _permissionManager.requestEssentialPermissions(context);
        break;
      case LocalPermissionType.location:
        await _permissionManager.requestLocationPermission(context);
        break;
      case LocalPermissionType.batteryOptimization:
        // طلب إذن البطارية بطريقة خاصة مع عرض رسالة توضيحية
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('استثناء تحسين البطارية'),
            content: const Text(
              'يحتاج التطبيق إلى إذن استثناء البطارية لتشغيل الإشعارات بشكل موثوق حتى عند تفعيل وضع توفير الطاقة. سيتم فتح إعدادات البطارية لتفعيل هذا الاستثناء.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('متابعة'),
              ),
            ],
          ),
        ) ?? false;
        
        if (result) {
          // طلب إذن البطارية واستخدام طريقة محسنة للتحقق
          await _permissionManager.openPermissionSettings(AppPermissionType.batteryOptimization);
          
          // انتظار قليلاً ثم إعادة التحقق من الحالة
          await Future.delayed(const Duration(seconds: 2));
        }
        break;
      case LocalPermissionType.doNotDisturb:
        // تحسين: عرض رسالة توضيحية قبل فتح الإعدادات
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('وضع عدم الإزعاج'),
            content: const Text(
              'يحتاج التطبيق إلى إذن لإظهار إشعارات الصلاة والأذكار حتى عندما يكون وضع عدم الإزعاج مفعّلاً. سيتم فتح إعدادات وضع عدم الإزعاج لتفعيل هذا الاستثناء.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('متابعة'),
              ),
            ],
          ),
        ) ?? false;
        
        if (result) {
          try {
            // استخدام الطريقة openDoNotDisturbSettings بدلاً من openDoNotDisturbSettings
            await _doNotDisturbService.openDoNotDisturbSettings();
            
            // عرض تعليمات إضافية للمستخدم بعد فتح الإعدادات
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ابحث عن "التطبيقات المستثناة" أو "الاستثناءات" وأضف تطبيق الأذكار إلى القائمة'),
                  duration: Duration(seconds: 5),
                ),
              );
            }
          } catch (e) {
            debugPrint('خطأ في فتح إعدادات وضع عدم الإزعاج: $e');
            // فتح إعدادات الإشعارات العامة كخطة بديلة
            await _permissionManager.openAppSettings(AppSettingsType.notification);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('انتقل إلى إعدادات الإشعارات > وضع عدم الإزعاج > الاستثناءات > التطبيقات، وأضف تطبيق الأذكار'),
                  duration: Duration(seconds: 7),
                ),
              );
            }
          }
          
          // انتظار قليلاً ثم إعادة التحقق من الحالة
          await Future.delayed(const Duration(seconds: 2));
        }
        break;
    }
    
    // تحديث حالة الأذونات بعد الطلب
    await _updatePermissionsStatus();
  }

  Widget _buildPermissionItem(
    BuildContext context, {
    required String title,
    required LocalPermissionType type,
    required LocalPermissionStatus status,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    // تحديد اللون والحالة حسب حالة الإذن
    Color statusColor;
    String statusText;
    
    switch (status) {
      case LocalPermissionStatus.granted:
        statusColor = Colors.green;
        statusText = 'ممنوح';
        break;
      case LocalPermissionStatus.denied:
        statusColor = Colors.orange;
        statusText = 'مرفوض';
        break;
      case LocalPermissionStatus.permanentlyDenied:
        statusColor = Colors.red;
        statusText = 'مرفوض دائمًا';
        break;
      case LocalPermissionStatus.restricted:
        statusColor = Colors.red;
        statusText = 'مقيد';
        break;
      case LocalPermissionStatus.limited:
        statusColor = Colors.orange;
        statusText = 'محدود';
        break;
    }
    
    return ListTile(
      leading: Icon(icon, color: statusColor),
      title: Text(title),
      subtitle: Text(statusText),
      trailing: TextButton(
        onPressed: onTap,
        child: const Text('تعديل'),
      ),
    );
  }
  
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تنبيه'),
        content: const Text(
          'تم رفض إذن الإشعارات. يرجى السماح بإذن الإشعارات من إعدادات الجهاز لتلقي إشعارات التطبيق.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Open notification settings
              _doNotDisturbService.openDoNotDisturbSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
  
  void _showLanguageDialog(SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'ar',
              groupValue: provider.settings!.language,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  provider.updateSetting(key: 'language', value: value);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('الإنجليزية'),
              value: 'en',
              groupValue: provider.settings!.language,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  provider.updateSetting(key: 'language', value: value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
  
  void _showLowBatteryThresholdDialog(SettingsProvider provider) {
    int tempThreshold = provider.settings!.lowBatteryThreshold;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحديد حد البطارية المنخفضة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('لن يتم إرسال الإشعارات عندما تكون نسبة البطارية أقل من هذا الحد ووضع توفير الطاقة مفعل'),
            const SizedBox(height: 16),
            Slider(
              value: tempThreshold.toDouble(),
              min: 5,
              max: 30,
              divisions: 5,
              label: '$tempThreshold%',
              onChanged: (value) {
                setState(() {
                  tempThreshold = value.round();
                });
              },
            ),
            Text(
              '$tempThreshold%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.updateSetting(key: 'lowBatteryThreshold', value: tempThreshold);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
  
  void _showCalculationMethodDialog(SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طريقة حساب مواقيت الصلاة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(11, (index) {
              return RadioListTile<int>(
                title: Text(_getCalculationMethodName(index)),
                value: index,
                groupValue: provider.settings!.calculationMethod,
                onChanged: (value) {
                  Navigator.pop(context);
                  if (value != null) {
                    provider.updateSetting(key: 'calculationMethod', value: value);
                  }
                },
              );
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
  
  void _showAsrMethodDialog(SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طريقة حساب العصر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('مذهب الشافعي (المعيار)'),
              subtitle: const Text('ظل الشيء مثله'),
              value: 0,
              groupValue: provider.settings!.asrMethod,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  provider.updateSetting(key: 'asrMethod', value: value);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('مذهب الحنفي'),
              subtitle: const Text('ظل الشيء مثليه'),
              value: 1,
              groupValue: provider.settings!.asrMethod,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  provider.updateSetting(key: 'asrMethod', value: value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
  
  String _getCalculationMethodName(int methodIndex) {
    switch (methodIndex) {
      case 0:
        return 'طريقة كراتشي';
      case 1:
        return 'طريقة أمريكا الشمالية';
      case 2:
        return 'رابطة العالم الإسلامي';
      case 3:
        return 'الطريقة المصرية';
      case 4:
        return 'طريقة أم القرى (مكة المكرمة)';
      case 5:
        return 'طريقة دبي';
      case 6:
        return 'طريقة قطر';
      case 7:
        return 'طريقة الكويت';
      case 8:
        return 'طريقة سنغافورة';
      case 9:
        return 'طريقة تركيا';
      case 10:
        return 'طريقة طهران';
      default:
        return 'طريقة أم القرى (افتراضي)';
    }
  }
}