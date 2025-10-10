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

  // ==========================================================
  // === GANTI SELURUH BAGIAN FACTORY INI DENGAN KODE BARU ===
  // ==========================================================
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      // PERUBAHAN: Tambahkan `?? 0` untuk memberikan nilai default jika null
      id_user: json['id_user'] ?? 0,
      id_role: json['id_role'] ?? 0,

      // Handle null dengan aman
      id_division: json['id_division'] as int?,
      name: json['name'] as String? ?? 'No Name', // Beri default jika nama null
      username: json['username'] as String? ??
          'no_username', // Beri default jika username null
      email: json['email'] as String? ?? '', // Default empty string jika null
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      photo: json['photo'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      // PERBAIKAN: Mengambil nama role dari objek bersarang.
      // json['role'] adalah Map, kita ambil nilai dari key 'role' di dalamnya.
      role: json['role'] is Map
          ? json['role']['role'] as String?
          : json['role'] as String?,
      // PERBAIKAN: Mengambil nama divisi dari objek bersarang.
      // json['division'] adalah Map, kita ambil nilai dari key 'division_name' di dalamnya.
      division: json['division'] is Map
          ? json['division']['division_name'] as String?
          : json['division'] as String?,
    );
  }
  // ==========================================================
  // === AKHIR BAGIAN YANG DIGANTI ============================
  // ==========================================================

  // Method lainnya tetap sama
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

  bool isAdmin() => id_role == 1;
  bool isPIC() => id_role == 2;
  bool isUser() => id_role == 3;

  @override
  String toString() {
    return 'AppUser{id: $id_user, name: $name, username: $username, idRole: $id_role, role: $role}';
  }
}
