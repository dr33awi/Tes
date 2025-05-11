// lib/prayer/screens/prayer_settings_screen.dart
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
  
  // Lista de nombres de oración para ajustes
  final List<String> _prayerNames = [
    'الفجر',
    'الشروق',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];
  
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
                        _buildSectionTitle('طريقة حساب المواقيت'),
                        _buildCalculationMethodSelector(),
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('المذهب الفقهي'),
                        _buildMadhabSelector(),
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('تعديلات المواقيت (بالدقائق)'),
                        _buildAdjustmentsSection(),
                        const SizedBox(height: 24),
                        
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                        ),
                        
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
  
  // Calculation method selector
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
            
            // List of available calculation methods
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
                      _hasChanges = true;
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
  
  // Madhab selector
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
            
            // List of available madhabs
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
                      _hasChanges = true;
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
  
  // Time adjustments section
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
            
            // List of prayers to adjust
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
                          min: -15, // Max 15 minutes earlier
                          max: 15, // Max 15 minutes later
                          divisions: 30,
                          activeColor: kPrimary,
                          inactiveColor: kPrimary.withOpacity(0.2),
                          label: '${_adjustments[prayerName] ?? 0} دقيقة',
                          onChanged: (double value) {
                            setState(() {
                              _adjustments[prayerName] = value.round();
                              _hasChanges = true;
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
            
            // Reset adjustments button
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
  
  // Info card
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
  
  // Info item
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
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ],
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