// lib/app/widgets/fadl_dialog.dart
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class FadlDialog extends StatelessWidget {
  final String? fadl;
  final String? source;
  final Color accentColor;
  final String title;
  final String closeButtonText;

  const FadlDialog({
    Key? key,
    required this.fadl,
    this.source,
    required this.accentColor,
    this.title = 'فضل الذكر',
    this.closeButtonText = 'إغلاق',
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String? fadl,
    String? source,
    required Color accentColor,
    String title = 'فضل الذكر',
    String closeButtonText = 'إغلاق',
  }) {
    // تأثير اهتزاز خفيف
    HapticFeedback.lightImpact();
    
    return showDialog(
      context: context,
      builder: (context) => FadlDialog(
        fadl: fadl,
        source: source,
        accentColor: accentColor,
        title: title,
        closeButtonText: closeButtonText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: accentColor),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fadl != null)
            Text(
              fadl!,
              style: const TextStyle(
                height: 1.6,
                fontSize: 16,
              ),
            ),
          if (source != null) ...[
            const SizedBox(height: ThemeSizes.marginMedium),
            _buildSourceContainer(),
          ],
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusLarge),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            closeButtonText,
            style: TextStyle(color: accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSizes.marginMedium,
        vertical: ThemeSizes.marginSmall,
      ),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
      ),
      child: Text(
        'المصدر: $source',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: accentColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}