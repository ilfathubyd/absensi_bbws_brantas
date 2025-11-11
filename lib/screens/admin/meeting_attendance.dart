import 'dart:async';
import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class MeetingAttendance extends StatefulWidget {
  final Rapat rapat;

  const MeetingAttendance({super.key, required this.rapat});

  @override
  State<MeetingAttendance> createState() => _MeetingAttendanceState();
}

class _MeetingAttendanceState extends State<MeetingAttendance> {
  final RapatApiService _rapatApiService = RapatApiService();
  Timer? _pollingTimer;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _attendanceList = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendance(); // Panggilan pertama saat halaman dibuka
    _startPolling(); // Mulai polling
  }

  void _startPolling() {
    // Mulai polling setiap 5 detik
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      _fetchAttendance(isPolling: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Hentikan polling saat halaman ditutup
    super.dispose();
  }

  Future<void> _fetchAttendance({bool isPolling = false}) async {
    if (!mounted) return;

    // Hanya tampilkan loading indicator saat pertama kali, bukan saat polling
    if (!isPolling) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data =
          await _rapatApiService.fetchAbsensiRapat(widget.rapat.idRapat);
      if (mounted) {
        setState(() {
          _attendanceList = data;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _handleError("Gagal memuat data absensi: ${e.toString()}",
            isPolling: isPolling);
      }
    } finally {
      if (mounted && !isPolling) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleError(String message, {bool isPolling = false}) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Data Absensi Rapat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                _fetchAttendance(), // Refresh hanya mengambil data absensi
            tooltip: 'Perbarui Data',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMeetingInfoCard(),
          Expanded(
            child: RefreshIndicator(
              // RefreshIndicator sekarang memanggil _fetchAttendance
              onRefresh: () => _fetchAttendance(),
              child: _isLoading
                  ? _buildShimmerList()
                  : _errorMessage != null
                      ? _buildErrorWidget()
                      : _attendanceList.isEmpty
                          ? _buildEmptyState()
                          : _buildAttendanceList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.rapat.judul,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0)),
            ),
            const Divider(height: 20),
            _buildInfoRow(
                Icons.calendar_today,
                DateFormat('EEEE, d MMMM y', 'id_ID')
                    .format(widget.rapat.waktuMulai)),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time,
                '${widget.rapat.waktuMulaiFormatted} - ${widget.rapat.waktuSelesaiFormatted}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.meeting_room, widget.rapat.namaRuangan),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
      ],
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _attendanceList.length,
      itemBuilder: (context, index) {
        final attendance = _attendanceList[index];
        final user = attendance['user'] as Map<String, dynamic>? ?? {};
        final waktuAbsen = attendance['waktu_absen'] != null
            ? DateFormat('HH:mm:ss')
                .format(DateTime.parse(attendance['waktu_absen']))
            : 'N/A';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1565C0).withOpacity(0.2),
              child: Text(
                user['name']?.toString().substring(0, 1) ?? '?',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
              ),
            ),
            title: Text(user['name'] ?? 'Nama Tidak Ditemukan',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(user['id_division'] != null
                ? 'ID Divisi: ${user['id_division']}'
                : 'Divisi Tidak Diketahui'),
            trailing: Text(
              waktuAbsen,
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.white),
            title: Container(height: 16, color: Colors.white),
            subtitle: Container(height: 12, width: 100, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(_errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Belum ada peserta yang melakukan absensi',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}
