// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:absen_app/Models/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:absen_app/config/api_config.dart'; // <-- Import config

class AuthService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<AppUser> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/login');

    // Tambahkan instance secure storage
    const storage = FlutterSecureStorage();
    const tokenKey = 'auth_token';

    // Get device info
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? deviceId;
    String? deviceName;

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceName = androidInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
        deviceName = iosInfo.name;
      } else if (Platform.isLinux) {
        LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        deviceId = linuxInfo.machineId ?? 'linux-machine-id-${DateTime.now().millisecondsSinceEpoch}';
        deviceName = linuxInfo.name;
      } else if (Platform.isWindows) {
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        deviceId = windowsInfo.deviceId;
        deviceName = windowsInfo.computerName;
      } else if (Platform.isMacOS) {
        MacOsDeviceInfo macOsInfo = await deviceInfo.macOsInfo;
        deviceId = macOsInfo.systemGUID;
        deviceName = macOsInfo.computerName;
      }
    } catch (e) {
      print("Failed to get device info: $e");
    }

    // Fallback if device info failed
    if (deviceId == null) {
      deviceId = 'unknown-device-${DateTime.now().millisecondsSinceEpoch}';
      deviceName = 'Unknown Device';
    }

    try {
// PERBAIKAN: Tambah timeout untuk menghindari hanging
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': username,
              'password': password,
              'device_id': deviceId,
              'device_name': deviceName,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

// PERBAIKAN: Validasi struktur response
        if (!data.containsKey('token') || !data.containsKey('user')) {
          throw Exception('Invalid response format from server');
        }

// Simpan token
        await storage.write(key: tokenKey, value: data['token']);

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
        throw Exception(
            'Gagal login: ${errorData['message'] ?? 'Unknown error'}');
      }
    } on http.ClientException catch (e) {
      print('ClientException: $e');
      throw Exception(
          'Tidak dapat terhubung ke server. Pastikan server Laravel berjalan.');
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
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'auth_token');
  }

  // PENAMBAHAN: Method untuk cek status login
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

// PERBAIKAN: Method untuk logout
  Future<void> logout() async {
    const storage = FlutterSecureStorage();
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
      await storage.delete(key: 'auth_token');
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
