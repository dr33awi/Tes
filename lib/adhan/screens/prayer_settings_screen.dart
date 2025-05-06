// lib/adhan/screens/prayer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/adhan/services/prayer_times_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;

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
    'الفجر': const Color(0xFF5C6BC0),      // أزرق للفجر
    'الشروق': const Color(0xFFFFB74D),     // برتقالي للشروق
    'الظهر': const Color(0xFFFFA000),      // أصفر للظهر
    'العصر': const Color(0xFF66BB6A),      // أخضر للعصر
    'المغرب': const Color(0xFF7B1FA2),     // أرجواني للمغرب
    'العشاء': const Color(0xFF3949AB),     // أزرق عميق للعشاء
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
  
  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
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
            onPressed: () => _onBackPressed(),
          ),
        ),
        body: _isLoading
          ? _buildLoader()
          : Directionality(
              textDirection: TextDirection.rtl,
              child: AnimationLimiter(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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

  // مؤشر التحميل المحسن
  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: kPrimary,
            size: 50,
          ),
          const SizedBox(height: 20),
          Text(
            'جاري تحميل إعدادات مواقيت الصلاة...',
            style: TextStyle(
              fontSize: 18,
              color: kPrimary,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
  
  // بطاقة المقدمة - تحسين التصميم
  Widget _buildIntroCard() {
    return Card(
      elevation: 8,
      shadowColor: kPrimary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryLight],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: const [0.3, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // أيقونة الخلفية
            Positioned(
              bottom: -30,
              right: -30,
              child: Icon(
                Icons.settings,
                size: 140,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // قسم قابل للتوسيع - تحسين التصميم
  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
  }) {
    return Card(
      elevation: isExpanded ? 6 : 4,
      shadowColor: kPrimary.withOpacity(isExpanded ? 0.3 : 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isExpanded 
            ? BorderSide(color: kPrimary.withOpacity(0.3), width: 1.5)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // زر العنوان للتوسيع
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isExpanded
                    ? LinearGradient(
                        colors: [kPrimary.withOpacity(0.2), kPrimary.withOpacity(0.05)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      )
                    : null,
                color: isExpanded ? null : Colors.transparent,
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topRight: Radius.circular(16),
                        topLeft: Radius.circular(16),
                      )
                    : BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: kPrimary,
                      size: 20,
                    ),
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
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isExpanded ? kPrimary.withOpacity(0.1) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: kPrimary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // محتوى القسم
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
  
  // ملخص طريقة الحساب
  Widget _buildMethodSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: kPrimary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'الطريقة المحددة: $_selectedMethod',
                style: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: kPrimary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'المذهب المحدد: ${_selectedMadhab == 'Shafi' ? 'الشافعي' : 'الحنفي'}',
                style: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                activeAdjustments > 0 ? Icons.tune : Icons.check_circle,
                color: kPrimary,
                size: 16,
              ),
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
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // طرق الحساب المتاحة - تحسين التصميم
  Widget _buildCalculationMethodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary.withOpacity(0.2), kPrimary.withOpacity(0.1)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: kPrimary,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'اختر طريقة الحساب المناسبة لمنطقتك:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // قائمة طرق الحساب المتاحة
          AnimationLimiter(
            child: Column(
              children: List.generate(
                _prayerService.getAvailableCalculationMethods().length,
                (index) {
                  final method = _prayerService.getAvailableCalculationMethods()[index];
                  final bool isSelected = method == _selectedMethod;
                  
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 300),
                    child: SlideAnimation(
                      verticalOffset: 20.0,
                      child: FadeInAnimation(
                        child: _buildRadioOption(
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
                          index: index,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // اختيار المذهب الفقهي
  Widget _buildMadhabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary.withOpacity(0.2), kPrimary.withOpacity(0.1)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: kPrimary,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'اختر المذهب الفقهي (يؤثر على حساب وقت العصر):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // قائمة المذاهب المتاحة
          AnimationLimiter(
            child: Column(
              children: List.generate(
                _prayerService.getAvailableMadhabs().length,
                (index) {
                  final madhab = _prayerService.getAvailableMadhabs()[index];
                  final bool isSelected = madhab == _selectedMadhab;
                  
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 300),
                    child: SlideAnimation(
                      verticalOffset: 20.0,
                      child: FadeInAnimation(
                        child: _buildRadioOption(
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
                          index: index,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // خيار الراديو المخصص - تحسين التصميم
  Widget _buildRadioOption({
    required String title, 
    required String value, 
    required String groupValue, 
    required Function(String?) onChanged,
    bool isSelected = false,
    int index = 0,
  }) {
    // ألوان مختلفة للخيارات
    final List<Color> optionColors = [
      const Color(0xFF4DB6AC),  // فيروزي
      const Color(0xFF5C6BC0),  // أزرق
      const Color(0xFFFFB74D),  // برتقالي فاتح  
      const Color(0xFF7B1FA2),  // بنفسجي
      const Color(0xFF66BB6A),  // أخضر
      const Color(0xFF3949AB),  // أزرق داكن
    ];
    
    final color = isSelected 
        ? optionColors[index % optionColors.length] 
        : Colors.grey;
    
    return Card(
      elevation: isSelected ? 2 : 0,
      shadowColor: isSelected ? color.withOpacity(0.3) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: RadioListTile<String>(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.black87,
            ),
          ),
          value: value,
          groupValue: groupValue,
          activeColor: color,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onChanged: onChanged,
          secondary: isSelected
              ? Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: color,
                    size: 16,
                  ),
                )
              : Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ),
        ),
      ),
    );
  }
  
  // قسم تعديلات المواقيت
  Widget _buildAdjustmentsSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: kPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تعديل المواقيت (+ للتأخير، - للتقديم):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // قائمة الصلوات للتعديل
          AnimationLimiter(
            child: Column(
              children: List.generate(
                _prayerNames.length,
                (index) {
                  final prayerName = _prayerNames[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 30.0,
                      child: FadeInAnimation(
                        child: _buildPrayerAdjustment(prayerName),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // زر إعادة ضبط التعديلات
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _adjustments = {};
                  _hasChanges = true;
                });
              },
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('إعادة ضبط التعديلات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary.withOpacity(0.1),
                foregroundColor: kPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // شريط تمرير تعديل الصلاة الفردية - تحسين التصميم
  Widget _buildPrayerAdjustment(String prayerName) {
    final Color prayerColor = _prayerColors[prayerName] ?? kPrimary;
    final IconData prayerIcon = _prayerIcons[prayerName] ?? Icons.access_time;
    final int adjustmentValue = _adjustments[prayerName] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            prayerColor.withOpacity(0.7),
            prayerColor.withOpacity(0.4),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: prayerColor.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // أيقونة خلفية
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              prayerIcon,
              size: 80,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اسم الصلاة والقيمة الحالية
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          prayerIcon,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      prayerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${adjustmentValue > 0 ? '+' : ''}${adjustmentValue} دقيقة',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // شريط التمرير
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.white.withOpacity(0.7),
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withOpacity(0.2),
                    valueIndicatorColor: Colors.white,
                    valueIndicatorTextStyle: TextStyle(
                      color: prayerColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                    trackHeight: 4,
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
                
                // مؤشرات القيم
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '-15',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        '+15',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // أزرار الإجراءات - تحسين التصميم
  Widget _buildActionButtons() {
    return Card(
      elevation: 6,
      shadowColor: kPrimary.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: kPrimary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // زر الحفظ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save, size: 20),
                label: const Text(
                  'حفظ الإعدادات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: kPrimary.withOpacity(0.4),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // زر إعادة الضبط
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetSettings,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text(
                  'إعادة ضبط الإعدادات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  side: BorderSide(color: kPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                
                // عرض رسالة تأكيد
                _showSuccessSnackBar('تم إعادة ضبط الإعدادات إلى القيم الافتراضية');
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إعادة الضبط'),
          ),
        ],
      ),
    );
  }
}