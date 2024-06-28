import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'gradebook_detailed_screen.dart'; // Import the new gradebook detail screen
import '../login_screen.dart';
import 'student_assignments_screen.dart';
import 'calendar_screen.dart';
import 'student_gradebook_screen.dart' hide GradebookPage;
import 'student_classes_screen.dart';

class StudentScreen extends StatelessWidget {
  final String token;
  final String school;
  final String firstName;
  final String lastName;
  final String userId;

  StudentScreen({
    required this.token,
    required this.school,
    required this.firstName,
    required this.lastName,
    required this.userId,
  });

  void _signOut(BuildContext context) {
    // Clear any stored data if necessary
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome $firstName $lastName'),
      ),
      body: Row(
        children: [
          Container(
            width: 80,
            color: Color(0xFF5580C1),
            child: Column(
              children: [
                IconButton(
                  icon: Icon(Icons.assignment, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentAssignmentsScreen(
                          token: token,
                          userId: userId,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CalendarScreen(
                          token: token,
                          userId: userId,
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
                          token: token,
                          userId: userId,
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
                          token: token,
                          userId: userId,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.exit_to_app, color: Colors.white),
                  onPressed: () => _signOut(context),
                ),
              ],
            ),
          ),
          VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: StudentDashboard(
              token: token,
              userId: userId,
              firstName: firstName,
              lastName: lastName,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentDashboard extends StatefulWidget {
  final String token;
  final String userId;
  final String firstName;
  final String lastName;

  StudentDashboard({
    required this.token,
    required this.userId,
    required this.firstName,
    required this.lastName,
  });

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<Map<String, dynamic>> upcomingEvents = [];
  List<Map<String, dynamic>> assignments = [];
  double performanceScore = 0.0;
  int assignmentsLeft = 0;
  int schedulePacked = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    // Implement API calls to fetch upcoming events, assignments, performance score, etc.
    // For now, let's use dummy data.
    setState(() {
      upcomingEvents = [
        {'name': 'Math Test', 'time': '1:20'},
        {'name': 'Basketball Game', 'time': '6:00'},
        {'name': 'English Essay', 'time': '11:59'}
      ];
      assignments = [
        {'name': 'Study for Math Test', 'duration': '180 min'}
      ];
      performanceScore = 0.75;
      assignmentsLeft = 5;
      schedulePacked = 3; // Example packed scale from 1 to 5
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildCalendarSnippetCard(),
              ),
              SizedBox(width: 16.0),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildNeedImprovementCard(),
                    ),
                    SizedBox(height: 16.0),
                    Expanded(
                      child: _buildGoodPerformanceCard(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.0),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildNextToDoCard(),
                    ),
                    SizedBox(height: 16.0),
                    Expanded(
                      child: _buildSchedulePackedCard(),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                flex: 2,
                child: _buildImportantAnnouncementsCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSnippetCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Snippet of Calendar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // Add your calendar snippet widget here
          ],
        ),
      ),
    );
  }

  Widget _buildNeedImprovementCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need Improvement (Class)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // Add your content here
          ],
        ),
      ),
    );
  }

  Widget _buildGoodPerformanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class They Are Doing Good In',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // Add your content here
          ],
        ),
      ),
    );
  }

  Widget _buildNextToDoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Next To-Do',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...assignments.map((assignment) => ListTile(
                  title: Text(assignment['name']),
                  trailing: Text(assignment['duration']),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulePackedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schedule Packed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('$schedulePacked/5', style: TextStyle(fontSize: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantAnnouncementsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Important Announcements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // Add your announcements content here
          ],
        ),
      ),
    );
  }
}

class GradebookPage extends StatefulWidget {
  final String token;
  final String userId;

  GradebookPage({
    required this.token,
    required this.userId,
  });

  @override
  _GradebookPageState createState() => _GradebookPageState();
}

class _GradebookPageState extends State<GradebookPage> {
  List<Map<String, dynamic>> classes = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/students/${widget.userId}/classes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          classes = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        print('Failed to fetch classes: ${response.body}');
      }
    } catch (error) {
      print('Error fetching classes: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gradebook'),
      ),
      body: Row(
        children: [
          Container(
            width: 200,
            color: Colors.blue[50],
            child: ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classModel = classes[index];
                return ListTile(
                  title: Text(classModel['className']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GradebookDetailScreen(
                          token: widget.token,
                          userId: widget.userId,
                          className: classModel['className'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: Center(
              child: Text('Select a class to view grades'),
            ),
          ),
        ],
      ),
    );
  }
}
