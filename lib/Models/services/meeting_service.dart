import 'package:absen_app/Models/models/meeting.dart';

class MeetingService {
  static final MeetingService _instance = MeetingService._internal();
  factory MeetingService() => _instance;
  MeetingService._internal();

  List<Meeting> _approvedMeetings = [];

  List<Meeting> get approvedMeetings => _approvedMeetings;
  
  void setApprovedMeetings(List<Meeting> meetings) {
    _approvedMeetings = meetings;
  }
  
  List<Meeting> getUpcomingMeetings() {
    return _approvedMeetings.where((m) => m.startTime.isAfter(DateTime.now())).toList();
  }
  
  List<Meeting> getHistoryMeetings() {
    return _approvedMeetings.where((m) => m.startTime.isBefore(DateTime.now())).toList();
  }
  
  // TAMBAHKAN METHOD INI: Untuk mendapatkan meeting berdasarkan PIC
  List<Meeting> getMeetingsByPIC(String picName) {
    return _approvedMeetings.where((m) => 
      m.responsible.toLowerCase().contains(picName.toLowerCase())
    ).toList();
  }
  
  // TAMBAHKAN METHOD INI: Untuk mendapatkan history meeting berdasarkan PIC
  List<Meeting> getHistoryMeetingsByPIC(String picName) {
    return _approvedMeetings.where((m) => 
      m.responsible.toLowerCase().contains(picName.toLowerCase()) &&
      m.startTime.isBefore(DateTime.now())
    ).toList();
  }
  
  // TAMBAHKAN METHOD INI: Untuk mendapatkan upcoming meeting berdasarkan PIC
  List<Meeting> getUpcomingMeetingsByPIC(String picName) {
    return _approvedMeetings.where((m) => 
      m.responsible.toLowerCase().contains(picName.toLowerCase()) &&
      m.startTime.isAfter(DateTime.now())
    ).toList();
  }
}