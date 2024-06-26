import 'package:flutter/material.dart';
import 'package:sdapp/auth_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _schoolCodeController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  String _role = 'student';
  bool _isLoading = false;
  String? _errorMessage;

  void _signup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = {
      'email': _emailController.text,
      'password': _passwordController.text,
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'schoolCode': _schoolCodeController.text,
      'grade': _role == 'student' ? _gradeController.text : 'N/A',
      'role': _role,
    };

    final response = await AuthService().register(data);

    setState(() {
      _isLoading = false;
    });

    if (response.isNotEmpty) {
      if (response.containsKey('token')) {
        Navigator.pushReplacementNamed(context, '/');
      } else {
        setState(() {
          _errorMessage =
              'Registration failed: ${response['message'] ?? 'Unknown error'}';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Registration failed: Unknown error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _schoolCodeController,
              decoration: InputDecoration(labelText: 'School Code'),
            ),
            if (_role == 'student')
              TextField(
                controller: _gradeController,
                decoration: InputDecoration(labelText: 'Grade'),
              ),
            DropdownButton<String>(
              value: _role,
              onChanged: (String? newValue) {
                setState(() {
                  _role = newValue!;
                });
              },
              items: <String>[
                'student',
                'teacher',
                'coach',
                'club coordinator',
                'extracurricular coordinator'
              ].map<DropdownMenuItem<String>>((String value) {
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
                    onPressed: _signup,
                    child: Text('Sign Up'),
                  ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('Already have an account? Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
