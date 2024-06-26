import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiUrl = 'http://your_backend_url';

  static Future<http.Response> addClass(String token, String className, String subject, String period, String design, String teacher) async {
    final response = await http.post(
      Uri.parse('$apiUrl/classes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'className': className,
        'subject': subject,
        'period': period,
        'design': design,
        'teacher': teacher,
      }),
    );
    return response;
  }
}
