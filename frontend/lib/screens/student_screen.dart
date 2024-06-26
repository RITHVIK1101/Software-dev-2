import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'gradebook_detailed_screen.dart'; // Import the new gradebook detail screen
import '../login_screen.dart';

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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Welcome $firstName $lastName',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('Assignments'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/student/assignments',
                  arguments: {
                    'token': token,
                    'userId': userId,
                  },
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Calendar'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/student/calendar',
                  arguments: {
                    'token': token,
                    'userId': userId,
                  },
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.class_),
              title: Text('Classes'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/student/classes',
                  arguments: {
                    'token': token,
                    'userId': userId,
                  },
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'A',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    WidgetSpan(
                      child: Transform.translate(
                        offset: const Offset(2, -8),
                        child: Text(
                          '+',
                          textScaleFactor: 0.9,
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              title: Text('Gradebook'),
              onTap: () {
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
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Sign Out'),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'Welcome to the student portal, $firstName $lastName!',
          style: TextStyle(fontSize: 18),
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
