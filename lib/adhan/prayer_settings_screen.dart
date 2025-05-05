// lib/screens/prayer_times_screen/prayer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;
import 'package:test_athkar_app/adhan/prayer_times_service.dart';

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
      
      // Depuración
      debugPrint('Configuración cargada: Método = $_selectedMethod, Madhab = $_selectedMadhab');
    } catch (e) {
      debugPrint('Error al cargar configuración: $e');
      
      // Valores por defecto en caso de error
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
              fontSize: 20,
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
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
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
                        
                        // Botones de acción
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
                        
                        // Información explicativa
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
  
  // Verificar cambios antes de salir
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
  
  // Mostrar mensaje de error
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
  
  // Mostrar mensaje de éxito
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
  
  // Título de sección
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kPrimary,
        ),
      ),
    );
  }
  
  // Selector de método de cálculo
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
            
            // Lista de métodos de cálculo disponibles
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
                    debugPrint('Método seleccionado: $_selectedMethod');
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Selector de madhab
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
            
            // Lista de madhabs disponibles
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
                    debugPrint('Madhab seleccionado: $_selectedMadhab');
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Sección de ajustes de tiempo
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
            
            // Lista de oraciones para ajustar
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
                          min: -15, // Adelantar máximo 15 minutos
                          max: 15, // Retrasar máximo 15 minutos
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
            
            // Botón para resetear ajustes
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
  
  // Tarjeta de información
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
  
  // Un elemento de información
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
  
  // Guardar configuración
  Future<void> _saveSettings() async {
    try {
      setState(() => _isLoading = true);
      
      // Depuración - valores antes de guardar
      debugPrint('Guardando configuración: Método = $_selectedMethod, Madhab = $_selectedMadhab');
      
      // Actualizar configuración en el servicio
      _prayerService.updateCalculationMethod(_selectedMethod);
      _prayerService.updateMadhab(_selectedMadhab);
      _prayerService.clearAdjustments();
      
      // Añadir ajustes
      _adjustments.forEach((prayerName, minutes) {
        if (minutes != 0) {
          _prayerService.setAdjustment(prayerName, minutes);
        }
      });
      
      // Guardar configuración
      await _prayerService.saveSettings();
      
      // Nueva función: recalcular tiempos de oración inmediatamente
      await _prayerService.recalculatePrayerTimes();
      
      // Verificar que se haya guardado correctamente
      final savedSettings = _prayerService.getUserSettings();
      debugPrint('Verificación después de guardar: ${savedSettings['calculationMethod']}');
      
      setState(() {
        _isLoading = false;
        _hasChanges = false; // Resetear indicador de cambios
      });
      
      // Mostrar mensaje de confirmación
      _showSuccessSnackBar('تم حفظ الإعدادات وتحديث مواقيت الصلاة بنجاح');
      
      // Regresar a la pantalla anterior
      Navigator.pop(context, true); // Enviar true para indicar cambios
    } catch (e) {
      debugPrint('Error al guardar configuración: $e');
      
      setState(() => _isLoading = false);
      
      // Mostrar mensaje de error
      _showErrorSnackBar('حدث خطأ أثناء حفظ الإعدادات');
    }
  }
  
  // Resetear configuración
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
              debugPrint('Configuración reseteada a los valores predeterminados');
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