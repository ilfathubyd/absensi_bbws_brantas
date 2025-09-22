import 'package:absen_app/Models/services/meeting_repo.dart';
import 'package:absen_app/screens/user/attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:absen_app/screens/login_screen.dart';
import 'package:absen_app/Models/models/meeting.dart';
import '../../services/auth_service.dart';
import 'package:absen_app/Models/models/user.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  bool _showLogoutOption = false;
  List<Meeting> upcomingMeetings = [];
  List<Meeting> allMeetings = [];
  bool _isLoading = true;
  String? _errorMessage;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load user profile
      _currentUser = await AuthService().getProfile();
      
      // Load meetings dari MeetingRepo (sama seperti admin dashboard)
      _loadMeetings();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat data: ${e.toString()}";
      });
    }
  }

  void _loadMeetings() {
    // Menggunakan MeetingRepo.all() agar sama dengan admin dashboard
    allMeetings = MeetingRepo.all();
    
    setState(() {
      upcomingMeetings = allMeetings.where((meeting) => 
        meeting.startTime.isAfter(DateTime.now())
      ).toList();
    });
  }

  void _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Fungsi untuk menampilkan detail rapat
  void _showMeetingDetails(Meeting meeting) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Detail Rapat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailItem('Nama Rapat', meeting.title),
                const SizedBox(height: 12),
                _buildDetailItem('Ruangan', meeting.room),
                const SizedBox(height: 12),
                _buildDetailItem('Tanggal', _formatDate(meeting.startTime)),
                const SizedBox(height: 12),
                _buildDetailItem('Jam Mulai', _formatTime(meeting.startTime)),
                const SizedBox(height: 12),
                _buildDetailItem('Penanggung Jawab', meeting.responsible),
                const SizedBox(height: 12),
                _buildDetailItem('ID Rapat', meeting.id),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                // Navigate ke AttendanceScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttendanceScreen(meeting: meeting),
                  ),
                ).then((success) {
                  if (success == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Absensi berhasil!"),
                        backgroundColor: Color(0xFF1E3A8A),
                      ),
                    );
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Absen',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget untuk menampilkan item detail
  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
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
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadData();
            },
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showLogoutOption = !_showLogoutOption;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: _currentUser?.photo != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(_currentUser!.photo!),
                      radius: 18,
                    )
                  : CircleAvatar(
                      backgroundColor: const Color(0xFFFFD700),
                      child: Text(
                        _currentUser?.username?.isNotEmpty == true 
                            ? _currentUser!.username![0].toUpperCase()
                            : 'U',
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
          SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
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
                          'Halo, ${_currentUser?.username ?? 'User'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentUser?.email ?? 'user@example.com',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Statistik Responsif - Diperbesar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isSmallScreen
                      ? Column(
                          children: [
                            _buildStatCard('Total Rapat', 
                                allMeetings.length.toString(), 
                                Icons.calendar_today),
                            const SizedBox(height: 16),
                            _buildStatCard('Akan Datang', 
                                upcomingMeetings.length.toString(), 
                                Icons.access_time),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildStatCard('Total Rapat', 
                                  allMeetings.length.toString(), 
                                  Icons.calendar_today),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard('Akan Datang', 
                                  upcomingMeetings.length.toString(), 
                                  Icons.access_time),
                            ),
                          ],
                        ),
                ),

                // Daftar Rapat
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rapat Akan Datang',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      upcomingMeetings.isEmpty
                          ? _buildEmptyState()
                          : Column(
                              children: upcomingMeetings.map((meeting) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: GestureDetector(
                                    onTap: () => _showMeetingDetails(meeting),
                                    child: _buildMeetingCard(meeting),
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Opsi Logout
          if (_showLogoutOption)
            Positioned(
              top: 70,
              right: 16,
              child: Container(
                width: 180,
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
                          _currentUser?.photo != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(_currentUser!.photo!),
                                  radius: 16,
                                )
                              : const CircleAvatar(
                                  backgroundColor: Color(0xFFFFD700),
                                  radius: 16,
                                  child: Icon(
                                    Icons.person,
                                    color: Color(0xFF1E3A8A),
                                    size: 20,
                                  ),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (_currentUser?.username ?? 'User').split(' ')[0],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _currentUser?.email ?? 'user@example.com',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
                            Icon(Icons.logout,
                                color: Colors.red, size: 20),
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada rapat yang akan datang',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14, 
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    final bool isUpcoming = meeting.startTime.isAfter(DateTime.now());
    
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isUpcoming
                  ? const Color(0xFFFFF8E1)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isUpcoming ? Icons.upcoming : Icons.event_available,
              color: const Color(0xFF1E3A8A),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.meeting_room,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        meeting.room,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(meeting.startTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(meeting.startTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        meeting.responsible,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.tag,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'ID: ${meeting.id}',
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
              color: isUpcoming
                  ? const Color(0xFFFFF8E1)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isUpcoming ? 'Akan Datang' : 'Selesai',
              style: TextStyle(
                color: isUpcoming
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}