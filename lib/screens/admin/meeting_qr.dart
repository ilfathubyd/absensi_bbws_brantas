import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/meeting.dart';

class MeetingQR extends StatefulWidget {
  final Meeting meeting;

  const MeetingQR({super.key, required this.meeting});

  @override
  State<MeetingQR> createState() => _MeetingQRState();
}

class _MeetingQRState extends State<MeetingQR> {
  late Timer _timer;
  late String _qrData;

  @override
  void initState() {
    super.initState();
    _generateQR();
    // Refresh setiap 3 detik
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _generateQR();
    });
  }

  void _generateQR() {
    final now = DateTime.now();
    final uniqueCode = '${widget.meeting.id}-${now.millisecondsSinceEpoch}';

    setState(() {
      _qrData = uniqueCode;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Rapat')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.meeting.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Waktu: ${widget.meeting.dateTime}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Center(
              child: QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 250,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
