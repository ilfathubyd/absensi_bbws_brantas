import 'package:absen_app/Models/models/meeting_request.dart';
import 'package:absen_app/Models/services/meeting_repo.dart';

class MeetingRequestRepo {
  static final List<MeetingRequest> _requests = [];
  
  static List<MeetingRequest> get all => List.unmodifiable(_requests);
  
  static List<MeetingRequest> pending() {
    return _requests.where((r) => r.status == 'pending').toList();
  }
  
  static List<MeetingRequest> approved() {
    return _requests.where((r) => r.status == 'approved').toList();
  }
  
  static List<MeetingRequest> rejected() {
    return _requests.where((r) => r.status == 'rejected').toList();
  }
  
  static void add(MeetingRequest request) {
    _requests.add(request);
    print('Meeting request added: ${request.title} (Total: ${_requests.length})');
  }
  
  static void approve(MeetingRequest request) {
    final index = _requests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      // Update status menjadi approved
      _requests[index] = MeetingRequest(
        id: request.id,
        title: request.title,
        description: request.description,
        room: request.room,
        proposedTime: request.proposedTime,
        requester: request.requester,
        requesterId: request.requesterId,
        requestTime: request.requestTime,
        status: 'approved',
      );
      
      // Otomatis buat meeting dari request yang disetujui
      MeetingRepo.addFromRequest(request);
      
      print('Meeting request approved: ${request.title}');
      print('Meeting created from request');
    }
  }
  
  // Perbaikan parameter: hapus rejectionReason yang redundant
  static void reject(MeetingRequest request, {required String reason}) {
    final index = _requests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      _requests[index] = MeetingRequest(
        id: request.id,
        title: request.title,
        description: request.description,
        room: request.room,
        proposedTime: request.proposedTime,
        requester: request.requester,
        requesterId: request.requesterId,
        requestTime: request.requestTime,
        status: 'rejected',
        rejectionReason: reason, // Gunakan parameter reason
      );
      print('Meeting request rejected: ${request.title}');
      print('Alasan: $reason');
    }
  }
  
  // Method untuk menghapus request (opsional)
  static void remove(String id) {
    _requests.removeWhere((r) => r.id == id);
    print('Meeting request removed: $id');
  }
  
  // Method untuk mencari request by ID
  static MeetingRequest? findById(String id) {
    try {
      return _requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
  
  // Method untuk mendapatkan jumlah request berdasarkan status
  static int countByStatus(String status) {
    return _requests.where((r) => r.status == status).length;
  }
  
  static void debugPrintRequests() {
    print('=== DEBUG: Meeting Requests (${_requests.length}) ===');
    for (var request in _requests) {
      print('ID: ${request.id}');
      print('Title: ${request.title}');
      print('Requester: ${request.requester}');
      print('Room: ${request.room}');
      print('Proposed Time: ${request.proposedTime}');
      print('Status: ${request.status}');
      
      if (request.status == 'rejected' && request.rejectionReason != null) {
        print('Alasan Penolakan: ${request.rejectionReason}');
      }
      
      if (request.status == 'approved') {
        print('✓ Disetujui dan sudah dibuat meeting-nya');
      }
      
      print('---');
    }
    print('===============================');
  }
  
  // Method untuk menambahkan data dummy (untuk testing)
  static void addDummyData() {
    final now = DateTime.now();
    
    final dummyRequests = [
      MeetingRequest(
        id: 'req-1',
        title: 'Rapat Tim Development',
        description: 'Membahas progress pengembangan aplikasi',
        room: 'Ruang Rapat A',
        proposedTime: now.add(const Duration(days: 1)),
        requester: 'Ahmad Fadli',
        requesterId: 'user-001',
        requestTime: now.subtract(const Duration(hours: 2)),
        status: 'pending',
      ),
      MeetingRequest(
        id: 'req-2',
        title: 'Presentasi Project Baru',
        description: 'Presentasi project baru kepada management',
        room: 'Ruang Konferensi',
        proposedTime: now.add(const Duration(days: 3)),
        requester: 'Siti Nurhaliza',
        requesterId: 'user-002',
        requestTime: now.subtract(const Duration(days: 1)),
        status: 'pending',
      ),
      MeetingRequest(
        id: 'req-3',
        title: 'Review Kinerja Bulanan',
        description: 'Review kinerja tim bulan ini',
        room: 'Meeting Room 1',
        proposedTime: now.add(const Duration(days: 5)),
        requester: 'Budi Santoso',
        requesterId: 'user-003',
        requestTime: now.subtract(const Duration(hours: 5)),
        status: 'pending',
      ),
    ];
    
    for (var request in dummyRequests) {
      // Cek dulu apakah request dengan ID yang sama sudah ada
      if (!_requests.any((r) => r.id == request.id)) {
        _requests.add(request);
      }
    }
    
    print('Dummy data added (Total: ${_requests.length})');
  }
  
  // Method untuk reset data (hati-hati, hanya untuk testing)
  static void clearAll() {
    _requests.clear();
    print('All meeting requests cleared');
  }
}