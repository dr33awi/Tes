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
  
  // List of prayer names for adjustments
  final List<String> _prayerNames = [
    'الفجر',
    'الشروق',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];
  
  // Prayer colors for visual appeal
  final Map<String, Color> _prayerColors = {
    'الفجر': const Color(0xFF5B68D9),    // Blue-ish for dawn
    'الشروق': const Color(0xFFFF9E0D),   // Orange for sunrise
    'الظهر': const Color(0xFFFFB746),    // Yellow for noon
    'العصر': const Color(0xFFFF8A65),    // Orange-ish for afternoon
    'المغرب': const Color(0xFF5C6BC0),   // Dark blue for sunset
    'العشاء': const Color(0xFF1A237E),   // Deep blue for night
  };
  
  // Prayer icons
  final Map<String, IconData> _prayerIcons = {
    'الفجر': Icons.brightness_2,
    'الشروق': Icons.wb_sunny_outlined,
    'الظهر': Icons.wb_sunny,
    'العصر': Icons.wb_twighlight,
    'المغرب': Icons.nights_stay_outlined,
    'العشاء': Icons.nightlight_round,
  };
  
  // Theme colors
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
    
    // Initialize theme colors
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
      debugPrint('Error loading settings: $e');
      
      // Default values in case of error
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
                        // Intro card
                        _buildIntroCard(),
                        
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('طريقة حساب المواقيت', Icons.calculate_rounded),
                        _buildCalculationMethodSelector(),
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('المذهب الفقهي', Icons.school_rounded),
                        _buildMadhabSelector(),
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('تعديلات المواقيت (بالدقائق)', Icons.timer_outlined),
                        _buildAdjustmentsSection(),
                        const SizedBox(height: 24),
                        
                        // Action buttons
                        _buildActionButtons(),
                        
                        const SizedBox(height: 24),
                        
                        // Info card
                        _buildInfoCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
  
  // Intro card explaining the settings
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
                'يمكنك تعديل طريقة حساب المواقيت والمذهب الفقهي وضبط تعديلات خاصة لكل وقت صلاة حسب المنطقة التي تتواجد فيها.',
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
  
  // Check for changes before exiting
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
  
  // Show error message
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
  
  // Show success message
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
  
  // Section title
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: kPrimary,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  // Calculation method selector
  Widget _buildCalculationMethodSelector() {
    return Card(
      elevation: 4,
      shadowColor: kPrimary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
            
            // List of available calculation methods
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
        ),
      ),
    );
  }
  
  // Madhab selector
  Widget _buildMadhabSelector() {
    return Card(
      elevation: 4,
      shadowColor: kPrimary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
            
            // List of available madhabs
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
        ),
      ),
    );
  }
  
  // Custom radio option
  Widget _buildRadioOption({
    required String title, 
    required String value, 
    required String groupValue, 
    required Function(String?) onChanged,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
  
  // Time adjustments section
  Widget _buildAdjustmentsSection() {
    return Card(
      elevation: 4,
      shadowColor: kPrimary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
            
            // List of prayers to adjust
            ...List.generate(
              _prayerNames.length,
              (index) {
                final prayerName = _prayerNames[index];
                return _buildPrayerAdjustment(prayerName);
              },
            ),
            
            // Reset adjustments button
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
        ),
      ),
    );
  }
  
  // Individual prayer adjustment slider
  Widget _buildPrayerAdjustment(String prayerName) {
    final Color prayerColor = _prayerColors[prayerName] ?? kPrimary;
    final IconData prayerIcon = _prayerIcons[prayerName] ?? Icons.access_time;
    final int adjustmentValue = _adjustments[prayerName] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Prayer name and current value
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
          
          // Slider
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
              min: -15, // Max 15 minutes earlier
              max: 15, // Max 15 minutes later
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
  
  // Action buttons
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Save button
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
        
        // Reset button
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
  
  // Info card
  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary.withOpacity(0.1), kPrimaryLight.withOpacity(0.05)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline, color: kPrimary, size: 20),
                ),
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
            
            // Info items
            _buildInfoItem(
              title: 'طريقة الحساب',
              content: 'اختر طريقة الحساب الأكثر استخداماً في منطقتك. على سبيل المثال، طريقة أم القرى هي الطريقة الرسمية في المملكة العربية السعودية.',
              icon: Icons.calculate,
            ),
            const SizedBox(height: 12),
            
            _buildInfoItem(
              title: 'المذهب الفقهي',
              content: 'يؤثر اختيار المذهب على وقت صلاة العصر فقط. المذهب الحنفي يبدأ وقت العصر متأخراً قليلاً مقارنة بالمذهب الشافعي.',
              icon: Icons.school,
            ),
            const SizedBox(height: 12),
            
            _buildInfoItem(
              title: 'التعديلات',
              content: 'يمكنك تعديل المواقيت يدوياً لمطابقة المواقيت المحلية في منطقتك. استخدم قيم سالبة للتقديم وقيم موجبة للتأخير.',
              icon: Icons.tune,
            ),
          ],
        ),
      ),
    );
  }
  
  // Info item
  Widget _buildInfoItem({
    required String title, 
    required String content, 
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: kPrimary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Save settings
  Future<void> _saveSettings() async {
    try {
      setState(() => _isLoading = true);
      
      // Update configuration in service
      _prayerService.updateCalculationMethod(_selectedMethod);
      _prayerService.updateMadhab(_selectedMadhab);
      _prayerService.clearAdjustments();
      
      // Add adjustments
      _adjustments.forEach((prayerName, minutes) {
        if (minutes != 0) {
          _prayerService.setAdjustment(prayerName, minutes);
        }
      });
      
      // Save settings
      await _prayerService.saveSettings();
      
      // Recalculate prayer times immediately
      await _prayerService.recalculatePrayerTimes();
      
      setState(() {
        _isLoading = false;
        _hasChanges = false; // Reset changes indicator
      });
      
      // Show confirmation message
      _showSuccessSnackBar('تم حفظ الإعدادات وتحديث مواقيت الصلاة بنجاح');
      
      // Return to previous screen
      Navigator.pop(context, true); // Send true to indicate changes
    } catch (e) {
      debugPrint('Error saving settings: $e');
      
      setState(() => _isLoading = false);
      
      // Show error message
      _showErrorSnackBar('حدث خطأ أثناء حفظ الإعدادات');
    }
  }
  
  // Reset settings
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