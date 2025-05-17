// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/interfaces/notification_service.dart';
import '../../blocs/prayers/prayer_times_provider.dart';
import '../../blocs/settings/settings_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService? _notificationService = null; // في التطبيق الحقيقي يجب استخدام getIt

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'الإعدادات'),
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
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'إعدادات التطبيق'),
                _buildThemeSettings(context, provider),
                _buildLanguageSettings(context, provider),
                
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'إعدادات الإشعارات'),
                _buildNotificationSettings(context, provider),
                
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'إعدادات مواقيت الصلاة'),
                _buildPrayerSettings(context, provider),
              ],
            ),
          );
        },
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
  
  Widget _buildThemeSettings(BuildContext context, SettingsProvider provider) {
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
  
  Widget _buildLanguageSettings(BuildContext context, SettingsProvider provider) {
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
            _showLanguageDialog(context, provider);
          },
        ),
      ),
    );
  }
  
  Widget _buildNotificationSettings(BuildContext context, SettingsProvider provider) {
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
                final hasPermission = await _requestNotificationPermission();
                if (hasPermission) {
                  provider.updateSetting(key: 'enableNotifications', value: value);
                } else {
                  // إظهار رسالة تنبيه بأنه لا يمكن تفعيل الإشعارات
                  if (mounted) {
                    _showPermissionDeniedDialog(context);
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
  
  Widget _buildPrayerSettings(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('طريقة حساب مواقيت الصلاة'),
            subtitle: Text(_getCalculationMethodName(provider.settings!.calculationMethod)),
            leading: const Icon(Icons.calculate),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showCalculationMethodDialog(context, provider);
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
              _showAsrMethodDialog(context, provider);
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
  
  Future<bool> _requestNotificationPermission() async {
    // في التطبيق الحقيقي، استخدم خدمة الإشعارات لطلب الإذن
    if (_notificationService != null) {
      return await _notificationService!.requestPermissions();
    }
    
    // للتجربة، نعتبر أن الإذن تم الحصول عليه
    return true;
  }
  
  void _showPermissionDeniedDialog(BuildContext context) {
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
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }
  
  void _showLanguageDialog(BuildContext context, SettingsProvider provider) {
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
  
  void _showCalculationMethodDialog(BuildContext context, SettingsProvider provider) {
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
  
  void _showAsrMethodDialog(BuildContext context, SettingsProvider provider) {
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