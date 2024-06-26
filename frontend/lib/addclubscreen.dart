import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddClubScreen extends StatefulWidget {
  final String token;
  final String userId;

  AddClubScreen({
    required this.token,
    required this.userId,
  });

  @override
  _AddClubScreenState createState() => _AddClubScreenState();
}

class _AddClubScreenState extends State<AddClubScreen> {
  final TextEditingController _clubNameController = TextEditingController();
  final TextEditingController _areaOfInterestController =
      TextEditingController();
  final TextEditingController _helpEmailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _createClub() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await http.post(
      Uri.parse('http://localhost:3000/clubs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'name': _clubNameController.text,
        'coordinatorId': widget.userId,
        'areaOfInterest': _areaOfInterestController.text,
        'helpEmail': _helpEmailController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 201) {
      Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage = 'Failed to create club';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Club'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _clubNameController,
              decoration: InputDecoration(labelText: 'Club Name'),
            ),
            TextField(
              controller: _areaOfInterestController,
              decoration: InputDecoration(labelText: 'Area of Interest'),
            ),
            TextField(
              controller: _helpEmailController,
              decoration: InputDecoration(labelText: 'Help Email'),
            ),
            SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createClub,
                    child: Text('Create Club'),
                  ),
          ],
        ),
      ),
    );
  }
}
