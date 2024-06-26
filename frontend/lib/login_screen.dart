import 'package:flutter/material.dart';
import 'package:sdapp/auth_service.dart';
import 'package:sdapp/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text;
    final password = _passwordController.text;
    final response = await AuthService().login(email, password);

    setState(() {
      _isLoading = false;
    });

    if (response.isNotEmpty) {
      if (response['role'] == 'teacher') {
        Navigator.pushReplacementNamed(
          context,
          '/teacher',
          arguments: {
            'token': response['token'],
            'school': response['school'],
            'firstName': response['firstName'],
            'lastName': response['lastName'],
            'teacherId': response['userId'],
          },
        );
      } else if (response['role'] == 'student') {
        Navigator.pushReplacementNamed(
          context,
          '/student',
          arguments: {
            'token': response['token'],
            'school': response['school'],
            'firstName': response['firstName'],
            'lastName': response['lastName'],
            'userId': response['userId'],
          },
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                  ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupScreen()),
                );
              },
              child: Text('Don\'t have an account? Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
