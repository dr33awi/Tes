// lib/adhan/screens/prayer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/adhan/services/prayer_times_service.dart';

class PrayerSettingsScreen extends StatefulWidget {
  const PrayerSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends State<PrayerSettingsScreen> {
  final PrayerTimesService _prayerService = PrayerTimesService();
  
  late String _selectedMethod;
  late String _selectedMadhab;
  late Map<String, int> _adjustments;
  bool _isLoading = true;
  bool _hasChanges = false;
  
  // مؤشرات عرض الأقسام المختلفة
  bool _showCalculationMethods = false;
  bool _showMadhabSelection = false;
  bool _showAdjustments = false;
  
  // قائمة أسماء الصلوات للتعديلات
  final List<String> _prayerNames = [
    'الفجر',
    'الشروق',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];
  
  // ألوان الصلوات للمظهر الجمالي
  final Map<String, Color> _prayerColors = {
    'الفجر': const Color(0xFF5B68D9),    // أزرق للفجر
    'الشروق': const Color(0xFFFF9E0D),   // برتقالي للشروق
    'الظهر': const Color(0xFFFFB746),    // أصفر للظهر
    'العصر': const Color(0xFFFF8A65),    // برتقالي للعصر
    'المغرب': const Color(0xFF5C6BC0),   // أزرق غامق للمغرب
    'العشاء': const Color(0xFF1A237E),   // أزرق عميق للعشاء
  };
  
  // أيقونات الصلوات
  final Map<String, IconData> _prayerIcons = {
    'الفجر': Icons.brightness_2,
    'الشروق': Icons.wb_sunny_outlined,
    'الظهر': Icons.wb_sunny,
    'العصر': Icons.wb_twighlight,
    'المغرب': Icons.nights_stay_outlined,
    'العشاء': Icons.nightlight_round,
  };
  
  // ألوان السمة
  late final Color kPrimary;
  late final Color kPrimaryLight;
  late final Color kSurface;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // تهيئة ألوان السمة
    kPrimary = Theme.of(context).primaryColor;
    kPrimaryLight = Theme.of(context).primaryColor.withOpacity(0.7);
    kSurface = Theme.of(context).scaffoldBackgroundColor;
  }
  
  Future<void> _loadCurrentSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final settings = _prayerService.getUserSettings();
      
      setState(() {
        _selectedMethod = settings['calculationMethod'];
        _selectedMadhab = settings['madhab'];
        _adjustments = Map<String, int>.from(settings['adjustments']);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل الإعدادات: $e');
      
      // القيم الافتراضية في حالة حدوث خطأ
      setState(() {
        _selectedMethod = 'Umm al-Qura';
        _selectedMadhab = 'Shafi';
        _adjustments = {};
        _isLoading = false;
      });
      
      _showErrorSnackBar('حدث خطأ أثناء تحميل الإعدادات');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: kSurface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'إعدادات مواقيت الصلاة',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: kPrimary,
            ),
            onPressed: () => _onBackPressed(),
          ),
        ),
        body: _isLoading
          ? Center(child: CircularProgressIndicator(color: kPrimary))
          : Directionality(
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
                        // بطاقة المقدمة
                        _buildIntroCard(),
                        
                        const SizedBox(height: 24),
                        
                        // قسم طريقة الحساب (أزرار قابلة للتوسيع)
                        _buildExpandableSection(
                          title: 'طريقة حساب المواقيت',
                          icon: Icons.calculate_rounded,
                          isExpanded: _showCalculationMethods,
                          onToggle: () {
                            setState(() {
                              _showCalculationMethods = !_showCalculationMethods;
                              if (_showCalculationMethods) {
                                _showMadhabSelection = false;
                                _showAdjustments = false;
                              }
                            });
                          },
                          content: _showCalculationMethods 
                            ? _buildCalculationMethodSelector() 
                            : _buildMethodSummary(),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // قسم المذهب الفقهي (أزرار قابلة للتوسيع)
                        _buildExpandableSection(
                          title: 'المذهب الفقهي',
                          icon: Icons.school_rounded,
                          isExpanded: _showMadhabSelection,
                          onToggle: () {
                            setState(() {
                              _showMadhabSelection = !_showMadhabSelection;
                              if (_showMadhabSelection) {
                                _showCalculationMethods = false;
                                _showAdjustments = false;
                              }
                            });
                          },
                          content: _showMadhabSelection 
                            ? _buildMadhabSelector() 
                            : _buildMadhabSummary(),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // قسم تعديلات المواقيت (أزرار قابلة للتوسيع)
                        _buildExpandableSection(
                          title: 'تعديلات المواقيت (بالدقائق)',
                          icon: Icons.timer_outlined,
                          isExpanded: _showAdjustments,
                          onToggle: () {
                            setState(() {
                              _showAdjustments = !_showAdjustments;
                              if (_showAdjustments) {
                                _showCalculationMethods = false;
                                _showMadhabSelection = false;
                              }
                            });
                          },
                          content: _showAdjustments 
                            ? _buildAdjustmentsSection() 
                            : _buildAdjustmentsSummary(),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // أزرار العمليات
                        _buildActionButtons(),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
  
  // بطاقة المقدمة
  Widget _buildIntroCard() {
    return Card(
      elevation: 8,
      shadowColor: kPrimary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryLight],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: const [0.3, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'إعدادات مواقيت الصلاة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Text(
                'اضغط على العناوين أدناه لفتح خيارات كل قسم، ثم اضغط حفظ الإعدادات عند الانتهاء.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // قسم قابل للتوسيع
  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
  }) {
    return Card(
      elevation: 4,
      shadowColor: kPrimary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // زر العنوان للتوسيع
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: kPrimary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: kPrimary,
                    ),
                  ],
                ),
              ),
            ),
            
            // محتوى القسم
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: content,
            ),
          ],
        ),
      ),
    );
  }
  
  // ملخص طريقة الحساب
  Widget _buildMethodSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: kPrimary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: kPrimary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'الطريقة المحددة: $_selectedMethod',
                style: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ملخص المذهب الفقهي
  Widget _buildMadhabSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: kPrimary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: kPrimary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'المذهب المحدد: ${_selectedMadhab == 'Shafi' ? 'الشافعي' : 'الحنفي'}',
                style: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ملخص التعديلات
  Widget _buildAdjustmentsSummary() {
    int activeAdjustments = _adjustments.values.where((value) => value != 0).length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: kPrimary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              activeAdjustments > 0 ? Icons.tune : Icons.check_circle,
              color: kPrimary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                activeAdjustments > 0 
                    ? 'التعديلات النشطة: $activeAdjustments صلوات'
                    : 'لا توجد تعديلات',
                style: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // طرق الحساب المتاحة
  Widget _buildCalculationMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: const Text(
            'اختر طريقة الحساب المناسبة لمنطقتك:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // قائمة طرق الحساب المتاحة
        ...List.generate(
          _prayerService.getAvailableCalculationMethods().length,
          (index) {
            final method = _prayerService.getAvailableCalculationMethods()[index];
            final bool isSelected = method == _selectedMethod;
            
            return _buildRadioOption(
              title: method,
              value: method,
              groupValue: _selectedMethod,
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value!;
                  _hasChanges = true;
                });
              },
              isSelected: isSelected,
            );
          },
        ),
      ],
    );
  }
  
  // اختيار المذهب الفقهي
  Widget _buildMadhabSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: const Text(
            'اختر المذهب الفقهي (يؤثر على حساب وقت العصر):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // قائمة المذاهب المتاحة
        ...List.generate(
          _prayerService.getAvailableMadhabs().length,
          (index) {
            final madhab = _prayerService.getAvailableMadhabs()[index];
            final bool isSelected = madhab == _selectedMadhab;
            
            return _buildRadioOption(
              title: madhab == 'Shafi' ? 'الشافعي' : 'الحنفي',
              value: madhab,
              groupValue: _selectedMadhab,
              onChanged: (value) {
                setState(() {
                  _selectedMadhab = value!;
                  _hasChanges = true;
                });
              },
              isSelected: isSelected,
            );
          },
        ),
      ],
    );
  }
  
  // خيار الراديو المخصص
  Widget _buildRadioOption({
    required String title, 
    required String value, 
    required String groupValue, 
    required Function(String?) onChanged,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? kPrimary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? kPrimary : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? kPrimary : Colors.black87,
          ),
        ),
        value: value,
        groupValue: groupValue,
        activeColor: kPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onChanged: onChanged,
      ),
    );
  }
  
  // قسم تعديلات المواقيت
  Widget _buildAdjustmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: const Text(
            'تعديل المواقيت (+ للتأخير، - للتقديم):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // قائمة الصلوات للتعديل
        ...List.generate(
          _prayerNames.length,
          (index) {
            final prayerName = _prayerNames[index];
            return _buildPrayerAdjustment(prayerName);
          },
        ),
        
        // زر إعادة ضبط التعديلات
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _adjustments = {};
                _hasChanges = true;
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
    );
  }
  
  // شريط تمرير تعديل الصلاة الفردية
  Widget _buildPrayerAdjustment(String prayerName) {
    final Color prayerColor = _prayerColors[prayerName] ?? kPrimary;
    final IconData prayerIcon = _prayerIcons[prayerName] ?? Icons.access_time;
    final int adjustmentValue = _adjustments[prayerName] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: prayerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: prayerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم الصلاة والقيمة الحالية
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: prayerColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    prayerIcon,
                    size: 18,
                    color: prayerColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                prayerName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: prayerColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: prayerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: prayerColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${adjustmentValue} دقيقة',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: prayerColor,
                  ),
                ),
              ),
            ],
          ),
          
          // شريط التمرير
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: prayerColor,
              inactiveTrackColor: prayerColor.withOpacity(0.2),
              thumbColor: prayerColor,
              overlayColor: prayerColor.withOpacity(0.2),
              valueIndicatorColor: prayerColor,
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            child: Slider(
              value: (_adjustments[prayerName] ?? 0).toDouble(),
              min: -15, // 15 دقيقة كحد أقصى للتقديم
              max: 15, // 15 دقيقة كحد أقصى للتأخير
              divisions: 30,
              label: '${_adjustments[prayerName] ?? 0} دقيقة',
              onChanged: (double value) {
                setState(() {
                  _adjustments[prayerName] = value.round();
                  _hasChanges = true;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // أزرار الإجراءات
  Widget _buildActionButtons() {
    return Row(
      children: [
        // زر الحفظ
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('حفظ الإعدادات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // زر إعادة الضبط
        OutlinedButton.icon(
          onPressed: _resetSettings,
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة ضبط'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimary,
            side: BorderSide(color: kPrimary),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
  
  // التحقق من التغييرات قبل الخروج
  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      return await _showUnsavedChangesDialog() ?? false;
    }
    return true;
  }
  
  void _onBackPressed() {
    if (_hasChanges) {
      _showUnsavedChangesDialog().then((confirmed) {
        if (confirmed ?? false) {
          Navigator.of(context).pop();
        }
      });
    } else {
      Navigator.of(context).pop();
    }
  }
  
  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حفظ التغييرات؟'),
        content: const Text('لديك تغييرات غير محفوظة. هل ترغب في المتابعة بدون حفظ؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
            ),
            child: const Text('متابعة بدون حفظ'),
          ),
        ],
      ),
    );
  }
  
  // عرض رسالة خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  // عرض رسالة نجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  // حفظ الإعدادات
  Future<void> _saveSettings() async {
    try {
      setState(() => _isLoading = true);
      
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
      await _prayerService.saveSettings();
      
      // إعادة حساب مواقيت الصلاة فوراً
      await _prayerService.recalculatePrayerTimes();
      
      setState(() {
        _isLoading = false;
        _hasChanges = false; // إعادة ضبط مؤشر التغييرات
      });
      
      // عرض رسالة تأكيد
      _showSuccessSnackBar('تم حفظ الإعدادات وتحديث مواقيت الصلاة بنجاح');
      
      // العودة إلى الشاشة السابقة
      Navigator.pop(context, true); // إرسال true للإشارة إلى حدوث تغييرات
    } catch (e) {
      debugPrint('خطأ في حفظ الإعدادات: $e');
      
      setState(() => _isLoading = false);
      
      // عرض رسالة خطأ
      _showErrorSnackBar('حدث خطأ أثناء حفظ الإعدادات');
    }
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
                _adjustments = {};
                _hasChanges = true;
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