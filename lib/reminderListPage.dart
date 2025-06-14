import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'hive_service.dart';
import 'reminderAdd.dart'; 
import 'firebaseService.dart';

class ReminderListPage extends StatefulWidget {
  @override
  _ReminderListPageState createState() => _ReminderListPageState();
}

class _ReminderListPageState extends State<ReminderListPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? _userId;
  List<Map<dynamic, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadUserIdAndReminders();
  }

  Future<void> _loadUserIdAndReminders() async {
    _userId = await _firebaseService.getCurrentUserId();
    if (_userId != null) {
      _loadReminders();
    }
    setState(() {});
  }

  Future<void> _loadReminders() async {
    final alarmsBox = HiveService.getAlarmsBox(); 
    List<Map<dynamic, dynamic>> userReminders = [];
    alarmsBox.values.forEach((reminderData) {
      if (reminderData is Map && reminderData['userId'] == _userId) {
        userReminders.add(reminderData.cast<dynamic, dynamic>());
      }
    });
    setState(() {
      _reminders = userReminders;
    });
  }

  Future<void> _cancelReminder(String reminderKey, int notificationId) async {
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    final alarmsBox = HiveService.getAlarmsBox(); 
    await alarmsBox.delete(reminderKey);
    _loadReminders(); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Reminders'),
      ),
      body: _userId == null
          ? Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? Center(child: Text('No reminders set yet. Tap the + to add one.'))
              : ListView.builder(
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = _reminders[index];
                    final reminderNotificationId = reminder['notificationId'] as int?;
                    String? reminderKeyToDelete;
                    final alarmsBox = HiveService.getAlarmsBox();

                    alarmsBox.keys.forEach((key) {
                      final storedReminder = alarmsBox.get(key) as Map?;
                      if (storedReminder != null && storedReminder['notificationId'] == reminderNotificationId) {
                        reminderKeyToDelete = key.toString();
                      }
                    });

                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(reminder['context'] ?? 'No Context'),
                        subtitle: Text(
                          reminder['scheduledDateTime'] != null
                              ? 'Scheduled for: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(reminder['scheduledDateTime']))}'
                              : 'Scheduled time not available',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            final notificationId = reminder['notificationId'] as int?;
                            if (notificationId != null && reminderKeyToDelete != null) {
                              _cancelReminder(reminderKeyToDelete!, notificationId);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error deleting reminder')),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReminderAddScreen()),
          ).then((_) {
            _loadReminders();
          });
        },
        child: Icon(Icons.add),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}