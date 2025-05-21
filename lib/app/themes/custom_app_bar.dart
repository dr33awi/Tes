// lib/features/widgets/common/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final bool transparent; // Hinzugefügter Parameter
  final double elevation;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.transparent = false, // Standard: nicht transparent
    this.elevation = 0,
    this.systemOverlayStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
      elevation: elevation,
      backgroundColor: transparent 
          ? Colors.transparent 
          : (backgroundColor ?? Theme.of(context).primaryColor),
      systemOverlayStyle: systemOverlayStyle ?? 
        (transparent
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle(
              statusBarColor: backgroundColor ?? Theme.of(context).primaryColor,
              statusBarIconBrightness: Brightness.light,
            )),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}