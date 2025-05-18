// lib/presentation/screens/athkar/athkar_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/athkar.dart';
import '../providers/athkar_provider.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/loading_widget.dart';

class AthkarDetailsScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const AthkarDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    // تحميل الأذكار حسب الفئة عند بناء الشاشة
    final provider = Provider.of<AthkarProvider>(context, listen: false);
    provider.loadAthkarByCategory(categoryId);

    return Scaffold(
      appBar: CustomAppBar(title: categoryName),
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
                    'حدث خطأ أثناء تحميل الأذكار',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadAthkarByCategory(categoryId),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }
          
          final athkarList = provider.getAthkarForCategory(categoryId);
          
          if (athkarList == null || athkarList.isEmpty) {
            return Center(
              child: Text(
                'لا توجد أذكار متاحة في هذه الفئة',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          
          return _buildAthkarList(context, athkarList);
        },
      ),
    );
  }

  Widget _buildAthkarList(BuildContext context, List<Athkar> athkarList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: athkarList.length,
      itemBuilder: (context, index) {
        final athkar = athkarList[index];
        return _buildAthkarCard(context, athkar);
      },
    );
  }

  Widget _buildAthkarCard(BuildContext context, Athkar athkar) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان الذكر
            if (athkar.title.isNotEmpty) ...[
              Text(
                athkar.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
            ],
            
            // محتوى الذكر
            SelectableText(
              athkar.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            
            const SizedBox(height: 12),
            
            // عدد مرات التكرار
            if (athkar.count > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'عدد المرات: ${athkar.count}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
            
            // فضل الذكر
            if (athkar.fadl != null && athkar.fadl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              Text(
                'الفضل:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                athkar.fadl!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            
            // المصدر
            if (athkar.source != null && athkar.source!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'المصدر: ${athkar.source}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            
            const SizedBox(height: 16),
            
            // أزرار التفاعل
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.copy,
                  label: 'نسخ',
                  onTap: () => _copyAthkar(context, athkar),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.share,
                  label: 'مشاركة',
                  onTap: () => _shareAthkar(athkar),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // نسخ الذكر إلى الحافظة
  void _copyAthkar(BuildContext context, Athkar athkar) {
    final String content = athkar.content;
    Clipboard.setData(ClipboardData(text: content)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ الذكر إلى الحافظة'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  // مشاركة الذكر
  void _shareAthkar(Athkar athkar) {
    final String title = athkar.title.isNotEmpty ? athkar.title : 'ذكر';
    final String content = athkar.content;
    final String count = athkar.count > 1 ? 'عدد المرات: ${athkar.count}' : '';
    
    String shareText = '$title\n\n$content';
    if (count.isNotEmpty) {
      shareText += '\n\n$count';
    }
    
    if (athkar.source != null && athkar.source!.isNotEmpty) {
      shareText += '\n\nالمصدر: ${athkar.source}';
    }
    
    shareText += '\n\nمشاركة من تطبيق الأذكار';
    
    Share.share(shareText);
  }
}