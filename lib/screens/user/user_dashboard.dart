// lib/screens/user/user_dashboard.dart

import 'dart:async';
import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/Models/models/user.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:absen_app/screens/login_screen.dart';
import 'package:absen_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shimmer/shimmer.dart';

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
  List<Map<String, dynamic>> _historyRapat =
      []; // Menggunakan Map untuk fleksibilitas

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
      _historyRapat =
          rapatData; // Langsung simpan data dari API (list of attendance)
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

  void _handleSessionExpired() {
    // Pastikan hanya dijalankan sekali dan widget masih ada
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;

    // Tampilkan snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
        backgroundColor: Colors.red,
      ),
    );

    // Navigasi ke halaman login dan hapus semua halaman sebelumnya.
    // Ini memastikan state lama dari dashboard tidak akan muncul kembali.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _logout() async {
    // Tampilkan dialog loading untuk mencegah interaksi pengguna
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Tunggu proses logout dari AuthService selesai
    await _authService.logout();

    // Setelah logout selesai, tutup dialog loading
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Tutup dialog loading

    // Panggil handleSessionExpired untuk navigasi
    _handleSessionExpired(); // Navigasi ke halaman login
  }

  // ============== FUNGSI SCAN QR ==============
  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          upcomingMeetings: const [], // Tidak ada lagi rapat akan datang di sini
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
        appBar: AppBar(
            title: const Text('Memuat Data...',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF1E3A8A),
            elevation: 0),
        body: _buildDashboardShimmer(),
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

  // ============== WIDGET UNTUK SHIMMER EFFECT ==============
  Widget _buildDashboardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Shimmer Header
            Container(
              width: double.infinity,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24)),
              ),
            ),
            // Shimmer Statistik
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            // Shimmer Rapat List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 200,
                    height: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  _buildShimmerMeetingCard(),
                  const SizedBox(height: 12),
                  _buildShimmerMeetingCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerMeetingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(width: 60, height: 60, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Container(height: 60, color: Colors.white),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${_currentUser?.name ?? 'User'}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUser?.email ?? 'user@example.com',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (!widget.isGuestMode) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _openQRScanner,
                    icon: const Icon(Icons.qr_code_scanner,
                        color: Color(0xFF1E3A8A)),
                    label: const Text('Scan',
                        style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD600),
                    ),
                  ),
                ]
              ],
            )
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
              widget.isGuestMode ? 0 : _historyRapat.length, 'Total Absen'),
          Container(width: 1, height: 60, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(Icons.history, _historyRapat.length, 'Riwayat'),
          Container(width: 1, height: 60, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(Icons.qr_code_scanner, 0, 'Absen'),
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
          const Text('Riwayat Absensi Rapat',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          if (widget.isGuestMode) _buildGuestEmptyState(),
          if (_errorMessage != null && !widget.isGuestMode)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off,
                        size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    const Text('Gagal Memuat Data',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    Text(_errorMessage!,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else if (_historyRapat.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _historyRapat.length,
              itemBuilder: (context, index) {
                final absensi = _historyRapat[index];
                final rapat = absensi['rapat'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _showMeetingDetails(rapat, absensi),
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

  void _showMeetingDetails(
      Map<String, dynamic> rapat, Map<String, dynamic> absensi) {
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
                _buildDetailItem('Nama Rapat', rapat['judul'] ?? 'N/A'),
                const SizedBox(height: 12),
                _buildDetailItem(
                    'ID Rapat', rapat['id_rapat']?.toString() ?? 'N/A'),
                const SizedBox(height: 12),
                _buildDetailItem('Tanggal Rapat', rapat['tanggal'] ?? 'N/A'),
                const SizedBox(height: 12),
                _buildDetailItem(
                    'Waktu Absen', absensi['waktu_absen'] ?? 'N/A'),
                const SizedBox(height: 12),
                _buildDetailItem(
                    'Status Kehadiran',
                    absensi['id_status_kehadiran'] == 2
                        ? 'Hadir'
                        : 'Status Lain'),
              ],
            ),
          ),
          actions: [
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

  Widget _buildMeetingCard(Map<String, dynamic> rapat) {
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
            child: const Icon(Icons.history_edu,
                color: Color(0xFF1E3A8A), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rapat['judul'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                _buildCardInfoRow(
                    Icons.calendar_today, rapat['tanggal'] ?? 'Tanpa Tanggal'),
                _buildCardInfoRow(Icons.qr_code, 'ID: ${rapat['id_rapat']}'),
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
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Belum ada riwayat absensi',
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
            const Text('Silakan login untuk melihat riwayat absensi.',
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
  final List<Map<String, dynamic>> upcomingMeetings;

  const QRScannerScreen({super.key, required this.upcomingMeetings});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  final RapatApiService _rapatApiService = RapatApiService();
  bool _isProcessing = false; // Flag untuk menandai proses API sedang berjalan
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeScanned(BarcodeCapture barcodes) {
    // Jika sedang memproses atau debounce aktif, abaikan scan baru
    if (_isProcessing || (_debounce?.isActive ?? false)) return;

    final barcode = barcodes.barcodes.first;
    if (barcode.rawValue == null) {
      return;
    }

    setState(() {
      _isProcessing = true; // Mulai proses
    });

    // Panggil API untuk absensi
    _processAttendance(barcode.rawValue!);
  }

  Future<void> _processAttendance(String qrToken) async {
    try {
      final result = await _rapatApiService.attendRapat(qrToken);
      final message = result['message']?.toString();

      // PERBAIKAN: Cek tipe data dari 'rapat' sebelum parsing
      Rapat? rapat;
      final rapatData = result['rapat'];

      // Hanya coba parsing jika 'rapatData' adalah sebuah Map (JSON object)
      if (rapatData != null && rapatData is Map<String, dynamic>) {
        rapat = Rapat.fromJson(rapatData);
      }
      ;

      _showResultDialog(
        isSuccess: true,
        title: 'Absensi Berhasil',
        message: message ?? 'Anda berhasil melakukan absensi.',
        rapat: rapat,
      );
    } catch (e) {
      _showResultDialog(
        isSuccess: false,
        title: 'Absensi Gagal',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showResultDialog(
      {required bool isSuccess,
      required String title,
      required String message,
      Rapat? rapat}) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: isSuccess ? Colors.green : Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              if (rapat != null) ...[
                const SizedBox(height: 8),
                Text('Rapat: ${rapat.judul}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetScanner(isSuccess: isSuccess);
              },
              child: Text(isSuccess ? 'Tutup' : 'Coba Lagi'),
            ),
          ],
        );
      },
    );
  }

  void _resetScanner({bool isSuccess = false}) {
    // Jika sukses, langsung kembali ke dashboard
    if (isSuccess) {
      Navigator.of(context).pop();
      return;
    }

    // Jika gagal, aktifkan debounce untuk memberi jeda sebelum scan berikutnya
    _debounce = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
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
                  border: Border.all(
                      color: const Color(0xFF1E3A8A).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFF1E3A8A), size: 20),
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
                    _buildTipItem(
                        'Pastikan QR code dalam kondisi baik dan tidak rusak'),
                    _buildTipItem('Jaga jarak optimal 15-30 cm dari QR code'),
                    _buildTipItem('Pastikan pencahayaan cukup'),
                    _buildTipItem(
                        'Tunggu hingga scanner mendeteksi secara otomatis'),
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
                ...widget.upcomingMeetings
                    .take(3)
                    .map(
                      (meeting) => Container(
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
                                    meeting['judul'] ?? 'Tanpa Judul',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'ID: ${meeting['id_rapat']} • ${meeting['nama_ruangan'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
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
