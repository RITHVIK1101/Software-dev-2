import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'calendar_screen.dart';
import 'package:sdapp/screens/student_gradebook_screen.dart';
import 'student_screen.dart' hide GradebookPage;
import 'student_classes_screen.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  final String token;
  final String userId;

  StudentAssignmentsScreen({
    required this.token,
    required this.userId,
  });

  @override
  _StudentAssignmentsScreenState createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  List<Map<String, dynamic>> assignments = [];
  String currentFilter = 'current';
  bool isPrioritized = false;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    String url;
    if (isPrioritized && currentFilter == 'current') {
      url = 'http://localhost:3000/students/${widget.userId}/todo-priority';
    } else {
      url =
          'http://localhost:3000/students/${widget.userId}/assignments?status=$currentFilter';
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          assignments =
              List<Map<String, dynamic>>.from(json.decode(response.body));
          print('Assignments fetched successfully: $assignments');
        });
      } else {
        print('Failed to fetch assignments: ${response.body}');
      }
    } catch (error) {
      print('Error fetching assignments: $error');
    }
  }

  Future<void> _turnInAssignment(String assignmentId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/assignments/$assignmentId/turn-in'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'studentId': widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assignment turned in successfully')),
        );
        _fetchAssignments(); // Refresh the assignments list
      } else {
        print('Failed to turn in assignment: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to turn in assignment: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error turning in assignment: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error turning in assignment: $error')),
      );
    }
  }

  Future<void> _undoTurnInAssignment(String assignmentId) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://localhost:3000/assignments/$assignmentId/undo-turn-in'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'studentId': widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Turn-in undone successfully')),
        );
        _fetchAssignments(); // Refresh the assignments list
      } else {
        print('Failed to undo turn-in: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to undo turn-in: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error undoing turn-in: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error undoing turn-in: $error')),
      );
    }
  }

  void _changeFilter(String filter) {
    setState(() {
      currentFilter = filter;
      _fetchAssignments();
    });
  }

  void _togglePrioritization(bool value) {
    setState(() {
      isPrioritized = value;
      _fetchAssignments();
    });
  }

  String formatDuration(int? hours, int? minutes) {
    final formattedHours = hours ?? 0;
    final formattedMinutes = minutes ?? 0;
    return '${formattedHours}h ${formattedMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignments'),
      ),
      body: Row(
        children: [
          Container(
            width: 80,
            color: Color(0xFF5580C1),
            child: Column(
              children: [
                IconButton(
                  icon: Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentDashboard(
                          token: widget.token,
                          userId: widget.userId,

                          firstName: '', // You'll need to provide this value
                          lastName: '', // You'll need to provide this value
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.check, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CalendarScreen(
                          token: widget.token,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.grade, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GradebookPage(
                          token: widget.token,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.class_, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentClassesScreen(
                          token: widget.token,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To-Do List',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5580C1),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _changeFilter('current'),
                        child: Text('Current'),
                      ),
                      ElevatedButton(
                        onPressed: () => _changeFilter('past-due'),
                        child: Text('Past Due'),
                      ),
                      ElevatedButton(
                        onPressed: () => _changeFilter('completed'),
                        child: Text('Completed'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: assignments.isEmpty
                        ? Center(child: Text('No assignments found.'))
                        : ListView.builder(
                            itemCount: assignments.length,
                            itemBuilder: (context, index) {
                              final assignment = assignments[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                                child: ListTile(
                                  title:
                                      Text(assignment['assignmentName'] ?? ''),
                                  subtitle: Text(
                                    formatDuration(assignment['durationHours'],
                                        assignment['durationMinutes']),
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  trailing: Text(
                                    assignment['dueDateFormatted'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5580C1),
                                    ),
                                  ),
                                  onTap: () {
                                    if (currentFilter == 'current') {
                                      _turnInAssignment(assignment['id']);
                                    } else if (currentFilter == 'completed' &&
                                        assignment['grade'] == null) {
                                      _undoTurnInAssignment(assignment['id']);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
