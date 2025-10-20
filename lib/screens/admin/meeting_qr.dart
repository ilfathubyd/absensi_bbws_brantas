import 'dart:async';
import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MeetingQR extends StatefulWidget {
  final Rapat initialRapat;

  const MeetingQR({super.key, required this.initialRapat});

  @override
  State<MeetingQR> createState() => _MeetingQRState();
}

class _MeetingQRState extends State<MeetingQR> {
  late Timer _timer;
  late Timer _countdownTimer;
  int _countdownSeconds = 30;
  late Rapat _currentRapat;
  bool _isLoading = false;
  String? _errorMessage;
  final RapatApiService _rapatApiService = RapatApiService();

  @override
  void initState() {
    super.initState();
    _currentRapat = widget.initialRapat;
    _startTimers();
  }

  void _startTimers() {
    // Set timer untuk refresh data setiap 30 detik sesuai dengan backend
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchLatestRapatData();
      if (mounted) setState(() => _countdownSeconds = 30);
    });

    // Timer untuk UI hitung mundur setiap detik
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _countdownSeconds--);
    });
  }

  Future<void> _fetchLatestRapatData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mengambil semua data rapat lagi dan mencari rapat yang sesuai
      final allRapat = await _rapatApiService.fetchAllRapat();
      final updatedRapat = allRapat.firstWhere(
        (r) => r.idRapat == widget.initialRapat.idRapat,
        orElse: () =>
            _currentRapat, // fallback ke data lama jika tidak ditemukan
      );

      if (mounted) {
        setState(() {
          _currentRapat = updatedRapat;
          _countdownSeconds = 30; // Reset countdown setelah fetch berhasil
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memperbarui QR: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel(); // Pastikan timer dihentikan saat widget dihancurkan
    _countdownTimer.cancel(); // Hentikan juga timer hitung mundur
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _currentRapat.currentQrToken;

    return Scaffold(
      // PERUBAHAN: Menyamakan background dengan dashboard
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title:
            const Text('QR Code Rapat', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // PENAMBAHAN: Kartu modern untuk membungkus konten
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _currentRapat.judul,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24, // PERUBAHAN: Ukuran font diperbesar
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.meeting_room_outlined,
                            color: Colors.grey[600], size: 18),
                        const SizedBox(width: 8),
                        Text(_currentRapat.namaRuangan,
                            style: TextStyle(
                                fontSize:
                                    18, // PERUBAHAN: Ukuran font diperbesar
                                color: Colors.grey[700])),
                      ],
                    ),
                    const SizedBox(height: 30), // PERUBAHAN: Spasi diperbesar
                    if (qrData != null && qrData.isNotEmpty)
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 300.0, // PERUBAHAN: Ukuran QR diperbesar
                        gapless: false,
                        // PERBAIKAN: Menggunakan path logo yang benar dari proyek Anda
                        embeddedImage:
                            const AssetImage('assets/images/logo_qr.png'),
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                            size: Size(
                                50, 50)), // PERUBAHAN: Ukuran logo diperbesar
                      )
                    else
                      const SizedBox(
                        height: 300, // PERUBAHAN: Ukuran placeholder disamakan
                        child: Center(child: Text('Token QR tidak tersedia.')),
                      ),
                    const SizedBox(height: 30), // PERUBAHAN: Spasi diperbesar
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Chip(
                        avatar: const Icon(Icons.timer_outlined, size: 18),
                        label: Text(
                          'Diperbarui dalam: $_countdownSeconds detik',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
