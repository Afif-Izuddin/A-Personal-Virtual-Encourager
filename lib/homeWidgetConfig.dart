import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart'; 

class HomeWidgetConfigScreen extends StatefulWidget {
  @override
  _HomeWidgetConfigScreenState createState() => _HomeWidgetConfigScreenState();
}

class _HomeWidgetConfigScreenState extends State<HomeWidgetConfigScreen> {
  String _refreshFrequency = 'Every day';
  List<String> _refreshFrequencies = ['Every 15 minutes', 'Every hour', 'Every 6 hours', 'Every day']; 

  @override
  void initState() {
    super.initState();
    _loadRefreshFrequency();
  }

  Future<void> _loadRefreshFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _refreshFrequency = prefs.getString('widget_refresh_frequency') ?? 'Every day';
    });
  }

  Future<void> _saveRefreshFrequency(String? newValue) async {
    if (newValue != null) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _refreshFrequency = newValue;
      });
      await prefs.setString('widget_refresh_frequency', newValue);
      _startBackgroundUpdates(); 
    }
  }

  Future<void> _requestPinWidget() async {
    try {
      await HomeWidget.requestPinWidget(
          name: 'DailyQuoteWidgetProvider', 
      );
    } catch (e) {
      print('Error requesting pin widget: $e');
    }
  }

  void _startBackgroundUpdates() {
    Workmanager().cancelByUniqueName('daily_quote_refresh'); 

    Duration interval;
    switch (_refreshFrequency) {
      case 'Every 15 minutes': 
        interval = const Duration(minutes: 15);
        break;
      case 'Every hour':
        interval = const Duration(hours: 1);
        break;
      case 'Every 6 hours':
        interval = const Duration(hours: 6);
        break;
      case 'Every day':
      default:
        interval = const Duration(hours: 24);
        break;
    }

    Workmanager().registerPeriodicTask(
      'daily_quote_refresh', 
      'fetchDailyQuoteAndUpdateWidget', 
      frequency: interval,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configure Quote Widget'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Refresh Frequency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            DropdownButton<String>(
              value: _refreshFrequency,
              onChanged: _saveRefreshFrequency,
              items: _refreshFrequencies.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestPinWidget,
              child: Text('Add Widget to Home Screen'),
            ),
          ],
        ),
      ),
    );
  }
}