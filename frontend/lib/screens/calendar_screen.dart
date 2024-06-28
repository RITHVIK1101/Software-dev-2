import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendarScreen extends StatefulWidget {
  final String token;
  final String userId;

  CalendarScreen({
    required this.token,
    required this.userId,
  });

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<Map<String, dynamic>> events = [];
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:3000/calendar/events?userId=${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List fetchedEvents = json.decode(response.body);
        setState(() {
          events = List<Map<String, dynamic>>.from(fetchedEvents);
        });
      } else {
        print('Failed to fetch events: ${response.body}');
      }
    } catch (error) {
      print('Error fetching events: $error');
    }
  }

  List<Widget> _buildDayView() {
    List<Widget> timeSlots = [];
    for (int i = 0; i < 24; i++) {
      DateTime time = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        i,
      );

      List eventsAtThisHour = events.where((event) {
        final eventStart = DateTime.parse(event['start']);
        final eventEnd = DateTime.parse(event['end']);
        return eventStart.hour <= i && eventEnd.hour >= i;
      }).toList();

      timeSlots.add(
        Container(
          height: 60, // Height for each hour slot
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey)),
          ),
          child: ListTile(
            title: Text(DateFormat('hh:mm a').format(time)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: eventsAtThisHour
                  .map<Widget>((event) => Text(event['summary']))
                  .toList(),
            ),
          ),
        ),
      );
    }
    return timeSlots;
  }

  void _navigateToPreviousDay() {
    setState(() {
      _selectedDay = _selectedDay.subtract(Duration(days: 1));
    });
  }

  void _navigateToNextDay() {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    return Scaffold(
      appBar: AppBar(
        title: Text('Day View'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _navigateToPreviousDay,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEEE').format(_selectedDay),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(_selectedDay),
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: _navigateToNextDay,
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  controller: _scrollController,
                  children: _buildDayView(),
                ),
                Positioned(
                  top: currentHour * 60.0 + currentMinute,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    color: Colors.red,
                  ),
                ),
                Positioned(
                  top: currentHour * 60.0 + currentMinute - 10,
                  right: 10,
                  child: Text(
                    '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
