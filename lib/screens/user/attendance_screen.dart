// import 'dart:io';
// import 'package:absen_app/Models/models/meeting.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class AttendanceScreen extends StatefulWidget {
//   final Meeting meeting;
//
//   const AttendanceScreen({super.key, required this.meeting});
//
//   @override
//   State<AttendanceScreen> createState() => _AttendanceScreenState();
// }
//
// class _AttendanceScreenState extends State<AttendanceScreen> {
//   CameraController? _controller;
//   File? _image;
//   Position? _currentPosition;
//   bool _isLoading = false;
//   bool _cameraInitialized = false;
//   String _errorMessage = '';
//   String _locationMessage = 'Mendapatkan lokasi...';
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }
//
//   Future<void> _initializeApp() async {
//     await _requestPermissions();
//     await _initializeCamera();
//     await _getCurrentLocation();
//   }
//
//   Future<void> _requestPermissions() async {
//     // Request camera permission
//     final cameraStatus = await Permission.camera.request();
//     if (cameraStatus.isDenied) {
//       setState(() {
//         _errorMessage = 'Izin kamera diperlukan untuk mengambil foto';
//       });
//     }
//
//     // Request location permission
//     final locationStatus = await Permission.location.request();
//     if (locationStatus.isDenied) {
//       setState(() {
//         _errorMessage = 'Izin lokasi diperlukan untuk absensi';
//       });
//     }
//   }
//
//   Future<void> _initializeCamera() async {
//     try {
//       final cameras = await availableCameras();
//       if (cameras.isEmpty) {
//         setState(() {
//           _errorMessage = 'Tidak ada kamera yang tersedia';
//         });
//         return;
//       }
//
//       final firstCamera = cameras.first;
//
//       _controller = CameraController(
//         firstCamera,
//         ResolutionPreset.medium,
//       );
//
//       await _controller!.initialize();
//
//       setState(() {
//         _cameraInitialized = true;
//       });
//     } on CameraException catch (e) {
//       setState(() {
//         _errorMessage = 'Error menginisialisasi kamera: ${e.description}';
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error: $e';
//       });
//     }
//   }
//
//   Future<void> _getCurrentLocation() async {
//     try {
//       setState(() {
//         _locationMessage = 'Mendapatkan lokasi...';
//       });
//
//       // Cek layanan lokasi
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() {
//           _locationMessage = 'Layanan lokasi tidak aktif';
//           _errorMessage = 'Silakan aktifkan GPS/lokasi untuk absensi';
//         });
//         return;
//       }
//
//       // Cek permission lokasi
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           setState(() {
//             _locationMessage = 'Izin lokasi ditolak';
//             _errorMessage = 'Izin lokasi diperlukan untuk absensi';
//           });
//           return;
//         }
//       }
//
//       if (permission == LocationPermission.deniedForever) {
//         setState(() {
//           _locationMessage = 'Izin lokasi ditolak permanen';
//           _errorMessage = 'Buka pengaturan untuk mengaktifkan izin lokasi';
//         });
//         return;
//       }
//
//       // Dapatkan posisi terkini
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.best,
//       );
//
//       setState(() {
//         _currentPosition = position;
//         _locationMessage = 'Lokasi berhasil didapatkan';
//       });
//     } catch (e) {
//       setState(() {
//         _locationMessage = 'Gagal mendapatkan lokasi';
//         _errorMessage = 'Error: $e';
//       });
//     }
//   }
//
//   Future<void> _takePicture() async {
//     try {
//       if (_controller == null || !_controller!.value.isInitialized) {
//         setState(() {
//           _errorMessage = 'Kamera belum siap';
//         });
//         return;
//       }
//
//       // Ambil gambar
//       XFile picture = await _controller!.takePicture();
//
//       setState(() {
//         _image = File(picture.path);
//         _errorMessage = '';
//       });
//     } on CameraException catch (e) {
//       setState(() {
//         _errorMessage = 'Error kamera: ${e.description}';
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error: $e';
//       });
//     }
//   }
//
//   Future<void> _submitAttendance() async {
//     if (_image == null) {
//       setState(() {
//         _errorMessage = 'Silakan ambil foto terlebih dahulu';
//       });
//       return;
//     }
//
//     if (_currentPosition == null) {
//       setState(() {
//         _errorMessage = 'Tidak dapat mendapatkan lokasi';
//       });
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });
//
//     try {
//       // Simulasi proses upload
//       await Future.delayed(const Duration(seconds: 2));
//
//       // Di sini Anda akan mengimplementasikan:
//       // 1. Upload gambar ke server
//       // 2. Kirim data lokasi
//       // 3. Kirim data meeting ID dan user ID
//
//       // Kembali ke previous screen dengan status sukses
//       if (mounted) {
//         Navigator.of(context).pop(true);
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Gagal mengirim absensi: $e';
//         _isLoading = false;
//       });
//     }
//   }
//
//   Widget _buildCameraPreview() {
//     if (!_cameraInitialized) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Menyiapkan kamera...'),
//           ],
//         ),
//       );
//     }
//
//     if (_controller == null || !_controller!.value.isInitialized) {
//       return const Center(child: Text('Kamera tidak tersedia'));
//     }
//
//     return _image != null
//         ? Image.file(_image!, fit: BoxFit.cover)
//         : CameraPreview(_controller!);
//   }
//
//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Absensi Rapat'),
//         backgroundColor: const Color(0xFF1E3A8A),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Informasi Meeting
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.meeting.title,
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text('Ruangan: ${widget.meeting.room}'),
//                           Text('Tanggal: ${_formatDate(widget.meeting.startTime)}'),
//                           Text('Waktu: ${_formatTime(widget.meeting.startTime)}'),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Camera Preview
//                   const Text(
//                     'Ambil Foto Selfie:',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 10),
//
//                   Container(
//                     height: 300,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: _buildCameraPreview(),
//                   ),
//
//                   const SizedBox(height: 10),
//
//                   Center(
//                     child: ElevatedButton.icon(
//                       onPressed: _takePicture,
//                       icon: const Icon(Icons.camera_alt),
//                       label: const Text('Ambil Foto'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF1E3A8A),
//                         foregroundColor: Colors.white,
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Location Information
//                   const Text(
//                     'Lokasi Saat Ini:',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 10),
//
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           if (_currentPosition != null) ...[
//                             Text('Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
//                             Text('Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
//                             Text('Akurasi: ${_currentPosition!.accuracy?.toStringAsFixed(2) ?? 'N/A'} meter'),
//                           ],
//                           Text(
//                             _locationMessage,
//                             style: TextStyle(
//                               color: _currentPosition != null ? Colors.green : Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 10),
//
//                   Center(
//                     child: ElevatedButton.icon(
//                       onPressed: _getCurrentLocation,
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Refresh Lokasi'),
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Error Message
//                   if (_errorMessage.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 10),
//                       child: Text(
//                         _errorMessage,
//                         style: const TextStyle(color: Colors.red),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//
//                   // Submit Button
//                   Center(
//                     child: ElevatedButton(
//                       onPressed: _submitAttendance,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF1E3A8A),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 40, vertical: 15),
//                       ),
//                       child: const Text('Submit Absensi'),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
//
//   String _formatDate(DateTime date) {
//     return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
//   }
//
//   String _formatTime(DateTime date) {
//     return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
//   }
// }