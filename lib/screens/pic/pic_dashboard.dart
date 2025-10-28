// lib/screens/pic/pic_dashboard.dart

import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import '../../Models/models/user.dart';
import '../../services/auth_service.dart';
import 'create_pengajuan.dart';
import '../../Models/services/rapat_api_service.dart';
import 'package:intl/intl.dart';
import 'package:absen_app/screens/admin/meeting_qr.dart'; // Import halaman QR
import 'package:shimmer/shimmer.dart';

import 'pic_rapat_detail.dart'; // <-- Pastikan import ini ada

class PICDashboard extends StatefulWidget {
  const PICDashboard({super.key});

  @override
  State<PICDashboard> createState() => _PICDashboardState();
}

class _PICDashboardState extends State<PICDashboard> {
  int _selectedTab = 0;
  int currentPageIndex = 1;
  bool _isLoading = true;
  String? _errorMessage;
  AppUser? _currentUser;

  final RapatApiService _rapatApiService = RapatApiService();

  List<Rapat> _rapatDisetujui = []; // Status: diterima
  List<Rapat> _rapatBerlangsung = []; // Status: berlangsung
  List<Rapat> _rapatDiajukan = []; // Status: menunggu
  List<Rapat> _historyRapat = []; // Status: selesai + ditolak

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
        AuthService().getProfile(),
        _rapatApiService.fetchRapatByUser(),
      ]);

      _currentUser = results[0] as AppUser?;
      final List<Map<String, dynamic>> rawRapatList =
          results[1] as List<Map<String, dynamic>>;

      final List<Rapat> allRapat =
          rawRapatList.map((json) => Rapat.fromJson(json)).toList();
      final DateTime now = DateTime.now();

      // KELOMPOKKAN RAPAT BERDASARKAN 4 STATUS (TETAP 4 TAB)
      _rapatDiajukan = allRapat.where((r) {
        final status = r.statusRapat.toLowerCase();
        return status.contains('menunggu') || status.contains('pending');
      }).toList();

      _rapatDisetujui = allRapat.where((r) {
        final status = r.statusRapat.toLowerCase();
        return (status.contains('diterima') || status.contains('approved')) &&
            r.waktuMulai.isAfter(now); // Rapat yang akan datang
      }).toList();

      _rapatBerlangsung = allRapat.where((r) {
        final status = r.statusRapat.toLowerCase();
        // HANYA rapat dengan status berlangsung/ongoing
        return status.contains('berlangsung') || status.contains('ongoing');
      }).toList();

      _historyRapat = allRapat.where((r) {
        final status = r.statusRapat.toLowerCase();
        final isSelesai =
            status.contains('selesai') || status.contains('completed');
        final isDitolak =
            status.contains('ditolak') || status.contains('rejected');
        final isSudahSelesai =
            r.waktuSelesai != null && r.waktuSelesai!.isBefore(now);

        return isSelesai || isDitolak || isSudahSelesai;
      }).toList();

      // Urutkan data
      _rapatDiajukan.sort((a, b) => b.waktuMulai.compareTo(a.waktuMulai));
      _rapatDisetujui.sort((a, b) => a.waktuMulai.compareTo(b.waktuMulai));
      _rapatBerlangsung.sort((a, b) => a.waktuMulai.compareTo(b.waktuMulai));
      _historyRapat.sort((a, b) => b.waktuMulai.compareTo(a.waktuMulai));
    } catch (e) {
      if (!mounted) return;
      _errorMessage =
          "Gagal memuat data: ${e.toString().replaceAll('Exception: ', '')}";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportMeetingData(Rapat rapat) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Mengekspor data rapat '${rapat.judul}'..."),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blueAccent,
      ),
    );

    try {
      final filePath = await _rapatApiService.downloadAbsensiRapat(
          rapat.idRapat, rapat.judul);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Data rapat berhasil diekspor ke: $filePath"),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Gagal mengekspor data: ${e.toString()}"),
            backgroundColor: Colors.red),
      );
    }
  }

  // Helper untuk warna status yang lebih spesifik
  Color _getStatusColor(String status) {
    final s = status.toLowerCase();

    if (s.contains('diterima') || s.contains('approved')) {
      return Colors.green;
    }
    if (s.contains('berlangsung') || s.contains('ongoing')) {
      return Colors.blue;
    }
    if (s.contains('selesai') || s.contains('completed')) {
      return Colors.grey;
    }
    if (s.contains('ditolak') || s.contains('rejected')) {
      return Colors.red;
    }
    if (s.contains('menunggu') || s.contains('pending')) {
      return Colors.orange;
    }
    return Colors.purple;
  }

  // Widget untuk halaman Rapat
  Widget _buildRapatPage() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _isLoading
          ? _buildRapatListShimmer()
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : _rapatDisetujui.isEmpty &&
                      _rapatBerlangsung.isEmpty &&
                      _rapatDiajukan.isEmpty &&
                      _historyRapat.isEmpty
                  ? const Center(child: Text("Belum ada data rapat."))
                  : Column(
                      children: [
                        // Tab Bar dengan 4 tab (TETAP 4 TAB)
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              _buildTabItem(0, 'Disetujui'),
                              _buildTabItem(1, 'Berlangsung'),
                              _buildTabItem(2, 'Diajukan'),
                              _buildTabItem(3, 'History'),
                            ],
                          ),
                        ),
                        // Content
                        Expanded(
                          child: _getCurrentTabContent(),
                        ),
                      ],
                    ),
    );
  }

  Widget _getCurrentTabContent() {
    switch (_selectedTab) {
      case 0: // Rapat Disetujui (diterima)
        return _buildRapatList(
            _rapatDisetujui, "Tidak ada rapat yang disetujui.");
      case 1: // Rapat Berlangsung (HANYA status berlangsung)
        return _buildRapatList(
            _rapatBerlangsung, "Tidak ada rapat yang berlangsung.");
      case 2: // Rapat Diajukan (menunggu)
        return _buildRapatList(
            _rapatDiajukan, "Tidak ada rapat yang diajukan.");
      case 3: // History Rapat (selesai + ditolak)
        return _buildRapatList(_historyRapat, "Tidak ada history rapat.");
      default:
        return _buildRapatList(
            _rapatDisetujui, "Tidak ada rapat yang disetujui.");
    }
  }

  Widget _buildRapatList(List<Rapat> rapatList, String emptyMessage) {
    if (rapatList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: rapatList.length,
      itemBuilder: (context, i) {
        final Rapat rapat = rapatList[i];
        return _buildRapatCard(rapat);
      },
    );
  }

  // Widget untuk halaman Dashboard
  Widget _buildDashboardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          // Header
          Container(
            height: 150, // Sesuaikan dengan tinggi header asli
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Statistik
                  Container(
                    width: double.infinity,
                    height: 90, // Sesuaikan tinggi card statistik
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Judul list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(height: 20, width: 200, color: Colors.white),
                      Container(height: 32, width: 100, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // List
                  Expanded(
                    child: ListView.builder(
                      itemCount: 3,
                      itemBuilder: (context, index) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Container(height: 70, color: Colors.white),
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

  Widget _buildDashboardPage() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _isLoading
          ? _buildDashboardShimmer()
          : Container(
              color: const Color(0xFFF5F7FA),
              child: Column(children: [
                // Header Section dengan gradient biru
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFFFD600),
                                  radius: 18,
                                  child: Text(
                                    _currentUser?.name.isNotEmpty == true
                                        ? _currentUser!.name
                                            .substring(0, 1)
                                            .toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Halo, ${_currentUser?.name ?? 'user'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _currentUser?.email ?? 'user@example.com',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Card Statistik dengan 4 informasi (TETAP 4)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD600),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              // Total Rapat
                              Expanded(
                                child: Column(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        color: Colors.white, size: 20),
                                    const SizedBox(height: 4),
                                    Text(
                                      (_rapatDisetujui.length +
                                              _rapatBerlangsung.length +
                                              _rapatDiajukan.length +
                                              _historyRapat.length)
                                          .toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Total',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withOpacity(0.5)),

                              // Disetujui
                              Expanded(
                                child: Column(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.white, size: 20),
                                    const SizedBox(height: 4),
                                    Text(
                                      _rapatDisetujui.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Disetujui',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withOpacity(0.5)),

                              // Berlangsung
                              Expanded(
                                child: Column(
                                  children: [
                                    const Icon(Icons.play_circle,
                                        color: Colors.white, size: 20),
                                    const SizedBox(height: 4),
                                    Text(
                                      _rapatBerlangsung.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Berlangsung',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withOpacity(0.5)),

                              // Menunggu
                              Expanded(
                                child: Column(
                                  children: [
                                    const Icon(Icons.schedule,
                                        color: Colors.white, size: 20),
                                    const SizedBox(height: 4),
                                    Text(
                                      _rapatDiajukan.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Menunggu',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Section Rapat Mendatang (Disetujui + Berlangsung)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Rapat Mendatang & Berlangsung',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const CreatePengajuan()),
                                );
                                _loadData();
                              },
                              icon: const Icon(Icons.add,
                                  size: 16, color: Colors.white),
                              label: const Text(
                                'Buat Rapat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Gabungan rapat disetujui dan berlangsung untuk dashboard
                        Expanded(
                          child: _buildDashboardRapatList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _buildDashboardRapatList() {
    final List<Rapat> combinedList = [
      ..._rapatBerlangsung,
      ..._rapatDisetujui,
    ];

    combinedList.sort((a, b) => a.waktuMulai.compareTo(b.waktuMulai));

    if (combinedList.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Tidak ada rapat mendatang',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: combinedList.length > 5 ? 5 : combinedList.length,
      itemBuilder: (context, index) {
        return _buildSimpleRapatCard(combinedList[index]);
      },
    );
  }

  // Widget card rapat sederhana untuk dashboard
  Widget _buildSimpleRapatCard(Rapat rapat) {
    final statusColor = _getStatusColor(rapat.statusRapat);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PICRapatDetail(rapat: rapat),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rapat.judul,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('d MMM y, HH:mm', 'id_ID')
                          .format(rapat.waktuMulai),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      rapat.namaRuangan,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rapat.statusRapat,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk halaman Profil (tetap sama)
  Widget _buildProfilePage() {
    final ThemeData theme = Theme.of(context);
    return Card(
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.all(8.0),
      child: SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_currentUser != null) ...[
                CircleAvatar(
                  backgroundColor: const Color(0xFF1976D2),
                  radius: 40,
                  child: Text(
                    _currentUser!.name.isNotEmpty
                        ? _currentUser!.name.substring(0, 1).toUpperCase()
                        : 'P',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_currentUser!.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(_currentUser!.email, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService().logout();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                Text('Profile Page', style: theme.textTheme.titleLarge),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('PIC Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: const Color(0xFFFFD600),
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.meeting_room),
            icon: Icon(Icons.meeting_room_outlined),
            label: 'Rapat',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person),
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: currentPageIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePengajuan()),
                );
                _loadData();
              },
              backgroundColor: const Color(0xFFFFD600),
              icon: const Icon(Icons.add, color: Colors.black87),
              label: const Text('Ajukan Rapat',
                  style: TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.bold)),
            )
          : null,
      body: <Widget>[
        _buildRapatPage(),
        _buildDashboardPage(),
        _buildProfilePage(),
      ][currentPageIndex],
    );
  }

  Widget _buildTabItem(int index, String title) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.blue[800],
              fontWeight: FontWeight.bold,
              fontSize: 12, // Sedikit lebih kecil untuk 4 tab
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRapatListShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 3, // Tampilkan beberapa placeholder
        itemBuilder: (context, i) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: double.infinity, height: 150, color: Colors.white)
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // WIDGET CARD UNIVERSAL UNTUK MENAMPILKAN DATA RAPAT
  Widget _buildRapatCard(Rapat rapat) {
    final statusColor = _getStatusColor(rapat.statusRapat);
    final isSelesai = rapat.statusRapat.toLowerCase().contains('selesai');
    final isDitolak = rapat.statusRapat.toLowerCase().contains('ditolak');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PICRapatDetail(rapat: rapat),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      rapat.judul,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isSelesai || isDitolak
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      rapat.statusRapat,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Tanggal
              _buildInfoRow(
                Icons.calendar_today,
                DateFormat('EEEE, d MMMM y', 'id_ID').format(rapat.waktuMulai),
              ),

              _buildInfoRow(
                Icons.access_time,
                '${DateFormat('HH:mm').format(rapat.waktuMulai)} - '
                '${rapat.waktuSelesai != null ? "${DateFormat('HH:mm').format(rapat.waktuSelesai!)} WIB" : "Selesai"}',
              ),

              // Ruangan
              _buildInfoRow(Icons.meeting_room, rapat.namaRuangan),

              // Nama Pengaju
              _buildInfoRow(Icons.person, 'Pengaju: ${rapat.namaPengaju}'),

              const SizedBox(height: 16),
              // Tombol Aksi
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Tombol Export hanya untuk rapat yang Selesai
                  if (rapat.statusRapat == 'Selesai')
                    ElevatedButton.icon(
                      onPressed: () => _exportMeetingData(rapat),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),

                  // Tombol QR untuk rapat yang belum selesai
                  if (rapat.statusRapat != 'Selesai' &&
                      rapat.statusRapat != 'Ditolak' &&
                      rapat.statusRapat != 'Menunggu')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MeetingQR(initialRapat: rapat)),
                        );
                      },
                      icon: const Icon(Icons.qr_code, size: 16),
                      label: const Text('QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2), // Warna biru
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
        ],
      ),
    );
  }
}
