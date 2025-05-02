// lib/screens/athkarscreen/tasbih_screen.dart - النسخة النهائية
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;
import 'package:circular_seek_bar/circular_seek_bar.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/services.dart';
import 'package:test_athkar_app/screens/home_screen/widgets/common/app_loading_indicator.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({Key? key}) : super(key: key);

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> with SingleTickerProviderStateMixin {
  // عداد التسبيح الحالي
  int _counter = 0;
  
  // الحد الأقصى للعداد الحالي
  int _maxCount = 33;
  
  // إجمالي عدد التسبيحات
  int _totalCount = 0;
  
  // العبارة الحالية للتسبيح
  String _currentTasbih = 'سبحان الله';
  
  // قائمة بعبارات التسبيح
  final List<Map<String, dynamic>> _tasbihList = [
    {
      'text': 'سبحان الله', 
      'count': 33, 
      'color': const Color(0xFF66BB6A), 
      'icon': Icons.auto_awesome,
      'fadl': 'عن أبي هريرة رضي الله عنه أن رسول الله ﷺ قال: "كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن: سبحان الله وبحمده، سبحان الله العظيم"',
      'source': 'متفق عليه'
    },
    {
      'text': 'الحمد لله', 
      'count': 33, 
      'color': const Color(0xFF42A5F5), 
      'icon': Icons.favorite,
      'fadl': 'عن أبي مالك الأشعري رضي الله عنه قال: قال رسول الله ﷺ: "الحمد لله تملأ الميزان"',
      'source': 'رواه مسلم'
    },
    {
      'text': 'الله أكبر', 
      'count': 33, 
      'color': const Color(0xFFFFB74D), 
      'icon': Icons.star,
      'fadl': 'عن أبي هريرة رضي الله عنه: "من قال سبحان الله وبحمده في يوم مائة مرة، حطت خطاياه وإن كانت مثل زبد البحر"',
      'source': 'متفق عليه'
    },
    {
      'text': 'لا إله إلا الله', 
      'count': 100, 
      'color': const Color(0xFFAB47BC), 
      'icon': Icons.air,
      'fadl': 'عن أبي هريرة رضي الله عنه أن النبي ﷺ قال: "من قال: لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير، في يوم مائة مرة، كانت له عدل عشر رقاب، وكتبت له مائة حسنة، ومحيت عنه مائة سيئة"',
      'source': 'متفق عليه'
    },
    {
      'text': 'لا حول ولا قوة إلا بالله', 
      'count': 100, 
      'color': const Color(0xFF5C6BC0), 
      'icon': Icons.shield,
      'fadl': 'قال النبي ﷺ: "ألا أدلك على كنز من كنوز الجنة؟ لا حول ولا قوة إلا بالله"',
      'source': 'متفق عليه'
    },
    {
      'text': 'أستغفر الله', 
      'count': 100, 
      'color': const Color(0xFFE57373), 
      'icon': Icons.water_drop,
      'fadl': 'قال رسول الله ﷺ: "والله إني لأستغفر الله وأتوب إليه في اليوم أكثر من سبعين مرة"',
      'source': 'رواه البخاري'
    },
    {
      'text': 'اللهم صل على محمد', 
      'count': 100, 
      'color': const Color(0xFF4DB6AC), 
      'icon': Icons.mosque,
      'fadl': 'قال رسول الله ﷺ: "من صلى علي صلاة واحدة صلى الله عليه بها عشراً"',
      'source': 'رواه مسلم'
    },
    {
      'text': 'سبحان الله وبحمده', 
      'count': 100, 
      'color': const Color(0xFF26A69A), 
      'icon': Icons.flare,
      'fadl': 'قال النبي ﷺ: "من قال سبحان الله وبحمده مائة مرة في يوم غُفرت له ذنوبه وإن كانت مثل زبد البحر"',
      'source': 'متفق عليه'
    },
    {
      'text': 'سبحان الله والحمد لله ولا إله إلا الله والله أكبر', 
      'count': 25, 
      'color': const Color(0xFFF06292), 
      'icon': Icons.shower,
      'fadl': 'قال رسول الله ﷺ: "أحب الكلام إلى الله أربع: سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر، لا يضرك بأيهن بدأت"',
      'source': 'رواه مسلم'
    },
  ];

  // الفهرس الحالي لعبارة التسبيح
  int _currentTasbihIndex = 0;

  // متحكم المؤشر الدائري
  final GlobalKey _seekBarKey = GlobalKey();
  
  // حالة التحميل
  bool _isLoading = true;
  
  // متحكم الحركة للزر
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // للتحكم في تأثيرات اللمس
  bool _isButtonPressed = false;
  
  // للتحكم في الاهتزاز
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadTasbihState();
    
    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // محاكاة التحميل
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // تحميل حالة التسبيح من التخزين المحلي
  Future<void> _loadTasbihState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('tasbih_counter') ?? 0;
      _currentTasbihIndex = prefs.getInt('tasbih_index') ?? 0;
      _totalCount = prefs.getInt('tasbih_total') ?? 0;
      _vibrationEnabled = prefs.getBool('tasbih_vibration') ?? true;
      
      _currentTasbih = _tasbihList[_currentTasbihIndex]['text'];
      _maxCount = _tasbihList[_currentTasbihIndex]['count'];
    });
  }

  // حفظ حالة التسبيح في التخزين المحلي
  Future<void> _saveTasbihState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_counter', _counter);
    await prefs.setInt('tasbih_index', _currentTasbihIndex);
    await prefs.setInt('tasbih_total', _totalCount);
    
    // حفظ إعداد الاهتزاز
    await prefs.setBool('tasbih_vibration', _vibrationEnabled);
  }

  // زيادة العداد
  void _incrementCounter() {
    _animateButton();
    
    setState(() {
      _counter++;
      _totalCount++;
      
      // انتقل إلى التسبيح التالي إذا وصلنا للحد الأقصى
      if (_counter >= _maxCount) {
        _counter = 0;
        _currentTasbihIndex = (_currentTasbihIndex + 1) % _tasbihList.length;
        _currentTasbih = _tasbihList[_currentTasbihIndex]['text'];
        _maxCount = _tasbihList[_currentTasbihIndex]['count'];
      }
    });
    _saveTasbihState();
    
    // تأثير اهتزاز للتغذية الراجعة (إذا كان مفعلاً)
    if (_vibrationEnabled) {
      if (_counter >= _maxCount) {
        HapticFeedback.mediumImpact();
        
        // إظهار رسالة عند إكمال العداد
        _showCompletionMessage();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }
  
  // إظهار رسالة عند إكمال العدد المطلوب
  void _showCompletionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.done_all, color: Colors.white),
            const SizedBox(width: 12),
            const Text('أحسنت! اكتمل عدد مرات الذكر', style: TextStyle(fontSize: 16)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kPrimary,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'عرض الفضل',
          textColor: Colors.white,
          onPressed: () {
            // عرض فضل الذكر
            _showFadlDialog();
          },
        ),
      ),
    );
  }
  
  // عرض فضل الذكر الحالي
  void _showFadlDialog() {
    final tasbih = _tasbihList[_currentTasbihIndex];
    
    if (tasbih['fadl'] != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(tasbih['icon'], color: tasbih['color']),
              SizedBox(width: 8),
              Text('فضل ${tasbih['text']}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tasbih['fadl'],
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'المصدر: ${tasbih['source']}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'حسنا',
                style: TextStyle(color: kPrimary),
              ),
            ),
          ],
        ),
      );
    }
  }
  
  // انيميشن الضغط على الزر
  void _animateButton() {
    setState(() {
      _isButtonPressed = true;
    });
    
    _animationController.reset();
    _animationController.forward();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isButtonPressed = false;
        });
      }
    });
  }

  // إعادة ضبط العداد
  void _resetCounter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange),
            SizedBox(width: 8),
            Text('إعادة ضبط العداد'),
          ],
        ),
        content: const Text('هل أنت متأكد من إعادة ضبط العداد؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _counter = 0;
              });
              _saveTasbihState();
              Navigator.pop(context);
              
              // تأثير اهتزاز للتغذية الراجعة
              if (_vibrationEnabled) {
                HapticFeedback.mediumImpact();
              }
              
              // إظهار رسالة بعد إعادة الضبط
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم إعادة ضبط العداد'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  // تغيير عبارة التسبيح
  void _changeTasbih(int index) {
    setState(() {
      _currentTasbihIndex = index;
      _currentTasbih = _tasbihList[_currentTasbihIndex]['text'];
      _maxCount = _tasbihList[_currentTasbihIndex]['count'];
      _counter = 0;
    });
    _saveTasbihState();
    
    // تأثير اهتزاز للتغذية الراجعة
    if (_vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
    
    // إظهار رسالة عند تغيير التسبيح
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم اختيار: ${_tasbihList[index]['text']}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _tasbihList[index]['color'],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  // تبديل إعداد الاهتزاز
  void _toggleVibration() {
    setState(() {
      _vibrationEnabled = !_vibrationEnabled;
    });
    _saveTasbihState();
    
    // إظهار رسالة
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_vibrationEnabled ? 'تم تفعيل الاهتزاز' : 'تم إيقاف الاهتزاز'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  // عرض الإحصائيات
  void _showStatistics() {
    final mostUsedTasbih = _findMostUsedTasbih();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.insights, color: kPrimary),
            SizedBox(width: 8),
            Text('إحصائيات المسبحة'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // إجمالي التسبيحات
              _buildStatItem(
                icon: Icons.format_list_numbered,
                title: 'إجمالي التسبيحات',
                value: '$_totalCount',
                color: kPrimary,
              ),
              
              const Divider(height: 30),
              
              // الذكر الحالي
              _buildStatItem(
                icon: _tasbihList[_currentTasbihIndex]['icon'],
                title: 'الذكر الحالي',
                subtitle: _currentTasbih,
                value: '$_counter / $_maxCount',
                color: _tasbihList[_currentTasbihIndex]['color'],
              ),
              
              if (mostUsedTasbih != null) ...[
                const Divider(height: 30),
                
                // الذكر الأكثر استخداماً
                _buildStatItem(
                  icon: mostUsedTasbih['icon'],
                  title: 'الذكر الأكثر استخداماً',
                  subtitle: mostUsedTasbih['text'],
                  value: '',
                  color: mostUsedTasbih['color'],
                ),
              ],
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.check),
            label: Text('حسناً'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
  
  // إيجاد الذكر الأكثر استخداماً
  Map<String, dynamic>? _findMostUsedTasbih() {
    // يمكن تنفيذ منطق أكثر تعقيداً لتتبع الذكر الأكثر استخداماً
    // لكن للتبسيط سنعيد الذكر الحالي
    return _tasbihList[_currentTasbihIndex];
  }
  
  // بناء عنصر إحصائية
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // الحصول على حجم الشاشة
    final size = MediaQuery.of(context).size;
    final double seekBarSize = size.width * 0.75;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kSurface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'المسبحة الإلكترونية',
            style: TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: kPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: AppLoadingIndicator(
          message: 'جاري تحضير المسبحة...',
          loadingType: LoadingType.bouncingBall,
        ),
      );
    }

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'المسبحة الإلكترونية',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: kPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _vibrationEnabled ? Icons.vibration : Icons.do_not_disturb,
              color: kPrimary,
            ),
            onPressed: _toggleVibration,
            tooltip: _vibrationEnabled ? 'إيقاف الاهتزاز' : 'تفعيل الاهتزاز',
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: kPrimary,
            ),
            onPressed: () => _showFadlDialog(),
            tooltip: 'فضل الذكر',
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: widget,
                ),
              ),
              children: [
                // إجمالي العدد
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: _showStatistics,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimary, kPrimaryLight],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.equalizer, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'الإجمالي: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          AnimatedFlipCounter(
                            duration: const Duration(milliseconds: 500),
                            value: _totalCount,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // عبارة التسبيح الحالية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    elevation: 8,
                    shadowColor: _tasbihList[_currentTasbihIndex]['color'].withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _tasbihList[_currentTasbihIndex]['color'],
                            Color.lerp(_tasbihList[_currentTasbihIndex]['color'], Colors.white, 0.3) ?? _tasbihList[_currentTasbihIndex]['color'],
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // أيقونة التسبيح
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _tasbihList[_currentTasbihIndex]['icon'],
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // نص التسبيح
                          Text(
                            _currentTasbih,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3.0,
                                  color: Color.fromARGB(100, 0, 0, 0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // العداد
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'العدد: ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AnimatedFlipCounter(
                                  duration: const Duration(milliseconds: 500),
                                  value: _counter,
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const Text(
                                  ' / ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$_maxCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // المؤشر الدائري
                Expanded(
                  child: Center(
                    child: CircularSeekBar(
                      key: _seekBarKey,
                      width: seekBarSize,
                      height: seekBarSize,
                      progress: _counter.toDouble(),
                      maxProgress: _maxCount.toDouble(),
                      barWidth: 16.0,
                      startAngle: 0,
                      sweepAngle: 360,
                      strokeCap: StrokeCap.round,
                      progressGradientColors: [
                        _tasbihList[_currentTasbihIndex]['color'],
                        Color.lerp(_tasbihList[_currentTasbihIndex]['color'], Colors.white, 0.3) ?? _tasbihList[_currentTasbihIndex]['color'],
                      ],
                      innerThumbRadius: 5.0,
                      innerThumbStrokeWidth: 3.0,
                      innerThumbColor: Colors.white,
                      outerThumbRadius: 18.0,
                      outerThumbStrokeWidth: 3.0,
                      outerThumbColor: _tasbihList[_currentTasbihIndex]['color'],
                      dashWidth: 0.0,
                      dashGap: 0.0,
                      animation: true,
                      animDurationMillis: 300,
                      curves: Curves.easeInOut,
                      trackColor: Colors.grey.shade300,
                      valueNotifier: null,
                      child: Center(
                        child: GestureDetector(
                          onTap: _incrementCounter,
                          child: AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isButtonPressed ? _animation.value : 1.0,
                                child: Container(
                                  width: seekBarSize * 0.75,
                                  height: seekBarSize * 0.75,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        _tasbihList[_currentTasbihIndex]['color'],
                                        Color.lerp(_tasbihList[_currentTasbihIndex]['color'], Colors.white, 0.2) ?? _tasbihList[_currentTasbihIndex]['color'],
                                      ],
                                      center: Alignment(0.2, 0.2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _tasbihList[_currentTasbihIndex]['color'].withOpacity(0.4),
                                        blurRadius: 25,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AnimatedFlipCounter(
                                          duration: const Duration(milliseconds: 300),
                                          value: _counter,
                                          textStyle: const TextStyle(
                                            fontSize: 60,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(0, 2),
                                                blurRadius: 4.0,
                                                color: Color.fromARGB(100, 0, 0, 0),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'اضغط للتسبيح',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // الأزرار السفلية (مباشرة بدون كارد)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _resetCounter,
                          icon: Icon(Icons.refresh),
                          label: Text('إعادة ضبط'),
                          style: TextButton.styleFrom(
                            foregroundColor: kPrimary,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _showTasbihList(context),
                          icon: Icon(Icons.list),
                          label: Text('قائمة الأذكار'),
                          style: TextButton.styleFrom(
                            foregroundColor: kPrimary,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // عرض قائمة التسبيحات
  void _showTasbihList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // مقبض السحب
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            
            // عنوان
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.format_list_bulleted, color: kPrimary),
                SizedBox(width: 8),
                Text(
                  'اختر الذكر',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // قائمة التسبيحات
            Flexible(
              child: AnimationLimiter(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _tasbihList.length,
                  itemBuilder: (context, index) {
                    final bool isSelected = index == _currentTasbihIndex;
                    final tasbih = _tasbihList[index];
                    
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 300),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            elevation: isSelected ? 6 : 2,
                            shadowColor: tasbih['color'].withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected 
                                  ? BorderSide(color: tasbih['color'], width: 2)
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: tasbih['color'],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isSelected 
                                      ? Icon(Icons.check, color: Colors.white, size: 22)
                                      : Icon(tasbih['icon'], color: Colors.white, size: 22),
                                ),
                              ),
                              title: Text(
                                tasbih['text'],
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                'العدد: ${tasbih['count']}',
                                style: TextStyle(
                                  color: isSelected ? tasbih['color'] : Colors.grey,
                                ),
                              ),
                              selected: isSelected,
                              trailing: isSelected
                                  ? Icon(Icons.radio_button_checked, color: tasbih['color'])
                                  : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                              onTap: () {
                                _changeTasbih(index);
                                Navigator.pop(context);
                              },
                            ),
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
      ),
    );
  }
}