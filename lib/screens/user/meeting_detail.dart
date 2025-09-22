// import 'package:flutter/material.dart';
// import 'package:absen_app/Models/models/meeting.dart';
// import 'scan_qr.dart';
//
// class UserMeetingDetail extends StatefulWidget {
//   final Meeting meeting;
//   const UserMeetingDetail({super.key, required this.meeting});
//
//   @override
//   State<UserMeetingDetail> createState() => _UserMeetingDetailState();
// }
//
// class _UserMeetingDetailState extends State<UserMeetingDetail> {
//   String? attendanceResult;
//
//   Future<void> _scanQR() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const ScanQR(user: null,)),
//     );
//
//     if (result != null) {
//       setState(() {
//         attendanceResult = result.toString();
//       });
//
//       // TODO: kirim hasil absensi ke backend
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Absensi berhasil untuk rapat ${widget.meeting.title}")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.meeting.title)),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Judul: ${widget.meeting.title}",
//                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             Text("Waktu: ${widget.meeting.dateTime}"),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: _scanQR,
//               icon: const Icon(Icons.qr_code_scanner),
//               label: const Text("Scan QR untuk Absen"),
//             ),
//             const SizedBox(height: 16),
//             if (attendanceResult != null)
//               Card(
//                 color: Colors.green.shade100,
//                 child: Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Text(
//                     "✅ Absen berhasil!\nKode: $attendanceResult",
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
