// lib/presentation/widgets/common/loading_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).primaryColor;
    
    return Center(
      child: SpinKitDoubleBounce(
        color: themeColor,
        size: size,
      ),
    );
  }
}