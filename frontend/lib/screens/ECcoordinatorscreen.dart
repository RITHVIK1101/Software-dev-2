import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'addsportsscreen.dart';
import 'addclubscreen.dart';

class EcCoordinatorChoiceScreen extends StatefulWidget {
  final String token;
  final String userId;

  const EcCoordinatorChoiceScreen({
    Key? key,
    required this.token,
    required this.userId,
  }) : super(key: key);

  @override
  _EcCoordinatorChoiceScreenState createState() =>
      _EcCoordinatorChoiceScreenState();
}

class _EcCoordinatorChoiceScreenState extends State<EcCoordinatorChoiceScreen> {
  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> clubs = [];
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTeamsAndClubs();
    fetchStudents(); // Ensure students are fetched during initialization
  }

  Future<void> fetchTeamsAndClubs() async {
    setState(() => isLoading = true);
    try {
      Dio dio = Dio();
      dio.options.headers["Authorization"] = "Bearer ${widget.token}";

      var response = await dio
          .get('http://localhost:3000/users/${widget.userId}/extracurriculars');

      setState(() {
        teams = List<Map<String, dynamic>>.from(response.data['teams']);
        clubs = List<Map<String, dynamic>>.from(response.data['clubs']);
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching teams and clubs: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to fetch teams and clubs: ${e.toString()}')),
      );
    }
  }

  Future<void> fetchStudents() async {
    try {
      Dio dio = Dio();
      dio.options.headers["Authorization"] = "Bearer ${widget.token}";

      var response = await dio
          .get('http://localhost:3000/users/${widget.userId}/school/students');

      setState(() {
        students = List<Map<String, dynamic>>.from(response.data);
      });
    } catch (e) {
      print("Error fetching students: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch students: ${e.toString()}')),
      );
    }
  }

  void addStudentPopup(String id, String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddStudentDialog(
          id: id,
          type: type,
          students: students,
          token: widget.token,
          onStudentAdded: fetchTeamsAndClubs,
        );
      },
    );
  }

  void schedulePracticePopup(String id, String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SchedulePracticeDialog(
          id: id,
          type: type,
          token: widget.token,
          onPracticeScheduled: fetchTeamsAndClubs,
        );
      },
    );
  }

  void signOut() {
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Extracurricular Coordinator'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      children: [
                        ...teams.map(
                            (team) => buildExtracurricularCard(team, 'team')),
                        ...clubs.map(
                            (club) => buildExtracurricularCard(club, 'club')),
                      ],
                    ),
                  ),
                  buildAddButton(
                      'Add Sports',
                      AddSportScreen(
                          token: widget.token, userId: widget.userId)),
                  buildAddButton(
                      'Add Clubs',
                      AddClubScreen(
                          token: widget.token, userId: widget.userId)),
                ],
              ),
      ),
    );
  }

  Widget buildExtracurricularCard(Map<String, dynamic> item, String type) {
    return Card(
      child: ListTile(
        title: Text(item['name']),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.person_add),
              onPressed: () {
                fetchStudents(); // Ensure the latest students are fetched before showing the dialog
                addStudentPopup(item['_id'], type);
              },
            ),
            IconButton(
              icon: Icon(Icons.schedule),
              onPressed: () => schedulePracticePopup(item['_id'], type),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAddButton(String text, Widget screen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => screen)),
        child: Text(text),
      ),
    );
  }
}

class AddStudentDialog extends StatefulWidget {
  final String id;
  final String type;
  final List<Map<String, dynamic>> students;
  final String token;
  final VoidCallback onStudentAdded;

  const AddStudentDialog({
    Key? key,
    required this.id,
    required this.type,
    required this.students,
    required this.token,
    required this.onStudentAdded,
  }) : super(key: key);

  @override
  _AddStudentDialogState createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredStudents = [];
  List<String> selectedStudentIds = [];

  @override
  void initState() {
    super.initState();
    filteredStudents = widget.students;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Student to ${widget.type}'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: searchController,
              decoration: InputDecoration(hintText: 'Search Students'),
              onChanged: (value) {
                setState(() {
                  filteredStudents = widget.students
                      .where((student) =>
                          student['firstName']
                              .toLowerCase()
                              .contains(value.toLowerCase()) ||
                          student['lastName']
                              .toLowerCase()
                              .contains(value.toLowerCase()))
                      .toList();
                });
              },
            ),
            SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final isSelected =
                      selectedStudentIds.contains(student['_id']);
                  return CheckboxListTile(
                    title:
                        Text('${student['firstName']} ${student['lastName']}'),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedStudentIds.add(student['_id']);
                        } else {
                          selectedStudentIds.remove(student['_id']);
                        }
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
          child: Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text('Add Students'),
          onPressed: () {
            addStudents();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void addStudents() async {
    try {
      Dio dio = Dio();
      dio.options.headers["Authorization"] = "Bearer ${widget.token}";
      await dio.post(
        'http://localhost:3000/extracurricular/${widget.id}/students',
        data: {
          'studentIds': selectedStudentIds,
          'type': widget.type,
        },
      );
      widget.onStudentAdded();
    } catch (e) {
      print("Error adding students: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add students: ${e.toString()}')),
      );
    }
  }
}

class SchedulePracticeDialog extends StatelessWidget {
  final String id;
  final String type;
  final String token;
  final VoidCallback onPracticeScheduled;

  SchedulePracticeDialog({
    required this.id,
    required this.type,
    required this.token,
    required this.onPracticeScheduled,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController startTimeController = TextEditingController();
    TextEditingController durationController = TextEditingController();

    return AlertDialog(
      title: Text('Schedule Practice for $type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: startTimeController,
            decoration: InputDecoration(hintText: 'Start Time (e.g. 10:00)'),
          ),
          TextField(
            controller: durationController,
            decoration: InputDecoration(hintText: 'Duration (minutes)'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text('Schedule'),
          onPressed: () async {
            try {
              Dio dio = Dio();
              dio.options.headers["Authorization"] = "Bearer $token";
              await dio.post(
                'http://localhost:3000/extracurricular/$id/times',
                data: {
                  'start': startTimeController.text,
                  'duration': durationController.text,
                  'type': type,
                },
              );
              Navigator.of(context).pop();
              onPracticeScheduled();
            } catch (e) {
              print("Error scheduling practice: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Failed to schedule practice: ${e.toString()}')),
              );
            }
          },
        ),
      ],
    );
  }
}
