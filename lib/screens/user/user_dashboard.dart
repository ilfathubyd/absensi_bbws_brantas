// lib/screens/user/user_dashboard.dart

import 'dart:async';
import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/Models/models/user.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:absen_app/screens/login_screen.dart';
import 'package:absen_app/screens/user/meeting_history.dart';
import 'package:absen_app/screens/user/user_shortcut_menu.dart';
import 'package:absen_app/services/auth_service.dart';
import 'package:flutter/material.dart';

import 'package:absen_app/screens/user/face_scan_screen.dart'; // Import FaceScanScreen
import 'dart:io'; // Import File
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shimmer/shimmer.dart';
import 'package:absen_app/utils/snackbar_helper.dart';
import 'package:absen_app/screens/user/rapat_detail_screen.dart'; // Import detail screen

// TODO: Pastikan AttendanceScreen di-uncomment dan constructornya menerima objek 'Rapat'
// import 'package:absen_app/screens/user/attendance_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

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
    _loadData();
  }

  Future<void> _loadData() async {
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
    SnackBarHelper.error(
      context,
      'Sesi Anda telah berakhir. Silakan login kembali.',
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
    const List<String> appBarTitles = ['Dashboard', 'Riwayat', 'Profil'];

    // Daftar halaman/widget untuk BottomNavBar
    final List<Widget> pages = [
      _buildDashboardPage(),
      const MeetingHistoryPage(showAppBar: false),
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
      floatingActionButton: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD600),
              Color(0xFFFFC107),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD600).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openQRScanner,
            borderRadius: BorderRadius.circular(35),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner,
                  color: Color(0xFF1E3A8A),
                  size: 36,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        child: SizedBox(
          height: 65,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dashboard
                Flexible(
                  flex: 1,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentPageIndex = 0;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentPageIndex == 0
                              ? Icons.home
                              : Icons.home_outlined,
                          color: _currentPageIndex == 0
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 9,
                            color: _currentPageIndex == 0
                                ? const Color(0xFF1E3A8A)
                                : Colors.grey,
                            fontWeight: _currentPageIndex == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                // Riwayat
                Flexible(
                  flex: 1,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentPageIndex = 1;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentPageIndex == 1
                              ? Icons.history
                              : Icons.history_outlined,
                          color: _currentPageIndex == 1
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Riwayat',
                          style: TextStyle(
                            fontSize: 9,
                            color: _currentPageIndex == 1
                                ? const Color(0xFF1E3A8A)
                                : Colors.grey,
                            fontWeight: _currentPageIndex == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                // Spacer for FAB
                const SizedBox(width: 80),
                // Profil
                Flexible(
                  flex: 1,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentPageIndex = 2;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentPageIndex == 2
                              ? Icons.person
                              : Icons.person_outline,
                          color: _currentPageIndex == 2
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Profil',
                          style: TextStyle(
                            fontSize: 9,
                            color: _currentPageIndex == 2
                                ? const Color(0xFF1E3A8A)
                                : Colors.grey,
                            fontWeight: _currentPageIndex == 2
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                // Shortcut Menu
                Flexible(
                  flex: 1,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserShortcutMenu(),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.apps,
                          color: Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontWeight: FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
          _buildStatItem(
              Icons.calendar_today, _historyRapat.length, 'Total Absen'),
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
          if (_errorMessage != null)
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
            child: _currentUser?.photo != null
                ? ClipOval(
                    child: Image.network(_currentUser!.photo!,
                        width: 100, height: 100, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person,
                          size: 50, color: Color(0xFF1E3A8A));
                    }),
                  )
                : const Icon(Icons.person, size: 50, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser?.name ?? 'Nama Pengguna',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            _currentUser?.email ?? 'email@example.com',
            style: TextStyle(color: Colors.grey[600]),
          ),
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
          // Tombol Logout
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
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
    // Langsung navigasi ke halaman detail
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              RapatDetailScreen(rapatId: rapat['id_rapat'].toString())),
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
}

// ============== SCREEN SCANNER QR ==============
class QRScannerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> upcomingMeetings;

  const QRScannerScreen({super.key, required this.upcomingMeetings});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController();
  final RapatApiService _rapatApiService = RapatApiService();
  bool _isProcessing = false; // Flag untuk menandai proses API sedang berjalan
  Timer? _debounce;

  // Animation state
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _debounce?.cancel();
    cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeScanned(BarcodeCapture barcodes) {
    if (_isProcessing || (_debounce?.isActive ?? false)) return;

    final barcode = barcodes.barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() => _isProcessing = true);

    // Stop camera sementara
    cameraController.stop();

    // Beri feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("QR Code berhasil dikenali. Memvalidasi..."),
        duration: Duration(milliseconds: 1500),
      ),
    );

    // Validasi QR token SEGERA
    _rapatApiService.validateQrToken(barcode.rawValue!).then((result) {
      if (!mounted) return;

      final sessionToken = result['session_token']?.toString();

      if (sessionToken == null) {
        throw Exception('Session token tidak diterima dari server');
      }

      // Navigasi ke FaceScanScreen dengan session token
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FaceScanScreen(
            qrToken: barcode.rawValue!,
            onCapture: (token, photo) async {
              // Callback saat foto diambil - gunakan session token
              await _processAttendanceWithPhoto(
                  token, File(photo.path), sessionToken);
            },
          ),
        ),
      ).then((_) {
        // Resume scanner setelah kembali
        if (mounted) {
          setState(() => _isProcessing = false);
          cameraController.start();
        }
      });
    }).catchError((error) {
      if (!mounted) return;

      // Tampilkan error jika validasi QR gagal
      _showResultDialog(
        isSuccess: false,
        title: 'QR Code Tidak Valid',
        message: error.toString().replaceFirst('Exception: ', ''),
      );

      // Resume scanner
      setState(() => _isProcessing = false);
      cameraController.start();
    });
  }

  Future<void> _processAttendanceWithPhoto(
      String qrToken, File photo, String sessionToken) async {
    try {
      // Kirim absensi dengan session token
      final result = await _rapatApiService.attendRapatWithPhoto(
        qrToken,
        photo,
        sessionToken: sessionToken,
      );
      final message = result['message']?.toString();

      Rapat? rapat;
      final rapatData = result['rapat'];
      final idRapat = result['id_rapat'];

      if (rapatData != null && rapatData is Map<String, dynamic>) {
        rapat = Rapat.fromJson(rapatData);
      }

      // Tutup FaceScanScreen dulu
      if (mounted) Navigator.of(context).pop();

      _showResultDialog(
        isSuccess: true,
        title: 'Absensi Berhasil',
        message: message ?? 'Anda berhasil melakukan absensi.',
        rapat: rapat,
        rapatId: idRapat?.toString() ?? rapat?.idRapat.toString(),
      );
    } catch (e) {
      // Tutup FaceScanScreen dulu jika masih terbuka
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();

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
      Rapat? rapat,
      String? rapatId}) {
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
                _resetScanner(isSuccess: isSuccess, rapatId: rapatId);
              },
              child: Text(isSuccess ? 'Tutup' : 'Coba Lagi'),
            ),
          ],
        );
      },
    );
  }

  void _resetScanner({bool isSuccess = false, String? rapatId}) {
    // Jika sukses, langsung kembali ke dashboard atau ke detail rapat
    if (isSuccess) {
      Navigator.of(context).pop(); // Tutup scanner

      if (rapatId != null) {
        // Redirect ke halaman detail rapat
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => RapatDetailScreen(rapatId: rapatId)));
      }
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: cameraController,
                        onDetect: _onBarcodeScanned,
                        fit: BoxFit.cover,
                      ),
                      // Animation Overlay
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Positioned(
                            top: 300 *
                                _animation.value, // 300 is container height
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.5),
                                      blurRadius: 5)
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Scanner Frame corners (Optional, simplified here)
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5), width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
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
                                          'ID: ${meeting['id_rapat']} • ${meeting['room']?['room'] ?? ''}',
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
