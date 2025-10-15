// lib/Models/models/division.dart

class Division {
  final int id;
  final String name;

  Division({
    required this.id,
    required this.name,
  });

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id_division'] as int,
      name: json['division_name'] as String,
    );
  }
}
