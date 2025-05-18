// lib/presentation/screens/athkar/athkar_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/athkar.dart';
import '../providers/athkar_provider.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/loading_widget.dart';

class AthkarCategoriesScreen extends StatelessWidget {
  const AthkarCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'الأذكار'),
      body: Consumer<AthkarProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingWidget();
          }
          
          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'حدث خطأ أثناء تحميل البيانات',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshData(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }
          
          final categories = provider.categories;
          
          if (categories == null || categories.isEmpty) {
            return Center(
              child: Text(
                'لا توجد فئات أذكار متاحة',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          
          return _buildCategoriesList(context, categories);
        },
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context, List<AthkarCategory> categories) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(context, category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, AthkarCategory category) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة الفئة
              Icon(
                _getCategoryIcon(category.id),
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              // اسم الفئة
              Text(
                category.name,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              // وصف الفئة (إذا وجد)
              if (category.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  category.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // تحديد أيقونة مناسبة لكل فئة
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
      case 'quran':
        return Icons.menu_book;
      case 'travel':
        return Icons.luggage;
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.auto_awesome;
    }
  }
}