import 'package:absen_app/Models/models/meeting.dart';
import 'package:absen_app/Models/services/meeting_repo.dart' show MeetingRepo;
import 'package:absen_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'create_pengajuan.dart';

class PICDashboard extends StatefulWidget {
  const PICDashboard({super.key});

  @override
  State<PICDashboard> createState() => _PICDashboardState();
}

class _PICDashboardState extends State<PICDashboard> {
  bool showHistory = false;
  String currentPIC = 'PIC User'; // Ubah menjadi variabel bukan final
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Simulasi loading data user (ganti dengan data sesungguhnya)
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        currentPIC = 'PIC User'; // Ganti dengan nama user yang login
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Gagal memuat data: $e';
      });
    }
  }

  // Format durasi rapat
  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return 'Selesai tidak menentu';
    
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours jam ${minutes} menit';
    } else {
      return '$minutes menit';
    }
  }

  // Format status rapat
  String _getMeetingStatus(Meeting meeting) {
    final now = DateTime.now();
    
    if (meeting.endTime == null) return 'Tidak Menentu';
    
    if (now.isAfter(meeting.endTime!)) return 'Selesai';
    if (now.isAfter(meeting.startTime)) return 'Berlangsung';
    return 'Akan Datang';
  }

  // Color untuk status rapat
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Selesai':
        return Colors.green;
      case 'Berlangsung':
        return Colors.orange;
      case 'Tidak Menentu':
        return Colors.grey;
      case 'Akan Datang':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dapatkan meetings untuk PIC ini (case insensitive)
    final picMeetings = MeetingRepo.getByResponsible(currentPIC);
    
    // History meetings: meeting yang sudah selesai
    final historyMeetings = picMeetings.where((m) => 
      m.endTime != null && DateTime.now().isAfter(m.endTime!)
    ).toList();

    // Upcoming meetings: meeting yang akan datang
    final upcomingMeetings = picMeetings.where((m) => 
      m.endTime == null || DateTime.now().isBefore(m.endTime!)
    ).toList();

    final meetings = showHistory ? historyMeetings : upcomingMeetings;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Memuat data rapat...',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PIC: $currentPIC',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'PIC Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF66BB6A),
              ],
            ),
          ),
        ),
        actions: [
          // Tombol refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
          // Toggle untuk show/hide history
          IconButton(
            icon: Icon(
              showHistory ? Icons.event : Icons.history,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                showHistory = !showHistory;
              });
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.person, color: Colors.white),
              onSelected: (value) {
                if (value == 'logout') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'username',
                  child: Text('PIC: $currentPIC'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF66BB6A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePengajuan()),
            );
            _refreshData();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          label: const Text(
            'Ajukan Rapat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Header info PIC
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFE8F5E9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ),

          Expanded(
            child: picMeetings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.meeting_room_outlined,
                            size: 60,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Belum ada rapat',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tekan tombol "+" untuk mengajukan rapat baru',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'PIC: $currentPIC',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Header statistik
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(Icons.event, 'Total', picMeetings.length),
                            _buildStatItem(Icons.check_circle, 'Selesai', historyMeetings.length),
                            _buildStatItem(Icons.upcoming, 'Akan Datang', upcomingMeetings.length),
                          ],
                        ),
                      ),

                      // Toggle history/upcoming
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              showHistory ? 'History Rapat' : 'Rapat Akan Datang',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            Text(
                              '${meetings.length} items',
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // List rapat
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadData,
                          backgroundColor: const Color(0xFF4CAF50),
                          color: Colors.white,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: meetings.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final Meeting m = meetings[i];
                              final status = _getMeetingStatus(m);
                              final statusColor = _getStatusColor(status);

                              return _buildMeetingCard(m, status, statusColor);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int count) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingCard(Meeting m, String status, Color statusColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFE8F5E8),
            ],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              showHistory ? Icons.history : Icons.event,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF4CAF50),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.meeting_room, m.room),
                const SizedBox(height: 4),
                _buildInfoRow(
                  Icons.access_time,
                  '${MeetingRepo.formatDate(m.startTime)}${m.endTime != null ? ' - ${MeetingRepo.formatTime(m.endTime!)}' : ''}',
                ),
                if (m.endTime != null) ...[
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    Icons.timer,
                    'Durasi: ${_formatDuration(m.startTime, m.endTime)}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}