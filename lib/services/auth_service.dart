import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class AuthService {
  final String baseUrl = Config.apiUrl;
  final storage = new FlutterSecureStorage();

  Future<void> register(String username, String password) async {
    print("Attempting registration");
    final response = await http
        .post(
          Uri.parse('$baseUrl/register'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'username': username,
            'password': password,
          }),
        )
        .timeout(
          const Duration(seconds: 3),
        );

    if (response.statusCode != 200) {
      final responseJson = jsonDecode(response.body);
      final message = responseJson["detail"];
      print(responseJson["detail"]);
      throw Exception(message);
    }
  }

Future<void> login(String username, String password) async {
  print("Attempting login");
  final response = await http.post(
    Uri.parse('$baseUrl/token'),  // Ensure the correct endpoint is used
    headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',  // Use form-encoded content type
    },
    body: {
      'username': username,  // Form-urlencoded data
      'password': password,
    },
  ).timeout(const Duration(seconds: 3),);

  print(response.body);  // Debug print to show the full response

  if (response.statusCode == 200) {
    final responseJson = jsonDecode(response.body);
    await storage.write(key: 'token', value: responseJson['access_token']);
  } else {
    final responseJson = jsonDecode(response.body);
    final message = responseJson["detail"];
    print(message);
    throw Exception(message);
  }
}


  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
  }

  Future<String?> getUsername() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/username'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body);
      return responseJson['username'];
    } else {
      throw Exception('Failed to fetch username');
    }
  }
}
