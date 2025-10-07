// lib/Models/models/rapat.dart

import 'package:intl/intl.dart';

class Rapat {
  final int idRapat;
  final String judul;
  final String deskripsi;

  // Kita akan menyimpan waktu sebagai objek DateTime untuk kemudahan
  final DateTime waktuMulai;
  final DateTime? waktuSelesai;

  // Properti dari relasi
  final int idCabang;
  final String namaCabang; // Akan kita bahas di bawah
  final int idRuangan;
  final String namaRuangan;
  final int idPengaju;
  final String namaPengaju;
  final int idStatus;
  final String statusRapat;

  Rapat({
    required this.idRapat,
    required this.judul,
    required this.deskripsi,
    required this.waktuMulai,
    this.waktuSelesai,
    required this.idCabang,
    required this.namaCabang,
    required this.idRuangan,
    required this.namaRuangan,
    required this.idPengaju,
    required this.namaPengaju,
    required this.idStatus,
    required this.statusRapat,
  });

  // --- INI BAGIAN PALING PENTING: FACTORY fromJson ---
  factory Rapat.fromJson(Map<String, dynamic> json) {
    // Helper untuk menggabungkan tanggal dan waktu dari API menjadi satu objek DateTime
    // PERBAIKAN: Dibuat lebih aman untuk menangani nilai null
    DateTime parseWaktu(String? tanggal, String? waktu) {
      if (tanggal == null || waktu == null) {
        // Jika data tanggal/waktu tidak lengkap, kembalikan waktu saat ini
        // untuk mencegah aplikasi crash.
        return DateTime.now();
      }
      // Formatnya: "YYYY-MM-DD HH:mm:ss"
      return DateTime.parse('$tanggal $waktu');
    }

    return Rapat(
      // PERBAIKAN: Tambahkan `?? 0` untuk memberikan nilai default jika null
      idRapat: json['id_rapat'] ?? 0,

      judul: json['judul'] ?? 'Tanpa Judul',
      deskripsi: json['desc'] ?? '', // Menggunakan 'desc' dari JSON

      // Menggabungkan tanggal dan waktu dari JSON dengan aman
      waktuMulai: parseWaktu(json['tanggal'], json['waktu_start']),
      waktuSelesai: json['waktu_end'] != null && json['tanggal'] != null
          ? parseWaktu(json['tanggal'], json['waktu_end'])
          : null,

      // --- Mengambil data dari level atas dan nested object ---

      // PERBAIKAN: Tambahkan `?? 0` untuk memberikan nilai default jika null
      idCabang: json['id_cabang'] ?? 0,

      // Kode ini sudah aman karena menggunakan null-aware (?) dan null-coalescing (??)
      namaCabang: json['cabang']?['nama_cabang'] ?? 'Nama Cabang TBD',

      // PERBAIKAN: Tambahkan `?? 0` untuk memberikan nilai default jika null
      idRuangan: json['id_room'] ?? 0,
      namaRuangan: json['room']?['room'] ?? 'Ruangan Tidak Ditemukan',

      // PERBAIKAN: Tambahkan `?? 0` untuk memberikan nilai default jika null
      idPengaju: json['id_user_pengaju'] ?? 0,
      namaPengaju: json['pengaju']?['name'] ?? 'Pengaju Tidak Ditemukan',

      // PERBAIKAN: Tambahkan `?? 0` untuk memberikan nilai default jika null
      idStatus: json['id_status'] ?? 0,
      statusRapat: json['status']?['status_rapat'] ?? 'Status Tidak Diketahui',
    );
  }

  // Helper getter untuk memformat tanggal & waktu untuk ditampilkan di UI
  String get tanggalFormatted => DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(waktuMulai);
  String get waktuMulaiFormatted => DateFormat('HH:mm', 'id_ID').format(waktuMulai);
  String get waktuSelesaiFormatted => waktuSelesai != null ? DateFormat('HH:mm', 'id_ID').format(waktuSelesai!) : '-';


  Map<String, dynamic> toJson() {
    return {
      // Properti utama dari tabel 'rapat'
      'judul': judul,
      'desc': deskripsi, // API Anda menggunakan 'desc', bukan 'deskripsi'

      // Pecah kembali objek DateTime menjadi format String yang diterima API
      'tanggal': DateFormat('yyyy-MM-dd').format(waktuMulai),
      'waktu_start': DateFormat('HH:mm:ss').format(waktuMulai),
      'waktu_end': waktuSelesai != null
          ? DateFormat('HH:mm:ss').format(waktuSelesai!)
          : null,

      // Saat mengirim data, biasanya server hanya butuh ID dari relasi
      'id_cabang': idCabang,
      'id_room': idRuangan,
      'id_user_pengaju': idPengaju, // API Anda menggunakan 'id_user_pengaju'
      'id_status': idStatus,

      // 'id_rapat' biasanya tidak perlu dikirim dalam body,
      // karena sudah ada di URL endpoint (misal: /api/rapat/34) saat update.
      // Namun, jika API Anda mengharapkannya, Anda bisa uncomment baris di bawah.
      // 'id_rapat': idRapat,
    };
  }

}