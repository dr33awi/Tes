// lib/screens/athkar_details_screen/athkar_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight, kSurface;
import 'package:test_athkar_app/screens/athkarscreen/athkar_service.dart';

class AthkarDetailsScreen extends StatefulWidget {
  final AthkarCategory category;

  const AthkarDetailsScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<AthkarDetailsScreen> createState() => _AthkarDetailsScreenState();
}

class _AthkarDetailsScreenState extends State<AthkarDetailsScreen> {
  final AthkarService _athkarService = AthkarService();
  
  // حالة المفضلة وعدادات الأذكار
  final Map<int, bool> _favorites = {};
  final Map<int, int> _counters = {};
  
  @override
  void initState() {
    super.initState();
    _loadThikrState();
  }
  
  // تحميل حالة كل ذكر (المفضلة والعدادات)
  Future<void> _loadThikrState() async {
    for (int i = 0; i < widget.category.athkar.length; i++) {
      final isFav = await _athkarService.isFavorite(widget.category.id, i);
      final count = await _athkarService.getThikrCount(widget.category.id, i);
      
      if (mounted) {
        setState(() {
          _favorites[i] = isFav;
          _counters[i] = count;
        });
      }
    }
  }
  
  // تبديل حالة المفضلة
  Future<void> _toggleFavorite(int index) async {
    await _athkarService.toggleFavorite(widget.category.id, index);
    setState(() {
      _favorites[index] = !(_favorites[index] ?? false);
    });
    
    // إظهار رسالة للمستخدم
    if (_favorites[index] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت الإضافة إلى المفضلة'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
        ),
      );
    }
  }
  
  // زيادة عداد الذكر
  Future<void> _incrementCounter(int index) async {
    final thikr = widget.category.athkar[index];
    int currentCount = _counters[index] ?? 0;
    
    if (currentCount < thikr.count) {
      currentCount++;
      setState(() {
        _counters[index] = currentCount;
      });
      await _athkarService.updateThikrCount(widget.category.id, index, currentCount);
    }
    
    // إذا اكتمل العدد المطلوب
    if (currentCount >= thikr.count) {
      // إظهار رسالة التهنئة
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أحسنت! اكتمل عدد مرات الذكر'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
        ),
      );
      
      // اهتزاز خفيف (للإشعار)
      HapticFeedback.mediumImpact();
    } else {
      // اهتزاز خفيف جدًا لكل نقرة
      HapticFeedback.lightImpact();
    }
  }
  
  // إعادة تعيين العداد
  Future<void> _resetCounter(int index) async {
    setState(() {
      _counters[index] = 0;
    });
    await _athkarService.updateThikrCount(widget.category.id, index, 0);
  }
  
  // مشاركة الذكر
  void _shareThikr(Thikr thikr) async {
    String text = thikr.text;
    
    if (thikr.fadl != null) {
      text += '\n\n${thikr.fadl}';
    }
    
    if (thikr.source != null) {
      text += '\n\nالمصدر: ${thikr.source}';
    }
    
    await Share.share(text, subject: 'ذكر من تطبيق الأذكار');
  }
  
  // نسخ الذكر
  void _copyThikr(Thikr thikr) {
    String text = thikr.text;
    
    if (thikr.fadl != null) {
      text += '\n\n${thikr.fadl}';
    }
    
    if (thikr.source != null) {
      text += '\n\nالمصدر: ${thikr.source}';
    }
    
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ الذكر إلى الحافظة'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
        ),
      );
    });
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
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.category.title,
                          style: const TextStyle(
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
              
              // وصف الفئة (إذا كان موجودًا)
              if (widget.category.description != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kPrimary.withOpacity(0.3)),
                    ),
                    child: Text(
                      widget.category.description!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kPrimary.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              // قائمة الأذكار
              Expanded(
                child: AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.category.athkar.length,
                    itemBuilder: (context, index) {
                      final thikr = widget.category.athkar[index];
                      final isFavorite = _favorites[index] ?? false;
                      final counter = _counters[index] ?? 0;
                      final isCompleted = counter >= thikr.count;
                      
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: isCompleted 
                                    ? BorderSide(color: kPrimary.withOpacity(0.3), width: 2)
                                    : BorderSide.none,
                              ),
                              child: InkWell(
                                onTap: () => _incrementCounter(index),
                                borderRadius: BorderRadius.circular(20),
                                child: Column(
                                  children: [
                                    // رأس البطاقة
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            widget.category.color,
                                            widget.category.color.withOpacity(0.8),
                                          ],
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(20),
                                          topLeft: Radius.circular(20),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          if (thikr.source != null)
                                            Expanded(
                                              child: Text(
                                                'المصدر: ${thikr.source}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.3),
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                child: Text(
                                                  '$counter / ${thikr.count}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // محتوى الذكر
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        thikr.text,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          height: 1.8,
                                          color: isCompleted
                                              ? kPrimary
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    
                                    // فضل الذكر (إذا كان موجودًا)
                                    if (thikr.fadl != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: widget.category.color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: widget.category.color.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            thikr.fadl!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                              color: widget.category.color.withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    
                                    // شريط الأدوات
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFavorite
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                            onPressed: () => _toggleFavorite(index),
                                            tooltip: 'إضافة للمفضلة',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.refresh,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () => _resetCounter(index),
                                            tooltip: 'إعادة ضبط العداد',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.copy,
                                              color: Colors.green,
                                            ),
                                            onPressed: () => _copyThikr(thikr),
                                            tooltip: 'نسخ الذكر',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.share,
                                              color: Colors.orange,
                                            ),
                                            onPressed: () => _shareThikr(thikr),
                                            tooltip: 'مشاركة الذكر',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }
}
