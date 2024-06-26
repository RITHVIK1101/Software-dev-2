import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TeacherScreen extends StatefulWidget {
  final String token;
  final String school;
  final String firstName;
  final String lastName;
  final String teacherId;

  TeacherScreen({
    required this.token,
    required this.school,
    required this.firstName,
    required this.lastName,
    required this.teacherId,
  });

  @override
  _TeacherScreenState createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  List<dynamic> _classes = [];
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _fetchStudents();
  }

  Future<void> _fetchClasses() async {
    final url = 'http://localhost:3000/teachers/${widget.teacherId}/classes';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> classesJson = json.decode(response.body);
        setState(() {
          _classes = classesJson;
        });
      } else {
        print('Failed to load classes. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching classes: $e');
    }
  }

  Future<void> _addClass(
      String className, String subject, String period, String color) async {
    final url = 'http://localhost:3000/classes';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        'className': className,
        'subject': subject,
        'period': period,
        'color': color,
        'teacher': widget.teacherId,
      }),
    );

    if (response.statusCode == 201) {
      _fetchClasses();
    } else {
      print('Failed to add class');
    }
  }

  Future<void> _fetchStudents() async {
    final url = 'http://localhost:3000/students?school=${widget.school}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _students = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      print('Failed to load students');
    }
  }

  void _showAddClassDialog() {
    String className = '';
    String subject = 'Math';
    String period = '1';
    String color = 'Red';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add Class'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(labelText: 'Class Name'),
                    onChanged: (value) {
                      className = value;
                    },
                  ),
                  SizedBox(height: 10),
                  Text('Subject'),
                  DropdownButton<String>(
                    value: subject,
                    onChanged: (String? newValue) {
                      setState(() {
                        subject = newValue!;
                      });
                    },
                    items: <String>[
                      'Math',
                      'English',
                      'PE',
                      'Humanities',
                      'Art',
                      'Science',
                      'CTE'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  Text('Period'),
                  DropdownButton<String>(
                    value: period,
                    onChanged: (String? newValue) {
                      setState(() {
                        period = newValue!;
                      });
                    },
                    items: List<String>.generate(9, (index) => '${index + 1}')
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  Text('Color'),
                  DropdownButton<String>(
                    value: color,
                    onChanged: (String? newValue) {
                      setState(() {
                        color = newValue!;
                      });
                    },
                    items: <String>['Red', 'Blue', 'Green', 'Yellow']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Add'),
                  onPressed: () {
                    _addClass(className, subject, period, color);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddAssignmentDialog(String classId) {
    String assignmentName = '';
    DateTime dueDate = DateTime.now();
    TimeOfDay dueTime = TimeOfDay.now();
    int points = 0;
    String category = 'Formative';
    int durationHours = 0;
    int durationMinutes = 0;
    String term = 'T1'; // Add term field

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add Assignment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(labelText: 'Assignment Name'),
                    onChanged: (value) {
                      assignmentName = value;
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Points'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      points = int.parse(value);
                    },
                  ),
                  DropdownButton<String>(
                    value: category,
                    onChanged: (String? newValue) {
                      setState(() {
                        category = newValue!;
                      });
                    },
                    items: <String>['Formative', 'Summative']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  ListTile(
                    title: Text("Due Date"),
                    subtitle: Text("${dueDate.toLocal()}".split(' ')[0]),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && picked != dueDate)
                        setState(() {
                          dueDate = picked;
                        });
                    },
                  ),
                  ListTile(
                    title: Text("Due Time"),
                    subtitle: Text("${dueTime.format(context)}"),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: dueTime,
                      );
                      if (picked != null && picked != dueTime)
                        setState(() {
                          dueTime = picked;
                        });
                    },
                  ),
                  ListTile(
                    title: Text("Duration (Hours)"),
                    trailing: DropdownButton<int>(
                      value: durationHours,
                      onChanged: (int? newValue) {
                        setState(() {
                          durationHours = newValue!;
                        });
                      },
                      items: List<int>.generate(24, (index) => index)
                          .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                    ),
                  ),
                  ListTile(
                    title: Text("Duration (Minutes)"),
                    trailing: DropdownButton<int>(
                      value: durationMinutes,
                      onChanged: (int? newValue) {
                        setState(() {
                          durationMinutes = newValue!;
                        });
                      },
                      items: List<int>.generate(60, (index) => index)
                          .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                    ),
                  ),
                  ListTile(
                    title: Text("Term"),
                    trailing: DropdownButton<String>(
                      value: term,
                      onChanged: (String? newValue) {
                        setState(() {
                          term = newValue!;
                        });
                      },
                      items: <String>['T1', 'T2', 'T3', 'T4']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Add Assignment'),
                  onPressed: () {
                    _addAssignment(classId, assignmentName, dueDate, dueTime,
                        points, category, durationHours, durationMinutes, term);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addAssignment(
      String classId,
      String assignmentName,
      DateTime dueDate,
      TimeOfDay dueTime,
      int points,
      String category,
      int durationHours,
      int durationMinutes,
      String term) async {
    final url = 'http://localhost:3000/classes/$classId/assignments';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        'assignmentName': assignmentName,
        'dueDate': dueDate.toIso8601String(),
        'dueTime': '${dueTime.hour}:${dueTime.minute}',
        'points': points,
        'category': category,
        'durationHours': durationHours,
        'durationMinutes': durationMinutes,
        'teacher': widget.teacherId,
        'term': term, // Add term field
      }),
    );

    if (response.statusCode == 201) {
      _fetchClasses();
    } else {
      print('Failed to add assignment');
    }
  }

  void _showAddStudentsDialog(String classId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add Students'),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      decoration: InputDecoration(labelText: 'Search Students'),
                      onChanged: (value) {
                        // Handle search input
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return CheckboxListTile(
                            title: Text(
                                '${student['firstName']} ${student['lastName']}'),
                            value: student['selected'] ?? false,
                            onChanged: (bool? value) {
                              setState(() {
                                student['selected'] = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Add Students'),
                  onPressed: () {
                    _addStudentsToClass(classId);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addStudentsToClass(String classId) async {
    final url = 'http://localhost:3000/classes/addStudents';
    final students = _students
        .where((student) => student['selected'] == true)
        .map((student) => student['_id'])
        .toList();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        'className': classId,
        'students': students,
      }),
    );

    if (response.statusCode == 200) {
      _fetchClasses();
    } else {
      print('Failed to add students');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.firstName} ${widget.lastName} - Teacher Portal'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Welcome ${widget.firstName} ${widget.lastName}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Sign Out'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('To Grade List'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/teacher/to-grade',
                  arguments: {
                    'token': widget.token,
                    'teacherId': widget.teacherId,
                    'firstName': widget.firstName,
                    'lastName': widget.lastName,
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          ElevatedButton(
            child: Text('Add Class'),
            onPressed: _showAddClassDialog,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _classes.length,
              itemBuilder: (context, index) {
                final classData = _classes[index];
                Color? classColor;
                switch (classData['color']) {
                  case 'Red':
                    classColor = Colors.red;
                    break;
                  case 'Blue':
                    classColor = Colors.blue;
                    break;
                  case 'Green':
                    classColor = Colors.green;
                    break;
                  case 'Yellow':
                    classColor = Colors.yellow;
                    break;
                  default:
                    classColor = Colors.grey;
                }
                return Card(
                  color: classColor,
                  child: ListTile(
                    title: Text(classData['className']),
                    subtitle: Text(
                        '${classData['subject']} - Period ${classData['period']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.person_add),
                          onPressed: () {
                            _showAddStudentsDialog(classData['_id']);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            _showAddAssignmentDialog(classData['_id']);
                          },
                        ),
                      ],
                    ),
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
