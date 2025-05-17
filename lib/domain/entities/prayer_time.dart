// lib/domain/entities/prayer_time.dart
class PrayerTime {
  final DateTime time;
  final String name;
  final bool isCurrent;
  final bool isNext;

  PrayerTime({
    required this.time,
    required this.name,
    this.isCurrent = false,
    this.isNext = false,
  });
}