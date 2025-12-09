import 'package:flutter/material.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:absen_app/screens/user/rapat_detail_screen.dart';

class MeetingHistoryPage extends StatefulWidget {
  final bool showAppBar;
  const MeetingHistoryPage({super.key, this.showAppBar = true});

  @override
  State<MeetingHistoryPage> createState() => _MeetingHistoryPageState();
}

class _MeetingHistoryPageState extends State<MeetingHistoryPage> {
  final RapatApiService _rapatApiService = RapatApiService();

  // Data state
  List<Map<String, dynamic>> _allMeetings = [];
  List<Map<String, dynamic>> _filteredMeetings = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  bool _isAscending = false; // false = descending (newest first)
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadMeetingHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetingHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _rapatApiService.fetchRapatByUser();
      if (mounted) {
        setState(() {
          _allMeetings = data;
          _applyFiltersAndSort();
          _isLoading = false;
        });
      }
    } catch (e) {
      // Extract more detailed error message
      String errorMsg = e.toString();

      // Check for common error patterns
      if (errorMsg.contains('SocketException') ||
          errorMsg.contains('Failed host lookup')) {
        errorMsg =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else if (errorMsg.contains('TimeoutException')) {
        errorMsg = 'Koneksi timeout. Server tidak merespons.';
      } else if (errorMsg.contains('401') ||
          errorMsg.contains('Tidak terautentikasi')) {
        errorMsg = 'Sesi Anda telah berakhir. Silakan login kembali.';
      } else if (errorMsg.contains('500')) {
        errorMsg = 'Terjadi kesalahan di server. Silakan coba lagi nanti.';
      } else if (errorMsg.contains('Format data')) {
        errorMsg = 'Format data tidak sesuai. Hubungi administrator.';
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }

      // Log error for debugging
      print('Meeting History Error: $e');
    }
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_allMeetings);

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((meeting) {
        final rapat = meeting['rapat'] as Map<String, dynamic>?;
        final judul = rapat?['judul']?.toString().toLowerCase() ?? '';
        return judul.contains(_searchController.text.toLowerCase());
      }).toList();
    }

    // Apply date range filter
    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((meeting) {
        final rapat = meeting['rapat'] as Map<String, dynamic>?;
        final tanggalStr = rapat?['tanggal'];
        if (tanggalStr == null) return false;

        try {
          final meetingDate = DateTime.parse(tanggalStr);
          final meetingDateOnly =
              DateTime(meetingDate.year, meetingDate.month, meetingDate.day);

          if (_startDate != null && _endDate != null) {
            final start =
                DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
            final end =
                DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
            return meetingDateOnly
                    .isAfter(start.subtract(const Duration(days: 1))) &&
                meetingDateOnly.isBefore(end.add(const Duration(days: 1)));
          } else if (_startDate != null) {
            final start =
                DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
            return meetingDateOnly
                .isAfter(start.subtract(const Duration(days: 1)));
          } else if (_endDate != null) {
            final end =
                DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
            return meetingDateOnly.isBefore(end.add(const Duration(days: 1)));
          }
        } catch (e) {
          return false;
        }
        return true;
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['waktu_absen'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['waktu_absen'] ?? '') ?? DateTime.now();
      return _isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    setState(() {
      _filteredMeetings = filtered;
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, clear it
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
      _applyFiltersAndSort();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      _applyFiltersAndSort();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildSearchAndFilterSection(),
        Expanded(
          child: _isLoading
              ? _buildShimmerLoading()
              : _errorMessage != null
                  ? _buildErrorState()
                  : _filteredMeetings.isEmpty
                      ? _buildEmptyState()
                      : _buildMeetingList(),
        ),
      ],
    );

    // If showAppBar is true, wrap in Scaffold with AppBar (for standalone usage)
    // Otherwise, just return the content in a Container (for embedded usage)
    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'Riwayat Rapat',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF1565C0),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: content,
      );
    } else {
      return Container(
        color: const Color(0xFFF5F7FA),
        child: content,
      );
    }
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (_) => _applyFiltersAndSort(),
            decoration: InputDecoration(
              hintText: 'Cari nama rapat...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFiltersAndSort();
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Date Filter Row
          Row(
            children: [
              // Start Date Button
              Expanded(
                child: Material(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _selectStartDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF1565C0),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _startDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                  : 'Dari Tanggal',
                              style: TextStyle(
                                color: _startDate != null
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey[600],
                                fontWeight: _startDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // End Date Button
              Expanded(
                child: Material(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _selectEndDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event,
                            color: Color(0xFF1565C0),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _endDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                  : 'Sampai Tanggal',
                              style: TextStyle(
                                color: _endDate != null
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey[600],
                                fontWeight: _endDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Clear Filter Button
              if (_startDate != null || _endDate != null)
                Material(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _applyFiltersAndSort();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.clear,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),

              const SizedBox(width: 8),

              // Sort Button
              Material(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isAscending = !_isAscending;
                    });
                    _applyFiltersAndSort();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Results count
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filteredMeetings.length} rapat ditemukan',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingList() {
    return RefreshIndicator(
      onRefresh: _loadMeetingHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredMeetings.length,
        itemBuilder: (context, index) {
          final meeting = _filteredMeetings[index];
          final rapat = meeting['rapat'] as Map<String, dynamic>?;
          final waktuAbsen = meeting['waktu_absen'];
          final statusKehadiran = meeting['id_status_kehadiran'];

          return GestureDetector(
            onTap: () {
              if (rapat != null && rapat['id_rapat'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RapatDetailScreen(
                      rapatId: rapat['id_rapat'].toString(),
                    ),
                  ),
                );
              }
            },
            child: _buildMeetingCard(
              judul: rapat?['judul'] ?? 'Tanpa Judul',
              tanggal: rapat?['tanggal'] ?? '',
              waktuAbsen: waktuAbsen,
              statusKehadiran: statusKehadiran,
              ruangan: rapat?['room']?['nama_ruangan'] ?? 'N/A',
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeetingCard({
    required String judul,
    required String tanggal,
    required String? waktuAbsen,
    required int? statusKehadiran,
    required String ruangan,
  }) {
    final isHadir = statusKehadiran == 2;
    final statusColor = isHadir ? Colors.green : Colors.orange;
    final statusText = isHadir ? 'Hadir' : 'Tidak Hadir';

    String formattedDate = 'N/A';
    String formattedTime = 'N/A';

    if (waktuAbsen != null) {
      try {
        final dateTime = DateTime.parse(waktuAbsen);
        formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
        formattedTime = DateFormat('HH:mm', 'id_ID').format(dateTime);
      } catch (e) {
        // Keep default N/A
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    judul,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Meeting Details
            _buildDetailRow(Icons.calendar_today, formattedDate),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.access_time, 'Absen: $formattedTime'),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.meeting_room, ruangan),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ||
                    _startDate != null ||
                    _endDate != null
                ? 'Tidak ada rapat yang sesuai'
                : 'Belum ada riwayat rapat',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty ||
                    _startDate != null ||
                    _endDate != null
                ? 'Coba ubah filter atau kata kunci'
                : 'Riwayat absensi rapat Anda akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMeetingHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
