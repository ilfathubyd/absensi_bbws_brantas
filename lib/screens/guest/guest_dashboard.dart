import 'package:flutter/material.dart';
import 'package:absen_app/screens/login_screen.dart';

class GuestDashboard extends StatelessWidget {
  final Map<String, dynamic> guestData;

  // PERBAIKAN: Tambahkan constructor dengan default value
  const GuestDashboard({super.key, required this.guestData});

  // PERBAIKAN: Constructor alternatif untuk kasus tanpa data
  const GuestDashboard.empty({super.key})
      : guestData = const {
    'name': 'Guest User',
    'position': 'Guest',
    'company': '',
    'roomCode': 'N/A',
    'loginTime': null,
  };

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN: Handle case ketika loginTime null
    final loginTime = guestData['loginTime'] ?? DateTime.now();

    // Responsive breakpoints
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isTablet = size.width >= 600;
    final crossAxisCount = isTablet ? 4 : 2;
    final horizontalPadding = isTablet ? 32.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: Text(
          'Guest Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header dengan gradient
            Container(
              width: double.infinity,
              height: isSmallScreen ? 100 : (isTablet ? 140 : 120),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Text(
                      'Halo, ${guestData['name'] ?? 'Guest User'}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 18 : (isTablet ? 24 : 20),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 8),
                    Text(
                      guestData['position'] ?? 'Guest',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info Card dengan gradient kuning
            Container(
              margin: EdgeInsets.all(horizontalPadding),
              padding: EdgeInsets.all(isSmallScreen ? 16 : (isTablet ? 24 : 20)),
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: isTablet ? 600 : double.infinity,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFFFC107),
                    Color(0xFFFFD54F),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Ruangan
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: isSmallScreen ? 40 : (isTablet ? 56 : 48),
                          height: isSmallScreen ? 40 : (isTablet ? 56 : 48),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.meeting_room,
                            color: Colors.white,
                            size: isSmallScreen ? 20 : (isTablet ? 28 : 24),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            guestData['roomCode'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : (isTablet ? 28 : 24),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          'Ruangan',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Divider vertikal
                  Container(
                    width: 1,
                    height: isSmallScreen ? 60 : (isTablet ? 100 : 80),
                    color: Colors.white.withOpacity(0.3),
                    margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : (isTablet ? 24 : 20)),
                  ),

                  // Waktu Login
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: isSmallScreen ? 40 : (isTablet ? 56 : 48),
                          height: isSmallScreen ? 40 : (isTablet ? 56 : 48),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: isSmallScreen ? 20 : (isTablet ? 28 : 24),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatTime(loginTime),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : (isTablet ? 28 : 24),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          'Waktu Login',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Fitur untuk Guest
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fitur Guest',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : (isTablet ? 22 : 18),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 800 : double.infinity,
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: isSmallScreen ? 8 : (isTablet ? 16 : 12),
                        mainAxisSpacing: isSmallScreen ? 8 : (isTablet ? 16 : 12),
                        childAspectRatio: isTablet ? 1.2 : (isSmallScreen ? 1.0 : 1.1),
                        children: [
                          _buildFeatureCard(
                            context: context,
                            icon: Icons.calendar_today,
                            title: 'Lihat Jadwal',
                            color: const Color(0xFF1E3A8A),
                            isSmallScreen: isSmallScreen,
                            isTablet: isTablet,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur Lihat Jadwal')),
                              );
                            },
                          ),
                          _buildFeatureCard(
                            context: context,
                            icon: Icons.qr_code_scanner,
                            title: 'Scan QR',
                            color: const Color(0xFFFFC107),
                            isSmallScreen: isSmallScreen,
                            isTablet: isTablet,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur Scan QR Code')),
                              );
                            },
                          ),
                          _buildFeatureCard(
                            context: context,
                            icon: Icons.info,
                            title: 'Informasi',
                            color: const Color(0xFF3B82F6),
                            isSmallScreen: isSmallScreen,
                            isTablet: isTablet,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur Informasi')),
                              );
                            },
                          ),
                          _buildFeatureCard(
                            context: context,
                            icon: Icons.help,
                            title: 'Bantuan',
                            color: const Color(0xFFFFB300),
                            isSmallScreen: isSmallScreen,
                            isTablet: isTablet,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur Bantuan')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required bool isSmallScreen,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : (isTablet ? 20 : 16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isSmallScreen ? 44 : (isTablet ? 64 : 56),
                  height: isSmallScreen ? 44 : (isTablet ? 64 : 56),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: isSmallScreen ? 24 : (isTablet ? 36 : 32),
                    color: color,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                      color: const Color(0xFF1E293B),
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Keluar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          content: const Text('Apakah Anda yakin ingin keluar dari akun guest?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                // PERBAIKAN: Kembali ke login screen dengan pushReplacement
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}