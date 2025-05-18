// lib/presentation/screens/prayers/prayer_times_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../../domain/usecases/get_prayer_times.dart';
import '../../../../core/services/interfaces/prayer_times_service.dart';
import '../../../settings/domain/entities/settings.dart';
import '../../domain/entities/prayer_times.dart';
import '../providers/prayer_times_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/custom_app_bar.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({Key? key}) : super(key: key);
  
  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }
  
  void _loadPrayerTimes() {
    // تأكد من تحميل مواقيت الصلاة إذا لم تكن قد حُملت بعد
    final prayerProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    if (!prayerProvider.hasLocation) {
      // تعيين موقع افتراضي مؤقت (مكة المكرمة)
      prayerProvider.setLocation(
        latitude: 21.422510,
        longitude: 39.826168,
      );
    }
    
    if (prayerProvider.todayPrayerTimes == null && settingsProvider.settings != null) {
      prayerProvider.loadTodayPrayerTimes(settingsProvider.settings!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'أوقات الصلاة'),
      body: Consumer2<PrayerTimesProvider, SettingsProvider>(
        builder: (context, prayerProvider, settingsProvider, _) {
          if (prayerProvider.isLoading) {
            return const LoadingWidget();
          } else if (prayerProvider.hasError) {
            return Center(
              child: Text(
                'حدث خطأ: ${prayerProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (prayerProvider.todayPrayerTimes != null) {
            return _buildPrayerTimesList(context, prayerProvider.todayPrayerTimes!);
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('لا توجد بيانات متاحة'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (settingsProvider.settings != null) {
                        prayerProvider.loadTodayPrayerTimes(settingsProvider.settings!);
                      }
                    },
                    child: const Text('تحميل مواقيت الصلاة'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
  
  Widget _buildPrayerTimesList(BuildContext context, PrayerTimes prayerTimes) {
    final timeFormat = DateFormat.jm();
    final now = DateTime.now();
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildPrayerTimeCard('الفجر', prayerTimes.fajr, timeFormat, now),
        _buildPrayerTimeCard('الشروق', prayerTimes.sunrise, timeFormat, now),
        _buildPrayerTimeCard('الظهر', prayerTimes.dhuhr, timeFormat, now),
        _buildPrayerTimeCard('العصر', prayerTimes.asr, timeFormat, now),
        _buildPrayerTimeCard('المغرب', prayerTimes.maghrib, timeFormat, now),
        _buildPrayerTimeCard('العشاء', prayerTimes.isha, timeFormat, now),
      ],
    );
  }
  
  Widget _buildPrayerTimeCard(String prayerName, DateTime prayerTime, DateFormat formatter, DateTime now) {
    final bool isCurrentPrayer = _isCurrentPrayer(prayerTime, now);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: isCurrentPrayer ? 4 : 1,
      color: isCurrentPrayer ? Colors.blue.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              prayerName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isCurrentPrayer ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              formatter.format(prayerTime),
              style: TextStyle(
                fontSize: 18,
                fontWeight: isCurrentPrayer ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  bool _isCurrentPrayer(DateTime prayerTime, DateTime now) {
    // يمكن تحسين هذا المنطق لتحديد الصلاة الحالية بدقة أكبر
    final diff = now.difference(prayerTime).inMinutes.abs();
    return diff < 30; // اعتبر الصلاة حالية إذا كانت خلال 30 دقيقة من الوقت الحالي
  }
}