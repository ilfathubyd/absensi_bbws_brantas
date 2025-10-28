// lib/screens/splash_screen.dart

import 'package:absen_app/screens/login_screen.dart'; // Ganti dengan path halaman login Anda
import 'package:absen_app/screens/pic/pic_dashboard.dart'; // Ganti dengan path dashboard Anda
import 'package:absen_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Beri sedikit jeda agar tidak terlalu cepat
    await Future.delayed(const Duration(seconds: 1));

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (mounted) {
        if (isLoggedIn) {
          // Jika ada token, coba validasi dengan getProfile
          // Ini untuk memastikan token masih valid di server
          await _authService.getProfile();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PICDashboard()), // Ganti ke dashboard yang sesuai
          );
        } else {
          // Jika tidak ada token, ke halaman login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()), // Ganti ke halaman login Anda
          );
        }
      }
    } catch (e) {
      // Jika terjadi error (misal: token expired, tidak ada koneksi),
      // arahkan ke halaman login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()), // Ganti ke halaman login Anda
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Memeriksa sesi...'),
          ],
        ),
      ),
    );
  }
}
