import 'package:flutter/material.dart';
import 'package:absen_app/screens/admin/admin_dashboard.dart'
    show AdminDashboard;
import 'package:absen_app/screens/user/user_dashboard.dart' show UserDashboard;
import 'package:absen_app/Models/models/user.dart';

late AppUser currentUser; // global user login

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isAdmin = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() {
    final username = _usernameCtrl.text.trim();
    final password = _passCtrl.text.trim();

    // TODO: Validasi ke backend sesuai role
    if (_isAdmin) {
      print("Login Admin: $username");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      // login user
      currentUser = AppUser(
        id: "u123",
        name: username,
        email: "$username@example.com", // dummy email
        photoUrl: "https://i.pravatar.cc/150?u=$username",
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1565C0), // Biru tua
              Color(0xFF42A5F5), // Biru muda
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon atau Logo
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107), // Background kuning
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
                          padding: const EdgeInsets.all(
                            8.0,
                          ), // Beri jarak dari tepi
                          child: Image.asset(
                            'assets/images/logo1.png',
                            fit: BoxFit.contain, // Atau BoxFit.cover
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Judul
                    const Text(
                      'Login Absensi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Silakan masuk untuk melanjutkan',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // TextField username
                    TextField(
                      controller: _usernameCtrl,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Color(0xFF1565C0),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1565C0),
                          ),
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
                        labelStyle: const TextStyle(color: Color(0xFF1565C0)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // TextField password
                    TextField(
                      controller: _passCtrl,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Color(0xFF1565C0),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1565C0),
                          ),
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
                        labelStyle: const TextStyle(color: Color(0xFF1565C0)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),

                    // Checkbox admin dengan container
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1), // Kuning muda
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFC107).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _isAdmin,
                            onChanged:
                                (v) => setState(() => _isAdmin = v ?? false),
                            activeColor: const Color(0xFFFFC107),
                            checkColor: Colors.white,
                          ),
                          const Text(
                            'Login sebagai Admin',
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol login
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFC107), // Kuning
                            Color(0xFFFFB300), // Kuning tua
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
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'LOGIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
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
    );
  }
}
