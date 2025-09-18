// lib/models/meeting.dart
class Meeting {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final String room;
  final String responsible;
  final String pic;
  final String status;
  final bool isApproved;

  Meeting({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    this.endTime,
    required this.room,
    required this.responsible,
    required this.pic,
    required this.status,
    required this.isApproved,
  });

  // Getter untuk kompatibilitas dengan kode yang menggunakan dateTime
  DateTime get dateTime => startTime;

  // Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'room': room,
      'pic': pic,
      'responsible': responsible,
    };
  }

  // Factory constructor untuk bikin Meeting dari JSON
   factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      room: json['room'],
      pic: json['pic'],
      responsible: json['responsible'],
      status: json['status'] ?? 'pending',
      isApproved: json['isApproved'] ?? false,
    );
  }
}