import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentClassesScreen extends StatefulWidget {
  final String token;
  final String userId; 

  StudentClassesScreen({required this.token, required this.userId});
  
  @override
  _StudentClassesScreenState createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  List<Map<String, dynamic>> classes = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    final url = 'http://localhost:3000/students/${widget.userId}/classes';
    print('Fetching classes from URL: $url');
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
        title: Text('My Classes'),
      ),
      body: classes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(classes[index]['className']),
                    subtitle: Text('${classes[index]['subject']} - Period ${classes[index]['period']}'),
                  ),
                );
              },
            ),
    );
  }
}
