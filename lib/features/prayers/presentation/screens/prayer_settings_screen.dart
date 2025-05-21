// lib/features/prayers/presentation/screens/prayer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/interfaces/prayer_times_service.dart';
import '../../../settings/domain/entities/settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/prayer_times_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/custom_app_bar.dart';

class PrayerSettingsScreen extends StatefulWidget {
  const PrayerSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends State<PrayerSettingsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  
  // طرق حساب مواقيت الصلاة
  final List<Map<String, dynamic>> _calculationMethods = [
    {
      'id': 0,
      'name': 'جامعة العلوم الإسلامية - كراتشي',
      'description': 'طريقة حساب مستخدمة في باكستان وأجزاء من آسيا',
      'icon': Icons.calculate_outlined,
    },
    {
      'id': 1,
      'name': 'جمعية أمريكا الشمالية الإسلامية (ISNA)',
      'description': 'طريقة حساب مستخدمة في أمريكا الشمالية',
      'icon': Icons.language,
    },
    {
      'id': 2,
      'name': 'رابطة العالم الإسلامي',
      'description': 'استخدام عالمي، المعيار الأكثر اعتمادًا',
      'icon': Icons.public,
    },
    {
      'id': 3,
      'name': 'الهيئة المصرية العامة للمساحة',
      'description': 'طريقة حساب مستخدمة في مصر',
      'icon': Icons.calculate,
    },
    {
      'id': 4,
      'name': 'أم القرى - مكة المكرمة',
      'description': 'المملكة العربية السعودية',
      'icon': Icons.mosque,
    },
    {
      'id': 5,
      'name': 'هيئة الشؤون الإسلامية - دبي',
      'description': 'الإمارات العربية المتحدة',
      'icon': Icons.location_city,
    },
    {
      'id': 6,
      'name': 'قطر',
      'description': 'التقويم القطري',
      'icon': Icons.calendar_today,
    },
    {
      'id': 7,
      'name': 'الكويت',
      'description': 'الهيئة العامة للأوقاف - الكويت',
      'icon': Icons.home_work,
    },
    {
      'id': 8,
      'name': 'سنغافورة',
      'description': 'المجلس الديني الإسلامي بسنغافورة',
      'icon': Icons.location_on,
    },
    {
      'id': 9,
      'name': 'تركيا',
      'description': 'رئاسة الشؤون الدينية التركية',
      'icon': Icons.account_balance,
    },
    {
      'id': 10,
      'name': 'طهران',
      'description': 'معهد الفيزياء الفلكية - جامعة طهران',
      'icon': Icons.school,
    },
  ];
  
  // طرق حساب وقت العصر
  final List<Map<String, dynamic>> _asrMethods = [
    {
      'id': 0,
      'name': 'المذهب الشافعي (الجمهور)',
      'description': 'عندما يكون ظل أي شيء مثل طوله',
      'icon': Icons.looks_one_outlined,
    },
    {
      'id': 1,
      'name': 'المذهب الحنفي',
      'description': 'عندما يكون ظل أي شيء مثل ضعف طوله',
      'icon': Icons.looks_two_outlined,
    },
  ];
  
  // الإعدادات المختارة حاليًا
  int _selectedCalculationMethod = 2; // رابطة العالم الإسلامي كافتراضي
  int _selectedAsrMethod = 0; // المذهب الشافعي كافتراضي
  bool _adjustForDst = true; // تعديل للتوقيت الصيفي
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // تحميل الإعدادات الحالية
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _selectedCalculationMethod = prefs.getInt('calculationMethod') ?? 2;
        _selectedAsrMethod = prefs.getInt('asrMethod') ?? 0;
        _adjustForDst = prefs.getBool('adjustForDst') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 10),
              Text('حدث خطأ: ${e.toString()}'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // حفظ الإعدادات
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final prayerProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
      
      // حفظ الإعدادات في SharedPreferences
      await prefs.setInt('calculationMethod', _selectedCalculationMethod);
      await prefs.setInt('asrMethod', _selectedAsrMethod);
      await prefs.setBool('adjustForDst', _adjustForDst);
      
      // إعادة تحميل مواقيت الصلاة - Erstellen einer minimalen Settings-Instanz
      final updatedSettings = Settings(
        calculationMethod: _selectedCalculationMethod,
        asrMethod: _selectedAsrMethod,
      );
      
      // Einfach die aktuellen Einstellungen verwenden
      if (prayerProvider.hasLocation) {
        await prayerProvider.refreshData(updatedSettings);
      }
      
      // تأثير اهتزاز خفيف
      HapticFeedback.mediumImpact();
      
      // رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('تم حفظ الإعدادات بنجاح'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // العودة إلى الصفحة السابقة
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 10),
              Text('حدث خطأ: ${e.toString()}'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // استعادة الإعدادات الافتراضية
  Future<void> _resetToDefaults() async {
    // تأكيد العملية
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('استعادة الافتراضي'),
          ],
        ),
        content: const Text('هل أنت متأكد من استعادة الإعدادات الافتراضية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('نعم', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _selectedCalculationMethod = 2; // رابطة العالم الإسلامي
      _selectedAsrMethod = 0; // المذهب الشافعي
      _adjustForDst = true;
    });
    
    // تأثير اهتزاز خفيف
    HapticFeedback.mediumImpact();
    
    // رسالة نجاح
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.settings_backup_restore, color: Colors.white),
            SizedBox(width: 10),
            Text('تم استعادة الإعدادات الافتراضية'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'إعدادات المواقيت',
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : _buildSettingsContent(),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }
  
  // عرض مؤشر التحميل
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingWidget(),
          SizedBox(height: 20),
          Text(
            'جاري تحميل الإعدادات...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // محتوى الإعدادات
  Widget _buildSettingsContent() {
    return AnimationLimiter(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              // وصف الإعدادات
              _buildIntroCard(),
              const SizedBox(height: 16),
              
              // طريقة حساب المواقيت
              _buildSectionTitle('طريقة حساب المواقيت'),
              const SizedBox(height: 12),
              _buildCalculationMethodSelection(),
              const SizedBox(height: 24),
              
              // طريقة حساب وقت العصر
              _buildSectionTitle('طريقة حساب وقت العصر'),
              const SizedBox(height: 12),
              _buildAsrMethodSelection(),
              const SizedBox(height: 24),
              
              // إعدادات أخرى
              _buildSectionTitle('إعدادات أخرى'),
              const SizedBox(height: 12),
              _buildOtherSettings(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // بطاقة المقدمة
  Widget _buildIntroCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'إعدادات حساب مواقيت الصلاة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'يمكنك تخصيص طريقة حساب مواقيت الصلاة حسب موقعك الجغرافي أو المذهب الفقهي الذي تتبعه. قم باختيار الطريقة المناسبة لضمان دقة المواقيت.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // عنوان القسم
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // اختيار طريقة حساب المواقيت
  Widget _buildCalculationMethodSelection() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _calculationMethods.length,
      itemBuilder: (context, index) {
        final method = _calculationMethods[index];
        final isSelected = _selectedCalculationMethod == method['id'];
        
        return Card(
          elevation: isSelected ? 3 : 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedCalculationMethod = method['id'];
              });
              // تأثير اهتزاز خفيف
              HapticFeedback.selectionClick();
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      method['icon'] as IconData,
                      color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method['name'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method['description'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // اختيار طريقة حساب وقت العصر
  Widget _buildAsrMethodSelection() {
    return Row(
      children: _asrMethods.map((method) {
        final isSelected = _selectedAsrMethod == method['id'];
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: method['id'] == 0 ? 8 : 0,
              left: method['id'] == 1 ? 8 : 0,
            ),
            child: Card(
              elevation: isSelected ? 3 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedAsrMethod = method['id'];
                  });
                  // تأثير اهتزاز خفيف
                  HapticFeedback.selectionClick();
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).primaryColor 
                              : Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          method['icon'] as IconData,
                          color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        method['name'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        method['description'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 12),
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // إعدادات أخرى
  Widget _buildOtherSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SwitchListTile(
          title: const Text(
            'تعديل للتوقيت الصيفي',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'ضبط مواقيت الصلاة تلقائيًا وفقًا للتوقيت الصيفي',
            style: TextStyle(
              fontSize: 14,
            ),
          ),
          value: _adjustForDst,
          onChanged: (value) {
            setState(() {
              _adjustForDst = value;
            });
            HapticFeedback.selectionClick();
          },
          activeColor: Theme.of(context).primaryColor,
          secondary: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wb_sunny_outlined,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  // أزرار أسفل الشاشة
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _resetToDefaults,
              icon: const Icon(Icons.restore),
              label: const Text('استعادة الافتراضي'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('حفظ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}