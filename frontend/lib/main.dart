import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'screens/teacher_screen.dart';
import 'screens/student_screen.dart';
import 'screens/student_classes_screen.dart'; // Import the screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Binder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/teacher': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return TeacherScreen(
            token: args['token'],
            school: args['school'],
            firstName: args['firstName'],
            lastName: args['lastName'],
          );
        },
        '/student': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return StudentScreen(
            token: args['token'],
            school: args['school'],
            firstName: args['firstName'],
            lastName: args['lastName'],
            userId: args['userId'],
          );
        },
        '/student/classes': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return StudentClassesScreen(
            token: args['token'],
            userId: args['userId'],
          );
        },
      },
    );
  }
}
