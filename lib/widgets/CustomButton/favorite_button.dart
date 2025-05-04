import 'package:animated_react_button/animated_react_button.dart';
import 'package:flutter/material.dart';

class FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final bool isReacting;

  const FavoriteButton({
    Key? key,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.isReacting,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedReactButton(
          onPressed: onToggleFavorite,
          defaultColor: isFavorite ? Colors.red : const Color(0xFF447055),
          reactColor: !isFavorite ? Colors.red : const Color(0xFF447055),
        ),
        Visibility(
          visible: isReacting,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}