// // lib/Models/models/user.dart

// class AppUser {
//   final int id;
//   final int idRole;
//   final int? idDivision; // Nullable karena bisa kosong
//   final String username;
//   final String name;
//   final String email;
//   final String? phone;
//   final String? gender;
//   final String? photo;
//   final String? createdAt;
//   final String? updatedAt;

//   // PERBAIKAN: Tambahan field untuk nama role dan division
//   final String? role;
//   final String? division;

//   AppUser({
//     required this.id,
//     required this.idRole,
//     this.idDivision,
//     required this.name,
//     required this.username,
//     required this.email,
//     this.phone,
//     this.gender,
//     this.photo,
//     this.createdAt,
//     this.updatedAt,
//     this.role,
//     this.division,
//   });

//   // PERBAIKAN: Factory constructor dengan null safety yang lebih baik
//   factory AppUser.fromJson(Map<String, dynamic> json) {
//     return AppUser(
//       id: json['id'] as int,
//       idRole: json['id_role'] as int,
//       // PERBAIKAN: Handle null dengan aman
//       idDivision: json['id_division'] as int?,
//       name: json['name'] as String,
//       username: json['username'] as String,
//       email: json['email'] as String? ?? '', // Default empty string jika null
//       phone: json['phone'] as String?,
//       gender: json['gender'] as String?,
//       photo: json['photo'] as String?,
//       createdAt: json['created_at'] as String?,
//       updatedAt: json['updated_at'] as String?,
//       role: json['role'] as String?,
//       division: json['division'] as String?,
//     );
//   }

//   // PERBAIKAN: Tambahan method untuk konversi ke JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'id_role': idRole,
//       'id_division': idDivision,
//       'name': name,
//       'username': username,
//       'email': email,
//       'phone': phone,
//       'gender': gender,
//       'photo': photo,
//       'created_at': createdAt,
//       'updated_at': updatedAt,
//       'role': role,
//       'division': division,
//     };
//   }

//   // PERBAIKAN: Method helper untuk cek role
//   bool isAdmin() => idRole == 1;
//   bool isPIC() => idRole == 2;
//   bool isUser() => idRole == 3;

//   // PERBAIKAN: Method untuk debugging
//   @override
//   String toString() {
//     return 'AppUser{id: $id, name: $name, username: $username, idRole: $idRole, role: $role}';
//   }
// }

// lib/Models/models/user.dart

class AppUser {
  final int id_user;
  final int id_role;
  final int? id_division; // Nullable karena bisa kosong
  final String username;
  final String name;
  final String email;
  final String? phone;
  final String? gender;
  final String? photo;
  final String? createdAt;
  final String? updatedAt;

  // PERBAIKAN: Tambahan field untuk nama role dan division
  final String? role;
  final String? division;

  AppUser({
    required this.id_user,
    required this.id_role,
    this.id_division,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.gender,
    this.photo,
    this.createdAt,
    this.updatedAt,
    this.role,
    this.division,
  });

  // PERBAIKAN: Factory constructor dengan null safety yang lebih baik
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id_user: json['id_user'] as int,
      id_role: json['id_role'] as int,
      // PERBAIKAN: Handle null dengan aman
      id_division: json['id_division'] as int?,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String? ?? '', // Default empty string jika null
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      photo: json['photo'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      role: json['role'] as String?,
      division: json['division'] as String?,
    );
  }

  // PERBAIKAN: Tambahan method untuk konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id_user,
      'id_role': id_role,
      'id_division': id_division,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'gender': gender,
      'photo': photo,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'role': role,
      'division': division,
    };
  }

  // PERBAIKAN: Method helper untuk cek role
  bool isAdmin() => id_role == 1;
  bool isPIC() => id_role == 2;
  bool isUser() => id_role == 3;

  // PERBAIKAN: Method untuk debugging
  @override
  String toString() {
    return 'AppUser{id: $id_user, name: $name, username: $username, idRole: $id_role, role: $role}';
  }
}