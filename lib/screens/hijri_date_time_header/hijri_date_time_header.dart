import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

//==============================================================================
// CONSTANTS
//==============================================================================
const Color kPrimary = Color(0xFF0B8457);
const Color kPrimaryLight = Color(0xFF27B376);
const Color kSurface = Color(0xFFE7E8E3);


const _kDialogRadius = 20.0;

// أسماء الأشهر الهجرية
const List<String> _hijriMonths = <String>[
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الثاني',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

// حروف أيام الأسبوع (الأحد = "أ")
const List<String> _weekDays = <String>['أ', 'إ', 'ث', 'ر', 'خ', 'ج', 'س'];

// أسماء الأشهر الميلادية بالعربية
const List<String> _gregorianMonths = <String>[
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

//==============================================================================
// HEADER WIDGET
//==============================================================================
class HijriDateTimeHeader extends StatelessWidget {
  const HijriDateTimeHeader({
    super.key,
    required this.currentTime,
  });

  final ValueListenable<DateTime> currentTime;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: currentTime,
      builder: (_, now, __) {
        final HijriCalendar hijri = HijriCalendar.fromDate(now);
        final String gregorianDate =
            '${now.day} ${_gregorianMonths[now.month - 1]} ${now.year} م';

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              const _CalendarAvatar(iconSize: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: () => _showCalendar(context, hijri),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _DateTexts(
                        hijri: hijri,
                        gregorianDate: gregorianDate,
                        textSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCalendar(BuildContext context, HijriCalendar hijri) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CalendarDialog(initial: hijri),
    );
  }
}

// Small reusable widgets to keep build methods tidy --------------------------
class _CalendarAvatar extends StatelessWidget {
  const _CalendarAvatar({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[kPrimary, kPrimaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.calendar_today_rounded, size: iconSize * 0.6, color: Colors.white),
    );
  }
}

class _DateTexts extends StatelessWidget {
  const _DateTexts({
    required this.hijri,
    required this.gregorianDate,
    required this.textSize,
  });

  final HijriCalendar hijri;
  final String gregorianDate;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${hijri.hDay} ${_hijriMonths[hijri.hMonth - 1]} ${hijri.hYear} هـ',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.bold,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          gregorianDate,
          style: TextStyle(
            fontSize: textSize * 0.8,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

//==============================================================================
// CALENDAR DIALOG
//==============================================================================
class _CalendarDialog extends StatefulWidget {
  const _CalendarDialog({required this.initial});

  final HijriCalendar initial;

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  late HijriCalendar _visibleMonth;
  final HijriCalendar _today = HijriCalendar.now();
  bool _showMonthsList = false;

  @override
  void initState() {
    super.initState();
    _visibleMonth = HijriCalendar()
      ..hYear = widget.initial.hYear
      ..hMonth = widget.initial.hMonth
      ..hDay = 1;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kDialogRadius)),
      elevation: 8,
      shadowColor: Colors.black38,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kDialogRadius),
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(.02),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Header(
                monthName: _hijriMonths[_visibleMonth.hMonth - 1],
                year: _visibleMonth.hYear,
                onPrevious: _prevMonth,
                onNext: _nextMonth,
                onMonthTap: () => setState(() => _showMonthsList = !_showMonthsList),
              ),
              if (_showMonthsList)
                _MonthsList(
                  currentMonth: _visibleMonth.hMonth,
                  onMonthSelected: (int m) => setState(() {
                    _visibleMonth.hMonth = m;
                    _showMonthsList = false;
                  }),
                )
              else ...<Widget>[
                const SizedBox(height: 20),
                const _WeekDaysRow(),
                const SizedBox(height: 12),
                _DaysGrid(visibleMonth: _visibleMonth, today: _today),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: Navigator.of(context).pop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text('إغلاق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation helpers --------------------------------------------------------
  void _prevMonth() => setState(() {
        if (_visibleMonth.hMonth == 1) {
          if (_visibleMonth.hYear > 1356) {
            _visibleMonth
              ..hYear -= 1
              ..hMonth = 12;
          }
        } else {
          _visibleMonth.hMonth -= 1;
        }
      });

  void _nextMonth() => setState(() {
        if (_visibleMonth.hMonth == 12) {
          if (_visibleMonth.hYear < 1500) {
            _visibleMonth
              ..hYear += 1
              ..hMonth = 1;
          }
        } else {
          _visibleMonth.hMonth += 1;
        }
      });
}

//==============================================================================
// HEADER WITH MONTH/YEAR
//==============================================================================
class _Header extends StatelessWidget {
  const _Header({
    required this.monthName,
    required this.year,
    required this.onPrevious,
    required this.onNext,
    required this.onMonthTap,
  });

  final String monthName;
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onMonthTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _NavButton(icon: Icons.arrow_back_ios_rounded, onPressed: onPrevious),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _MonthChip(label: monthName, onTap: onMonthTap),
              const SizedBox(width: 12),
              _YearChip(year: year),
            ],
          ),
        ),
        _NavButton(icon: Icons.arrow_forward_ios_rounded, onPressed: onNext),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      color: kPrimary,
      tooltip: 'الشهر السابق',
      style: IconButton.styleFrom(
        backgroundColor: kPrimaryLight.withOpacity(.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kPrimary.withOpacity(.3)),
          color: kPrimaryLight.withOpacity(.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: kPrimary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: kPrimaryLight.withOpacity(.05),
      ),
      child: Text('$year هـ',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: kPrimary,
              )),
    );
  }
}

//==============================================================================
// MONTHS LIST
//==============================================================================
class _MonthsList extends StatelessWidget {
  const _MonthsList({required this.currentMonth, required this.onMonthSelected});

  final int currentMonth;
  final ValueChanged<int> onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 12,
        itemBuilder: (_, int index) {
          final int monthIndex = index + 1;
          final bool isSelected = monthIndex == currentMonth;

          return InkWell(
            onTap: () => onMonthSelected(monthIndex),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: <Color>[kPrimary, kPrimaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: kPrimary.withOpacity(.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
                border: isSelected ? null : Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  _hijriMonths[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

//==============================================================================
// WEEK DAYS ROW
//==============================================================================
class _WeekDaysRow extends StatelessWidget {
  const _WeekDaysRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: kPrimaryLight.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _weekDays
            .map(
              (String d) => SizedBox(
                width: 30,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

//==============================================================================
// DAYS GRID
//==============================================================================
class _DaysGrid extends StatelessWidget {
  const _DaysGrid({required this.visibleMonth, required this.today});

  final HijriCalendar visibleMonth;
  final HijriCalendar today;

  @override
  Widget build(BuildContext context) {
    try {
      final DateTime firstGregorian = HijriCalendar().hijriToGregorian(
        visibleMonth.hYear,
        visibleMonth.hMonth,
        1,
      );
      final int leadingEmpty = firstGregorian.weekday % 7; // الأحد = 0
      final int daysInMonth = _daysInHijriMonth(visibleMonth.hYear, visibleMonth.hMonth);

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        height: 280,
        child: GridView.count(
          crossAxisCount: 7,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            for (int i = 0; i < leadingEmpty; i++) const SizedBox.shrink(),
            for (int day = 1; day <= daysInMonth; day++)
              _DayCell(day: day, month: visibleMonth, today: today),
          ],
        ),
      );
    } catch (e) {
      return _ErrorGrid();
    }
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.month, required this.today});

  final int day;
  final HijriCalendar month;
  final HijriCalendar today;

  @override
  Widget build(BuildContext context) {
    final HijriCalendar cellDate = HijriCalendar()
      ..hYear = month.hYear
      ..hMonth = month.hMonth
      ..hDay = day;

    final bool isToday = cellDate.isSameDate(today);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isToday ? kPrimary : null,
        boxShadow: isToday
            ? <BoxShadow>[
                BoxShadow(
                  color: kPrimary.withOpacity(.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            color: isToday ? Colors.white : Colors.black87,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _ErrorGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'عذراً، لا يمكن عرض التقويم للتاريخ المحدد',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'التاريخ الهجري يجب أن يكون بين 1356 هـ و 1500 هـ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

//==============================================================================
// HELPERS + EXTENSIONS
//==============================================================================
extension _HijriCompare on HijriCalendar {
  bool isSameDate(HijriCalendar other) =>
      hDay == other.hDay && hMonth == other.hMonth && hYear == other.hYear;
}

int _daysInHijriMonth(int year, int month) {
  if (month % 2 == 1) return 30; // الأشهر الفردية
  if (month == 12 && _isLeap(year)) return 30; // ذو الحجة في الكبيسة
  return 29;
}

bool _isLeap(int year) {
  const List<int> leapYears = <int>[2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29];
  return leapYears.contains(year % 30);
}
