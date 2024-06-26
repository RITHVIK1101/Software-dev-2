import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class GradebookDetailScreen extends StatefulWidget {
  final String token;
  final String userId;
  final String className;

  GradebookDetailScreen({
    required this.token,
    required this.userId,
    required this.className,
  });

  @override
  _GradebookDetailScreenState createState() => _GradebookDetailScreenState();
}

class _GradebookDetailScreenState extends State<GradebookDetailScreen> {
  List<Map<String, dynamic>> formativeGrades = [];
  List<Map<String, dynamic>> summativeGrades = [];
  bool _detailedView = true;

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  Future<void> _fetchGrades() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/students/${widget.userId}/grades'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> allGrades = List<Map<String, dynamic>>.from(json.decode(response.body));

        setState(() {
          formativeGrades = allGrades
              .where((grade) => grade['category'].toString().toLowerCase() == 'formative' && grade['className'] == widget.className)
              .toList();
          summativeGrades = allGrades
              .where((grade) => grade['category'].toString().toLowerCase() == 'summative' && grade['className'] == widget.className)
              .toList();
        });
      } else {
        print('Failed to fetch grades: ${response.body}');
      }
    } catch (error) {
      print('Error fetching grades: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} Gradebook'),
        actions: [
          Switch(
            value: _detailedView,
            onChanged: (value) {
              setState(() {
                _detailedView = value;
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDataTable(formativeGrades, 'Formative Grades'),
            SizedBox(height: 16),
            _buildDataTable(summativeGrades, 'Summative Grades'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> grades, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        DataTable(
          columns: [
            DataColumn(label: Text('Due Date')),
            DataColumn(label: Text('Assignment')),
            DataColumn(label: Text('Grade')),
            DataColumn(label: Text('Score(%)')),
            DataColumn(label: Text('Points Earned')),
          ],
          rows: grades.map((grade) {
            return DataRow(cells: [
              DataCell(Text(grade['dueDate'] ?? 'N/A')),
              DataCell(Text(grade['assignmentName'])),
              DataCell(Text(_getLetterGrade(grade['percentage']))),
              DataCell(Text('${grade['percentage'] ?? 'N/A'}')),
              DataCell(Text('${grade['grade'] ?? 'Not graded'} out of ${grade['points']}')),
            ]);
          }).toList(),
        ),
      ],
    );
  }

  String _getLetterGrade(dynamic percentage) {
    if (percentage == null || percentage is String) return 'N/A';
    final percent = percentage as double;
    if (percent >= 90) return 'A';
    if (percent >= 80) return 'B';
    if (percent >= 70) return 'C';
    if (percent >= 60) return 'D';
    return 'F';
  }
}
