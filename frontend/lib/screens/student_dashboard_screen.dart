import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../login_screen.dart'; // Make sure you have this import

class StudentDashboardScreen extends StatefulWidget {
  final String token;
  final String userId;
  final String firstName;
  final String lastName;

  StudentDashboardScreen({
    required this.token,
    required this.userId,
    required this.firstName,
    required this.lastName,
  });

  @override
  _StudentDashboardScreenState createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${widget.firstName} ${widget.lastName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 3 / 2,
                children: [
                  _buildUpcomingEventsCard(),
                  _buildAssignmentsLeftCard(),
                  _buildPerformanceGraphCard(),
                  _buildSchedulePackedCard(),
                  _buildCalendarSnippetCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEventsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upcoming Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...upcomingEvents.map((event) => ListTile(
                  title: Text(event['name']),
                  trailing: Text(event['time']),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsLeftCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assignments Left',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('$assignmentsLeft', style: TextStyle(fontSize: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceGraphCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: LineChart(LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 0.5),
                      FlSpot(1, 0.6),
                      FlSpot(2, 0.7),
                      FlSpot(3, performanceScore)
                    ],
                    isCurved: true,
                    barWidth: 4,
                    colors: [Colors.blue],
                  ),
                ],
              )),
            ),
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

  Widget _buildCalendarSnippetCard() {
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
}
