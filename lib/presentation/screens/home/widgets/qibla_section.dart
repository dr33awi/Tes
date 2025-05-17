// lib/presentation/screens/home/widgets/qibla_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_router.dart';
import '../../../blocs/prayers/prayer_times_provider.dart';
import '../../../widgets/common/loading_widget.dart';

class QiblaSection extends StatelessWidget {
  const QiblaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Consumer<PrayerTimesProvider>(
        builder: (context, provider, child) {
          return InkWell(
            onTap: () {
              Navigator.pushNamed(context, AppRouter.qibla);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: provider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.explore,
                              color: Theme.of(context).primaryColor,
                              size: 32,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اتجاه القبلة',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        if (provider.qiblaDirection != null)
                          Text(
                            'اتجاه القبلة: ${provider.qiblaDirection!.toStringAsFixed(1)}°',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        else
                          Text(
                            'اضغط لتحديد اتجاه القبلة',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}