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
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  
  // إحصائيات إضافية
  Map<int, int> _tasbihUsageCount = {};
  DateTime? _sessionStartTime;
  int _sessionCount = 0;
  int _streakDays = 0;
  DateTime? _lastUseDate;

  // ألوان جديدة للأزرار
  final Color _buttonColor1 = const Color(0xFF5C6BC0); // أزرق داكن
  final Color _buttonColor2 = const Color(0xFF7986CB); // أزرق فاتح

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
        backgroundColor: _buttonColor1,
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
                style: TextStyle(color: _buttonColor1),
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
            Icon(Icons.refresh, color: Colors.red),
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
                  backgroundColor: _buttonColor1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _buttonColor1,
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
        backgroundColor: _buttonColor1,
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
  
  // عرض الإحصائيات - نسخة مبسطة ومحسنة
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
              Padding(
                padding: EdgeInsets.all(16),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_buttonColor1, _buttonColor2],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insights, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'إحصائيات المسبحة',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      if (_streakDays > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.local_fire_department, color: Colors.amber, size: 20),
                              SizedBox(width: 4),
                              Text(
                                'تتابع التسبيح: $_streakDays يوم',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
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
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // إحصائيات عامة
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.analytics_outlined, color: _buttonColor1, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'إحصائيات عامة',
                                      style: TextStyle(
                                        color: _buttonColor1,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: 24),
                                
                                // إجمالي التسبيحات
                                _buildStatItem(
                                  icon: Icons.format_list_numbered,
                                  title: 'إجمالي التسبيحات',
                                  value: '$_totalCount',
                                  color: _buttonColor1,
                                ),
                                
                                SizedBox(height: 12),
                                
                                // تسبيحات الجلسة
                                _buildStatItem(
                                  icon: Icons.hourglass_top,
                                  title: 'تسبيحات الجلسة الحالية',
                                  value: '$_sessionCount',
                                  color: Colors.orangeAccent,
                                ),
                                
                                SizedBox(height: 12),
                                
                                // وقت الجلسة
                                _buildStatItem(
                                  icon: Icons.timer,
                                  title: 'وقت الجلسة',
                                  value: _getSessionDuration(),
                                  color: Colors.green,
                                ),
                                
                                if (averageSpeed > 0) ... [
                                  SizedBox(height: 12),
                                  
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
                        
                        SizedBox(height: 16),
                        
                        // الذكر الحالي
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          color: _tasbihList[_currentTasbihIndex]['color'].withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _tasbihList[_currentTasbihIndex]['icon'],
                                      color: _tasbihList[_currentTasbihIndex]['color'],
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'الذكر الحالي',
                                        style: TextStyle(
                                          color: _tasbihList[_currentTasbihIndex]['color'],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _tasbihList[_currentTasbihIndex]['color'].withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _currentTasbih,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _tasbihList[_currentTasbihIndex]['color'],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        if (mostUsedTasbih != null) ...[
                          SizedBox(height: 16),
                          
                          // الذكر الأكثر استخداماً
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.emoji_events, color: mostUsedTasbih['color'], size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'الذكر الأكثر استخداماً',
                                        style: TextStyle(
                                          color: mostUsedTasbih['color'],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(height: 24),
                                  
                                  // محتوى الذكر الأكثر استخداماً
                                  Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: mostUsedTasbih['color'].withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          mostUsedTasbih['icon'],
                                          color: mostUsedTasbih['color'],
                                          size: 24,
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
                                            SizedBox(height: 4),
                                            Text(
                                              'المرات: ${_tasbihUsageCount[_tasbihList.indexOf(mostUsedTasbih)] ?? 0}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
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
                      ],
                    ),
                  ),
                ),
              ),
              
              // زر الإغلاق
              Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.check),
                    label: Text('إغلاق'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonColor1,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
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
                  fontSize: 14,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
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
              fontSize: 16,
              color: color,
            ),
          ),
      ],
    );
  }
  
  // بناء زر متناسق مع quote_details_screen
  Widget _buildMatchingStyleButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          // تعديل للتوافق مع جميع الشاشات - تقليل العرض
          width: MediaQuery.of(context).size.width * 0.25,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
              stops: const [0.3, 1.0],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة دائرية
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              // عنوان الزر
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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
    final double seekBarSize = size.width * 0.7; // تقليل الحجم قليلاً
    
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
            color: _buttonColor1,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _buttonColor1,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _vibrationEnabled ? Icons.vibration : Icons.do_not_disturb,
              color: _buttonColor1,
            ),
            onPressed: _toggleVibration,
            tooltip: _vibrationEnabled ? 'إيقاف الاهتزاز' : 'تفعيل الاهتزاز',
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: _buttonColor1,
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
                          colors: [_buttonColor1, _buttonColor2],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: _buttonColor1.withOpacity(0.3),
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
                            Color.lerp(_tasbihList[_currentTasbihIndex]['color'], Colors.white, 0.3)!,
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
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _currentTasbih,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
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
                                    fontSize: 14,
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
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '$_maxCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
                                            fontSize: 50, // تعديل حجم الخط
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
                
                // الأزرار
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMatchingStyleButton(
                            icon: Icons.refresh,
                            title: 'إعادة ضبط',
                            color: Colors.red,
                            onPressed: _resetCounter,
                          ),
                          const SizedBox(width: 12),
                          _buildMatchingStyleButton(
                            icon: Icons.insights,
                            title: 'إحصائيات',
                            color: _buttonColor1,
                            onPressed: _showStatistics,
                          ),
                          const SizedBox(width: 12),
                          _buildMatchingStyleButton(
                            icon: Icons.list,
                            title: 'قائمة الأذكار',
                            color: Colors.purple,
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
            
            // العنوان
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple, // لون بنفسجي متناسق مع زر قائمة الأذكار
                    Colors.purpleAccent,
                  ],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.format_list_bulleted, color: Colors.white),
                  SizedBox(width: 8),
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
                            child: InkWell(
                              onTap: () {
                                _changeTasbih(index);
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            tasbih['color'],
                                            Color.lerp(tasbih['color'], Colors.white, 0.3)!,
                                          ],
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: tasbih['color'].withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: isSelected 
                                            ? Icon(Icons.check, color: Colors.white, size: 22)
                                            : Icon(tasbih['icon'], color: Colors.white, size: 22),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tasbih['text'],
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? tasbih['color'] : Colors.black87,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? tasbih['color'].withOpacity(0.1) : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.repeat,
                                                      size: 14,
                                                      color: isSelected ? tasbih['color'] : Colors.grey,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '${tasbih['count']} مرة',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isSelected ? tasbih['color'] : Colors.grey,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                                    // سهم الانتقال
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? tasbih['color'].withOpacity(0.1) 
                                            : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isSelected 
                                              ? Icons.radio_button_checked 
                                              : Icons.arrow_forward_ios,
                                          color: isSelected ? tasbih['color'] : Colors.grey,
                                          size: 14,
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