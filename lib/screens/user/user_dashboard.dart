import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const UserDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final String userName = "Ahmad Rizki";
  final String userEmail = "ahmad.rizki@example.com";
  final List<Map<String, dynamic>> meetings = [
    {
      'title': 'Rapat Tim Produk',
      'date': '15 Nov 2023',
      'time': '09:00 - 11:00 WIB',
      'status': 'Akan Datang'
    },
    {
      'title': 'Review Kinerja Bulanan',
      'date': '12 Nov 2023',
      'time': '13:30 - 15:00 WIB',
      'status': 'Selesai'
    },
    {
      'title': 'Brainstorming Project Baru',
      'date': '10 Nov 2023',
      'time': '10:00 - 12:00 WIB',
      'status': 'Selesai'
    },
    {
      'title': 'Presentasi Klien',
      'date': '18 Nov 2023',
      'time': '14:00 - 16:00 WIB',
      'status': 'Akan Datang'
    },
  ];

  bool _showLogoutOption = false;

  void _logout() {
    // Logika logout di sini
    print("User logged out");
    
    // Navigasi ke halaman login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showLogoutOption = !_showLogoutOption;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFFFD700),
                child: Text(
                  userName[0],
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header dengan gradien biru
              Container(
                width: double.infinity,
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF3B82F6),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Halo, $userName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Statistik
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Rapat Hari Ini', '2', Icons.calendar_today),
                    _buildStatCard('Hadir', '12', Icons.check_circle),
                    _buildStatCard('Izin', '1', Icons.pending_actions),
                  ],
                ),
              ),
              
              // Daftar Rapat
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rapat Terbaru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: meetings.length,
                          itemBuilder: (context, index) {
                            final meeting = meetings[index];
                            return _buildMeetingCard(meeting);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Opsi Logout
          if (_showLogoutOption)
            Positioned(
              top: 70,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showLogoutOption = false;
                  });
                },
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFFFD700),
                              child: Icon(
                                Icons.person,
                                color: Color(0xFF1E3A8A),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName.split(' ')[0],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  userEmail,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      InkWell(
                        onTap: _logout,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1E3A8A),
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event,
              color: Color(0xFF1E3A8A),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      meeting['date'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      meeting['time'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: meeting['status'] == 'Akan Datang'
                  ? const Color(0xFFFFF8E1)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              meeting['status'],
              style: TextStyle(
                color: meeting['status'] == 'Akan Datang'
                    ? const Color(0xFFF57C00)
                    : const Color(0xFF388E3C),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Halaman Login Screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo atau Gambar
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(75),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFFFFD700),
                  size: 70,
                ),
              ),
              const SizedBox(height: 30),
              
              // Judul
              const Text(
                'Selamat Datang Kembali',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Silakan masuk ke akun Anda',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              
              // Form Login
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Color(0xFF1E3A8A)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock, color: Color(0xFF1E3A8A)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Logika login di sini
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const UserDashboard()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}