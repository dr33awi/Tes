// lib/screens/athkarscreen/tasbih_screen.dart
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
      'fadl': 'عن أبي هريرة رضي الله عنه أن رسول الله ﷺ قال: "كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن: سبحان الله وبحمده، سبحان الله العظيم"',
      'source': 'متفق عليه'
    },
    {
      'text': 'الحمد لله', 
      'count': 33, 
      'color': const Color(0xFF42A5F5), 
      'fadl': 'عن أبي مالك الأشعري رضي الله عنه قال: قال رسول الله ﷺ: "الحمد لله تملأ الميزان"',
      'source': 'رواه مسلم'
    },
    {
      'text': 'الله أكبر', 
      'count': 33, 
      'color': const Color(0xFFFFB74D), 
      'fadl': 'عن أبي هريرة رضي الله عنه: "من قال سبحان الله وبحمده في يوم مائة مرة، حطت خطاياه وإن كانت مثل زبد البحر"',
      'source': 'متفق عليه'
    },
    {
      'text': 'لا إله إلا الله', 
      'count': 100, 
      'color': const Color(0xFFAB47BC), 
      'fadl': 'عن أبي هريرة رضي الله عنه أن النبي ﷺ قال: "من قال: لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير، في يوم مائة مرة، كانت له عدل عشر رقاب، وكتبت له مائة حسنة، ومحيت عنه مائة سيئة"',
      'source': 'متفق عليه'
    },
    {
      'text': 'لا حول ولا قوة إلا بالله', 
      'count': 100, 
      'color': const Color(0xFF5C6BC0), 
      'fadl': 'قال النبي ﷺ: "ألا أدلك على كنز من كنوز الجنة؟ لا حول ولا قوة إلا بالله"',
      'source': 'متفق عليه'
    },
    {
      'text': 'أستغفر الله', 
      'count': 100, 
      'color': const Color(0xFFE57373), 
      'fadl': 'قال رسول الله ﷺ: "والله إني لأستغفر الله وأتوب إليه في اليوم أكثر من سبعين مرة"',
      'source': 'رواه البخاري'
    },
    {
      'text': 'اللهم صل على محمد', 
      'count': 100, 
      'color': const Color(0xFF4DB6AC), 
      'fadl': 'قال رسول الله ﷺ: "من صلى علي صلاة واحدة صلى الله عليه بها عشراً"',
      'source': 'رواه مسلم'
    },
    {
      'text': 'سبحان الله وبحمده', 
      'count': 100, 
      'color': const Color(0xFF26A69A), 
      'fadl': 'قال النبي ﷺ: "من قال سبحان الله وبحمده مائة مرة في يوم غُفرت له ذنوبه وإن كانت مثل زبد البحر"',
      'source': 'متفق عليه'
    },
    {
      'text': 'سبحان الله والحمد لله ولا إله إلا الله والله أكبر', 
      'count': 25, 
      'color': const Color(0xFFF06292), 
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
  
  // إحصائيات إضافية
  Map<int, int> _tasbihUsageCount = {};
  DateTime? _sessionStartTime;
  int _sessionCount = 0;
  int _streakDays = 0;
  DateTime? _lastUseDate;

  // ألوان جديدة للأزرار - متناسقة مع التطبيق
  final Color _primaryColor = const Color(0xFF447055); // اللون الأساسي للتطبيق (kPrimary)
  final Color _secondaryColor = const Color(0xFF27B376); // اللون الثانوي للتطبيق (kPrimaryLight)
  final Color _accentColor = const Color(0xFF6C9B7F); // لون مشتق من اللون الأساسي
  final Color _surfaceColor = const Color(0xFFE7E8E3); // لون السطح للتطبيق (kSurface)
  
  // أشكال وتأثيرات بصرية محسنة
  final BorderRadius _buttonBorderRadius = BorderRadius.circular(15);
  final double _buttonElevation = 6.0;

  @override
  void initState() {
    super.initState();
    _loadTasbihState();
    
    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // تعيين وقت بدء الجلسة
    _sessionStartTime = DateTime.now();
    
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
    
    // تحميل البيانات الأساسية
    setState(() {
      _counter = prefs.getInt('tasbih_counter') ?? 0;
      _currentTasbihIndex = prefs.getInt('tasbih_index') ?? 0;
      _totalCount = prefs.getInt('tasbih_total') ?? 0;
      _vibrationEnabled = prefs.getBool('tasbih_vibration') ?? true;
      
      _currentTasbih = _tasbihList[_currentTasbihIndex]['text'];
      _maxCount = _tasbihList[_currentTasbihIndex]['count'];
      
      // تحميل إحصائيات إضافية
      _streakDays = prefs.getInt('tasbih_streak_days') ?? 0;
      _sessionCount = 0;
      
      // تحميل بيانات آخر استخدام وتحديث التتابع
      String? lastUseDateStr = prefs.getString('tasbih_last_use_date');
      if (lastUseDateStr != null) {
        _lastUseDate = DateTime.parse(lastUseDateStr);
        _updateStreak();
      }
      
      // تحميل إحصائيات استخدام كل تسبيح
      for (int i = 0; i < _tasbihList.length; i++) {
        int count = prefs.getInt('tasbih_usage_$i') ?? 0;
        _tasbihUsageCount[i] = count;
      }
    });
  }

  // تحديث تتابع الأيام
  void _updateStreak() {
    if (_lastUseDate == null) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastUseDay = DateTime(_lastUseDate!.year, _lastUseDate!.month, _lastUseDate!.day);
    
    if (lastUseDay.isAtSameMomentAs(yesterday)) {
      // الاستخدام كان بالأمس، زيادة التتابع
      _streakDays++;
    } else if (!lastUseDay.isAtSameMomentAs(today) && !lastUseDay.isAfter(yesterday)) {
      // انقطع التتابع، إعادة للصفر
      _streakDays = 1;
    }
    // لا تغيير إذا كان آخر استخدام اليوم
  }

  // حفظ حالة التسبيح في التخزين المحلي
  Future<void> _saveTasbihState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // حفظ البيانات الأساسية
    await prefs.setInt('tasbih_counter', _counter);
    await prefs.setInt('tasbih_index', _currentTasbihIndex);
    await prefs.setInt('tasbih_total', _totalCount);
    await prefs.setBool('tasbih_vibration', _vibrationEnabled);
    
    // حفظ إحصائيات إضافية
    final now = DateTime.now();
    await prefs.setString('tasbih_last_use_date', now.toIso8601String());
    await prefs.setInt('tasbih_streak_days', _streakDays);
    
    // حفظ إحصائيات استخدام كل تسبيح
    await prefs.setInt('tasbih_usage_$_currentTasbihIndex', 
      _tasbihUsageCount[_currentTasbihIndex] ?? 0);
  }

  // زيادة العداد
  void _incrementCounter() {
    _animateButton();
    
    setState(() {
      _counter++;
      _totalCount++;
      _sessionCount++;
      
      // زيادة عداد استخدام التسبيح الحالي
      _tasbihUsageCount[_currentTasbihIndex] = 
        (_tasbihUsageCount[_currentTasbihIndex] ?? 0) + 1;
      
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
        backgroundColor: _primaryColor,
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
          title: Text('فضل ${tasbih['text']}'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'حسنا',
                style: TextStyle(color: _primaryColor),
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
    
    Future.delayed(const Duration(milliseconds: 150), () {
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
        title: Row(
          children: [
            Icon(Icons.refresh, color: _accentColor),
            SizedBox(width: 8),
            Text('إعادة ضبط العداد'),
          ],
        ),
        content: const Text('هل أنت متأكد من إعادة ضبط العداد؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        backgroundColor: _primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  // حساب الوقت المستغرق في الجلسة الحالية
  String _getSessionDuration() {
    if (_sessionStartTime == null) return "0 دقيقة";
    
    final now = DateTime.now();
    final difference = now.difference(_sessionStartTime!);
    
    if (difference.inHours > 0) {
      return "${difference.inHours} ساعة ${difference.inMinutes % 60} دقيقة";
    } else {
      return "${difference.inMinutes} دقيقة";
    }
  }
  
  // إيجاد الذكر الأكثر استخداماً
  Map<String, dynamic>? _findMostUsedTasbih() {
    if (_tasbihUsageCount.isEmpty) return null;
    
    int mostUsedIndex = 0;
    int maxCount = 0;
    
    _tasbihUsageCount.forEach((index, count) {
      if (count > maxCount) {
        maxCount = count;
        mostUsedIndex = index;
      }
    });
    
    if (maxCount > 0) {
      return _tasbihList[mostUsedIndex];
    }
    
    return null;
  }
  
  // عرض الإحصائيات
  void _showStatistics() {
    final mostUsedTasbih = _findMostUsedTasbih();
    
    // حساب متوسط سرعة التسبيح
    double averageSpeed = 0;
    if (_sessionStartTime != null && _sessionCount > 0) {
      final duration = DateTime.now().difference(_sessionStartTime!).inSeconds;
      if (duration > 0) {
        averageSpeed = _sessionCount / (duration / 60); // تسبيحات في الدقيقة
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // مقبض السحب
              Container(
                width: 50,
                height: 6,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              
              // عنوان
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insights, color: Colors.white, size: 26),
                          SizedBox(width: 12),
                          Text(
                            'إحصائيات المسبحة',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      if (_streakDays > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Icon(Icons.local_fire_department, color: Colors.amber, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'تتابع التسبيح: $_streakDays يوم',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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
              
              // محتوى الإحصائيات
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        
                        // إحصائيات عامة
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black26,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.analytics_outlined, 
                                        color: _primaryColor, 
                                        size: 24
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'إحصائيات عامة',
                                      style: TextStyle(
                                        color: _primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: 30, thickness: 1),
                                
                                // إجمالي التسبيحات
                                _buildStatItem(
                                  icon: Icons.format_list_numbered,
                                  title: 'إجمالي التسبيحات',
                                  value: '$_totalCount',
                                  color: _primaryColor,
                                ),
                                
                                SizedBox(height: 16),
                                
                                // تسبيحات الجلسة
                                _buildStatItem(
                                  icon: Icons.hourglass_top,
                                  title: 'تسبيحات الجلسة الحالية',
                                  value: '$_sessionCount',
                                  color: Colors.orangeAccent,
                                ),
                                
                                SizedBox(height: 16),
                                
                                // وقت الجلسة
                                _buildStatItem(
                                  icon: Icons.timer,
                                  title: 'وقت الجلسة',
                                  value: _getSessionDuration(),
                                  color: Colors.green,
                                ),
                                
                                if (averageSpeed > 0) ... [
                                  SizedBox(height: 16),
                                  
                                  // سرعة التسبيح
                                  _buildStatItem(
                                    icon: Icons.speed,
                                    title: 'متوسط السرعة',
                                    value: '${averageSpeed.toStringAsFixed(1)} / دقيقة',
                                    color: Colors.blue,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // الذكر الحالي
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black26,
                          child: Stack(
                            children: [
                              // زخرفة خلفية
                              Positioned(
                                right: -20,
                                bottom: -20,
                                child: Icon(
                                  Icons.format_quote,
                                  size: 100,
                                  color: _tasbihList[_currentTasbihIndex]['color'].withOpacity(0.08),
                                ),
                              ),
                              
                              Container(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: _tasbihList[_currentTasbihIndex]['color'].withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.format_quote, 
                                            color: _tasbihList[_currentTasbihIndex]['color'], 
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'الذكر الحالي',
                                                style: TextStyle(
                                                  color: _tasbihList[_currentTasbihIndex]['color'],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: _tasbihList[_currentTasbihIndex]['color'].withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                child: Text(
                                                  '$_counter / $_maxCount',
                                                  style: TextStyle(
                                                    color: _tasbihList[_currentTasbihIndex]['color'],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _tasbihList[_currentTasbihIndex]['color'],
                                            _tasbihList[_currentTasbihIndex]['color'].withOpacity(0.7),
                                          ],
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _tasbihList[_currentTasbihIndex]['color'].withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _currentTasbih,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        if (mostUsedTasbih != null) ...[
                          SizedBox(height: 20),
                          
                          // الذكر الأكثر استخداماً
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            shadowColor: Colors.black26,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: mostUsedTasbih['color'].withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.emoji_events, 
                                          color: mostUsedTasbih['color'], 
                                          size: 24
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'الذكر الأكثر استخداماً',
                                        style: TextStyle(
                                          color: mostUsedTasbih['color'],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(height: 30, thickness: 1),
                                  
                                  // محتوى الذكر الأكثر استخداماً
                                  Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              mostUsedTasbih['color'],
                                              mostUsedTasbih['color'].withOpacity(0.7),
                                            ],
                                            begin: Alignment.topRight,
                                            end: Alignment.bottomLeft,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: mostUsedTasbih['color'].withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            "${_tasbihList.indexOf(mostUsedTasbih) + 1}",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold, 
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              mostUsedTasbih['text'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: mostUsedTasbih['color'].withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                              child: Text(
                                                'المرات: ${_tasbihUsageCount[_tasbihList.indexOf(mostUsedTasbih)] ?? 0}',
                                                style: TextStyle(
                                                  color: mostUsedTasbih['color'],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
              
              // زر الإغلاق
              Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'إغلاق',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // بناء عنصر إحصائية بألوان متناسقة
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required String value,
    required Color color,
  }) {
    // استخدام ألوان متناسقة مع التطبيق
    final Color itemColor = color == Colors.red ? color : _primaryColor; // الاحتفاظ بلون الخطأ كأحمر
    final Color bgColor = _surfaceColor; // استخدام لون السطح للخلفية
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: itemColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
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
                    color: Colors.black87,
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
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // بناء زر جديد مع تأثيرات محسنة - نسخة مصغرة بألوان متناسقة
  Widget _buildNewStyleButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    // استخدام ألوان متناسقة مع التطبيق
    Color buttonColor = color;
    
    // إذا كان اللون المطلوب هو الأحمر (لزر الإعادة)، نحتفظ به، وإلا نستخدم ألوان التطبيق
    if (color != Colors.red) {
      buttonColor = _primaryColor;
    }
    
    return Card(
      elevation: 4,
      shadowColor: buttonColor.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                buttonColor,
                color == Colors.red ? color.withOpacity(0.7) : _secondaryColor,
              ],
              stops: [0.2, 0.9],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: buttonColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // الحصول على حجم الشاشة
    final size = MediaQuery.of(context).size;
    final double seekBarSize = size.width * 0.7;
    
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
              color: _primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: _primaryColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: AppLoadingIndicator(
          message: 'جاري تحضير المسبحة...',
          color: _primaryColor,
          loadingType: LoadingType.staggeredDotsWave,
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
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _primaryColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _vibrationEnabled ? Icons.vibration : Icons.do_not_disturb,
              color: _primaryColor,
            ),
            onPressed: _toggleVibration,
            tooltip: _vibrationEnabled ? 'إيقاف الاهتزاز' : 'تفعيل الاهتزاز',
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: _primaryColor,
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
                // إجمالي العدد مع إضافة وظيفة عرض الإحصائيات
                Padding(
                  padding: const EdgeInsets.all(6.0), // تقليل البطانة
                  child: InkWell(
                    onTap: _showStatistics,
                    borderRadius: BorderRadius.circular(15), // تقليل انحناء الحواف
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // تقليل البطانة
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor, _secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15), // تقليل انحناء الحواف
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.3), // تقليل الكثافة
                            blurRadius: 8, // تقليل التمويه
                            offset: Offset(0, 3), // تقليل الإزاحة
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.equalizer, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          const Text(
                            'الإجمالي: ',
                            style: TextStyle(
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
                          const SizedBox(width: 12),
                          // إضافة رمز يوحي بوجود إحصائيات
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // عبارة التسبيح الحالية - تصميم جديد مصغر
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: GestureDetector(
                    onTap: _incrementCounter,
                    child: Card(
                      elevation: 6, // تقليل الارتفاع
                      shadowColor: _tasbihList[_currentTasbihIndex]['color'].withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // تقليل انحناء الحواف
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10), // تقليل البطانة العمودية
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _tasbihList[_currentTasbihIndex]['color'],
                              _tasbihList[_currentTasbihIndex]['color'].withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // جعلها أصغر ما يمكن
                          children: [
                            // نص التسبيح
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12), // تقليل البطانة الأفقية
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // تقليل البطانة
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12), // تقليل انحناء الحواف
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1, // تقليل عرض الحدود
                                  ),
                                ),
                                child: Text(
                                  _currentTasbih,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16, // تقليل حجم الخط
                                    height: 1.4, // تقليل ارتفاع السطر
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 10), // تقليل المسافة
                            
                            // عداد
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // تقليل البطانة
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20), // تقليل انحناء الحواف
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4, // تقليل التمويه
                                        offset: const Offset(0, 2), // تقليل الإزاحة
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.timer,
                                        color: Colors.white,
                                        size: 14, // تقليل حجم الأيقونة
                                      ),
                                      SizedBox(width: 6), // تقليل المسافة
                                      Text(
                                        '$_counter / $_maxCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14, // تقليل حجم الخط
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4), // إضافة مسافة صغيرة في النهاية
                          ],
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
                      barWidth: 12.0,
                      startAngle: 0,
                      sweepAngle: 360,
                      strokeCap: StrokeCap.round,
                      progressGradientColors: [
                        _tasbihList[_currentTasbihIndex]['color'],
                        Color.lerp(_tasbihList[_currentTasbihIndex]['color'], Colors.white, 0.3)!,
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
                                        Color.lerp(_tasbihList[_currentTasbihIndex]['color'], Colors.white, 0.2)!,
                                      ],
                                      center: Alignment(0.2, 0.2),
                                      focal: Alignment(0.2, 0.2),
                                      focalRadius: 0.2,
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
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'اضغط للتسبيح',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
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
                
                // الأزرار
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildNewStyleButton(
                            icon: Icons.refresh,
                            title: 'إعادة ضبط',
                            color: Colors.red,
                            onPressed: _resetCounter,
                          ),
                          const SizedBox(width: 16),
                          _buildNewStyleButton(
                            icon: Icons.insights,
                            title: 'إحصائيات',
                            color: _primaryColor,
                            onPressed: _showStatistics,
                          ),
                          const SizedBox(width: 16),
                          _buildNewStyleButton(
                            icon: Icons.list,
                            title: 'قائمة الأذكار',
                            color: _accentColor,
                            onPressed: () => _showTasbihList(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // عرض قائمة التسبيحات بتصميم محسن
  void _showTasbihList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // مقبض السحب
            Container(
              width: 50,
              height: 6,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            
            // العنوان
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // تقليل البطانة
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accentColor,
                    _accentColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15), // تقليل انحناء الحواف
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 6, // تقليل التمويه
                    offset: Offset(0, 2), // تقليل الإزاحة
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.format_list_bulleted, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'اختر الذكر',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // قائمة التسبيحات
            Expanded(
              child: AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: _tasbihList.length,
                  itemBuilder: (context, index) {
                    final bool isSelected = index == _currentTasbihIndex;
                    final tasbih = _tasbihList[index];
                    
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 400),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12),
                            child: Card(
                              margin: EdgeInsets.zero,
                              elevation: isSelected ? 8 : 4,
                              shadowColor: tasbih['color'].withOpacity(isSelected ? 0.5 : 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: isSelected 
                                    ? BorderSide(color: tasbih['color'], width: 2)
                                    : BorderSide.none,
                              ),
                              child: InkWell(
                                onTap: () {
                                  _changeTasbih(index);
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: isSelected ? LinearGradient(
                                      colors: [
                                        tasbih['color'],
                                        tasbih['color'].withOpacity(0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ) : null,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // رقم الذكر في دائرة
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              tasbih['color'],
                                              tasbih['color'].withOpacity(0.7),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: tasbih['color'].withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            "${index + 1}",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      
                                      // تفاصيل الذكر
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // نص الذكر
                                            Text(
                                              tasbih['text'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.white : Colors.black87,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            
                                            // عدد المرات
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isSelected 
                                                    ? Colors.white.withOpacity(0.2)
                                                    : tasbih['color'].withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.repeat,
                                                    color: isSelected 
                                                        ? Colors.white
                                                        : tasbih['color'],
                                                    size: 14,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '${tasbih['count']} مرة',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: isSelected 
                                                          ? Colors.white
                                                          : tasbih['color'],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // أيقونة التحديد أو السهم
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? Colors.white.withOpacity(0.2)
                                              : tasbih['color'].withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            isSelected 
                                                ? Icons.check_circle
                                                : Icons.arrow_forward_ios,
                                            color: isSelected 
                                                ? Colors.white
                                                : tasbih['color'],
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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