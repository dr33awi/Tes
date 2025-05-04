// lib/screens/prayer_times_screen/prayer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;
import 'package:test_athkar_app/services/prayer_times_service.dart';

class PrayerSettingsScreen extends StatefulWidget {
  const PrayerSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends State<PrayerSettingsScreen> {
  final PrayerTimesService _prayerService = PrayerTimesService();
  
  // قيم الإعدادات
  late String _selectedMethod;
  late String _selectedMadhab;
  late Map<String, int> _adjustments;
  
  // قائمة بأسماء الصلوات لضبط التعديلات
  final List<String> _prayerNames = [
    'الفجر',
    'الشروق',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];
  
  @override
  void initState() {
    super.initState();
    // تحميل الإعدادات الحالية
    _loadCurrentSettings();
  }
  
  void _loadCurrentSettings() {
    final settings = _prayerService.getUserSettings();
    setState(() {
      _selectedMethod = settings['calculationMethod'];
      _selectedMadhab = settings['madhab'];
      _adjustments = Map<String, int>.from(settings['adjustments']);
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
          'إعدادات مواقيت الصلاة',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
                  _buildSectionTitle('طريقة حساب المواقيت'),
                  _buildCalculationMethodSelector(),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('المذهب الفقهي'),
                  _buildMadhabSelector(),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('تعديلات المواقيت (بالدقائق)'),
                  _buildAdjustmentsSection(),
                  const SizedBox(height: 24),
                  
                  // زر حفظ الإعدادات
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ الإعدادات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // زر إعادة الضبط
                  Center(
                    child: TextButton.icon(
                      onPressed: _resetSettings,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة ضبط الإعدادات'),
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimary,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // شرح الإعدادات
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // عنوان قسم
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kPrimary,
        ),
      ),
    );
  }
  
  // اختيار طريقة الحساب
  Widget _buildCalculationMethodSelector() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر طريقة الحساب المناسبة لمنطقتك:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // قائمة بطرق الحساب المتاحة
            ...List.generate(
              _prayerService.getAvailableCalculationMethods().length,
              (index) {
                final method = _prayerService.getAvailableCalculationMethods()[index];
                return RadioListTile<String>(
                  title: Text(method),
                  value: method,
                  groupValue: _selectedMethod,
                  activeColor: kPrimary,
                  dense: true,
                  onChanged: (value) {
                    setState(() {
                      _selectedMethod = value!;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // اختيار المذهب
  Widget _buildMadhabSelector() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر المذهب الفقهي (يؤثر على حساب وقت العصر):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // قائمة بالمذاهب المتاحة
            ...List.generate(
              _prayerService.getAvailableMadhabs().length,
              (index) {
                final madhab = _prayerService.getAvailableMadhabs()[index];
                return RadioListTile<String>(
                  title: Text(madhab == 'Shafi' ? 'الشافعي' : 'الحنفي'),
                  value: madhab,
                  groupValue: _selectedMadhab,
                  activeColor: kPrimary,
                  dense: true,
                  onChanged: (value) {
                    setState(() {
                      _selectedMadhab = value!;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // قسم تعديلات المواقيت
  Widget _buildAdjustmentsSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تعديل المواقيت (+ للتأخير، - للتقديم):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // قائمة بالصلوات للتعديل
            ...List.generate(
              _prayerNames.length,
              (index) {
                final prayerName = _prayerNames[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          prayerName,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Slider(
                          value: (_adjustments[prayerName] ?? 0).toDouble(),
                          min: -15, // تقديم بحد أقصى 15 دقيقة
                          max: 15, // تأخير بحد أقصى 15 دقيقة
                          divisions: 30,
                          activeColor: kPrimary,
                          inactiveColor: kPrimary.withOpacity(0.2),
                          label: '${_adjustments[prayerName] ?? 0} دقيقة',
                          onChanged: (double value) {
                            setState(() {
                              _adjustments[prayerName] = value.round();
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${_adjustments[prayerName] ?? 0} دقيقة',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // زر إعادة ضبط التعديلات
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _adjustments.clear();
                  });
                },
                icon: const Icon(Icons.restore),
                label: const Text('إعادة ضبط التعديلات'),
                style: TextButton.styleFrom(
                  foregroundColor: kPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // بطاقة معلومات
  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary.withOpacity(0.1), kPrimaryLight.withOpacity(0.05)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: kPrimary),
                const SizedBox(width: 8),
                Text(
                  'معلومات إضافية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'طريقة الحساب',
              'اختر طريقة الحساب الأكثر استخداماً في منطقتك. على سبيل المثال، طريقة أم القرى هي الطريقة الرسمية في المملكة العربية السعودية.'
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'المذهب الفقهي',
              'يؤثر اختيار المذهب على وقت صلاة العصر فقط. المذهب الحنفي يبدأ وقت العصر متأخراً قليلاً مقارنة بالمذهب الشافعي.'
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'التعديلات',
              'يمكنك تعديل المواقيت يدوياً لمطابقة المواقيت المحلية في منطقتك. استخدم قيم سالبة للتقديم وقيم موجبة للتأخير.'
            ),
          ],
        ),
      ),
    );
  }
  
  // معلومة واحدة
  Widget _buildInfoItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ],
    );
  }
  
  // حفظ الإعدادات
  void _saveSettings() {
    // تحديث الإعدادات في الخدمة
    _prayerService.updateCalculationMethod(_selectedMethod);
    _prayerService.updateMadhab(_selectedMadhab);
    _prayerService.clearAdjustments();
    
    // إضافة التعديلات
    _adjustments.forEach((prayerName, minutes) {
      if (minutes != 0) {
        _prayerService.setAdjustment(prayerName, minutes);
      }
    });
    
    // حفظ الإعدادات
    _prayerService.saveSettings();
    
    // إظهار رسالة تأكيد
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text('تم حفظ الإعدادات بنجاح'),
          ],
        ),
        backgroundColor: kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
    
    // العودة للشاشة السابقة
    Navigator.pop(context, true); // إرسال قيمة true للإشارة إلى تغيير الإعدادات
  }
  
  // إعادة ضبط الإعدادات
  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة ضبط الإعدادات'),
        content: const Text('هل أنت متأكد من إعادة ضبط جميع إعدادات مواقيت الصلاة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedMethod = 'Umm al-Qura';
                _selectedMadhab = 'Shafi';
                _adjustments.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
            ),
            child: const Text('إعادة الضبط'),
          ),
        ],
      ),
    );
  }
}