// lib/screens/login_screen.dart

import 'package:absen_app/screens/admin/admin_dashboard.dart';
import 'package:absen_app/screens/user/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:absen_app/screens/pic/pic_dashboard.dart' show PICDashboard;
import 'package:absen_app/Models/models/user.dart';
import 'package:absen_app/services/auth_service.dart';

// TAMBAHAN: Import untuk Guest Dashboard dan modal baru
import 'package:absen_app/screens/guest/guest_dashboard.dart' show GuestDashboard;
import 'package:absen_app/screens/guest/guest_room_modal.dart' show GuestRoomModal;

late AppUser currentUser;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isGuestLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final username = _usernameCtrl.text.trim();
      final password = _passCtrl.text.trim();

      if (username.isEmpty || password.isEmpty) {
        throw Exception('Username dan password tidak boleh kosong');
      }

      final user = await _authService.login(username, password);
      currentUser = user;

      if (!mounted) return;

      Widget targetScreen;
      String screenName;

      switch (user.id_role) {
        case 1: // Admin
        targetScreen = const AdminDashboard();
          screenName = 'Admin Dashboard';
          break;
        case 2: // PIC
          targetScreen = const PICDashboard();
          screenName = 'PIC Dashboard';
          break;
        case 3: // User biasa
          targetScreen = const UserDashboard();
          screenName = 'User Dashboard';
          break;
        default:
          targetScreen = const Placeholder(
            child: Center(child: Text("Default User Dashboard")),
          );
          screenName = 'User Dashboard (Default)';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login berhasil! Mengalihkan ke $screenName...'),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 2),
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );

    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString().replaceAll('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loginAsGuest() {
    if (_isGuestLoading) return;

    setState(() {
      _isGuestLoading = true;
    });

    try {
      final guestUser = AppUser(
        id_user: 0,
        username: 'guest',
        name: 'Guest User',
        id_role: 3,
        role: 'Guest',
        email: '',
      );
      currentUser = guestUser;

      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isGuestLoading = false;
          });
          _showRoomCodeModal(context);
        }
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _isGuestLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat login sebagai guest: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showRoomCodeModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const GuestRoomModal();
      },
    );
  }

  // FUNGSI UTAMA UNTUK RESPONSIVITAS
  double _getResponsiveSize(BuildContext context, double small, double medium, double large) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return small; // Untuk layar sangat kecil
    if (width < 600) return medium; // Untuk layar ponsel standar
    return large; // Untuk layar besar / tablet
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 350;

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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                // PERUBAHAN: Padding responsif
                horizontal: _getResponsiveSize(context, 16, 20, 24),
                vertical: _getResponsiveSize(context, 8, 16, 20),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isSmallScreen ? 320 : 400,
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
                ),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.white,
                  child: Padding(
                    // PERUBAHAN: Padding dalam card responsif
                    padding: EdgeInsets.all(_getResponsiveSize(context, 16, 24, 32)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          // PERUBAHAN: Ukuran logo responsif
                          height: _getResponsiveSize(context, 80, 90, 100),
                          width: _getResponsiveSize(context, 80, 90, 100),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFC107).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                'assets/images/logo1.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 40,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        // PERUBAHAN: Jarak vertikal responsif
                        SizedBox(height: _getResponsiveSize(context, 16, 20, 24)),

                        // Title
                        Text(
                          'Login Absensi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            // PERUBAHAN: Ukuran font responsif
                            fontSize: _getResponsiveSize(context, 20, 23, 25),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 4, 6, 8)),

                        // Subtitle
                        Text(
                          'Silakan masuk untuk melanjutkan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            // PERUBAHAN: Ukuran font responsif
                            fontSize: _getResponsiveSize(context, 12, 13, 14),
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 20, 28, 32)),

                        // Username field
                        TextField(
                          controller: _usernameCtrl,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(
                              Icons.person,
                              color: const Color(0xFF1565C0),
                              // PERUBAHAN: Ukuran ikon responsif
                              size: _getResponsiveSize(context, 18, 20, 22),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1565C0),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 12, 14, 16)),

                        // Password field
                        TextField(
                          controller: _passCtrl,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(
                              Icons.lock,
                              color: const Color(0xFF1565C0),
                              // PERUBAHAN: Ukuran ikon responsif
                              size: _getResponsiveSize(context, 18, 20, 22),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1565C0),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          obscureText: true,
                        ),
                        SizedBox(height: _getResponsiveSize(context, 20, 24, 28)),

                        // Tombol Login Utama
                        Container(
                          // PERUBAHAN: Tinggi tombol responsif
                          height: _getResponsiveSize(context, 45, 48, 50),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFC107),
                                Color(0xFFFFB300),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFC107).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                              // PERUBAHAN: Ukuran loading indicator responsif
                              width: _getResponsiveSize(context, 20, 22, 24),
                              height: _getResponsiveSize(context, 20, 22, 24),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                                : Text(
                              'LOGIN',
                              style: TextStyle(
                                color: Colors.white,
                                // PERUBAHAN: Ukuran font tombol responsif
                                fontSize: _getResponsiveSize(context, 14, 15, 16),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                        // Tombol Login Sebagai Guest
                        SizedBox(height: _getResponsiveSize(context, 12, 14, 16)),
                        Container(
                          // PERUBAHAN: Tinggi tombol responsif
                          height: _getResponsiveSize(context, 45, 48, 50),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF757575),
                                Color(0xFF9E9E9E),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isGuestLoading ? null : _loginAsGuest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isGuestLoading
                                ? SizedBox(
                              // PERUBAHAN: Ukuran loading indicator responsif
                              width: _getResponsiveSize(context, 20, 22, 24),
                              height: _getResponsiveSize(context, 20, 22, 24),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  // PERUBAHAN: Ukuran ikon responsif
                                  size: _getResponsiveSize(context, 16, 18, 20),
                                ),
                                SizedBox(width: _getResponsiveSize(context, 6, 7, 8)),
                                Flexible(
                                  child: Text(
                                    'LOGIN SEBAGAI GUEST',
                                    style: TextStyle(
                                      color: Colors.white,
                                      // PERUBAHAN: Ukuran font tombol responsif
                                      fontSize: _getResponsiveSize(context, 12, 14, 16),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
