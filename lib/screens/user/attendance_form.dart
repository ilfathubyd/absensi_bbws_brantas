// import 'dart:typed_data';
// import 'package:absen_app/Models/models/user.dart';
// import 'package:flutter/material.dart';
// import 'package:signature/signature.dart';

// class AttendanceForm extends StatefulWidget {
//   final String meetingId;
//   final AppUser user;

//   const AttendanceForm({
//     super.key,
//     required this.meetingId,
//     required this.user,
//   });

//   @override
//   State<AttendanceForm> createState() => _AttendanceFormState();
// }

// class _AttendanceFormState extends State<AttendanceForm> {
//   final SignatureController _sigController = SignatureController(
//     penStrokeWidth: 3,
//     penColor: Colors.black,
//     exportBackgroundColor: Colors.white,
//   );

//   Uint8List? _signatureBytes;

//   @override
//   void dispose() {
//     _sigController.dispose();
//     super.dispose();
//   }

//   Future<void> _saveAttendance() async {
//     if (_sigController.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Tanda tangan belum diisi")),
//       );
//       return;
//     }

//     final bytes = await _sigController.toPngBytes();
//     if (bytes == null) return;

//     setState(() {
//       _signatureBytes = bytes;
//     });

//     // TODO: Simpan ke backend atau generate PDF surat absensi
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Absensi berhasil disimpan")),
//     );
//   }

//   void _clearSignature() {
//     _sigController.clear();
//     setState(() {
//       _signatureBytes = null;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Form Absensi")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Text(
//               "Absensi Rapat ID: ${widget.meetingId}",
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),

//             // Foto + identitas user
//             CircleAvatar(
//               radius: 40,
//               //backgroundImage: NetworkImage(widget.user.photoUrl),
//             ),
//             const SizedBox(height: 8),
//             Text(widget.user.name, style: const TextStyle(fontSize: 20)),
//             Text(widget.user.email, style: const TextStyle(color: Colors.grey)),
//             const SizedBox(height: 20),

//             // Area tanda tangan
//             const Text("Tanda Tangan Digital:"),
//             const SizedBox(height: 8),
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.black),
//               ),
//               height: 150,
//               child: Signature(
//                 controller: _sigController,
//                 backgroundColor: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 12),

//             // Tombol aksi
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: _saveAttendance,
//                   icon: const Icon(Icons.save),
//                   label: const Text("Simpan"),
//                 ),
//                 const SizedBox(width: 12),
//                 OutlinedButton.icon(
//                   onPressed: _clearSignature,
//                   icon: const Icon(Icons.clear),
//                   label: const Text("Hapus"),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 20),

//             // Preview tanda tangan
//             if (_signatureBytes != null) ...[
//               const Text("Preview Tanda Tangan:"),
//               const SizedBox(height: 8),
//               Image.memory(_signatureBytes!, height: 100),
//             ]
//           ],
//         ),
//       ),
//     );
//   }
// }
