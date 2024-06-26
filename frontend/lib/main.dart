import 'package:flutter/material.dart';
import 'package:sdapp/login_screen.dart';
import 'package:sdapp/signup_screen.dart';
import 'package:sdapp/screens/teacher_screen.dart';
import 'package:sdapp/screens/student_screen.dart';
import 'package:sdapp/screens/student_classes_screen.dart';
import 'package:sdapp/screens/teacher_assignments_screen.dart';
import 'package:sdapp/screens/student_assignments_screen.dart';
import 'package:sdapp/screens/teacher_to_grade_screen.dart';
import 'package:sdapp/screens/gradebook_detailed_screen.dart';
import 'package:sdapp/screens/calendar_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School App',
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
            teacherId: args['teacherId'],
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
        '/teacher/assignments': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return TeacherAssignmentsScreen(
            className: args['className'],
            token: args['token'],
            teacherId: args['teacherId'],
          );
        },
        '/student/assignments': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return StudentAssignmentsScreen(
            token: args['token'],
            userId: args['userId'],
          );
        },
        '/teacher/to-grade': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return TeacherToGradeScreen(
            token: args['token'],
            teacherId: args['teacherId'],
            firstName: args['firstName'],
            lastName: args['lastName'],
          );
        },
        '/student/gradebook/detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return GradebookDetailScreen(
            token: args['token'],
            userId: args['userId'],
            className: args['className'],
          );
        },
        '/student/calendar': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return CalendarScreen(
            token: args['token'],
            userId: args['userId'],
          );
        },
      },
    );
  }
}
