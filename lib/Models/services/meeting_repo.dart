import 'dart:math';
import 'package:absen_app/Models/models/meeting.dart';
import 'package:absen_app/Models/models/meeting_request.dart';
import 'package:intl/intl.dart';

class MeetingRepo {
  static final List<Meeting> _meetings = [];
  
  // Enum untuk status meeting (opsional tapi recommended)
  static const String statusApproved = 'approved';
  static const String statusPending = 'pending';
  static const String statusRejected = 'rejected';
  
  // Method all() tanpa parameter wajib
  static List<Meeting> all() => List.unmodifiable(
    _meetings.where((m) => m.status == statusApproved).toList()
  );
  
  // Method dengan filter title (jika masih diperlukan)
  static List<Meeting> allByTitle({String? title}) => List.unmodifiable(
    _meetings.where((m) => m.status == statusApproved && 
      (title == null || m.title.contains(title))).toList()
  );
  
  static List<Meeting> allIncludingPending() => List.unmodifiable(_meetings);

  // Tambahkan fungsi untuk convert MeetingRequest ke Meeting
  static Meeting add({
  required String title,
  required DateTime startTime,
  DateTime? endTime,
  required String room,
  required String responsible,
  String pic = 'default_pic.jpg',
  String description = '',
}) {
  final String id = _generateId();
  final Meeting meeting = Meeting(
    id: id,
    title: title,
    description: description,
    startTime: startTime,
    endTime: endTime ?? startTime.add(const Duration(hours: 1)),
    room: room,
    responsible: responsible,
    pic: pic,
    status: statusApproved,
    isApproved: true,
  );
  _meetings.add(meeting);
  return meeting;
}

  // Cari meeting berdasarkan ID
  static Meeting? findById(String id) {
    try {
      return _meetings.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // Format tanggal
  static String formatDate(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  // Generate ID sederhana
  static String _generateId() {
    final rand = Random().nextInt(900) + 100;
    return '${DateTime.now().millisecondsSinceEpoch}-$rand';
  }

  // Ambil semua meeting yang approved
  static List<Meeting> getAll() => all();

  // Update meeting
  static void update(Meeting updatedMeeting) {
    final index = _meetings.indexWhere((m) => m.id == updatedMeeting.id);
    if (index != -1) {
      _meetings[index] = updatedMeeting;
    }
  }

  // Hapus meeting
  static void delete(String id) {
    _meetings.removeWhere((m) => m.id == id);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
  
  // Tambahan: Method untuk mendapatkan meeting berdasarkan status
  static List<Meeting> getByStatus(String status) {
    return List.unmodifiable(
      _meetings.where((m) => m.status == status).toList()
    );
  }
}