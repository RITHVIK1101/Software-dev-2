import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeacherToGradeScreen extends StatefulWidget {
  final String token;
  final String firstName;
  final String lastName;
  final String teacherId;

  TeacherToGradeScreen({
    required this.token,
    required this.firstName,
    required this.lastName,
    required this.teacherId,
  });

  @override
  _TeacherToGradeScreenState createState() => _TeacherToGradeScreenState();
}

class _TeacherToGradeScreenState extends State<TeacherToGradeScreen> {
  List<Map<String, dynamic>> assignmentsToGrade = [];
  Map<String, String> studentGrades = {};

  @override
  void initState() {
    super.initState();
    _fetchAssignmentsToGrade();
  }

  Future<void> _fetchAssignmentsToGrade() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:3000/teachers/${widget.teacherId}/assignments-to-grade'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          assignmentsToGrade =
              List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        print('Failed to fetch assignments to grade: ${response.body}');
      }
    } catch (error) {
      print('Error fetching assignments to grade: $error');
    }
  }

  Future<void> _scoreAssignment(
      String assignmentId, String studentId, String grade) async {
    try {
      print('Assignment ID: $assignmentId');
      print('Student ID: $studentId');
      print('Grade: $grade');

      final parsedGrade = int.tryParse(grade);
      if (parsedGrade == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid score value')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/assignments/$assignmentId/score'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'studentId': studentId,
          'grade': parsedGrade,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Score saved!')),
        );
        _fetchAssignmentsToGrade(); // Refresh the assignments to grade
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save score: ${response.body}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving score: $error')),
      );
      print('Error scoring assignment: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignments to Grade'),
      ),
      body: ListView.builder(
        itemCount: assignmentsToGrade.length,
        itemBuilder: (context, index) {
          final assignment = assignmentsToGrade[index];
          return Card(
            child: ExpansionTile(
              title: Text(assignment['assignmentName']),
              subtitle: Text('Class: ${assignment['className']}'),
              children: List<Widget>.generate(assignment['students'].length,
                  (studentIndex) {
                final student = assignment['students'][studentIndex];
                return ListTile(
                  leading: SizedBox(
                    width: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '--',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          studentGrades[student['studentId']] = value;
                        });
                      },
                    ),
                  ),
                  title: Text(student['studentName']),
                  subtitle: Text('Max points: ${assignment['points']}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      final grade = studentGrades[student['studentId']];
                      print('Grade entered: $grade');
                      if (grade != null) {
                        try {
                          final int parsedGrade = int.parse(grade);
                          print('Parsed grade: $parsedGrade');
                          print(
                              'Assignment ID: ${assignment['id']}'); // Changed from '_id' to 'id'
                          print('Student ID: ${student['studentId']}');
                          if (parsedGrade <= assignment['points']) {
                            _scoreAssignment(
                                assignment['id'],
                                student['studentId'],
                                grade); // Changed from '_id' to 'id'
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Score is more than 100%')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invalid score value')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Score cannot be empty')),
                        );
                      }
                    },
                    child: Text('Grade it!'),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
