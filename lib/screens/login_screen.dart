//login_screen.dart

import 'package:absen_app/screens/admin/admin_dashboard.dart';
import 'package:absen_app/screens/user/user_shortcut_menu.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // TAMBAHAN: Import untuk url_launcher
import 'package:line_awesome_flutter/line_awesome_flutter.dart'; // TAMBAHAN: Import Line Awesome
import 'package:absen_app/screens/pic/pic_dashboard.dart' show PICDashboard;
import 'package:absen_app/Models/models/user.dart';
import 'package:absen_app/services/auth_service.dart';
import 'package:absen_app/utils/snackbar_helper.dart';

// TAMBAHAN: Import untuk Guest Dashboard dan modal baru
// import 'package:absen_app/screens/guest/guest_dashboard.dart' show GuestDashboard;
// import 'package:absen_app/screens/guest/guest_room_modal.dart' show GuestRoomModal;

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
  // bool _isGuestLoading = false;

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
          targetScreen = const UserShortcutMenu();
          screenName = 'User Menu';
          break;
        default:
          targetScreen = const Placeholder(
            child: Center(child: Text("Default User Dashboard")),
          );
          screenName = 'User Dashboard (Default)';
      }

      SnackBarHelper.success(
        context,
        'Login berhasil! Mengalihkan ke $screenName...',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString().replaceAll('Exception: ', '');

      SnackBarHelper.error(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // TAMBAHAN: Method untuk membuka WhatsApp
  Future<void> _launchWhatsApp(String phoneNumber) async {
    const message = "Halo mas, kami ingin custom aplikasi SIMRAPEL";
    final url =
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode:
              LaunchMode.externalApplication, // Penting: buka di app eksternal
        );
      } else {
        if (mounted) {
          SnackBarHelper.error(context, 'Tidak dapat membuka WhatsApp');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.error(context, 'Error: $e');
      }
    }
  }

  // TAMBAHAN: Method untuk membuka email
  Future<void> _launchEmail(String email) async {
    final url = 'mailto:$email';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          SnackBarHelper.error(context, 'Tidak dapat membuka aplikasi email');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.error(context, 'Error: $e');
      }
    }
  }

  // TAMBAHAN: Method untuk menampilkan popup contact person
  void _showContactPersonPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(LineAwesomeIcons.whatsapp,
                  color: Color(
                      0xFF1565C0)), // UBAH: Gunakan LineAwesome WhatsApp icon
              SizedBox(width: 8),
              Text(
                'Contact Person',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Untuk bantuan teknis atau informasi lebih lanjut, hubungi:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              // Admin IT Support
              GestureDetector(
                onTap: () => _launchWhatsApp('6281333753902'),
                child: _buildContactItem(
                  LineAwesomeIcons
                      .whatsapp, // UBAH: Gunakan LineAwesome WhatsApp icon
                  'Admin IT Support (Ilfath)',
                  '+62 813-3375-3902',
                  Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              // Customer Service
              GestureDetector(
                onTap: () => _launchWhatsApp('6289659958740'),
                child: _buildContactItem(
                  LineAwesomeIcons
                      .whatsapp, // UBAH: Gunakan LineAwesome WhatsApp icon
                  'Customer Service (Aldi)',
                  '+62 896-5995-8740',
                  Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              // Email Support
              GestureDetector(
                onTap: () => _launchEmail('magang@untag-sby2025.com'),
                child: _buildContactItem(
                  Icons.email,
                  'Email Support',
                  'magang@untag-sby2025.com',
                  Colors.blue,
                ),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[100]!),
                ),
                child: const Row(
                  children: [
                    Icon(LineAwesomeIcons.whatsapp,
                        color: Colors.green,
                        size: 16), // UBAH: Gunakan LineAwesome WhatsApp icon
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tekan nomor untuk langsung chat di WhatsApp',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // TAMBAHAN: Widget untuk item contact (diperbarui)
  Widget _buildContactItem(
      IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 320, // DIKECILKAN dari 400
                ),
                child: Card(
                  elevation: 8, // DIKURANGI dari 12
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16), // DIKECILKAN dari 20
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20), // DIKECILKAN dari 24/32
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo - DIKECILKAN
                        Container(
                          height: 70, // DIKECILKAN dari 80-100
                          width: 70, // DIKECILKAN dari 80-100
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFC107).withOpacity(0.3),
                                blurRadius: 8, // DIKURANGI dari 10
                                offset: const Offset(0, 3), // DIKURANGI dari 4
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(6.0), // DIKECILKAN
                              child: Image.asset(
                                'assets/images/logo1.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 30, // DIKECILKAN dari 40
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16), // DIKECILKAN

                        // Title
                        Text(
                          'Login Absensi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20, // DIKECILKAN dari 20-25
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(height: 4), // DIKECILKAN

                        // Subtitle
                        Text(
                          'Silakan masuk untuk melanjutkan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12, // DIKECILKAN dari 12-14
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20), // DIKECILKAN

                        // Username field
                        TextField(
                          controller: _usernameCtrl,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Color(0xFF1565C0),
                              size: 18, // DIKECILKAN
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // DIKECILKAN
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // DIKECILKAN
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // DIKECILKAN
                              borderSide: const BorderSide(
                                color: Color(0xFF1565C0),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              // DIKECILKAN
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // DIKECILKAN

                        // Password field
                        TextField(
                          controller: _passCtrl,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Color(0xFF1565C0),
                              size: 18, // DIKECILKAN
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // DIKECILKAN
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // DIKECILKAN
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // DIKECILKAN
                              borderSide: const BorderSide(
                                color: Color(0xFF1565C0),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              // DIKECILKAN
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20), // DIKECILKAN

                        // Tombol Login Utama
                        Container(
                          height: 44, // DIKECILKAN dari 45-50
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFC107),
                                Color(0xFFFFB300),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(10), // DIKECILKAN
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFC107).withOpacity(0.4),
                                blurRadius: 6, // DIKURANGI dari 8
                                offset: const Offset(0, 3), // DIKURANGI dari 4
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10), // DIKECILKAN
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20, // DIKECILKAN
                                    height: 20, // DIKECILKAN
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5, // DIKURANGI
                                    ),
                                  )
                                : Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14, // DIKECILKAN
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8, // DIKURANGI
                                    ),
                                  ),
                          ),
                        ),

                        // TAMBAHAN: Watermark Contact Person
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _showContactPersonPopup(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.contact_support,
                                  color: Colors.grey[600],
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Butuh Bantuan? Hubungi Kami',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // TAMBAHAN: Copyright/Version Info
                        const SizedBox(height: 12),
                        Text(
                          'v1.0.0 © 2024 Absen App',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
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
