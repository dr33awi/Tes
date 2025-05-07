// lib/adhan/services/prayer_times_service_extension.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/adhan/services/prayer_times_service.dart';

/// تمديد لخدمة مواقيت الصلاة
extension PrayerTimesServiceExtension on PrayerTimesService {
  /// حفظ الموقع في التخزين المحلي
  Future<void> saveLocation(double latitude, double longitude, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('prayer_location_latitude', latitude);
      await prefs.setDouble('prayer_location_longitude', longitude);
      await prefs.setString('prayer_location_name', name);
    } catch (e) {
      debugPrint('خطأ في حفظ الموقع: $e');
    }
  }
  
  /// الحصول على الموقع المحفوظ من التخزين المحلي
  Future<Map<String, dynamic>?> getSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latitude = prefs.getDouble('prayer_location_latitude');
      final longitude = prefs.getDouble('prayer_location_longitude');
      final name = prefs.getString('prayer_location_name');
      
      if (latitude != null && longitude != null) {
        return {
          'latitude': latitude,
          'longitude': longitude,
          'name': name,
        };
      }
    } catch (e) {
      debugPrint('خطأ في قراءة الموقع المحفوظ: $e');
    }
    
    return null;
  }
  
  /// البحث عن اسم الموقع باستخدام الإحداثيات (متاح للاستخدام العام)
Future<String?> _getLocationName(double latitude, double longitude) async {
  // Simple placeholder implementation
  return 'Location at $latitude, $longitude';
  
  }
}