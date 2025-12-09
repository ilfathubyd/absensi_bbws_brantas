// lib/screens/splash_screen.dart

import 'package:absen_app/Models/models/user.dart';
import 'package:absen_app/screens/login_screen.dart'; // Ganti dengan path halaman login Anda
import 'package:absen_app/screens/pic/pic_dashboard.dart'; // Ganti dengan path dashboard Anda
import 'package:absen_app/screens/user/user_shortcut_menu.dart';
import 'package:absen_app/services/auth_service.dart';
import 'package:flutter/material.dart'; // Hapus jika tidak perlu

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation =
        Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Beri sedikit jeda agar tidak terlalu cepat
    await Future.delayed(const Duration(seconds: 3));

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (mounted) {
        if (isLoggedIn) {
          // Jika ada token, coba validasi dengan getProfile
          final AppUser user = await _authService.getProfile();

          // PERBAIKAN: Arahkan ke dashboard yang sesuai berdasarkan role
          if (!mounted) return;
          Widget destination = const LoginScreen(); // Default
          if (user.isPIC()) {
            destination = const PICDashboard();
          } else if (user.isUser()) {
            destination = const UserShortcutMenu();
          }
          // TODO: Tambahkan kondisi untuk admin jika ada AdminDashboard

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => destination),
          );
        } else {
          // Jika tidak ada token, ke halaman login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) =>
                    const LoginScreen()), // Ganti ke halaman login Anda
          );
        }
      }
    } catch (e) {
      // Jika terjadi error (misal: token expired, tidak ada koneksi),
      // arahkan ke halaman login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) =>
                  const LoginScreen()), // Ganti ke halaman login Anda
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1565C0),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo1.png',
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.qr_code_scanner_rounded,
                              color: Colors.white, size: 120);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Absensi App',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'v1.0.0 © 2024',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
