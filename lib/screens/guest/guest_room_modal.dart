import 'package:flutter/material.dart';
import 'package:absen_app/screens/guest/guest_info_form.dart' show GuestInfoForm;

class GuestRoomModal extends StatefulWidget {
  const GuestRoomModal({super.key});

  @override
  State<GuestRoomModal> createState() => _GuestRoomModalState();
}

class _GuestRoomModalState extends State<GuestRoomModal> {
  final _roomCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  void _submitRoomCode() {
    final roomCode = _roomCodeController.text.trim();

    if (roomCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masukkan kode ruangan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulasi validasi kode ruangan
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });

      // Jika kode valid, lanjut ke form data diri
      if (roomCode.isNotEmpty) {
        Navigator.of(context).pop(); // Tutup modal kode ruangan
        _showGuestInfoForm(roomCode);
      }
    });
  }

  void _showGuestInfoForm(String roomCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GuestInfoForm(roomCode: roomCode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.meeting_room,
                  color: Colors.blue[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Masukkan Kode Ruangan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan masukkan kode ruangan yang diberikan oleh PIC',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Input Kode Ruangan
            TextField(
              controller: _roomCodeController,
              decoration: InputDecoration(
                labelText: 'Kode Ruangan',
                prefixIcon: const Icon(Icons.qr_code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                hintText: 'Contoh: RMN-1234',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitRoomCode(),
            ),
            const SizedBox(height: 8),
            Text(
              'Kode ruangan biasanya terdiri dari angka dan huruf',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),

            // Tombol
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('BATAL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRoomCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('LANJUTKAN'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}