// lib/features/common/widgets/loading_widget.dart
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingWidget extends StatelessWidget {
  final Color color;
  final double size;
  
  const LoadingWidget({
    Key? key,
    this.color = Colors.blue,
    this.size = 50.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // استخدام لون مخصص إذا تم تمريره، وإلا استخدام لون التطبيق الأساسي
    final Color loadingColor = color == Colors.blue 
        ? Theme.of(context).primaryColor
        : color;
    
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: loadingColor,
        size: size,
      ),
    );
  }
}