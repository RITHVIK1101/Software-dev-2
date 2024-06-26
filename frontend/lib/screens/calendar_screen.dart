import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
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
  Map<DateTime, List> eventSource = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
          eventSource = {
            for (var event in events) DateTime.parse(event['start']): [event]
          };
        });
      } else {
        print('Failed to fetch events: ${response.body}');
      }
    } catch (error) {
      print('Error fetching events: $error');
    }
  }

  List _getEventsForDay(DateTime day) {
    return eventSource[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // update `_focusedDay` here as well
              });
            },
            eventLoader: _getEventsForDay,
          ),
          ..._getEventsForDay(_selectedDay ?? _focusedDay).map(
            (event) => ListTile(
              title: Text(event['summary']),
              subtitle: Text(event['description']),
            ),
          ),
        ],
      ),
    );
  }
}
