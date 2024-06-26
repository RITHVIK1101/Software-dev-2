import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeacherAssignmentsScreen extends StatefulWidget {
  final String className;
  final String token;
  final String teacherId;

  TeacherAssignmentsScreen({
    required this.className,
    required this.token,
    required this.teacherId,
  });

  @override
  _TeacherAssignmentsScreenState createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  List<Map<String, dynamic>> assignments = [];

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    print('Fetching assignments for class: ${widget.className}');
    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:3000/classes/${widget.className}/assignments'),
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

  void _showAddAssignmentDialog() {
    String name = '';
    String durationStr = '';
    String pointsStr = '';
    String category = 'Formative';
    String? rubric;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Assignment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Assignment Name'),
                onChanged: (value) {
                  name = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Duration'),
                onChanged: (value) {
                  durationStr = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Points'),
                onChanged: (value) {
                  pointsStr = value;
                },
              ),
              DropdownButton<String>(
                value: category,
                items: <String>['Formative', 'Summative'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    category = newValue!;
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Rubric (optional)'),
                onChanged: (value) {
                  rubric = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addAssignment(name, durationStr, pointsStr, category, rubric);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addAssignment(String name, String durationStr, String pointsStr,
      String category, String? rubric) async {
    try {
      final int duration = int.parse(durationStr);
      final int points = int.parse(pointsStr);
      final response = await http.post(
        Uri.parse(
            'http://localhost:3000/classes/${widget.className}/assignments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'assignmentName': name,
          'duration': duration,
          'points': points,
          'category': category,
          'rubric': rubric,
        }),
      );

      if (response.statusCode == 201) {
        _fetchAssignments(); // Refresh assignments list
      } else {
        print('Failed to add assignment: ${response.body}');
      }
    } catch (error) {
      print('Error adding assignment: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignments for ${widget.className}'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _showAddAssignmentDialog,
            child: Text('Add Assignment'),
          ),
          Expanded(
            child: assignments.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: assignments.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(assignments[index]['assignmentName']),
                        subtitle: Text(
                            'Duration: ${assignments[index]['duration']} minutes'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
