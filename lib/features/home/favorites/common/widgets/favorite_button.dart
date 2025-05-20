// lib/features/common/widgets/favorite_button.dart
import 'package:athkar_app/app/routes/app_router.dart';
import 'package:flutter/material.dart';
import '../../../models/daily_quote_model.dart';

class FavoriteButton extends StatelessWidget {
  final String quote;
  final String source;
  final String headerTitle;
  final IconData headerIcon;
  final Color? color;
  final double size;

  const FavoriteButton({
    Key? key,
    required this.quote,
    required this.source,
    required this.headerTitle,
    this.headerIcon = Icons.format_quote,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.favorite_border,
        color: color ?? Theme.of(context).primaryColor,
        size: size,
      ),
      tooltip: 'إضافة إلى المفضلة',
      onPressed: () {
        final highlightItem = HighlightItem(
          quote: quote,
          source: source,
          headerTitle: headerTitle,
          headerIcon: headerIcon,
        );
        
        // عرض رسالة تأكيد
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.favorite, color: Colors.white),
                SizedBox(width: 12),
                Text('تم إضافة الاقتباس إلى المفضلة'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'عرض',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.favorites,
                  arguments: highlightItem,
                );
              },
            ),
          ),
        );
        
        // الانتقال إلى صفحة المفضلة
        Navigator.pushNamed(
          context,
          AppRouter.favorites,
          arguments: highlightItem,
        );
      },
    );
  }
}