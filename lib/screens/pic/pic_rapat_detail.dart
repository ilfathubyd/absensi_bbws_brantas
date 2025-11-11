// lib/screens/pic/pic_rapat_detail.dart

import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/screens/admin/meeting_attendance.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PICRapatDetail extends StatelessWidget {
  final Rapat rapat;

  // ignore: use_super_parameters
  const PICRapatDetail({super.key, required this.rapat});

  // Helper untuk warna status
  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('diterima')) return Colors.green;
    if (s.contains('berlangsung')) return Colors.blue;
    if (s.contains('selesai')) return Colors.grey;
    if (s.contains('ditolak')) return Colors.red;
    if (s.contains('menunggu')) return Colors.orange;
    return Colors.purple;
  }

  // Helper untuk ikon status
  IconData _getStatusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('diterima')) return Icons.check_circle;
    if (s.contains('berlangsung')) return Icons.play_circle_filled;
    if (s.contains('selesai')) return Icons.history;
    if (s.contains('ditolak')) return Icons.cancel;
    if (s.contains('menunggu')) return Icons.pending_actions;
    return Icons.help;
  }

  @override
  Widget build(BuildContext context) {
    final bool canShowAttendance =
        rapat.statusRapat != 'Menunggu' && rapat.statusRapat != 'Ditolak';

    // Helper style untuk tombol aksi
    ButtonStyle actionButtonStyle(Color color) {
      return ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Detail Rapat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KARTU INFORMASI UTAMA ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rapat.judul,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      avatar: Icon(_getStatusIcon(rapat.statusRapat), color: _getStatusColor(rapat.statusRapat), size: 18),
                      label: Text(
                        rapat.statusRapat,
                        style: TextStyle(color: _getStatusColor(rapat.statusRapat), fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: _getStatusColor(rapat.statusRapat).withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      side: BorderSide.none,
                    ),
                    const Divider(height: 24),
                    Text(
                      rapat.deskripsi.isNotEmpty ? rapat.deskripsi : 'Tidak ada deskripsi untuk rapat ini.',
                      style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- KARTU DETAIL WAKTU & LOKASI ---
            _buildSectionTitle('Waktu & Lokasi'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.calendar_today_outlined, "Tanggal", rapat.tanggalFormatted),
                    _buildDetailRow(
                      Icons.access_time_outlined,
                      "Waktu",
                      '${rapat.waktuMulaiFormatted} - ${rapat.waktuSelesaiFormatted} WIB',
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(Icons.business_outlined, "Cabang", rapat.namaCabang),
                    _buildDetailRow(Icons.meeting_room_outlined, "Ruangan", rapat.namaRuangan),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- KARTU DETAIL PENGAJU & ID ---
            _buildSectionTitle('Informasi Tambahan'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.person_outline, "Diajukan Oleh", rapat.namaPengaju),
                    _buildDetailRow(Icons.tag, "ID Rapat", rapat.idRapat.toString()),
                  ],
                ),
              ),
            ),
            if (canShowAttendance) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MeetingAttendance(rapat: rapat),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people_alt_outlined),
                  label: const Text('Lihat Daftar Absensi'),
                  style: actionButtonStyle(Colors.teal),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
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
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
