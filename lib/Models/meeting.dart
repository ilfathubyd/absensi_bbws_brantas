class Meeting {
  final String id;
  final String title;
  final DateTime dateTime;
  final String room; // wajib ada

  Meeting({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.room, // harus ada
  });
}
