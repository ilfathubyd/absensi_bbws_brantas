// import 'package:flutter/material.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
// import 'attendance_form.dart'; // halaman tanda tangan digital
//
//
// class ScanQR extends StatefulWidget {
//   final user; // kirim data user login
//
//   const ScanQR({super.key, required this.user});
//
//   @override
//   State<ScanQR> createState() => _ScanQRState();
// }
//
// class _ScanQRState extends State<ScanQR> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;
//   bool scanned = false; // supaya tidak dobel navigasi
//
//   @override
//   void reassemble() {
//     super.reassemble();
//     if (controller != null) {
//       if (Theme.of(context).platform == TargetPlatform.android) {
//         controller!.pauseCamera();
//       }
//       controller!.resumeCamera();
//     }
//   }
//
//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }
//
//   void _onQRViewCreated(QRViewController ctrl) {
//     controller = ctrl;
//     ctrl.scannedDataStream.listen((scanData) {
//       if (!scanned) {
//         setState(() {
//           scanned = true;
//         });
//
//         final meetingId = scanData.code ?? "";
//
//         // Arahkan ke AttendanceForm
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => AttendanceForm(
//               meetingId: meetingId,
//               user: widget.user,
//             ),
//           ),
//         );
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Scan QR Absen")),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 4,
//             child: QRView(
//               key: qrKey,
//               onQRViewCreated: _onQRViewCreated,
//             ),
//           ),
//           const Expanded(
//             flex: 1,
//             child: Center(
//               child: Text("Arahkan kamera ke QR Code"),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
