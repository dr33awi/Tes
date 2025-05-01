import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;

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
    {'text': 'سبحان الله', 'count': 33},
    {'text': 'الحمد لله', 'count': 33},
    {'text': 'الله أكبر', 'count': 33},
    {'text': 'لا إله إلا الله', 'count': 100},
    {'text': 'لا حول ولا قوة إلا بالله', 'count': 100},
    {'text': 'أستغفر الله', 'count': 100},
    {'text': 'اللهم صل على محمد', 'count': 100},
  ];

  // الفهرس الحالي لعبارة التسبيح
  int _currentTasbihIndex = 0;

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
              });
              _saveTasbihState();
              Navigator.pop(context);
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
    });
    _saveTasbihState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              // شريط العنوان
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: kPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'المسبحة الإلكترونية',
                          style: TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              // إجمالي العدد
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: kPrimary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.equalizer, color: kPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'الإجمالي: $_totalCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // عبارة التسبيح الحالية
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 500),
                  child: FadeInAnimation(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kPrimary, kPrimaryLight],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _currentTasbih,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$_counter / $_maxCount',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // زر العداد
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _animationController.forward().then((_) {
                        _animationController.reverse();
                      });
                      _incrementCounter();
                    },
                    child: ScaleTransition(
                      scale: _animation,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [kPrimary, kPrimaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$_counter',
                            style: const TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // شريط أدوات في الأسفل
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _resetCounter,
                      icon: const Icon(Icons.refresh, color: kPrimary),
                      tooltip: 'إعادة ضبط',
                    ),
                    IconButton(
                      onPressed: () => _showTasbihList(context),
                      icon: const Icon(Icons.list, color: kPrimary),
                      tooltip: 'قائمة التسبيحات',
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
              color: Colors.black.withOpacity(0.1),
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
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'اختر التسبيح',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
            ),
            Flexible(
              child: AnimationLimiter(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _tasbihList.length,
                  itemBuilder: (context, index) {
                    final bool isSelected = index == _currentTasbihIndex;
                    
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 300),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: ListTile(
                            title: Text(
                              _tasbihList[index]['text'],
                              style: TextStyle(
                                color: isSelected ? kPrimary : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              'العدد: ${_tasbihList[index]['count']}',
                              style: TextStyle(
                                color: isSelected ? kPrimary.withOpacity(0.7) : Colors.black54,
                              ),
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected ? kPrimary : kPrimary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: isSelected ? Colors.white : Colors.transparent,
                                size: 20,
                              ),
                            ),
                            onTap: () {
                              _changeTasbih(index);
                              Navigator.pop(context);
                            },
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