import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddSportScreen extends StatefulWidget {
  final String token;
  final String userId;

  AddSportScreen({
    required this.token,
    required this.userId,
  });

  @override
  _AddSportScreenState createState() => _AddSportScreenState();
}

class _AddSportScreenState extends State<AddSportScreen> {
  final TextEditingController _teamNameController = TextEditingController();
  String _selectedSport = 'Basketball';
  String _selectedTeam = 'Varsity';
  bool _isLoading = false;
  String? _errorMessage;

  void _createTeam() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await http.post(
      Uri.parse('http://localhost:3000/teams'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'name': _teamNameController.text,
        'coachId': widget.userId,
        'sport': _selectedSport,
        'team': _selectedTeam,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 201) {
      Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage = 'Failed to create team';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Sport Team'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _teamNameController,
              decoration: InputDecoration(labelText: 'Team Name'),
            ),
            DropdownButton<String>(
              value: _selectedSport,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSport = newValue!;
                });
              },
              items: <String>['Basketball', 'Soccer', 'Baseball', 'Football']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            DropdownButton<String>(
              value: _selectedTeam,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTeam = newValue!;
                });
              },
              items: <String>['C team', 'Junior Varsity', 'Varsity']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
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
                    onPressed: _createTeam,
                    child: Text('Create Team'),
                  ),
          ],
        ),
      ),
    );
  }
}
