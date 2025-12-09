// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:absen_app/Models/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:absen_app/config/api_config.dart'; // <-- Import config

import 'package:uuid/uuid.dart';

class AuthService {
  static const String _baseUrl = ApiConfig.baseUrl;

  // Helper untuk mendapatkan payload device lengkap
  Future<Map<String, String>> _getDevicePayload() async {
    const storage = FlutterSecureStorage();
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    String hardwareId = 'unknown';
    String manufacturer = 'unknown';
    String model = 'unknown';
    String osVersion = 'unknown';
    String buildId = '';
    String deviceName = 'Unknown Device';

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        hardwareId = androidInfo.id; // stable hardware id
        manufacturer = androidInfo.manufacturer;
        model = androidInfo.model;
        osVersion =
            'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
        buildId = androidInfo.display; // or androidInfo.id
        deviceName = androidInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        // identifierForVendor can change on reinstall, but we use it as hardware_id base
        hardwareId = iosInfo.identifierForVendor ?? 'unknown_ios_id';
        manufacturer = 'Apple';
        model = iosInfo.utsname.machine;
        osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
        buildId = iosInfo.utsname.version;
        deviceName = iosInfo.name;
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    // --- APP INSTANCE ID (UUID persisten hanya selama app tidak di-uninstall) ---
    // Backend akan mendeteksi jika ini berubah untuk update DB.
    String? appInstanceId = await storage.read(key: 'app_instance_id');
    if (appInstanceId == null) {
      appInstanceId = const Uuid().v4();
      await storage.write(key: 'app_instance_id', value: appInstanceId);
    }

    return {
      'hardware_id': hardwareId,
      'app_instance_id': appInstanceId,
      'manufacturer': manufacturer,
      'model': model,
      'os_version': osVersion,
      'build_id': buildId,
      'device_name': deviceName, // For display in users table if needed legacy
    };
  }

  Future<AppUser> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    const storage = FlutterSecureStorage();
    const tokenKey = 'auth_token';

    // 1. Get Comprehensive Device Payload
    final devicePayload = await _getDevicePayload();

    try {
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
              ...devicePayload, // Spread payload: hardware_id, app_instance_id, etc.
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Response Status: ${response.statusCode}');
      // print('Response Body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!data.containsKey('token') || !data.containsKey('user')) {
          throw Exception('Invalid response format from server');
        }

        await storage.write(key: tokenKey, value: data['token']);

        return AppUser.fromJson(data['user']);
      } else if (response.statusCode == 401) {
        // Bisa invalid credentials atau token mismatch (tapi login endpoint jarang token mismatch kecuali middleware aneh)
        // 401 biasanya invalid username/password
        throw Exception('Username atau password salah.');
      } else if (response.statusCode == 403) {
        // Forbidden: Device Mismatch
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Akses ditolak.');
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
      throw Exception(
          'Server mengembalikan response yang tidak valid. Cek koneksi internet/server.');
    } catch (e) {
      print('General Exception: $e');
      rethrow;
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
