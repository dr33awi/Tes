// lib/presentation/screens/home/widgets/athkar_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/athkar.dart';
import '../../../blocs/athkar/athkar_provider.dart';
import '../../../widgets/common/loading_widget.dart';

class AthkarSection extends StatelessWidget {
  const AthkarSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الأذكار',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.athkarCategories);
                  },
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            const Divider(),
            Consumer<AthkarProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: LoadingWidget()),
                  );
                }

                if (provider.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'حدث خطأ في تحميل الأذكار',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                final categories = provider.categories;
                if (categories == null || categories.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('لا توجد أذكار متاحة'),
                    ),
                  );
                }

                return _buildFeaturedCategories(context, categories);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCategories(BuildContext context, List<AthkarCategory> categories) {
    // اختيار عدة فئات مهمة للعرض في الشاشة الرئيسية
    final featuredCategories = categories.where((category) => 
      [
        AppConstants.morningAthkarCategory,
        AppConstants.eveningAthkarCategory,
        AppConstants.sleepAthkarCategory,
      ].contains(category.id)
    ).toList();

    if (featuredCategories.isEmpty) {
      featuredCategories.addAll(categories.take(3));
    }

    return Column(
      children: featuredCategories.map((category) => 
        _buildCategoryButton(context, category)
      ).toList(),
    );
  }

  Widget _buildCategoryButton(BuildContext context, AthkarCategory category) {
    return ListTile(
      title: Text(
        category.name,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: category.description != null 
          ? Text(
              category.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ) 
          : null,
      leading: Icon(
        _getCategoryIcon(category.id),
        color: Theme.of(context).primaryColor,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.athkarDetails,
          arguments: {
            'categoryId': category.id,
            'categoryName': category.name,
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return Icons.wb_sunny;
      case 'evening':
        return Icons.nights_stay;
      case 'sleep':
        return Icons.nightlight_round;
      case 'wakeup':
        return Icons.alarm;
      case 'prayer':
        return Icons.mosque;
      default:
        return Icons.auto_awesome;
    }
  }
}