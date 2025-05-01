// lib/screens/athkarscreen/tasbih_screen.dart - النسخة المصححة
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
    {'text': 'سبحان الله', 'count': 33, 'color': const Color(0xFF66BB6A)},
    {'text': 'الحمد لله', 'count': 33, 'color': const Color(0xFF42A5F5)},
    {'text': 'الله أكبر', 'count': 33, 'color': const Color(0xFFFFB74D)},
    {'text': 'لا إله إلا الله', 'count': 100, 'color': const Color(0xFFAB47BC)},
    {'text': 'لا حول ولا قوة إلا بالله', 'count': 100, 'color': const Color(0xFF5C6BC0)},
    {'text': 'أستغفر الله', 'count': 100, 'color': const Color(0xFFE57373)},
    {'text': 'اللهم صل على محمد', 'count': 100, 'color': const Color(0xFF4DB6AC)},
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
  }

  // زيادة العداد
  void _incrementCounter() {
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
    
    // تأثير اهتزاز للتغذية الراجعة
    if (_counter >= _maxCount) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  // إعادة ضبط العداد
  void _resetCounter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة ضبط العداد'),
        content: const Text('هل أنت متأكد من إعادة ضبط العداد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _counter = 0;
                // المؤشر سيتحدث تلقائياً عند إعادة البناء
              });
              _saveTasbihState();
              Navigator.pop(context);
              
              // تأثير اهتزاز للتغذية الراجعة
              HapticFeedback.mediumImpact();
            },
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
      
      // تحديث المؤشر الدائري بالقيم الجديدة سيحدث تلقائياً عند إعادة بناء الصفحة
    });
    _saveTasbihState();
    
    // تأثير اهتزاز للتغذية الراجعة
    HapticFeedback.mediumImpact();
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
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              // إجمالي العدد
              Padding(
                padding: const EdgeInsets.all(8.0),
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
              
              // عبارة التسبيح الحالية
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 20,
                    child: FadeInAnimation(
                      child: Card(
                        elevation: 4,
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
                              Text(
                                _currentTasbih,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'العدد: ',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  AnimatedFlipCounter(
                                    duration: const Duration(milliseconds: 500),
                                    value: _counter,
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    ' / ',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$_maxCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
                    child: Center(
                      child: GestureDetector(
                        onTap: _incrementCounter,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _animation.value,
                              child: Container(
                                width: seekBarSize * 0.7,
                                height: seekBarSize * 0.7,
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
                                  child: AnimatedFlipCounter(
                                    duration: const Duration(milliseconds: 300),
                                    value: _counter,
                                    textStyle: const TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // تمرير null للمعلمة
                    valueNotifier: null,
                  ),
                ),
              ),
              
              // شريط أدوات في الأسفل
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildToolbarButton(
                      onPressed: _resetCounter,
                      icon: Icons.refresh,
                      label: 'إعادة ضبط',
                      color: Colors.blue,
                    ),
                    _buildToolbarButton(
                      onPressed: () => _showTasbihList(context),
                      icon: Icons.list,
                      label: 'قائمة التسبيحات',
                      color: kPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // بناء زر في شريط الأدوات
  Widget _buildToolbarButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
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
            Text(
              'اختر التسبيح',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
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
                            elevation: isSelected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: tasbih['color'],
                                  shape: BoxShape.circle,
                                ),
                                child: isSelected 
                                    ? Icon(Icons.check, color: Colors.white, size: 20)
                                    : null,
                              ),
                              title: Text(
                                tasbih['text'],
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text('العدد: ${tasbih['count']}'),
                              selected: isSelected,
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