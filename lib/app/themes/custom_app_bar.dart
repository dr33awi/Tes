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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: transparent ? Colors.transparent : backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      elevation: transparent ? 0 : elevation,
      systemOverlayStyle: systemOverlayStyle ?? Theme.of(context).appBarTheme.systemOverlayStyle,
    );
  }
}