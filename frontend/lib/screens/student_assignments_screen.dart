import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        actions: [
          Row(
            children: [
              Text('Unprioritized'),
              Switch(
                value: isPrioritized,
                onChanged: (value) {
                  _togglePrioritization(value);
                },
              ),
              Text('Prioritized'),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
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
            child: ListView.builder(
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                return Card(
                  child: ListTile(
                    title: Text(assignment['assignmentName']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Class: ${assignment['className']}'),
                        Text('Category: ${assignment['category']}'),
                        Text('Due Date: ${assignment['dueDateFormatted']}'),
                        Text(
                            'Duration: ${formatDuration(assignment['durationHours'], assignment['durationMinutes'])}'),
                        Text('Points: ${assignment['points']}'),
                        if (assignment['rubric'] != null)
                          Text('Rubric: ${assignment['rubric']}'),
                        if (assignment['files'] != null &&
                            assignment['files'].isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: assignment['files']
                                .map<Widget>((file) => Text('File: $file'))
                                .toList(),
                          ),
                        if (isPrioritized)
                          Text(
                              'Priority Score: ${assignment['priorityScore']}'),
                      ],
                    ),
                    trailing: currentFilter == 'current'
                        ? ElevatedButton(
                            onPressed: () {
                              _turnInAssignment(assignment['id']);
                            },
                            child: Text('Turn In'),
                          )
                        : currentFilter == 'completed' &&
                                assignment['grade'] == null
                            ? ElevatedButton(
                                onPressed: () {
                                  _undoTurnInAssignment(assignment['id']);
                                },
                                child: Text('Undo Turn In'),
                              )
                            : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
