import 'package:absen_app/Models/models/meeting.dart';
import 'package:absen_app/Models/models/meeting_request.dart';
import 'package:absen_app/Models/services/meeting_repo.dart' show MeetingRepo;
import 'package:absen_app/Models/services/meeting_request_repo.dart';
import 'package:absen_app/Models/services/meeting_service.dart';
import 'package:absen_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'create_meeting.dart';
import 'edit_meeting.dart';
import 'meeting_qr.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool showHistory = false;
  int _selectedTab = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('AdminDashboard initialized');
    _loadData();
  }

  // Helper method untuk mendapatkan screen size
  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  double _getResponsivePadding(BuildContext context) {
    if (_isDesktop(context)) return 16.0;
    if (_isTablet(context)) return 14.0;
    return 12.0;
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    if (_isDesktop(context)) return baseSize + 1;
    if (_isTablet(context)) return baseSize;
    return baseSize - 1;
  }

  int _getCrossAxisCount(BuildContext context) {
    if (_isDesktop(context)) return 4;
    if (_isTablet(context)) return 2;
    return 1;
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      MeetingRequestRepo.debugPrintRequests();
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final approvedMeetings = MeetingRepo.all();
      
      // TAMBAHKAN BARIS INI: Simpan data ke service agar bisa diakses oleh user dashboard
      MeetingService().setApprovedMeetings(approvedMeetings);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat data: ${e.toString()}";
      });
    }
  }

  void _exportMeetingData(Meeting meeting) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Export data rapat '${meeting.title}' belum diimplementasi"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = _isTablet(context);
    final isDesktop = _isDesktop(context);
    final responsivePadding = _getResponsivePadding(context);

    try {
      final approvedMeetings = MeetingRepo.all();
      final meetingRequests = MeetingRequestRepo.pending();
      
      final upcomingMeetings = approvedMeetings.where((m) => 
        m.startTime.isAfter(DateTime.now())
      ).toList();
      
      final historyMeetings = approvedMeetings.where((m) => 
        m.startTime.isBefore(DateTime.now())
      ).toList();

      final meetings = showHistory ? historyMeetings : upcomingMeetings;

      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            'Admin Dashboard',
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(context, 20),
            ),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1565C0),
                  Color(0xFF42A5F5),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshData,
            ),
            if (meetingRequests.isNotEmpty)
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        meetingRequests.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            Container(
              margin: EdgeInsets.only(right: responsivePadding / 2),
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
                  } else if (value == 'debug') {
                    MeetingRequestRepo.debugPrintRequests();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data ditampilkan di konsol debug'),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'username',
                    child: Text('Admin Username'),
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
        floatingActionButton: _selectedTab == 0
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFC107),
                      Color(0xFFFFB300),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateMeeting()),
                    );
                    setState(() {});
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  label: Text(
                    'Buat Rapat',
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: _getResponsiveFontSize(context, 14),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              )
            : null,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(responsivePadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: isDesktop ? 80 : isTablet ? 72 : 64,
                            color: Colors.red,
                          ),
                          SizedBox(height: responsivePadding),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 16),
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: responsivePadding),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Tab Selector - Responsive
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: responsivePadding, 
                          vertical: responsivePadding / 2
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isDesktop 
                          ? Row(
                              children: [
                                Expanded(child: _buildTabButton(0, 'Daftar Rapat', context)),
                                Expanded(child: _buildTabButton(1, 'Pengajuan Rapat', context, meetingRequests.length)),
                              ],
                            )
                          : Column(
                              children: [
                                _buildTabButton(0, 'Daftar Rapat', context),
                                const SizedBox(height: 4),
                                _buildTabButton(1, 'Pengajuan Rapat', context, meetingRequests.length),
                              ],
                            ),
                      ),
                      
                      Expanded(
                        child: _selectedTab == 0 
                            ? _buildMeetingList(approvedMeetings, upcomingMeetings, historyMeetings, meetings, context)
                            : _buildMeetingRequestList(meetingRequests, context),
                      ),
                    ],
                  ),
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(responsivePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: isDesktop ? 80 : isTablet ? 72 : 64,
                  color: Colors.red,
                ),
                SizedBox(height: responsivePadding),
                Text(
                  'Terjadi kesalahan dalam menampilkan dashboard',
                  style: TextStyle(fontSize: _getResponsiveFontSize(context, 16)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: responsivePadding),
                Text(
                  'Error: ${e.toString()}',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 12), 
                    color: Colors.grey
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: responsivePadding),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboard(),
                      ),
                    );
                  },
                  child: const Text('Muat Ulang'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTabButton(int tabIndex, String title, BuildContext context, [int? badgeCount]) {
    final isSelected = _selectedTab == tabIndex;
    final responsivePadding = _getResponsivePadding(context);
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = tabIndex;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: responsivePadding * 0.75),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: _getResponsiveFontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                right: _isDesktop(context) ? 20 : 10,
                top: _isDesktop(context) ? 0 : -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingList(List<Meeting> approvedMeetings, List<Meeting> upcomingMeetings, 
                          List<Meeting> historyMeetings, List<Meeting> meetings, BuildContext context) {
    final responsivePadding = _getResponsivePadding(context);
    final isDesktop = _isDesktop(context);
    final isTablet = _isTablet(context);
    
    return approvedMeetings.isEmpty
        ? Center(
            child: Padding(
              padding: EdgeInsets.all(responsivePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: isDesktop ? 140 : isTablet ? 130 : 120,
                    height: isDesktop ? 140 : isTablet ? 130 : 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.meeting_room_outlined,
                      size: isDesktop ? 80 : isTablet ? 70 : 60,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  SizedBox(height: responsivePadding * 1.5),
                  Text(
                    'Belum ada rapat',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 24),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  SizedBox(height: responsivePadding / 2),
                  Text(
                    'Tekan tombol "+" untuk membuat rapat baru',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 16), 
                      color: Colors.grey[600]
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        : Column(
            children: [
              // Stats Cards - Responsive Grid
              Container(
                margin: EdgeInsets.all(responsivePadding),
                child: isDesktop
                  ? Row(
                      children: [
                        Expanded(child: _buildStatsCard(
                          'Total Rapat', 
                          approvedMeetings.length.toString(), 
                          Icons.event, 
                          context
                        )),
                        SizedBox(width: responsivePadding),
                        Expanded(child: _buildStatsCard(
                          'Akan Datang', 
                          upcomingMeetings.length.toString(), 
                          Icons.access_time, 
                          context
                        )),
                      ],
                    )
                  : _buildStatsCard(
                      null, 
                      null, 
                      null, 
                      context,
                      totalMeetings: approvedMeetings.length,
                      upcomingMeetings: upcomingMeetings.length,
                    ),
              ),

              // Filter Buttons - Responsive
              Container(
                margin: EdgeInsets.symmetric(horizontal: responsivePadding),
                child: isDesktop
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFilterButton("Rapat Akan Datang", !showHistory, context),
                        SizedBox(width: responsivePadding),
                        _buildFilterButton("History Rapat", showHistory, context),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildFilterButton("Rapat Akan Datang", !showHistory, context)),
                            SizedBox(width: responsivePadding / 2),
                            Expanded(child: _buildFilterButton("History Rapat", showHistory, context)),
                          ],
                        ),
                      ],
                    ),
              ),

              const SizedBox(height: 16),

              // Meeting List - Responsive Grid
              Expanded(
                child: isDesktop || isTablet
                  ? GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: responsivePadding),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(context),
                        childAspectRatio: isDesktop ? 2.2 : 1.8,
                        crossAxisSpacing: responsivePadding,
                        mainAxisSpacing: responsivePadding,
                      ),
                      itemCount: meetings.length,
                      itemBuilder: (context, i) => _buildMeetingCard(meetings[i], context),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: responsivePadding),
                      itemCount: meetings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _buildMeetingCard(meetings[i], context),
                    ),
              ),
              SizedBox(height: responsivePadding * 5),
            ],
          );
  }

  Widget _buildStatsCard(String? title, String? value, IconData? icon, BuildContext context,
      {int? totalMeetings, int? upcomingMeetings}) {
    final responsivePadding = _getResponsivePadding(context);
    final isDesktop = _isDesktop(context);
    
    if (title != null && value != null && icon != null) {
      // Single stat card for desktop
      return Container(
        padding: EdgeInsets.all(responsivePadding),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC107).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isDesktop ? 24 : 20,
            ),
            SizedBox(height: responsivePadding / 3),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: _getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: _getResponsiveFontSize(context, 10),
              ),
            ),
          ],
        ),
      );
    } else {
      // Combined stats card for mobile/tablet
      return Container(
        padding: EdgeInsets.all(responsivePadding),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC107).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Icon(
                  Icons.event,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(height: responsivePadding / 3),
                Text(
                  totalMeetings.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total Rapat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 10),
                  ),
                ),
              ],
            ),
            Container(
              height: 50,
              width: 1,
              color: Colors.white.withOpacity(0.3),
            ),
            Column(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(height: responsivePadding / 3),
                Text(
                  upcomingMeetings.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Akan Datang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFilterButton(String title, bool isActive, BuildContext context) {
    return TextButton(
      onPressed: () {
        setState(() {
          showHistory = title == "History Rapat";
        });
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: _getResponsivePadding(context),
          vertical: _getResponsivePadding(context) / 2,
        ),
        backgroundColor: isActive ? const Color(0xFF1565C0) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : const Color(0xFF1565C0),
          fontWeight: FontWeight.bold,
          fontSize: _getResponsiveFontSize(context, 14),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting, BuildContext context) {
    final bool isUpcoming = meeting.startTime.isAfter(DateTime.now());
    final responsivePadding = _getResponsivePadding(context);
    final isDesktop = _isDesktop(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              isUpcoming
                  ? const Color(0xFFF3F8FF)
                  : const Color(0xFFFFFBE6),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(responsivePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: isDesktop ? 40 : 35,
                    height: isDesktop ? 40 : 35,
                    decoration: BoxDecoration(
                      color: isUpcoming
                          ? const Color(0xFF1565C0)
                          : const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isUpcoming
                          ? Icons.upcoming
                          : Icons.event_available,
                      color: Colors.white,
                      size: isDesktop ? 20 : 18,
                    ),
                  ),
                  SizedBox(width: responsivePadding / 2),
                  Expanded(
                    child: Text(
                      meeting.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _getResponsiveFontSize(context, 16),
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: responsivePadding),
              
              // Meeting details
              _buildDetailRow(Icons.meeting_room, meeting.room, context),
              SizedBox(height: responsivePadding / 4),
              _buildDetailRow(Icons.access_time, MeetingRepo.formatDate(meeting.startTime), context),
              SizedBox(height: responsivePadding / 4),
              _buildDetailRow(Icons.person, meeting.responsible, context),
              SizedBox(height: responsivePadding / 4),
              _buildDetailRow(Icons.tag, 'ID: ${meeting.id}', context),
              
              SizedBox(height: responsivePadding),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    Icons.edit,
                    const Color(0xFFFFC107),
                    'Edit Rapat',
                    () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditMeeting(meeting: meeting),
                        ),
                      );
                      if (result == true) {
                        setState(() {});
                      }
                    },
                    context,
                  ),
                  if (!isUpcoming) ...[
                    SizedBox(width: responsivePadding / 2),
                    _buildActionButton(
                      Icons.download,
                      Colors.green,
                      'Export Data Rapat',
                      () => _exportMeetingData(meeting),
                      context,
                    ),
                  ],
                  SizedBox(width: responsivePadding / 2),
                  _buildActionButton(
                    Icons.qr_code,
                    const Color(0xFF1565C0),
                    'QR Code',
                    () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (_) => MeetingQR(meeting: meeting),
                      //   ),
                      // );
                    },
                    context,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: _isDesktop(context) ? 14 : 12,
          color: Colors.grey,
        ),
        SizedBox(width: _getResponsivePadding(context) / 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey,
              fontSize: _getResponsiveFontSize(context, 12),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color color, String tooltip, VoidCallback onPressed, BuildContext context) {
    final size = _isDesktop(context) ? 28.0 : 24.0;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: _isDesktop(context) ? 14 : 12,
        ),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildMeetingRequestList(List<MeetingRequest> requests, BuildContext context) {
    final responsivePadding = _getResponsivePadding(context);
    final isDesktop = _isDesktop(context);
    final isTablet = _isTablet(context);

    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(responsivePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isDesktop ? 80 : isTablet ? 70 : 60,
            height: isDesktop ? 80 : isTablet ? 70 : 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: isDesktop ? 40 : isTablet ? 35 : 30,
              color: const Color(0xFF1565C0),
            ),
          ),
          SizedBox(height: responsivePadding),
          Text(
            'Tidak ada pengajuan rapat',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1565C0),
            ),
          ),
          SizedBox(height: responsivePadding / 2),
          Text(
            'Semua pengajuan rapat telah diproses',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 14),
              color: Colors.grey[600]
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
        ),
      );
    }

    return isDesktop || isTablet
      ? GridView.builder(
          padding: EdgeInsets.all(responsivePadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
            childAspectRatio: isDesktop ? 2.0 : 1.6,
            crossAxisSpacing: responsivePadding,
            mainAxisSpacing: responsivePadding,
          ),
          itemCount: requests.length,
          itemBuilder: (context, index) => _buildRequestCard(requests[index], context),
        )
      : ListView.separated(
          padding: EdgeInsets.all(responsivePadding),
          itemCount: requests.length,
          separatorBuilder: (_, __) => SizedBox(height: responsivePadding),
          itemBuilder: (context, index) => _buildRequestCard(requests[index], context),
        );
  }

  Widget _buildRequestCard(MeetingRequest request, BuildContext context) {
    final responsivePadding = _getResponsivePadding(context);
    final isDesktop = _isDesktop(context);

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
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(responsivePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: isDesktop ? 60 : 50,
                    height: isDesktop ? 60 : 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.pending_actions,
                      color: Colors.white,
                      size: isDesktop ? 28 : 24,
                    ),
                  ),
                  SizedBox(width: responsivePadding / 2),
                  Expanded(
                    child: Text(
                      request.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _getResponsiveFontSize(context, 16),
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: responsivePadding),
              
              // Request details
              _buildDetailRow(Icons.person, 'Oleh: ${request.requester}', context),
              SizedBox(height: responsivePadding / 4),
              _buildDetailRow(Icons.meeting_room, request.room, context),
              SizedBox(height: responsivePadding / 4),
              _buildDetailRow(Icons.access_time, MeetingRepo.formatDate(request.proposedTime), context),
              
              // Description if available
              if (request.description.isNotEmpty) ...[
                SizedBox(height: responsivePadding / 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description,
                      size: _isDesktop(context) ? 18 : 16,
                      color: Colors.grey,
                    ),
                    SizedBox(width: _getResponsivePadding(context) / 4),
                    Expanded(
                      child: Text(
                        request.description,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: _getResponsiveFontSize(context, 14),
                        ),
                        maxLines: isDesktop ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              SizedBox(height: responsivePadding),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    Icons.check,
                    Colors.green,
                    'Setujui Pengajuan',
                    () async {
                      bool confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Setujui Pengajuan Rapat',
                            style: TextStyle(fontSize: _getResponsiveFontSize(context, 18)),
                          ),
                          content: Text(
                            'Apakah Anda yakin ingin menyetujui pengajuan rapat "${request.title}"?',
                            style: TextStyle(fontSize: _getResponsiveFontSize(context, 14)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Setujui'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        MeetingRequestRepo.approve(request);
                        setState(() {});
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Pengajuan "${request.title}" telah disetujui dan dipindahkan ke daftar rapat'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    context,
                  ),
                  SizedBox(width: responsivePadding / 2),
                  _buildActionButton(
                    Icons.close,
                    Colors.red,
                    'Tolak Pengajuan',
                    () => _showRejectionDialog(request),
                    context,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRejectionDialog(MeetingRequest request) async {
    final reasonController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    final responsivePadding = _getResponsivePadding(context);
    
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Tolak Pengajuan Rapat',
          style: TextStyle(fontSize: _getResponsiveFontSize(context, 18)),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tolak pengajuan rapat "${request.title}"?',
                style: TextStyle(fontSize: _getResponsiveFontSize(context, 14)),
              ),
              SizedBox(height: responsivePadding),
              Text(
                'Alasan Penolakan:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _getResponsiveFontSize(context, 14),
                ),
              ),
              SizedBox(height: responsivePadding / 2),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan alasan penolakan...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Harap masukkan alasan penolakan';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final rejectionReason = reasonController.text.trim();
      
      MeetingRequestRepo.reject(request, reason: rejectionReason);
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengajuan "${request.title}" telah ditolak'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}