import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
    return Center(
      child: SpinKitDoubleBounce(
        color: color,
        size: size,
      ),
    );
  }
}