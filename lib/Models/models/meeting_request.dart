class MeetingRequest {
  final String id;
  final String title;
  final String description;
  final String room;
  final DateTime proposedTime;
  final String requester;
  final String requesterId;
  final DateTime requestTime;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason; // Tambahkan field untuk alasan penolakan

  MeetingRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.room,
    required this.proposedTime,
    required this.requester,
    required this.requesterId,
    required this.requestTime,
    this.status = 'pending',
    this.rejectionReason, // Tambahkan parameter opsional
  });
}