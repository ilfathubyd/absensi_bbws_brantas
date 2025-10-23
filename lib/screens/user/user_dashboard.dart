// lib/screens/user/user_dashboard.dart

import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/Models/models/user.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:absen_app/screens/login_screen.dart';
import 'package:absen_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
          id_user: 'guest_id', // PERUBAHAN: Gunakan String, bukan int
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
      if (e.toString().contains('Sesi') ||
          e.toString().contains('Not authenticated')) {
        _handleSessionExpired();
      }
    }
  }

  void _filterRapat() {
    final now = DateTime.now();
    _upcomingRapat = _allRapat.where((r) {
      final status = r.statusRapat.toLowerCase();
      return (status == 'disetujui' || status == 'berlangsung') &&
          r.waktuMulai.isAfter(now);
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

  // ============== FUNGSI SCAN QR ==============
  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          upcomingMeetings: _upcomingRapat,
        ),
      ),
    );
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
              ElevatedButton(
                  onPressed: _loadData, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: Text(appBarTitles[_currentPageIndex],
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          if (!widget.isGuestMode && _currentPageIndex == 0)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              onPressed: _openQRScanner,
              tooltip: 'Scan QR Code',
            ),
          if (!widget.isGuestMode)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
              tooltip: 'Refresh Data',
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
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Halo, ${_currentUser?.name ?? 'User'}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
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
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFFC107).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.calendar_today,
              widget.isGuestMode ? 0 : _allRapat.length, 'Total Rapat'),
          Container(width: 1, height: 60, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(Icons.access_time,
              widget.isGuestMode ? 0 : _upcomingRapat.length, 'Akan Datang'),
          Container(width: 1, height: 60, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(Icons.qr_code_scanner, 0, 'Scan QR'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(count.toString(),
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ],
    );
  }

  Widget _buildRapatList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rapat Akan Datang',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
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
                ? const Icon(Icons.person_pin_circle_outlined,
                    size: 50, color: Color(0xFF1E3A8A))
                : _currentUser?.photo != null
                    ? ClipOval(
                        child: Image.network(_currentUser!.photo!,
                            fit: BoxFit.cover, width: 100, height: 100))
                    : Text(
                        _currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                            fontSize: 48, color: Color(0xFF1E3A8A)),
                      ),
          ),
          const SizedBox(height: 16),
          Text(_currentUser?.name ?? 'Guest User',
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(_currentUser?.email ?? 'Silakan login',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 32),
          const Divider(),
          _buildProfileInfoTile(
              Icons.person_outline, "Username", _currentUser?.username ?? '-'),
          _buildProfileInfoTile(
              Icons.badge_outlined, "Role", _currentUser?.role ?? 'Guest'),
          _buildProfileInfoTile(Icons.business_outlined, "Division",
              _currentUser?.division ?? '-'),
          _buildProfileInfoTile(
              Icons.phone_outlined, "Telepon", _currentUser?.phone ?? '-'),
          const Divider(),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.isGuestMode) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false);
              } else {
                _logout();
              }
            },
            icon: Icon(widget.isGuestMode ? Icons.login : Icons.logout),
            label: Text(widget.isGuestMode ? 'Login Sekarang' : 'Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isGuestMode
                  ? const Color(0xFF1E3A8A)
                  : Colors.red[400],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
          title: const Text('Detail Rapat',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailItem('Nama Rapat', rapat.judul),
                const SizedBox(height: 12),
                _buildDetailItem('ID Rapat', rapat.idRapat.toString()),
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
                _openQRScanner();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text('Scan QR', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup',
                  style: TextStyle(color: Color(0xFF1E3A8A))),
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
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMeetingCard(Rapat rapat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10)),
            child:
                const Icon(Icons.upcoming, color: Color(0xFF1E3A8A), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rapat.judul,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                _buildCardInfoRow(Icons.meeting_room, rapat.namaRuangan),
                _buildCardInfoRow(Icons.calendar_today,
                    '${rapat.tanggalFormatted} - ${rapat.waktuMulaiFormatted}'),
                _buildCardInfoRow(Icons.qr_code, 'ID: ${rapat.idRapat}'),
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
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis)),
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
            const Text('Tidak ada rapat yang akan datang',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
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
            const Text('Anda masuk sebagai tamu',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Silakan login untuk melihat daftar rapat.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ============== SCREEN SCANNER QR ==============
class QRScannerScreen extends StatefulWidget {
  final List<Rapat> upcomingMeetings;

  const QRScannerScreen({super.key, required this.upcomingMeetings});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  String? _scannedData;
  Rapat? _selectedMeeting;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeScanned(BarcodeCapture barcodes) {
    if (!_isScanning) return;

    final barcode = barcodes.barcodes.first;
    if (barcode.rawValue == null) {
      return;
    }

    setState(() {
      _isScanning = false;
      _scannedData = barcode.rawValue!;
    });

    // Cari meeting berdasarkan ID dari QR code
    _findMeetingFromQR(_scannedData!);
  }

  void _findMeetingFromQR(String qrData) {
    // Reset state terlebih dahulu
    setState(() {
      _selectedMeeting = null;
    });

    try {
      // Bersihkan QR data dari spasi atau karakter tidak perlu
      final cleanQrData = qrData.trim();
      final meetingId = int.tryParse(cleanQrData);
      
      if (meetingId == null) {
        _showScanResult();
        return;
      }

      // Cari meeting dengan loop manual (paling aman)
      Rapat? foundMeeting;
      for (final meeting in widget.upcomingMeetings) {
        if (meeting.idRapat == meetingId) {
          foundMeeting = meeting;
          break;
        }
      }

      setState(() {
        _selectedMeeting = foundMeeting;
      });
    } catch (e) {
      print('Error dalam memproses QR code: $e');
      // Tetap lanjutkan untuk menampilkan hasil (walaupun error)
    } finally {
      _showScanResult();
    }
  }

  void _showScanResult() {
    // Pastikan context masih mounted
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hasil Scan QR',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: _selectedMeeting != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rapat Ditemukan!',
                        style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('Judul: ${_selectedMeeting!.judul}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('ID: ${_selectedMeeting!.idRapat}'),
                    Text('Ruangan: ${_selectedMeeting!.namaRuangan}'),
                    const SizedBox(height: 8),
                    const Text('Silakan lakukan absensi.'),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    const Text('QR Code tidak valid atau rapat tidak ditemukan.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    if (_scannedData != null)
                      Text('Data QR: $_scannedData',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetScanner();
              },
              child: const Text('Scan Lagi'),
            ),
            if (_selectedMeeting != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _processAttendance();
                },
                child: const Text('Absen Sekarang'),
              ),
          ],
        );
      },
    );
  }

  void _processAttendance() {
    // TODO: Implement your attendance logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Absensi untuk "${_selectedMeeting?.judul}" berhasil!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _scannedData = null;
      _selectedMeeting = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        titleTextStyle: TextStyle(color: Colors.white),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Judul dan instruksi
              const Text(
                'Scan QR Code Rapat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Arahkan kamera ke QR code yang tersedia di ruangan rapat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Container untuk kamera dengan ukuran lebih kecil
              Container(
                width: double.infinity,
                height: 300, // Tinggi kamera diperkecil
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    controller: cameraController,
                    onDetect: _onBarcodeScanned,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Informasi tambahan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF1E3A8A), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tips Scan QR Code:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTipItem('Pastikan QR code dalam kondisi baik dan tidak rusak'),
                    _buildTipItem('Jaga jarak optimal 15-30 cm dari QR code'),
                    _buildTipItem('Pastikan pencahayaan cukup'),
                    _buildTipItem('Tunggu hingga scanner mendeteksi secara otomatis'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Daftar rapat yang bisa di-scan
              if (widget.upcomingMeetings.isNotEmpty) ...[
                const Text(
                  'Rapat yang Dapat Di-scan:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.upcomingMeetings.take(3).map((meeting) => 
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meeting.judul,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${meeting.idRapat} • ${meeting.namaRuangan}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
                if (widget.upcomingMeetings.length > 3)
                  Text(
                    'dan ${widget.upcomingMeetings.length - 3} rapat lainnya...',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF1E3A8A))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
    );
  }
}