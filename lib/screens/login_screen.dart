// import 'package:flutter/material.dart';
// import 'package:absen_app/screens/admin/admin_dashboard.dart' show AdminDashboard;
// import 'package:absen_app/screens/user/user_dashboard.dart' show UserDashboard;
// import 'package:absen_app/screens/pic/pic_dashboard.dart' show PICDashboard;
// import 'package:absen_app/Models/models/user.dart';
// import 'package:absen_app/services/auth_service.dart';

// late AppUser currentUser;

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _usernameCtrl = TextEditingController();
//   final _passCtrl = TextEditingController();
//   final AuthService _authService = AuthService();

//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _usernameCtrl.dispose();
//     _passCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _login() async {
//     if (_isLoading) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final username = _usernameCtrl.text.trim();
//       final password = _passCtrl.text.trim();

//       // PERBAIKAN: Validasi input
//       if (username.isEmpty || password.isEmpty) {
//         throw Exception('Username dan password tidak boleh kosong');
//       }

//       final user = await _authService.login(username, password);
//       currentUser = user;

//       if (!mounted) return;

//       // PERBAIKAN: Debug print untuk melihat data user
//       print('Login successful:');
//       print('User ID: ${user.id}');
//       print('Username: ${user.username}');
//       print('Name: ${user.name}');
//       print('Role ID: ${user.idRole}');
//       print('Role Name: ${user.role}');

//       // PERBAIKAN: Navigasi berdasarkan role ID dengan fallback
//       Widget targetScreen;
//       String screenName;

//       switch (user.idRole) {
//         case 1: // Admin
//           targetScreen = const AdminDashboard();
//           screenName = 'Admin Dashboard';
//           break;
//         case 2: // PIC
//           targetScreen = const PICDashboard();
//           screenName = 'PIC Dashboard';
//           break;
//         case 3: // User biasa
//           targetScreen = const UserDashboard();
//           screenName = 'User Dashboard';
//           break;
//         default:
//         // PERBAIKAN: Handle role yang tidak dikenal
//           print('Unknown role ID: ${user.idRole}, defaulting to User Dashboard');
//           targetScreen = const UserDashboard();
//           screenName = 'User Dashboard (Default)';
//       }

//       // PERBAIKAN: Show success message dengan info role
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Login berhasil! Mengalihkan ke $screenName...'),
//           backgroundColor: Colors.green[600],
//           duration: const Duration(seconds: 2),
//         ),
//       );

//       // PERBAIKAN: Delay sebentar agar user bisa melihat pesan sukses
//       await Future.delayed(const Duration(milliseconds: 500));

//       if (!mounted) return;

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => targetScreen),
//       );

//     } catch (e) {
//       if (!mounted) return;

//       // PERBAIKAN: Error handling yang lebih detail
//       String errorMessage = e.toString().replaceAll('Exception: ', '');
//       print('Login error: $e');

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(errorMessage),
//           backgroundColor: Colors.red[600],
//           duration: const Duration(seconds: 4),
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color(0xFF1565C0),
//               Color(0xFF42A5F5),
//             ],
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Card(
//               elevation: 12,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               color: Colors.white,
//               child: Padding(
//                 padding: const EdgeInsets.all(32),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Logo
//                     Container(
//                       height: 100,
//                       width: 100,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFFFC107),
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: const Color(0xFFFFC107).withOpacity(0.3),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: ClipOval(
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Image.asset(
//                             'assets/images/logo1.png',
//                             fit: BoxFit.contain,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // Title
//                     const Text(
//                       'Login Absensi',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 25,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1565C0),
//                       ),
//                     ),
//                     const SizedBox(height: 8),

//                     Text(
//                       'Silakan masuk untuk melanjutkan',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                     ),
//                     const SizedBox(height: 32),

//                     // Username field
//                     TextField(
//                       controller: _usernameCtrl,
//                       keyboardType: TextInputType.text,
//                       decoration: InputDecoration(
//                         labelText: 'Username',
//                         prefixIcon: const Icon(
//                           Icons.person,
//                           color: Color(0xFF1565C0),
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(color: Color(0xFF1565C0)),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(
//                             color: Color(0xFF1565C0),
//                             width: 2,
//                           ),
//                         ),
//                         labelStyle: const TextStyle(color: Color(0xFF1565C0)),
//                         filled: true,
//                         fillColor: Colors.grey[50],
//                       ),
//                     ),
//                     const SizedBox(height: 14),

//                     // Password field
//                     TextField(
//                       controller: _passCtrl,
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         prefixIcon: const Icon(
//                           Icons.lock,
//                           color: Color(0xFF1565C0),
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(color: Color(0xFF1565C0)),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(
//                             color: Color(0xFF1565C0),
//                             width: 2,
//                           ),
//                         ),
//                         labelStyle: const TextStyle(color: Color(0xFF1565C0)),
//                         filled: true,
//                         fillColor: Colors.grey[50],
//                       ),
//                       obscureText: true,
//                       // PERBAIKAN: Tambah onSubmitted untuk login dengan Enter
//                       onSubmitted: (_) => _login(),
//                     ),
//                     const SizedBox(height: 24),

//                     // Login button
//                     Container(
//                       height: 50,
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [
//                             Color(0xFFFFC107),
//                             Color(0xFFFFB300),
//                           ],
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: const Color(0xFFFFC107).withOpacity(0.4),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : _login,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.transparent,
//                           shadowColor: Colors.transparent,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: _isLoading
//                             ? const SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 3,
//                           ),
//                         )
//                             : const Text(
//                           'LOGIN',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 1,
//                           ),
//                         ),
//                       ),
//                     ),

//                     // PERBAIKAN: Debug info dalam mode development
//                     if (const bool.fromEnvironment('dart.vm.product') == false) ...[
//                       const SizedBox(height: 16),
//                       Text(
//                         'Debug: Pastikan Laravel server berjalan di http://127.0.0.1:8000',
//                         style: TextStyle(
//                           fontSize: 10,
//                           color: Colors.grey[500],
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:absen_app/screens/admin/admin_dashboard.dart' show AdminDashboard;
import 'package:absen_app/screens/user/user_dashboard.dart' show UserDashboard;
import 'package:absen_app/screens/pic/pic_dashboard.dart' show PICDashboard;
import 'package:absen_app/Models/models/user.dart';
import 'package:absen_app/services/auth_service.dart';

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

      // PERBAIKAN: Validasi input
      if (username.isEmpty || password.isEmpty) {
        throw Exception('Username dan password tidak boleh kosong');
      }

      final user = await _authService.login(username, password);
      currentUser = user;

      if (!mounted) return;

      // PERBAIKAN: Debug print untuk melihat data user
      print('Login successful:');
      print('User ID: ${user.id_user}');
      print('Username: ${user.username}');
      print('Name: ${user.name}');
      print('Role ID: ${user.id_role}');
      print('Role Name: ${user.role}');

      // PERBAIKAN: Navigasi berdasarkan role ID dengan fallback
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
        // PERBAIKAN: Handle role yang tidak dikenal
          print('Unknown role ID: ${user.id_role}, defaulting to User Dashboard');
          targetScreen = const UserDashboard();
          screenName = 'User Dashboard (Default)';
      }

      // PERBAIKAN: Show success message dengan info role
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login berhasil! Mengalihkan ke $screenName...'),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 2),
        ),
      );

      // PERBAIKAN: Delay sebentar agar user bisa melihat pesan sukses
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );

    } catch (e) {
      if (!mounted) return;

      // PERBAIKAN: Error handling yang lebih detail
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      print('Login error: $e');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                    // Logo
                    Container(
                      height: 100,
                      width: 100,
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
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
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

                    // Username field
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
                          borderSide: const BorderSide(color: Color(0xFF1565C0)),
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

                    // Password field
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
                          borderSide: const BorderSide(color: Color(0xFF1565C0)),
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
                      // PERBAIKAN: Tambah onSubmitted untuk login dengan Enter
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    Container(
                      height: 50,
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
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                            : const Text(
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

                    // PERBAIKAN: Debug info dalam mode development
                    if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Debug: Pastikan Laravel server berjalan di http://127.0.0.1:8000',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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