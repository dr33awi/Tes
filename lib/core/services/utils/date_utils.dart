// lib/core/services/utils/date_utils.dart
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

class AppDateUtils {
  /// تنسيق التاريخ الميلادي بالتنسيق المحدد
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    final dateFormat = DateFormat(format);
    return dateFormat.format(date);
  }
  
  /// تنسيق الوقت بتنسيق 12 ساعة (مثال: 10:30 AM)
  static String formatTime12(DateTime dateTime) {
    final timeFormat = DateFormat.jm();
    return timeFormat.format(dateTime);
  }
  
  /// تنسيق الوقت بتنسيق 24 ساعة (مثال: 22:30)
  static String formatTime24(DateTime dateTime) {
    final timeFormat = DateFormat.Hm();
    return timeFormat.format(dateTime);
  }
  
  /// تحويل التاريخ الميلادي إلى هجري
  static HijriCalendar convertToHijri(DateTime gregorianDate) {
    return HijriCalendar.fromDate(gregorianDate);
  }
  
  /// تنسيق التاريخ الهجري بالتنسيق المحدد
  static String formatHijriDate(
    HijriCalendar hijriDate, {
    String format = 'dd MMMM yyyy',
    String locale = 'ar',
  }) {
    // الشهور الهجرية بالعربية
    const List<String> hijriMonthsAr = [
      'محرم', 'صفر', 'ربيع الأول', 'ربيع الثاني',
      'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
      'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
    ];
    
    // الشهور الهجرية بالإنجليزية
    const List<String> hijriMonthsEn = [
      'Muharram', 'Safar', 'Rabi\' al-Awwal', 'Rabi\' al-Thani',
      'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Sha\'ban',
      'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
    ];
    
    String result = format;
    
    // استبدال السنة
    result = result.replaceAll('yyyy', hijriDate.year.toString());
    result = result.replaceAll('yy', hijriDate.year.toString().substring(2));
    
    // استبدال الشهر
    if (result.contains('MMMM')) {
      result = result.replaceAll(
        'MMMM', 
        locale == 'ar' ? hijriMonthsAr[hijriDate.month - 1] : hijriMonthsEn[hijriDate.month - 1],
      );
    } else if (result.contains('MMM')) {
      result = result.replaceAll(
        'MMM', 
        locale == 'ar' 
            ? hijriMonthsAr[hijriDate.month - 1].split(' ')[0] 
            : hijriMonthsEn[hijriDate.month - 1].substring(0, 3),
      );
    } else if (result.contains('MM')) {
      result = result.replaceAll(
        'MM', 
        hijriDate.month.toString().padLeft(2, '0'),
      );
    } else if (result.contains('M')) {
      result = result.replaceAll('M', hijriDate.month.toString());
    }
    
    // استبدال اليوم
    result = result.replaceAll('dd', hijriDate.day.toString().padLeft(2, '0'));
    result = result.replaceAll('d', hijriDate.day.toString());
    
    return result;
  }
  
  /// حساب المدة المتبقية حتى تاريخ محدد
  static String getRemainingTime(DateTime targetTime) {
    final now = DateTime.now();
    final difference = targetTime.difference(now);
    
    if (difference.isNegative) {
      return 'انتهى الوقت';
    }
    
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    
    if (days > 0) {
      return '$days يوم، $hours ساعة';
    } else if (hours > 0) {
      return '$hours ساعة، $minutes دقيقة';
    } else if (minutes > 0) {
      return '$minutes دقيقة، $seconds ثانية';
    } else {
      return '$seconds ثانية';
    }
  }
}