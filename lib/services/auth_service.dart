// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absen_app/Models/models/user.dart';

class AuthService {
// PERBAIKAN: Ganti dengan URL yang benar
static const String _baseUrl = "http://192.168.50.60:8000/api"; // atau http://localhost:8000/api

Future<AppUser> login(String username, String password) async {
final url = Uri.parse('$_baseUrl/login');

try {
// PERBAIKAN: Tambah timeout untuk menghindari hanging
final response = await http.post(
url,
headers: {
'Content-Type': 'application/json',
'Accept': 'application/json',
},
body: jsonEncode({
'username': username,
'password': password,
}),
).timeout(const Duration(seconds: 30));

print('Response Status: ${response.statusCode}');
print('Response Body: ${response.body}');

if (response.statusCode == 200) {
final data = jsonDecode(response.body);

// PERBAIKAN: Validasi struktur response
if (!data.containsKey('token') || !data.containsKey('user')) {
throw Exception('Invalid response format from server');
}

// Simpan token
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', data['token']);

// PERBAIKAN: Debug print untuk melihat data user
print('User data from API: ${data['user']}');

return AppUser.fromJson(data['user']);
} else if (response.statusCode == 401) {
throw Exception('Username atau password salah.');
} else if (response.statusCode == 422) {
final errorData = jsonDecode(response.body);
String errorMessage = 'Validation error';
if (errorData['errors'] != null) {
final errors = errorData['errors'] as Map<String, dynamic>;
errorMessage = errors.values.first.first.toString();
}
throw Exception(errorMessage);
} else {
final errorData = jsonDecode(response.body);
throw Exception('Gagal login: ${errorData['message'] ?? 'Unknown error'}');
}
} on http.ClientException catch (e) {
print('ClientException: $e');
throw Exception('Tidak dapat terhubung ke server. Pastikan server Laravel berjalan.');
} on FormatException catch (e) {
print('FormatException: $e');
throw Exception('Server mengembalikan response yang tidak valid.');
} catch (e) {
print('General Exception: $e');
if (e.toString().contains('Exception:')) {
rethrow; // Re-throw jika sudah custom exception
}
throw Exception('Terjadi kesalahan: ${e.toString()}');
}
}

// PERBAIKAN: Method untuk get token
Future<String?> getToken() async {
final prefs = await SharedPreferences.getInstance();
return prefs.getString('auth_token');
}

// PERBAIKAN: Method untuk logout
Future<void> logout() async {
try {
final token = await getToken();
if (token != null) {
final url = Uri.parse('$_baseUrl/logout');
await http.post(
url,
headers: {
'Content-Type': 'application/json',
'Accept': 'application/json',
'Authorization': 'Bearer $token',
},
).timeout(const Duration(seconds: 10));
}
} catch (e) {
// Ignore logout error, just clear local storage
print('Logout error: $e');
} finally {
// Clear local storage
final prefs = await SharedPreferences.getInstance();
await prefs.remove('auth_token');
}
}

// PERBAIKAN: Method untuk get profile
Future<AppUser> getProfile() async {
final token = await getToken();
if (token == null) {
throw Exception('Not authenticated');
}

final url = Uri.parse('$_baseUrl/profile');
final response = await http.get(
url,
headers: {
'Content-Type': 'application/json',
'Accept': 'application/json',
'Authorization': 'Bearer $token',
},
).timeout(const Duration(seconds: 30));

if (response.statusCode == 200) {
final data = jsonDecode(response.body);
return AppUser.fromJson(data);
} else if (response.statusCode == 401) {
await logout(); // Clear invalid token
throw Exception('Session expired. Please login again.');
} else {
throw Exception('Failed to get profile');
}
}


}