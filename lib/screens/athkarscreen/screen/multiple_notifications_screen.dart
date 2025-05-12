// lib/screens/athkarscreen/screen/multiple_notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/athkarscreen/model/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/athkar_service.dart';
import 'package:test_athkar_app/services/notification_facade.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kSurface;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class MultipleNotificationsScreen extends StatefulWidget {
  final AthkarCategory category;

  const MultipleNotificationsScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<MultipleNotificationsScreen> createState() => _MultipleNotificationsScreenState();
}

class _MultipleNotificationsScreenState extends State<MultipleNotificationsScreen> {
  final AthkarService _athkarService = AthkarService();
  final NotificationFacade _notificationFacade = NotificationFacade.instance;
  final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  
  List<String> _notificationTimes = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadNotificationTimes();
  }
  
  // Load saved notification times
  Future<void> _loadNotificationTimes() async {
    setState(() => _isLoading = true);
    
    try {
      // Get saved additional times
      final times = await _athkarService.getAdditionalNotificationTimes(widget.category.id);
      setState(() {
        _notificationTimes = times;
        _isLoading = false;
      });
    } catch (e) {
      _errorLoggingService.logError(
        'MultipleNotificationsScreen', 
        'Failed to load notification times', 
        e
      );
      
      setState(() {
        _notificationTimes = [];
        _isLoading = false;
      });
      
      // Show error to user
      if (mounted) {
        _errorLoggingService.showErrorDialog(
          context,
          'خطأ في تحميل البيانات',
          'حدث خطأ أثناء تحميل أوقات الإشعارات. يرجى المحاولة مرة أخرى.',
          onRetry: _loadNotificationTimes,
        );
      }
    }
  }
  
  // Format time string to readable format
  String _formatTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        
        final TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
        return _formatTimeOfDay(time);
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }
  
  // Format notification time
  String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'ص' : 'م';
    
    String displayHour = (time.hour > 12) ? (time.hour - 12).toString() : time.hour.toString();
    if (displayHour == '0') displayHour = '12';
    
    return '$displayHour:$minutes $period';
  }
  
  // Add a new notification time
  Future<void> _addNotificationTime() async {
    // Show time picker
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _getCategoryColor(),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _getCategoryColor(),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      try {
        // Format time to string
        final timeString = '${pickedTime.hour}:${pickedTime.minute}';
        
        // Check if time already exists
        if (_notificationTimes.contains(timeString)) {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('هذا الوقت موجود بالفعل في القائمة'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Add to list
        await _athkarService.addAdditionalNotificationTime(widget.category.id, timeString);
        
        // Get all times including the new one
        final updatedTimes = _notificationTimes + [timeString];
        final timeOfDayList = updatedTimes.map((timeStr) {
          final parts = timeStr.split(':');
          return TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }).toList();
        
        // Schedule the notifications using NotificationFacade
        await _notificationFacade.scheduleAthkarNotifications(
          categoryId: widget.category.id,
          categoryTitle: widget.category.title,
          times: timeOfDayList,
          customTitle: widget.category.notifyTitle,
          customBody: widget.category.notifyBody,
          color: widget.category.color,
        );
        
        // Refresh the list
        _loadNotificationTimes();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة وقت إشعار جديد: ${_formatTimeString(timeString)}'),
            backgroundColor: _getCategoryColor(),
          ),
        );
      } catch (e) {
        _errorLoggingService.logError(
          'MultipleNotificationsScreen', 
          'Failed to add notification time', 
          e
        );
        
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إضافة وقت الإشعار'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Remove a notification time
  Future<void> _removeNotificationTime(String timeString) async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('حذف وقت الإشعار'),
          content: Text('هل أنت متأكد من حذف هذا الوقت: ${_formatTimeString(timeString)}؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('حذف'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ) ?? false;
      
      if (confirm) {
        // Remove from list
        await _athkarService.removeAdditionalNotificationTime(widget.category.id, timeString);
        
        // Re-schedule all remaining notifications
        final updatedTimes = _notificationTimes.where((t) => t != timeString).toList();
        
        if (updatedTimes.isNotEmpty) {
          // Convert strings to TimeOfDay
          final timeOfDayList = updatedTimes.map((timeStr) {
            final parts = timeStr.split(':');
            return TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }).toList();
          
          // Re-schedule notifications using NotificationFacade
          await _notificationFacade.scheduleAthkarNotifications(
            categoryId: widget.category.id,
            categoryTitle: widget.category.title,
            times: timeOfDayList,
            customTitle: widget.category.notifyTitle,
            customBody: widget.category.notifyBody,
            color: widget.category.color,
          );
        } else {
          // If no additional times left, cancel all notifications for this category
          await _notificationFacade.cancelAthkarNotifications(widget.category.id);
        }
        
        // Refresh the list
        _loadNotificationTimes();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف وقت الإشعار: ${_formatTimeString(timeString)}'),
            backgroundColor: _getCategoryColor(),
          ),
        );
      }
    } catch (e) {
      _errorLoggingService.logError(
        'MultipleNotificationsScreen', 
        'Failed to remove notification time', 
        e
      );
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حذف وقت الإشعار'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Edit a notification time
  Future<void> _editNotificationTime(String timeString) async {
    try {
      // Parse current time
      final parts = timeString.split(':');
      if (parts.length != 2) return;
      
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final currentTime = TimeOfDay(hour: hour, minute: minute);
      
      // Show time picker
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: currentTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: _getCategoryColor(),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: _getCategoryColor(),
                ),
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        // Format new time to string
        final newTimeString = '${pickedTime.hour}:${pickedTime.minute}';
        
        // Check if time already exists
        if (newTimeString != timeString && _notificationTimes.contains(newTimeString)) {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('هذا الوقت موجود بالفعل في القائمة'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Remove old time
        await _athkarService.removeAdditionalNotificationTime(widget.category.id, timeString);
        
        // Add new time
        await _athkarService.addAdditionalNotificationTime(widget.category.id, newTimeString);
        
        // Re-schedule notifications
        final updatedTimes = _notificationTimes
            .where((t) => t != timeString)
            .toList()
          ..add(newTimeString);
        
        // Convert strings to TimeOfDay
        final timeOfDayList = updatedTimes.map((timeStr) {
          final parts = timeStr.split(':');
          return TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }).toList();
        
        // Schedule all notifications using NotificationFacade
        await _notificationFacade.scheduleAthkarNotifications(
          categoryId: widget.category.id,
          categoryTitle: widget.category.title,
          times: timeOfDayList,
          customTitle: widget.category.notifyTitle,
          customBody: widget.category.notifyBody,
          color: widget.category.color,
        );
        
        // Refresh the list
        _loadNotificationTimes();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تعديل وقت الإشعار من ${_formatTimeString(timeString)} إلى ${_formatTimeString(newTimeString)}'),
            backgroundColor: _getCategoryColor(),
          ),
        );
      }
    } catch (e) {
      _errorLoggingService.logError(
        'MultipleNotificationsScreen', 
        'Failed to edit notification time', 
        e
      );
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تعديل وقت الإشعار'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Get category color
  Color _getCategoryColor() {
    return widget.category.color;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'أوقات إشعارات ${widget.category.title}',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: kPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNotificationTime,
        backgroundColor: _getCategoryColor(),
        child: Icon(Icons.add),
        tooltip: 'إضافة وقت إشعار جديد',
      ),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: _getCategoryColor(),
                size: 50,
              ),
            )
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getCategoryColor(),
                              _getCategoryColor().withOpacity(0.7),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  widget.category.icon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  widget.category.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'يمكنك إضافة أوقات متعددة لتلقي إشعارات ${widget.category.title}. اضغط على زر الإضافة لتحديد وقت جديد.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'قم بالضغط على أي وقت في القائمة لتعديله، أو اسحب لليسار للحذف.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Notification times list
                  Expanded(
                    child: _notificationTimes.isEmpty
                        ? _buildEmptyState()
                        : _buildNotificationTimesList(),
                  ),
                ],
              ),
            ),
    );
  }
  
  // Empty state when no notification times are set
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد أوقات إشعارات إضافية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'اضغط على زر الإضافة لتحديد وقت جديد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  // List of notification times
  Widget _buildNotificationTimesList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _notificationTimes.length,
        itemBuilder: (context, index) {
          final timeString = _notificationTimes[index];
          final formattedTime = _formatTimeString(timeString);
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Dismissible(
                    key: Key('time_$timeString'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('حذف وقت الإشعار'),
                          content: Text('هل أنت متأكد من حذف وقت الإشعار $formattedTime؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('حذف'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ) ?? false;
                    },
                    onDismissed: (direction) {
                      _removeNotificationTime(timeString);
                    },
                    child: ListTile(
                      onTap: () => _editNotificationTime(timeString),
                      leading: CircleAvatar(
                        backgroundColor: _getCategoryColor().withOpacity(0.2),
                        child: Icon(
                          Icons.access_time,
                          color: _getCategoryColor(),
                        ),
                      ),
                      title: Text(
                        formattedTime,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'اضغط للتعديل',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Colors.blue,
                            ),
                            onPressed: () => _editNotificationTime(timeString),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeNotificationTime(timeString),
                            tooltip: 'حذف',
                          ),
                        ],
                      ),
                    ),
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