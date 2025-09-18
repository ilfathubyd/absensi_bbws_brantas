class MeetingRequest {
  final String id;
  final String title;
  final String description;
  final String room;
  final DateTime proposedTime;
  final String requester;
  final String requesterId;
  final DateTime requestTime;
  final String status;
  final String? rejectionReason; // Tambahkan field ini

  MeetingRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.room,
    required this.proposedTime,
    required this.requester,
    required this.requesterId,
    required this.requestTime,
    required this.status,
    this.rejectionReason, // Tambahkan parameter ini
  });
}