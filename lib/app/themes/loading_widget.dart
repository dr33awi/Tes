// lib/features/common/widgets/loading_widget.dart
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:athkar_app/app/themes/theme_constants.dart'; // Import theme constants

class LoadingWidget extends StatelessWidget {
  final Color color;
  final double size;
  
  const LoadingWidget({
    Key? key,
    this.color = ThemeColors.accentLight, // Changed default color
    this.size = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.inkDrop( // Using a different animation for a modern look
        color: color,
        size: size,
      ),
    );
  }
}