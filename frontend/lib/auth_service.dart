import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://localhost:3000';
  final String hardcodedEmail = 'user@example.com';
  final String hardcodedPassword = 'password123';

  Future<Map<String, dynamic>?> login(String email, String password) async {
    if (email == hardcodedEmail && password == hardcodedPassword) {
      // Return a fixed response mimicking a successful login
      return {
        'token': 'hardcoded_token',
        'role': 'student',
        'school': 'Example School',
        'firstName': 'John',
        'lastName': 'Doe',
        'userId': '12345',
      };
    } else {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'token': data['token'] ?? '',
          'role': data['role'] ?? '',
          'school': data['school'] ?? '',
          'firstName': data['firstName'] ?? '',
          'lastName': data['lastName'] ?? '',
          'userId': data['userId'] ?? '',
        };
      } else {
        print('Error during login: ${response.body}');
        return null;
      }
    }
  }

  Future<Map<String, dynamic>?> register(
    String email,
    String password,
    String role,
    String schoolCode,
    String firstName,
    String lastName,
    String grade,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
        'role': role,
        'schoolCode': schoolCode,
        'firstName': firstName,
        'lastName': lastName,
        'grade': grade,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return {
        'token': data['token'] ?? '',
        'role': data['role'] ?? '',
        'school': data['school'] ?? '',
        'firstName': data['firstName'] ?? '',
        'lastName': data['lastName'] ?? '',
        'userId': data['userId'] ?? '',
      };
    } else {
      print('Error during registration: ${response.body}');
      return null;
    }
  }
}
