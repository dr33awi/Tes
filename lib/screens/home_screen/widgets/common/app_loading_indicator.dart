// lib/widgets/common/app_loading_indicator.dart
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight;

/// مكون مؤشر التحميل الموحد للتطبيق
class AppLoadingIndicator extends StatelessWidget {
  /// الرسالة التي تظهر أسفل مؤشر التحميل
  final String message;
  
  /// حجم مؤشر التحميل
  final double size;
  
  /// لون مؤشر التحميل
  final Color color;
  
  /// نوع مؤشر التحميل
  final LoadingType loadingType;
  
  /// إذا كان مؤشر التحميل يظهر داخل بطاقة
  final bool useCard;
  
  /// ارتفاع البطاقة
  final double? cardHeight;

  const AppLoadingIndicator({
    Key? key,
    this.message = 'جاري التحميل...',
    this.size = 50,
    this.color = kPrimary,
    this.loadingType = LoadingType.staggeredDotsWave,
    this.useCard = false,
    this.cardHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget loadingContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAnimation(),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            color: useCard ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
    
    if (useCard) {
      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          height: cardHeight ?? 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [kPrimary, kPrimaryLight],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              stops: const [0.3, 1.0],
            ),
          ),
          child: Center(child: loadingContent),
        ),
      );
    }
    
    return Center(child: loadingContent);
  }

  /// بناء الرسوم المتحركة المناسبة حسب النوع المطلوب
  Widget _buildAnimation() {
    switch (loadingType) {
      case LoadingType.staggeredDotsWave:
        return LoadingAnimationWidget.staggeredDotsWave(
          color: useCard ? Colors.white : color,
          size: size,
        );
      case LoadingType.fourRotatingDots:
        return LoadingAnimationWidget.fourRotatingDots(
          color: useCard ? Colors.white : color,
          size: size,
        );
      case LoadingType.inkDrop:
        return LoadingAnimationWidget.inkDrop(
          color: useCard ? Colors.white : color,
          size: size,
        );
      case LoadingType.newtonCradle:
        return LoadingAnimationWidget.newtonCradle(
          color: useCard ? Colors.white : color,
          size: size,
        );
      case LoadingType.waveDots:
        return LoadingAnimationWidget.waveDots(
          color: useCard ? Colors.white : color,
          size: size,
        );
      case LoadingType.threeArchedCircle:
        return LoadingAnimationWidget.threeArchedCircle(
          color: useCard ? Colors.white : color,
          size: size,
        );
      case LoadingType.bouncingBall:
        return LoadingAnimationWidget.bouncingBall(
          color: useCard ? Colors.white : color,
          size: size,
        );
      case LoadingType.horizontalRotatingDots:
        return LoadingAnimationWidget.horizontalRotatingDots(
          color: useCard ? Colors.white : color,
          size: size,
        );
      case LoadingType.beat:
        return LoadingAnimationWidget.beat(
          color: useCard ? Colors.white : color,
          size: size,
        );
      default:
        return LoadingAnimationWidget.staggeredDotsWave(
          color: useCard ? Colors.white : color,
          size: size,
        );
    }
  }
}

/// أنواع مؤشرات التحميل المتاحة
enum LoadingType {
  staggeredDotsWave,    // نقاط متموجة متدرجة
  fourRotatingDots,     // أربع نقاط دوارة
  inkDrop,              // قطرة حبر
  newtonCradle,         // مهد نيوتن
  waveDots,             // نقاط متموجة
  threeArchedCircle,    // ثلاث أقواس دائرية
  bouncingBall,         // كرة قافزة
  horizontalRotatingDots, // نقاط دوارة أفقية
  beat,                 // نبضات
}