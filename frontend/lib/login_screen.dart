import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'screens/teacher_screen.dart';
import 'screens/student_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _login() async {
    final result = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );

    if (result != null) {
      print('Login successful, token: ${result['token']}');
      if (result['role'] == 'teacher') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherScreen(
              token: result['token']!,
              school: result['school']!,
              firstName: result['firstName']!,
              lastName: result['lastName']!,
            ),
          ),
        );
      } else if (result['role'] == 'student') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentScreen(
              token: result['token']!,
              school: result['school']!,
              firstName: result['firstName']!,
              lastName: result['lastName']!,
              userId: '123456',
            ),
          ),
        );
      }
    } else {
      print('Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    double verticalPadding = screenHeight * 0.2;
    double horizontalPadding = screenWidth * 0.05;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/login_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(16.0),

            decoration: BoxDecoration(
              color: Colors.white, // Semi-transparent background for the box
              borderRadius: BorderRadius.circular(40.0), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            width: MediaQuery.of(context).size.width *
                0.5, // Box width relative to screen width
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/logo.png',
                  height: verticalPadding * 0.7,
                  fit: BoxFit.contain,
                ),
                Image.asset(
                  'images/login_text.png',
                  height: verticalPadding * 0.2,
                  fit: BoxFit.contain,
                ),
                Padding(
                  padding: EdgeInsets.only(
                      top: verticalPadding * 0.5,
                      left: horizontalPadding,
                      right: horizontalPadding,
                      bottom: verticalPadding * 0.1),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      left: horizontalPadding, right: horizontalPadding),
                  child: TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                    ),
                    obscureText: true,
                  ),
                ),
                SizedBox(height: screenHeight * 0.1),
                Padding(
                  padding: EdgeInsets.only(bottom: verticalPadding * 0.1),
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9.0),
                        ),
                        fixedSize:
                            Size(horizontalPadding * 8, verticalPadding * 0.3),
                        foregroundColor: CupertinoColors.white,
                        backgroundColor: Color.fromARGB(255, 10, 120, 189)),
                    child: Text(
                      'LOGIN',
                      style: TextStyle(
                          fontSize: verticalPadding * 0.15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: Text('Don\'t have an account? Sign up'),
                ),
                Padding(padding: EdgeInsets.only(bottom: verticalPadding)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
