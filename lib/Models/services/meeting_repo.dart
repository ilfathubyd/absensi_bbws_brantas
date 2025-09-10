import 'dart:math';
import 'package:absen_app/models/meeting.dart';
import 'package:intl/intl.dart';

class MeetingRepo {
  static final List<Meeting> _meetings = [];

  // Ambil semua meeting
  static List<Meeting> all() => List.unmodifiable(_meetings);

  // Tambah meeting baru
  static Meeting add({
    required String title,
    required DateTime dateTime,
    required String room, // wajib isi
  }) {
    final id = _generateId();
    final meeting = Meeting(
      id: id,
      title: title,
      dateTime: dateTime,
      room: room, // pastikan dimasukkan
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

  // Generate ID sederhana: timestamp + 3 digit random
  static String _generateId() {
    final rand = Random().nextInt(900) + 100; // 100..999
    return '${DateTime.now().millisecondsSinceEpoch}-$rand';
  }

  // Ambil semua meeting
  static List<Meeting> getAll() => List.unmodifiable(_meetings);
}
