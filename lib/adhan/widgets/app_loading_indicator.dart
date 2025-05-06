// lib/common/widgets/app_loading_indicator.dart
import 'package:flutter/material.dart';


enum LoadingType {
  circle,
  threeBounce,
  wave,
  foldingCube,
  doubleBounce,
  wanderingCubes,
  pulsingGrid,
  staggeredDotsWave,
}

class AppLoadingIndicator extends StatelessWidget {
  final String? message;

  const AppLoadingIndicator({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            color: themeColor,
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
