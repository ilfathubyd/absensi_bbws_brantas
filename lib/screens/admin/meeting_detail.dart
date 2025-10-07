// import 'dart:io';
// import 'package:csv/csv.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:absen_app/Models/models/meeting.dart';
//
// import '../../Models/services/meeting_repo.dart';
//
// class MeetingDetailScreen extends StatelessWidget {
//   final Meeting meeting;
//
//   const MeetingDetailScreen({super.key, required this.meeting});
//
//   Future<void> _exportSingleMeeting(BuildContext context) async {
//     // Data rapat ini aja
//     List<List<dynamic>> rows = [
//       ["ID", "Judul", "Tanggal", "Ruangan"],
//       [meeting.id, meeting.title, MeetingRepo.formatDate(meeting.dateTime), meeting.room],
//     ];
//
//     String csvData = const ListToCsvConverter().convert(rows);
//
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File("${dir.path}/rapat_${meeting.id}.csv");
//     await file.writeAsString(csvData);
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Rapat berhasil diexport ke ${file.path}")),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Detail Rapat", style: TextStyle(color: Colors.white)),
//         backgroundColor: const Color(0xFF1565C0),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download, color: Colors.white),
//             tooltip: "Export Rapat",
//             onPressed: () => _exportSingleMeeting(context),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(meeting.title,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1565C0),
//                     )),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     const Icon(Icons.tag, color: Colors.grey),
//                     const SizedBox(width: 8),
//                     Text("ID: ${meeting.id}"),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     const Icon(Icons.access_time, color: Colors.grey),
//                     const SizedBox(width: 8),
//                     Text(MeetingRepo.formatDate(meeting.dateTime)),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     const Icon(Icons.meeting_room, color: Colors.grey),
//                     const SizedBox(width: 8),
//                     Text("Ruangan: ${meeting.room}"),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
