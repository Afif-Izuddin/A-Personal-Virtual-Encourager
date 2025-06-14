import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'geminiService.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'hive_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebaseService.dart';
import 'main.dart';

class ReminderAddScreen extends StatefulWidget {
  @override
  _ReminderAddScreenState createState() => _ReminderAddScreenState();
}

class _ReminderAddScreenState extends State<ReminderAddScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TextEditingController _contextController = TextEditingController();
  final Geminiservice _geminiService = Geminiservice();
  final FirebaseService _firebaseService = FirebaseService();
  int _notificationIdCounter = 31;

  @override
  void initState() {
    super.initState();
    //_initializeNotifications();
    //tz.initializeTimeZones();
    //tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    _requestExactAlarmPermission();
  }

  Future<void> _requestExactAlarmPermission() async {
    var status = await Permission.scheduleExactAlarm.status;
    if (status.isDenied) {
      status = await Permission.scheduleExactAlarm.request();
      if (status.isGranted) {
        print('Exact alarm permission granted.');
      } else {
        print('Exact alarm permission denied.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Precise reminders might not work as exact alarm permission was denied.'),
          ),
        );
      }
    } else if (status.isGranted) {
      print('Exact alarm permission already granted.');
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _scheduleReminder() async {
    if (_selectedDate == null || _selectedTime == null || _contextController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select date, time, and context')),
      );
      return;
    }

    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected time cannot be in the past')),
      );
      return;
    }

    final String? userId = await _firebaseService.getCurrentUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found')),
      );
      return;
    }

    final generatedQuote = await _geminiService.sendMessage(
      'reminder_context_$userId',
      [{"text": "Generate a short motivational quote related to ${_contextController.text}.", "isBot": false}],
      '',
    );

    final notificationId = _notificationIdCounter++;

    await scheduleReminder(
      scheduledDateTime: scheduledDateTime,
      title: _contextController.text,
      body: generatedQuote,
      id: notificationId,
    );

    final alarmsBox = HiveService.getAlarmsBox();
    await alarmsBox.put(
      'reminder_$userId$notificationId',
      {
        'userId': userId,
        'notificationId': notificationId,
        'scheduledDateTime': scheduledDateTime.toIso8601String(),
        'context': _contextController.text,
        'quote': generatedQuote,
      },
    );

    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder set for ${DateFormat('yyyy-MM-dd HH:mm').format(scheduledDateTime)}')),
      );
    });
  }

  Future<void> scheduleReminder({
  required int id,
  required String title,
  String? body,
  required DateTime scheduledDateTime,
  }) async {
  final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
    scheduledDateTime, 
    tz.local,
  );
  print('Scheduling notification:');
    print('  ID: $id');
    print('  Title: $title');
    print('  Body: $body');
    print('  Scheduled Time: $scheduledDate');
    
  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    scheduledDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'PVENotification', 
        'Reminder Notifications', 
        channelDescription: 'Notifications for scheduled reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ListTile(
              title: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            ListTile(
              title: Text(
                _selectedTime == null
                    ? 'Select Time'
                    : _selectedTime!.format(context),
              ),
              trailing: Icon(Icons.access_time),
              onTap: () => _selectTime(context),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _contextController,
              decoration: InputDecoration(
                labelText: 'Reminder Context (e.g., Water plants)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _scheduleReminder,
              child: Text('Set Reminder'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}