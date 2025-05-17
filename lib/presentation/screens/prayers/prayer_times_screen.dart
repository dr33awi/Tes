import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../../domain/usecases/prayers/get_prayer_times.dart';
import '../../../core/services/interfaces/prayer_times_service.dart';
import '../../widgets/common/loading_widget.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({Key? key}) : super(key: key);
  
  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late Future<PrayerData> _prayerTimesFuture;
  final GetPrayerTimes _getPrayerTimes = GetPrayerTimes(); // يمكن استخدام حقن التبعية Get_it بدلاً من هذا
  
  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }
  
  void _loadPrayerTimes() {
    // استخدم مواقع افتراضية أو احصل عليها من خدمة الموقع
    const double latitude = 24.7136; // مثال: الرياض
    const double longitude = 46.6753;
    
    _prayerTimesFuture = _getPrayerTimes.getTodayPrayerTimes(
      PrayerTimesCalculationParams(
        calculationMethod: 'muslim_world_league',
      ),
      latitude: latitude,
      longitude: longitude,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أوقات الصلاة'),
        centerTitle: true,
      ),
      body: FutureBuilder<PrayerData>(
        future: _prayerTimesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData) {
            final prayerTimes = snapshot.data!;
            return _buildPrayerTimesList(prayerTimes);
          } else {
            return const Center(
              child: Text('لا توجد بيانات متاحة'),
            );
          }
        },
      ),
    );
  }
  
  Widget _buildPrayerTimesList(PrayerData prayerTimes) {
    final timeFormat = DateFormat.jm();
    final now = DateTime.now();
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildPrayerTimeCard('الفجر', prayerTimes.fajr!, timeFormat, now),
        _buildPrayerTimeCard('الشروق', prayerTimes.sunrise!, timeFormat, now),
        _buildPrayerTimeCard('الظهر', prayerTimes.dhuhr!, timeFormat, now),
        _buildPrayerTimeCard('العصر', prayerTimes.asr!, timeFormat, now),
        _buildPrayerTimeCard('المغرب', prayerTimes.maghrib!, timeFormat, now),
        _buildPrayerTimeCard('العشاء', prayerTimes.isha!, timeFormat, now),
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