import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:absen_app/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RapatDetailScreen extends StatefulWidget {
  final String rapatId;

  const RapatDetailScreen({super.key, required this.rapatId});

  @override
  State<RapatDetailScreen> createState() => _RapatDetailScreenState();
}

class _RapatDetailScreenState extends State<RapatDetailScreen> {
  final RapatApiService _apiService = RapatApiService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _rapatData;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _apiService.fetchRapatDetail(widget.rapatId);
      if (mounted) {
        setState(() {
          _rapatData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
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

      // 1. Dapatkan Signed URL dari backend
      final urlString = await _apiService.getDownloadUrl(fileId);
      final Uri url = Uri.parse(urlString);

      // 2. Buka URL di browser eksternal
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: const Text('Detail Rapat'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchDetail,
                        child: const Text('Coba Lagi'),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildFilesSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    final judul = _rapatData?['judul'] ?? 'Tanpa Judul';
    final status = _rapatData?['status'] != null
        ? _rapatData!['status']['status_rapat']
        : '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    String tanggal = _rapatData?['tanggal'] ?? '-';
    try {
      if (tanggal != '-') {
        final date = DateTime.parse(tanggal);
        tanggal = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
      }
    } catch (_) {}

    String start = _rapatData?['waktu_start'] ?? '';
    String end = _rapatData?['waktu_end'] ?? '';

    // Simple substring to remove seconds if present (HH:mm:ss -> HH:mm)
    if (start.length > 5) start = start.substring(0, 5);
    if (end.length > 5) end = end.substring(0, 5);

    final waktu = (start.isNotEmpty || end.isNotEmpty) ? '$start - $end' : '-';

    final ruangan =
        _rapatData?['room'] != null ? _rapatData!['room']['room'] ?? '-' : '-';
    final cabang = _rapatData?['cabang'] != null
        ? _rapatData!['cabang']['nama_cabang'] ??
            _rapatData!['cabang']['cabang']
        : '-';
    final deskripsi = _rapatData?['desc'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.calendar_today, 'Tanggal', tanggal),
          const Divider(height: 24),
          _buildInfoRow(Icons.access_time, 'Waktu', waktu),
          const Divider(height: 24),
          _buildInfoRow(Icons.meeting_room, 'Ruangan', ruangan),
          const Divider(height: 24),
          _buildInfoRow(Icons.location_city, 'Cabang', cabang),
          const Divider(height: 24),
          _buildInfoRow(Icons.description, 'Deskripsi', deskripsi),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: categoryColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
              color: categoryColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor.withOpacity(0.15),
                  categoryColor.withOpacity(0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(categoryIcon, color: categoryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                        ),
                      ),
                      Text(
                        '${files.length} file${files.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${files.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
            padding: const EdgeInsets.all(12),
            itemCount: files.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: categoryColor.withOpacity(0.1),
            ),
            itemBuilder: (context, index) {
              final file = files[index];
              final fileName = file['file_name'] ?? 'Dokumen';
              final fileExtension = _getFileExtension(fileName);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: categoryColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        fileExtension.toUpperCase(),
                        style: TextStyle(
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    fileExtension.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: categoryColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.download_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () =>
                          _downloadFile(file['id_file'].toString()),
                      tooltip: 'Download',
                    ),
                  ),
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
