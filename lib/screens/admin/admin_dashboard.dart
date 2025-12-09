// ignore_for_file: use_build_context_synchronously

import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:absen_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/auth_service.dart';
import 'package:absen_app/screens/admin/create_meeting.dart';
import 'package:absen_app/screens/admin/edit_meeting.dart';
import 'package:absen_app/screens/admin/meeting_attendance.dart';
import 'package:absen_app/screens/admin/admin_meeting_detail_dialog.dart';
import 'package:absen_app/Models/models/user.dart';
import 'package:absen_app/utils/snackbar_helper.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // --- State untuk UI ---
  int _currentPageIndex = 0; // Untuk BottomNavigationBar
  int _selectedTab =
      0; // Untuk Tab di halaman Dashboard (Daftar Rapat / Pengajuan)

  // PERUBAHAN: Mengganti bool showHistory dengan int untuk 3 state
  int _activeMeetingFilterIndex = 0; // 0: Diterima, 1: Menunggu, 2: History

  // --- State untuk Data ---
  bool _isLoading = true;
  String? _errorMessage;
  AppUser? _currentUser;
  List<Rapat> _allRapat = [];
  List<Map<String, dynamic>> _allCabang = [];
  int? _selectedCabangId;

  // --- Services ---
  final RapatApiService _rapatApiService = RapatApiService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await Future.wait([
        _authService.getProfile(),
        _rapatApiService.fetchCabang(),
        _rapatApiService.fetchAllRapat(),
      ]);

      _currentUser = results[0] as AppUser?;
      if (_currentUser == null) {
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }

      _allCabang = results[1] as List<Map<String, dynamic>>;
      _allRapat = results[2] as List<Rapat>;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
      if (e.toString().contains('Sesi')) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false);
          }
        });
      }
    }
  }

  Future<void> _exportMeetingData(Rapat rapat) async {
    SnackBarHelper.info(
      context,
      "Mengekspor data rapat '${rapat.judul}'...",
    );

    try {
      final filePath = await _rapatApiService.downloadAbsensiRapat(
          rapat.idRapat, rapat.judul);
      SnackBarHelper.success(
        context,
        "Data rapat '${rapat.judul}' berhasil diekspor ke: $filePath",
      );
      // Opsional: Anda bisa menambahkan kode di sini untuk membuka file yang diunduh.
      // Misalnya, menggunakan package `open_filex`: `OpenFilex.open(filePath);`
    } catch (e) {
      SnackBarHelper.error(
        context,
        "Gagal mengekspor data rapat '${rapat.judul}': ${e.toString()}",
      );
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  // file: lib/screens/admin/admin_dashboard.dart

// GANTI SELURUH METHOD BUILD ANDA DENGAN INI
  @override
  Widget build(BuildContext context) {
    final meetingRequests =
        _allRapat.where((r) => r.statusRapat == 'Menunggu').toList();

    // Daftar judul untuk AppBar sesuai dengan halaman
    const List<String> _appBarTitles = ['Admin Dashboard', 'Profil Admin'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        // Menggunakan judul dari list berdasarkan index halaman
        title: Text(_appBarTitles[_currentPageIndex],
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
          ),
        ),
        actions: [
          if (meetingRequests.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () => setState(() {
                    _currentPageIndex = 0; // Tetap di dashboard
                    _selectedTab = 1;
                  }),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6)),
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(meetingRequests.length.toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 8),
                        textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          // PERBAIKAN: Sembunyikan popup menu hanya di halaman profil
          if (_currentPageIndex != 1) // Indeks profil sekarang adalah 1
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: _currentUser?.photo != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(_currentUser!.photo!),
                        radius: 18)
                    : const CircleAvatar(child: Icon(Icons.person), radius: 18),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await _authService.logout();
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Row(children: [
                      const Icon(Icons.person, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Halo, ${_currentUser?.name ?? 'Admin'}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout')
                    ]),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        indicatorColor: const Color(0xFFFFD600),
        selectedIndex: _currentPageIndex,
        // PERUBAHAN: Menghapus item "Admin Panel"
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
      floatingActionButton: _currentPageIndex == 0 && _selectedTab == 0
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFC107), Color(0xFFFFB300)]),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFFFC107).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6))
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CreateRapat()));
                  if (result == true) _refreshData();
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                label: const Text('Buat Rapat',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
      // PERUBAHAN: Menghapus halaman panel dari daftar body
      body: <Widget>[
        _buildDashboardPage(),
        _buildProfilePage(),
      ][_currentPageIndex],
    );
  }

  Widget _buildDashboardPage() {
    final meetingRequests =
        _allRapat.where((r) => r.statusRapat == 'Menunggu').toList();
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: _isLoading
          ? _buildDashboardShimmer()
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_errorMessage!,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.red),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Coba Lagi')),
                        ]),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTab = 0),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                  color: _selectedTab == 0
                                      ? const Color(0xFF1565C0)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Center(
                                  child: Text('Daftar Rapat',
                                      style: TextStyle(
                                          color: _selectedTab == 0
                                              ? Colors.white
                                              : Colors.grey[700],
                                          fontWeight: FontWeight.bold))),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTab = 1),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                  color: _selectedTab == 1
                                      ? const Color(0xFF1565C0)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12)),
                              child:
                                  Stack(alignment: Alignment.center, children: [
                                Center(
                                    child: Text('Pengajuan Rapat',
                                        style: TextStyle(
                                            color: _selectedTab == 1
                                                ? Colors.white
                                                : Colors.grey[700],
                                            fontWeight: FontWeight.bold))),
                                if (meetingRequests.isNotEmpty)
                                  Positioned(
                                    right: 10,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle),
                                      constraints: const BoxConstraints(
                                          minWidth: 20, minHeight: 20),
                                      child: Center(
                                          child: Text(
                                              meetingRequests.length.toString(),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10),
                                              textAlign: TextAlign.center)),
                                    ),
                                  ),
                              ]),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    Expanded(
                        child: _selectedTab == 0
                            ? _buildMeetingList()
                            : _buildMeetingRequestList(meetingRequests)),
                  ],
                ),
    );
  }

  Widget _buildDashboardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          // Tab bar shimmer
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Statistik shimmer
          Container(
            margin: const EdgeInsets.all(16),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          // Filter shimmer
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // List shimmer
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              itemCount: 2,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Container(height: 250, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    final ThemeData theme = Theme.of(context);
    return Card(
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.all(8.0),
      child: SizedBox.expand(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentUser != null) ...[
                      _currentUser!.photo != null
                          ? CircleAvatar(
                              backgroundImage:
                                  NetworkImage(_currentUser!.photo!),
                              radius: 40,
                            )
                          : CircleAvatar(
                              backgroundColor: const Color(0xFF1565C0),
                              radius: 40,
                              child: Text(
                                _currentUser!.name.isNotEmpty
                                    ? _currentUser!.name
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24),
                              ),
                            ),
                      const SizedBox(height: 16),
                      Text(_currentUser!.name,
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(_currentUser!.email,
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _authService.logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
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
                      const Icon(Icons.person_off,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Gagal memuat profil',
                          style: theme.textTheme.titleLarge),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMeetingList() {
    // 1. Filter rapat berdasarkan cabang yang dipilih (jika ada)
    final meetingsForDisplay = (_selectedCabangId == null)
        ? _allRapat
        : _allRapat.where((r) => r.idCabang == _selectedCabangId).toList();

    // 2. Filter dan urutkan rapat berdasarkan status untuk setiap tab
    final diterimaMeetings = meetingsForDisplay.where((r) {
      final status = r.statusRapat.toLowerCase();
      return status == 'diterima' ||
          status == 'disetujui' ||
          status == 'berlangsung';
    }).toList()
      ..sort((a, b) => a.waktuMulai.compareTo(b.waktuMulai)); // Ascending

    final menungguMeetings = meetingsForDisplay
        .where((r) => r.statusRapat.toLowerCase() == 'menunggu')
        .toList()
      ..sort((a, b) => a.waktuMulai.compareTo(b.waktuMulai)); // Ascending

    final historyMeetings = meetingsForDisplay.where((r) {
      final status = r.statusRapat.toLowerCase();
      return status == 'selesai' || status == 'ditolak';
    }).toList()
      ..sort((a, b) => b.waktuMulai.compareTo(a.waktuMulai)); // Descending

    // 3. Tentukan list mana yang akan ditampilkan berdasarkan tab aktif
    List<Rapat> meetings;
    switch (_activeMeetingFilterIndex) {
      case 1:
        meetings = menungguMeetings;
        break;
      case 2:
        meetings = historyMeetings;
        break;
      case 0:
      default:
        meetings = diterimaMeetings;
    }

    if (_allRapat.isEmpty && _selectedCabangId == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.meeting_room_outlined,
                size: 60, color: Color(0xFF1565C0)),
          ),
          const SizedBox(height: 24),
          const Text('Belum ada rapat',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0))),
          const SizedBox(height: 8),
          Text('Tekan tombol "+" untuk membuat rapat baru',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ]),
      );
    }

    return Column(
      children: [
        // Kartu Statistik
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFFC107), Color(0xFFFFB300)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFFFC107).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Column(children: [
              const Icon(Icons.event, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text('${_allRapat.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const Text('Total Rapat',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ]),
            Container(
                height: 60, width: 1, color: Colors.white.withOpacity(0.3)),
            Column(children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                  '${_allRapat.where((r) => r.statusRapat.toLowerCase() == 'diterima' || r.statusRapat.toLowerCase() == 'disetujui' || r.statusRapat.toLowerCase() == 'berlangsung').length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const Text('Diterima',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ]),
          ]),
        ),

        const SizedBox(height: 16),
        _buildCabangFilterDropdown(),
        const SizedBox(height: 16),

        // UI Tab Filter Baru
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFilterTab(label: "Diterima", index: 0),
              _buildFilterTab(label: "Menunggu", index: 1),
              _buildFilterTab(label: "History", index: 2),
            ],
          ),
        ),

        meetings.isEmpty
            ? Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _selectedCabangId == null
                          ? 'Tidak ada rapat untuk kategori ini.'
                          : 'Tidak ada data rapat untuk cabang yang dipilih.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
            : Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: meetings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final Rapat m = meetings[i];
                    return InkWell(
                      onTap: () => _showMeetingDetailsDialog(m),
                      borderRadius: BorderRadius.circular(16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(colors: [
                              Colors.white,
                              _getCardGradientColor(m.statusRapat)
                            ]),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                          color: _getStatusColor(m.statusRapat),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Icon(_getStatusIcon(m.statusRapat),
                                          color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: Text(m.judul,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF1565C0)),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis)),
                                  ]),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                      Icons.meeting_room, m.namaRuangan),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                      Icons.access_time,
                                      DateFormat('EEEE, dd MMMM yyyy HH:mm',
                                              'id_ID')
                                          .format(m.waktuMulai)),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(Icons.person, m.namaPengaju),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                      Icons.flag, 'Status: ${m.statusRapat}'),
                                  const SizedBox(height: 16),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(children: [
                                      if (_activeMeetingFilterIndex != 2) ...[
                                        _buildActionButton('Edit', Icons.edit,
                                            const Color(0xFFFFC107), () async {
                                          final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      EditMeeting(rapat: m)));
                                          if (result == true) _refreshData();
                                        }),
                                        const SizedBox(width: 8),
                                        // Tombol Hapus - ditambahkan untuk CRUD lengkap
                                        _buildActionButton(
                                            'Hapus', Icons.delete, Colors.red,
                                            () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                  'Konfirmasi Hapus'),
                                              content: Text(
                                                  'Anda yakin ingin menghapus rapat "${m.judul}"?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.red),
                                                  child: const Text('Hapus'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await _deleteRapat(
                                                m.idRapat, m.judul);
                                          }
                                        }),
                                        const SizedBox(width: 8),
                                      ],
                                      if (m.statusRapat == 'Selesai') ...[
                                        _buildActionButton(
                                            'Export',
                                            Icons.download,
                                            Colors.green,
                                            () => _exportMeetingData(m)),
                                        const SizedBox(width: 8),
                                      ],
                                      if (m.statusRapat != 'Selesai') ...[
                                        // Tambahkan kondisi ini
                                        _buildActionButton(
                                            'Absensi',
                                            Icons.people,
                                            const Color(0xFF4CAF50), () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      MeetingAttendance(
                                                          rapat: m)));
                                        }),
                                      ]
                                    ]),
                                  ),
                                ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  // Widget baru untuk membuat tab filter
  Widget _buildFilterTab({required String label, required int index}) {
    final bool isActive = _activeMeetingFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeMeetingFilterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1565C0) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingRequestList(List<Rapat> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline,
                size: 60, color: Color(0xFF1565C0)),
          ),
          const SizedBox(height: 24),
          const Text('Tidak ada pengajuan rapat',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0))),
          const SizedBox(height: 8),
          Text('Semua pengajuan rapat telah diproses',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = requests[index];
        return InkWell(
          onTap: () => _showMeetingDetailsDialog(request),
          borderRadius: BorderRadius.circular(16),
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFE3F2FD)])),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              color: const Color(0xFFFF9800),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.pending_actions,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(request.judul,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1565C0)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                          Icons.person, 'Oleh: ${request.namaPengaju}'),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.meeting_room, request.namaRuangan),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                          Icons.access_time,
                          DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID')
                              .format(request.waktuMulai)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _buildRequestButton('Setujui', Icons.check,
                              Colors.green, () => _approveRequest(request)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildRequestButton('Tolak', Icons.close,
                              Colors.red, () => _showRejectionDialog(request)),
                        ),
                      ]),
                    ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(color: Colors.grey[800], fontSize: 14),
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRequestButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper functions untuk warna dan ikon berdasarkan status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Berlangsung':
        return Colors.blue;
      case 'Menunggu':
        return Colors.orange;
      case 'Ditolak':
        return Colors.red;
      case 'Selesai':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Disetujui':
        return Icons.check_circle;
      case 'Berlangsung':
        return Icons.play_circle_filled;
      case 'Menunggu':
        return Icons.pending_actions;
      case 'Ditolak':
        return Icons.cancel;
      case 'Selesai':
        return Icons.history;
      default:
        return Icons.help;
    }
  }

  Color _getCardGradientColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green.shade50;
      case 'Berlangsung':
        return Colors.blue.shade50;
      case 'Menunggu':
        return Colors.orange.shade50;
      case 'Ditolak':
        return Colors.red.shade50;
      case 'Selesai':
        return Colors.grey.shade100;
      default:
        return Colors.purple.shade50;
    }
  }

  // GANTI FUNGSI LAMA ANDA DENGAN INI
  void _showMeetingDetailsDialog(Rapat rapat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AdminMeetingDetailDialog(
          rapat: rapat,
          onDelete: () => _showDeleteConfirmationFromDetail(rapat),
        );
      },
    );
  }

  Future<void> _approveRequest(Rapat request) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui Pengajuan Rapat'),
        content: Text(
            'Apakah Anda yakin ingin menyetujui pengajuan rapat "${request.judul}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Setujui')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _rapatApiService.approveRapat(request.idRapat);
      SnackBarHelper.success(
        context,
        'Pengajuan "${request.judul}" telah disetujui',
      );
      _refreshData();
    } catch (e) {
      SnackBarHelper.error(
        context,
        'Gagal menyetujui: ${e.toString()}',
      );
    }
  }

  Future<void> _showRejectionDialog(Rapat request) async {
    final reasonController = TextEditingController();
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Pengajuan Rapat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Apakah Anda yakin ingin menolak pengajuan rapat "${request.judul}"?'),
            const SizedBox(height: 16),
            const Text('Alasan Penolakan:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                    hintText: 'Masukkan alasan penolakan...',
                    border: OutlineInputBorder()),
                maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                SnackBarHelper.warning(
                  context,
                  'Alasan penolakan tidak boleh kosong',
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final rejectionReason = reasonController.text.trim();
      await _rapatApiService.rejectRapat(request.idRapat, rejectionReason);
      SnackBarHelper.success(
        context,
        'Pengajuan "${request.judul}" telah ditolak',
      );
      _refreshData();
    } catch (e) {
      SnackBarHelper.error(
        context,
        'Gagal menolak: ${e.toString()}',
      );
    }
  }

  Widget _buildCabangFilterDropdown() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(16, 0, 16, 0), // Mengurangi padding atas
      child: DropdownButtonFormField<int?>(
        value: _selectedCabangId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Filter Berdasarkan Cabang',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.business_outlined),
        ),
        hint: const Text('Semua Cabang'),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Semua Cabang',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ..._allCabang.map<DropdownMenuItem<int?>>((cabang) {
            final int id = (cabang['id'] ?? 0) as int;
            final String nama =
                (cabang['cabang'] ?? 'Cabang Tanpa Nama') as String;
            return DropdownMenuItem<int?>(
              value: id,
              child: Text(nama),
            );
          }).toList(),
        ],
        onChanged: (int? newValue) {
          setState(() {
            _selectedCabangId = newValue;
          });
        },
      ),
    );
  }

  // TAMBAHKAN DUA FUNGSI BARU INI DI DALAM class _AdminDashboardState
  Future<void> _deleteRapat(String idRapat, String judul) async {
    try {
      await _rapatApiService.deleteRapat(idRapat);
      SnackBarHelper.success(
        context,
        'Rapat "$judul" berhasil dihapus',
      );
      _refreshData(); // Refresh data setelah berhasil menghapus
    } catch (e) {
      SnackBarHelper.error(
        context,
        'Gagal menghapus rapat: ${e.toString()}',
      );
    }
  }

  void _showDeleteConfirmationFromDetail(Rapat rapat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
            'Apakah Anda yakin ingin menghapus rapat "${rapat.judul}"? Tindakan ini tidak dapat diurungkan.'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(ctx).pop(); // Tutup dialog konfirmasi
              _deleteRapat(rapat.idRapat, rapat.judul);
            },
          ),
        ],
      ),
    );
  }
}
