// lib/presentation/screens/home/widgets/prayer_times_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart' as adhan; // استيراد مكتبة أذان مع تحديد مساحة الاسم
import '../../../../app/routes/app_router.dart';
import '../../../../core/services/interfaces/prayer_times_service.dart';
import '../providers/prayer_times_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../app/themes/loading_widget.dart';

class PrayerTimesSection extends StatelessWidget {
  const PrayerTimesSection({super.key});

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
                  'مواقيت الصلاة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.prayerTimes);
                  },
                  child: const Text('التفاصيل'),
                ),
              ],
            ),
            const Divider(),
            Consumer2<PrayerTimesProvider, SettingsProvider>(
              builder: (context, prayerProvider, settingsProvider, child) {
                if (prayerProvider.isLoading) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: LoadingWidget()),
                  );
                }

                if (!prayerProvider.hasLocation) {
                  return _buildLocationRequest(context, prayerProvider, settingsProvider);
                }

                if (prayerProvider.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'حدث خطأ في تحميل مواقيت الصلاة',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (settingsProvider.settings != null) {
                                prayerProvider.refreshData(settingsProvider.settings!);
                              }
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (prayerProvider.todayPrayerTimes == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (settingsProvider.settings != null) {
                            prayerProvider.loadTodayPrayerTimes(settingsProvider.settings!);
                          }
                        },
                        child: const Text('تحميل مواقيت الصلاة'),
                      ),
                    ),
                  );
                }

                return _buildPrayerTimes(context, prayerProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRequest(
    BuildContext context, 
    PrayerTimesProvider prayerProvider,
    SettingsProvider settingsProvider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.location_off,
              size: 40,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى السماح بالوصول إلى الموقع لتحميل مواقيت الصلاة',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // تعيين موقع افتراضي مؤقت (في التطبيق الحقيقي سيتم استخدام موقع المستخدم)
                prayerProvider.setLocation(
                  latitude: 21.422510,
                  longitude: 39.826168,
                );
                
                if (settingsProvider.settings != null) {
                  await prayerProvider.loadTodayPrayerTimes(settingsProvider.settings!);
                }
              },
              child: const Text('استخدام موقع افتراضي'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimes(BuildContext context, PrayerTimesProvider provider) {
    final prayerTimes = provider.todayPrayerTimes!;
    // استخدام مكتبة أذان للصلاة الحالية والتالية
    final adhan.Prayer currentPrayer = prayerTimes.getCurrentPrayer();
    final adhan.Prayer nextPrayer = prayerTimes.getNextPrayer();
    
    return Column(
      children: [
        // عرض الصلاة التالية
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                'الصلاة التالية',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _getPrayerName(nextPrayer),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(prayerTimes.getTimeForPrayer(nextPrayer)),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildRemainingTime(prayerTimes.getTimeForPrayer(nextPrayer)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // عرض أوقات الصلوات
        Row(
          children: [
            _buildPrayerTimeItem(
              context, 
              'الفجر', 
              prayerTimes.fajr, 
              currentPrayer == adhan.Prayer.fajr
            ),
            _buildPrayerTimeItem(
              context, 
              'الظهر', 
              prayerTimes.dhuhr, 
              currentPrayer == adhan.Prayer.dhuhr
            ),
            _buildPrayerTimeItem(
              context, 
              'العصر', 
              prayerTimes.asr, 
              currentPrayer == adhan.Prayer.asr
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPrayerTimeItem(
              context, 
              'المغرب', 
              prayerTimes.maghrib, 
              currentPrayer == adhan.Prayer.maghrib
            ),
            _buildPrayerTimeItem(
              context, 
              'العشاء', 
              prayerTimes.isha, 
              currentPrayer == adhan.Prayer.isha
            ),
            _buildPrayerTimeItem(
              context, 
              'الشروق', 
              prayerTimes.sunrise, 
              false
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPrayerTimeItem(
    BuildContext context, 
    String name, 
    DateTime time, 
    bool isCurrent
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isCurrent ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: isCurrent 
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCurrent ? Theme.of(context).primaryColor : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isCurrent ? Theme.of(context).primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRemainingTime(DateTime prayerTime) {
    final now = DateTime.now();
    final remaining = prayerTime.difference(now);
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    if (hours <= 0 && minutes <= 0) {
      return const Text('حان وقت الصلاة');
    }
    
    String remainingText = '';
    if (hours > 0) {
      remainingText += '$hours ساعة';
      if (minutes > 0) {
        remainingText += ' و ';
      }
    }
    
    if (minutes > 0) {
      remainingText += '$minutes دقيقة';
    }
    
    return Text(
      'متبقي $remainingText',
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
  
  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }
  
  // تحويل نوع الصلاة إلى اسم مقروء
  String _getPrayerName(adhan.Prayer prayer) {
    switch (prayer) {
      case adhan.Prayer.fajr:
        return 'الفجر';
      case adhan.Prayer.sunrise:
        return 'الشروق';
      case adhan.Prayer.dhuhr:
        return 'الظهر';
      case adhan.Prayer.asr:
        return 'العصر';
      case adhan.Prayer.maghrib:
        return 'المغرب';
      case adhan.Prayer.isha:
        return 'العشاء';
      default:
        return '';
    }
  }
}