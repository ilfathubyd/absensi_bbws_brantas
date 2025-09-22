import 'dart:math';
import 'package:absen_app/Models/models/meeting.dart';
import 'package:absen_app/Models/models/meeting_request.dart';
import 'package:intl/intl.dart';

class MeetingRepo {
  static final List<Meeting> _meetings = [];
  
  // Enum untuk status meeting
  static const String statusApproved = 'approved';
  static const String statusPending = 'pending';
  static const String statusRejected = 'rejected';
  
  // Method all() tanpa parameter wajib
  static List<Meeting> all() => List.unmodifiable(
    _meetings.where((m) => m.status == statusApproved).toList()
  );
  
  // Method dengan filter title
  static List<Meeting> allByTitle({String? title}) => List.unmodifiable(
    _meetings.where((m) => m.status == statusApproved && 
      (title == null || m.title.contains(title))).toList()
  );
  
  static List<Meeting> allIncludingPending() => List.unmodifiable(_meetings);

  // Method untuk membuat meeting baru
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
    print('Meeting created: $title (ID: $id)');
    return meeting;
  }

  // Method untuk convert MeetingRequest ke Meeting (PENTING: Ini yang hilang)
  static Meeting addFromRequest(MeetingRequest request) {
    final String id = _generateId();
    final Meeting meeting = Meeting(
      id: id,
      title: request.title,
      description: request.description,
      startTime: request.proposedTime,
      endTime: request.proposedTime.add(const Duration(hours: 1)),
      room: request.room,
      responsible: request.requester,
      pic: request.requester,
      status: statusApproved,
      isApproved: true,
    );
    _meetings.add(meeting);
    print('Meeting created from request: ${request.title} (ID: $id)');
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
      print('Meeting updated: ${updatedMeeting.title}');
    }
  }

  // Hapus meeting
  static void delete(String id) {
    final meeting = findById(id);
    if (meeting != null) {
      _meetings.removeWhere((m) => m.id == id);
      print('Meeting deleted: ${meeting.title}');
    }
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
  
  // Method untuk mendapatkan meeting berdasarkan status
  static List<Meeting> getByStatus(String status) {
    return List.unmodifiable(
      _meetings.where((m) => m.status == status).toList()
    );
  }

  // Method untuk mendapatkan meeting berdasarkan PIC/penanggung jawab
  // Di MeetingRepo
static List<Meeting> getByResponsible(String responsible) {
  return List.unmodifiable(
    _meetings.where((m) => 
      m.status == statusApproved && 
      m.responsible.toLowerCase() == responsible.toLowerCase() // Case insensitive
    ).toList()
  );
}

  // Method untuk mendapatkan meeting yang akan datang
  static List<Meeting> getUpcoming() {
    final now = DateTime.now();
    return List.unmodifiable(
      _meetings.where((m) => 
        m.status == statusApproved && m.startTime.isAfter(now)
      ).toList()
    );
  }

  // Method untuk mendapatkan meeting yang sudah selesai
  static List<Meeting> getHistory() {
    final now = DateTime.now();
    return List.unmodifiable(
      _meetings.where((m) => 
        m.status == statusApproved && m.startTime.isBefore(now)
      ).toList()
    );
  }

  // Method untuk mendapatkan meeting yang sedang berlangsung
  static List<Meeting> getOngoing() {
    final now = DateTime.now();
    return List.unmodifiable(
      _meetings.where((m) => 
        m.status == statusApproved &&
        m.startTime.isBefore(now) &&
        (m.endTime == null || m.endTime!.isAfter(now))
      ).toList()
    );
  }

  // Method untuk menambahkan data dummy (untuk testing)
  static void addDummyData() {
    final now = DateTime.now();
    
    final dummyMeetings = [
      Meeting(
        id: 'meet-1',
        title: 'Rapat Tim Development',
        description: 'Membahas progress pengembangan aplikasi',
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, hours: 2)),
        room: 'Ruang Rapat A',
        responsible: 'Ahmad Fadli',
        pic: 'ahmad_fadli.jpg',
        status: statusApproved,
        isApproved: true,
      ),
      Meeting(
        id: 'meet-2',
        title: 'Presentasi Project Baru',
        description: 'Presentasi project baru kepada management',
        startTime: now.add(const Duration(days: 3, hours: 1)),
        endTime: now.add(const Duration(days: 3, hours: 3)),
        room: 'Ruang Konferensi',
        responsible: 'Siti Nurhaliza',
        pic: 'siti_nurhaliza.jpg',
        status: statusApproved,
        isApproved: true,
      ),
      Meeting(
        id: 'meet-3',
        title: 'Review Kinerja Bulanan',
        description: 'Review kinerja tim bulan ini',
        startTime: now.subtract(const Duration(days: 2)),
        endTime: now.subtract(const Duration(days: 2, hours: 2)),
        room: 'Meeting Room 1',
        responsible: 'Budi Santoso',
        pic: 'budi_santoso.jpg',
        status: statusApproved,
        isApproved: true,
      ),
    ];
    
    for (var meeting in dummyMeetings) {
      // Cek dulu apakah meeting dengan ID yang sama sudah ada
      if (!_meetings.any((m) => m.id == meeting.id)) {
        _meetings.add(meeting);
      }
    }
    
    print('Dummy meetings added (Total: ${_meetings.length})');
  }

  // Method untuk reset data (hati-hati, hanya untuk testing)
  static void clearAll() {
    _meetings.clear();
    print('All meetings cleared');
  }

  // Method untuk debug print semua meetings
  static void debugPrintMeetings() {
    print('=== DEBUG: Meetings (${_meetings.length}) ===');
    for (var meeting in _meetings) {
      print('ID: ${meeting.id}');
      print('Title: ${meeting.title}');
      print('Room: ${meeting.room}');
      print('Responsible: ${meeting.responsible}');
      print('Start: ${formatDate(meeting.startTime)}');
      print('End: ${meeting.endTime != null ? formatDate(meeting.endTime!) : "Tidak menentu"}');
      print('Status: ${meeting.status}');
      print('---');
    }
    print('===============================');
  }
}