// lib/screens/user/user_dashboard.dart

import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/Models/models/user.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:absen_app/screens/login_screen.dart';
import 'package:absen_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// TODO: Pastikan AttendanceScreen di-uncomment dan constructornya menerima objek 'Rapat'
// import 'package:absen_app/screens/user/attendance_screen.dart';

class UserDashboard extends StatefulWidget {
  final bool isGuestMode;
  const UserDashboard({super.key, this.isGuestMode = false});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  // --- State untuk UI ---
  int _currentPageIndex = 0; // State untuk BottomNavBar
  bool _isLoading = true;
  String? _errorMessage;

  // --- State untuk Data ---
  AppUser? _currentUser;
  List<Rapat> _allRapat = [];
  List<Rapat> _upcomingRapat = [];

  // --- Services ---
  final AuthService _authService = AuthService();
  final RapatApiService _rapatApiService = RapatApiService();

  @override
  void initState() {
    super.initState();
    if (!widget.isGuestMode) {
      _loadData();
    } else {
      setState(() {
        _isLoading = false;
        _currentUser = AppUser(
          id_user: 0,
          id_role: 4, // Guest role
          name: 'Guest User',
          username: 'guest',
          email: 'Login untuk melihat detail',
        );
      });
    }
  }

  Future<void> _loadData() async {
    if (widget.isGuestMode) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _authService.getProfile(),
        _rapatApiService.fetchRapatByUser(),
      ]);

      _currentUser = results[0] as AppUser?;
      final rapatData = results[1] as List<Map<String, dynamic>>;
      _allRapat = rapatData.map((json) => Rapat.fromJson(json)).toList();

      _filterRapat();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat data: ${e.toString()}";
      });
      if (e.toString().contains('Sesi') || e.toString().contains('Not authenticated')) {
        _handleSessionExpired();
      }
    }
  }

  void _filterRapat() {
    final now = DateTime.now();
    _upcomingRapat = _allRapat.where((r) {
      final status = r.statusRapat.toLowerCase();
      return (status == 'disetujui' || status == 'berlangsung') && r.waktuMulai.isAfter(now);
    }).toList();
    _upcomingRapat.sort((a, b) => a.waktuMulai.compareTo(b.waktuMulai));
  }

  void _handleSessionExpired() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _logout() async {
    await _authService.logout();
    _handleSessionExpired();
  }

  @override
  Widget build(BuildContext context) {
    const List<String> appBarTitles = ['Dashboard', 'Profil'];

    // Daftar halaman/widget untuk BottomNavBar
    final List<Widget> pages = [
      _buildDashboardPage(),
      _buildProfilePage(),
    ];

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memuat Data...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: Text(appBarTitles[_currentPageIndex], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          if (!widget.isGuestMode)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
            ),
        ],
      ),
      body: pages[_currentPageIndex], // Body akan berganti sesuai index
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        indicatorColor: const Color(0xFFFFD600).withOpacity(0.5),
        selectedIndex: _currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.dashboard),
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person),
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // ============== WIDGET UNTUK HALAMAN DASHBOARD ==============
  Widget _buildDashboardPage() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),
            _buildStatistikCard(),
            _buildRapatList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Halo, ${_currentUser?.name ?? 'User'}',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _currentUser?.email ?? 'user@example.com',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistikCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.calendar_today, widget.isGuestMode ? 0 : _allRapat.length, 'Total Rapat'),
          Container(width: 1, height: 60, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(Icons.access_time, widget.isGuestMode ? 0 : _upcomingRapat.length, 'Akan Datang'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(count.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  Widget _buildRapatList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rapat Akan Datang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          if (widget.isGuestMode)
            _buildGuestEmptyState()
          else if (_upcomingRapat.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingRapat.length,
              itemBuilder: (context, index) {
                final rapat = _upcomingRapat[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _showMeetingDetails(rapat),
                    child: _buildMeetingCard(rapat),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ============== WIDGET UNTUK HALAMAN PROFIL ==============
  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.2),
            child: widget.isGuestMode
                ? const Icon(Icons.person_pin_circle_outlined, size: 50, color: Color(0xFF1E3A8A))
                : _currentUser?.photo != null
                ? ClipOval(child: Image.network(_currentUser!.photo!, fit: BoxFit.cover, width: 100, height: 100))
                : Text(
              _currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 48, color: Color(0xFF1E3A8A)),
            ),
          ),
          const SizedBox(height: 16),
          Text(_currentUser?.name ?? 'Guest User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(_currentUser?.email ?? 'Silakan login', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 32),
          const Divider(),
          _buildProfileInfoTile(Icons.person_outline, "Username", _currentUser?.username ?? '-'),
          _buildProfileInfoTile(Icons.badge_outlined, "Role", _currentUser?.role ?? 'Guest'),
          _buildProfileInfoTile(Icons.business_outlined, "Division", _currentUser?.division ?? '-'),
          _buildProfileInfoTile(Icons.phone_outlined, "Telepon", _currentUser?.phone ?? '-'),
          const Divider(),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.isGuestMode) {
                Navigator.pushAndRemoveUntil(
                    context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              } else {
                _logout();
              }
            },
            icon: Icon(widget.isGuestMode ? Icons.login : Icons.logout),
            label: Text(widget.isGuestMode ? 'Login Sekarang' : 'Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isGuestMode ? const Color(0xFF1E3A8A) : Colors.red[400],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E3A8A)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
    );
  }


  // ============== WIDGET-WIDGET HELPER ==============

  void _showMeetingDetails(Rapat rapat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detail Rapat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailItem('Nama Rapat', rapat.judul),
                const SizedBox(height: 12),
                _buildDetailItem('Ruangan', rapat.namaRuangan),
                const SizedBox(height: 12),
                _buildDetailItem('Tanggal', rapat.tanggalFormatted),
                const SizedBox(height: 12),
                _buildDetailItem('Jam Mulai', rapat.waktuMulaiFormatted),
                const SizedBox(height: 12),
                _buildDetailItem('Pengaju Rapat', rapat.namaPengaju),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Halaman absensi belum diaktifkan.')),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Absen', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup', style: TextStyle(color: Color(0xFF1E3A8A))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMeetingCard(Rapat rapat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.upcoming, color: Color(0xFF1E3A8A), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rapat.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                _buildCardInfoRow(Icons.meeting_room, rapat.namaRuangan),
                _buildCardInfoRow(Icons.calendar_today, '${rapat.tanggalFormatted} - ${rapat.waktuMulaiFormatted}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Tidak ada rapat yang akan datang', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_accounts, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Anda masuk sebagai tamu', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Silakan login untuk melihat daftar rapat.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}