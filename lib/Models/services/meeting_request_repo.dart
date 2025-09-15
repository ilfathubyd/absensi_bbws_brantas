import 'package:absen_app/Models/models/meeting_request.dart';

class MeetingRequestRepo {
  static final List<MeetingRequest> _requests = [];
  
  static List<MeetingRequest> get all => List.unmodifiable(_requests);
  
  static List<MeetingRequest> pending() {
    return _requests.where((r) => r.status == 'pending').toList();
  }
  
  static void add(MeetingRequest request) {
    _requests.add(request);
    print('Meeting request added: ${request.title} (Total: ${_requests.length})');
  }
  
  static void approve(MeetingRequest request) {
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
        status: 'approved',
      );
      print('Meeting request approved: ${request.title}');
    }
  }
  
  // Tambahkan parameter rejectionReason
  static void reject(MeetingRequest request, {String rejectionReason = '', required String reason}) {
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
        rejectionReason: rejectionReason, // Tambahkan alasan penolakan
      );
      print('Meeting request rejected: ${request.title}');
      print('Alasan: $rejectionReason');
    }
  }
  
  static void debugPrintRequests() {
    print('=== DEBUG: Meeting Requests (${_requests.length}) ===');
    for (var request in _requests) {
      print('ID: ${request.id}, Title: ${request.title}, Status: ${request.status}');
      if (request.status == 'rejected' && request.rejectionReason != null) {
        print('Alasan Penolakan: ${request.rejectionReason}');
      }
    }
    print('===============================');
  }
}