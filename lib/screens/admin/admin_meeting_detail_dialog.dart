// lib/screens/admin/admin_meeting_detail_dialog.dart

import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminMeetingDetailDialog extends StatefulWidget {
  final Rapat rapat;
  final VoidCallback? onDelete;

  const AdminMeetingDetailDialog({
    super.key,
    required this.rapat,
    this.onDelete,
  });

  @override
  State<AdminMeetingDetailDialog> createState() =>
      _AdminMeetingDetailDialogState();
}

class _AdminMeetingDetailDialogState extends State<AdminMeetingDetailDialog> {
  final RapatApiService _apiService = RapatApiService();
  bool _isLoadingFiles = true;
  Map<String, dynamic>? _rapatData;

  @override
  void initState() {
    super.initState();
    _fetchRapatDetails();
  }

  Future<void> _fetchRapatDetails() async {
    try {
      final data = await _apiService.fetchRapatDetail(widget.rapat.idRapat);
      if (mounted) {
        setState(() {
          _rapatData = data;
          _isLoadingFiles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFiles = false;
        });
      }
    }
  }

  Future<void> _downloadFile(String fileId) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meminta link download...')),
        );
      }

      final urlString = await _apiService.getDownloadUrl(fileId);
      final Uri url = Uri.parse(urlString);

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Tidak dapat membuka link download');
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal download: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.info_outline, color: Color(0xFF1565C0)),
        SizedBox(width: 10),
        Text('Detail Rapat', style: TextStyle(fontWeight: FontWeight.bold)),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.rapat.judul,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.black)),
              const SizedBox(height: 8),
              const Divider(),
              _buildDetailRow(
                  Icons.tag, "ID Rapat", widget.rapat.idRapat.toString()),
              _buildDetailRow(Icons.description_outlined, "Deskripsi",
                  widget.rapat.deskripsi),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        color: Colors.grey[700], size: 20),
                    const SizedBox(width: 16),
                    Chip(
                      avatar: Icon(_getStatusIcon(widget.rapat.statusRapat),
                          color: _getStatusColor(widget.rapat.statusRapat),
                          size: 18),
                      label: Text(widget.rapat.statusRapat,
                          style: TextStyle(
                              color: _getStatusColor(widget.rapat.statusRapat),
                              fontWeight: FontWeight.bold)),
                      backgroundColor: _getStatusColor(widget.rapat.statusRapat)
                          .withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ],
                ),
              ),
              _buildDetailRow(
                  Icons.person_outline, "Pengaju", widget.rapat.namaPengaju),
              _buildDetailRow(
                  Icons.business_outlined, "Cabang", widget.rapat.namaCabang),
              _buildDetailRow(Icons.meeting_room_outlined, "Ruangan",
                  widget.rapat.namaRuangan),
              _buildDetailRow(
                  Icons.calendar_today_outlined,
                  "Waktu Mulai",
                  DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID')
                      .format(widget.rapat.waktuMulai)),
              _buildDetailRow(Icons.timelapse_outlined, "Waktu Selesai",
                  widget.rapat.waktuSelesaiFormatted),
              const SizedBox(height: 16),
              // Files Section
              if (_isLoadingFiles)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_rapatData != null)
                _buildFilesSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Hapus",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDelete?.call();
          },
        ),
        TextButton(
          child: const Text("Tutup",
              style: TextStyle(
                  color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
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

  Widget _buildFilesSection() {
    final files = _rapatData?['files'] as List<dynamic>? ?? [];

    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group files by category
    Map<int, List<dynamic>> filesByCategory = {};
    for (var file in files) {
      final categoryId = file['id_categories'] ?? 4;
      if (!filesByCategory.containsKey(categoryId)) {
        filesByCategory[categoryId] = [];
      }
      filesByCategory[categoryId]!.add(file);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dokumen Rapat',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 12),
        // Build category sections
        ...filesByCategory.entries.map((entry) {
          final categoryId = entry.key;
          final categoryFiles = entry.value;
          return _buildCategorySection(categoryId, categoryFiles);
        }).toList(),
      ],
    );
  }

  Widget _buildCategorySection(int categoryId, List<dynamic> files) {
    final categoryInfo = _getCategoryInfo(categoryId);
    final categoryName = categoryInfo['name'] as String;
    final categoryColor = categoryInfo['color'] as Color;
    final categoryIcon = categoryInfo['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(categoryIcon, color: categoryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${files.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Files List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: files.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: categoryColor.withOpacity(0.1),
            ),
            itemBuilder: (context, index) {
              final file = files[index];
              final fileName = file['file_name'] ?? 'Dokumen';
              final fileExtension = _getFileExtension(fileName);

              return ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      fileExtension.toUpperCase(),
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.download_rounded,
                      color: categoryColor, size: 18),
                  onPressed: () => _downloadFile(file['id_file'].toString()),
                  tooltip: 'Download',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCategoryInfo(int id) {
    switch (id) {
      case 1:
        return {
          'name': 'Materi',
          'color': const Color(0xFF2563EB), // Blue
          'icon': Icons.book_rounded,
        };
      case 2:
        return {
          'name': 'Notulensi',
          'color': const Color(0xFF10B981), // Green
          'icon': Icons.edit_note_rounded,
        };
      case 3:
        return {
          'name': 'Dokumentasi',
          'color': const Color(0xFFF59E0B), // Orange
          'icon': Icons.image_rounded,
        };
      case 4:
        return {
          'name': 'Lainnya',
          'color': const Color(0xFF8B5CF6), // Purple
          'icon': Icons.folder_rounded,
        };
      default:
        return {
          'name': 'File',
          'color': const Color(0xFF6B7280), // Gray
          'icon': Icons.insert_drive_file_rounded,
        };
    }
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last;
    }
    return 'file';
  }
}
