import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:absen_app/services/auth_service.dart';

import '../models/rapat.dart';

class RapatApiService {
  static const String _baseUrl = "http://192.168.50.60:8000/api";

  final AuthService _authService;

  RapatApiService({AuthService? authService}) : _authService = authService ?? AuthService();

    Future<Map<String, dynamic>> createRapat({
    required int idCabang,
    required int idRoom,
    required String judul,
    required String tanggal, // format YYYY-MM-DD
    required String waktuStart, // HH:mm
    String? waktuEnd,   // HH:mm or null
    String? desc,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    final uri = Uri.parse('$_baseUrl/rapat');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'id_cabang': idCabang,
            'id_room': idRoom,
            'judul': judul,
            'tanggal': tanggal,
            'waktu_start': waktuStart,
            if (waktuEnd != null) 'waktu_end': waktuEnd,
            if (desc != null) 'desc': desc,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    }

    // coba ekstrak pesan error dari server
    try {
      final err = jsonDecode(response.body);
      final msg = (err is Map && err['message'] != null)
          ? err['message'].toString()
          : 'Gagal membuat rapat (status ${response.statusCode})';
      throw Exception(msg);
    } catch (_) {
      throw Exception('Gagal membuat rapat (status ${response.statusCode})');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCabang() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }
    final uri = Uri.parse('$_baseUrl/cabang');
    final response = await http
        .get(uri, headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        })
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map && data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      throw Exception('Format data cabang tidak dikenali');
    }
    throw Exception('Gagal memuat cabang');
  }

  Future<List<Map<String, dynamic>>> fetchRoomsByCabang(int idCabang) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    // URL diubah untuk menargetkan endpoint baru
    final uri = Uri.parse('$_baseUrl/cabang/$idCabang/room');

    final response = await http
        .get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    })
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Karena server sudah memfilter, kita tidak perlu filter 'status_ruang_id' di sini lagi.
      // Kode menjadi lebih bersih dan efisien.
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }

      // Penanganan jika API Anda membungkus data dalam properti 'data'
      if (data is Map && data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }

      throw Exception('Format data ruangan tidak dikenali');
    }
    throw Exception('Gagal memuat ruangan (status: ${response.statusCode})');
  }


  Future<List<Map<String, dynamic>>> fetchRapatByUser() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }
    final uri = Uri.parse('$_baseUrl/rapat/saya');
    final response = await http
        .get(uri, headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        })
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map && data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      throw Exception('Format data rapat tidak dikenali');
    }
    throw Exception('Gagal memuat rapat');

    }
  Future<List<Map<String, dynamic>>> fetchRapatSaya() async {
    final url = Uri.parse("$_baseUrl/rapat/saya");

    final response = await http.get(url, headers: {
      "Accept": "application/json",
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Gagal memuat rapat saya (${response.statusCode})");
    }
  }

  /// Menyetujui pengajuan rapat dengan mengirim POST request ke endpoint /setujui.
  Future<void> approveRapat(int idRapat) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    // Endpoint spesifik untuk menyetujui rapat
    final uri = Uri.parse('$_baseUrl/rapat/$idRapat/setujui');

    final response = await http.post( // Menggunakan metode POST
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      // Biasanya endpoint seperti ini tidak memerlukan body,
      // tapi aman untuk mengirim body kosong jika server mengharapkannya.
      body: jsonEncode({}),
    );

    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body);
        final msg = (err is Map && err['message'] != null)
            ? err['message'].toString()
            : 'Gagal menyetujui rapat';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Gagal menyetujui rapat (status ${response.statusCode})');
      }
    }
  }

  /// Menolak pengajuan rapat dengan mengirim POST request ke endpoint /tolak.
  Future<void> rejectRapat(int idRapat, String reason) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    // Endpoint spesifik untuk menolak rapat
    final uri = Uri.parse('$_baseUrl/rapat/$idRapat/tolak');

    final response = await http.post( // Menggunakan metode POST
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      // Endpoint tolak kemungkinan besar membutuhkan alasan penolakan di body
      body: jsonEncode({
        'rejection_reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body);
        final msg = (err is Map && err['message'] != null)
            ? err['message'].toString()
            : 'Gagal menolak rapat';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Gagal menolak rapat (status ${response.statusCode})');
      }
    }
  }

  // Tambahkan ini di dalam class RapatApiService di rapat_api_service.dart

  Future<Map<String, dynamic>> updateRapat({
    required int idRapat,
    required String judul,
    String? desc,
    required int idCabang,   // <-- TAMBAHKAN INI DI PARAMETER
    required int idRuangan,
    required int idPengaju,
    required int idStatus,
    required String tanggal,
    required String waktuStart,
    String? waktuEnd,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Tidak terautentikasi');

    final uri = Uri.parse('$_baseUrl/rapat/$idRapat');

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'judul': judul,
        'tanggal': tanggal,
        'id_cabang': idCabang,
        'id_room': idRuangan,
        'id_user_pengaju': idPengaju,
        'id_status' : idStatus,
        'waktu_start': waktuStart,
        'desc': desc,
       'waktu_end': waktuEnd,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final err = jsonDecode(response.body);
        final msg = err['message']?.toString() ?? 'Gagal memperbarui rapat';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Gagal memperbarui rapat (status ${response.statusCode})');
      }
    }
  }

  Future<void> deleteRapat(int idRapat) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Tidak terautentikasi');

    // Endpoint untuk delete biasanya menggunakan DELETE dengan ID di URL
    final uri = Uri.parse('$_baseUrl/rapat/$idRapat');

    final response = await http.delete(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 30));

    // Status 200 (OK) atau 204 (No Content) biasanya menandakan sukses
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Gagal menghapus rapat (status ${response.statusCode})');
    }
  }

  Future<List<Rapat>> fetchAllRapat() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    final uri = Uri.parse('$_baseUrl/rapat');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // PERUBAHAN: Langsung konversi ke List<Rapat> di sini
      return data.map((json) => Rapat.fromJson(json)).toList();
    } else if (response.statusCode == 403) {
      throw Exception('Akses ditolak. Anda bukan admin.');
    } else {
      throw Exception('Gagal memuat semua data rapat (Status: ${response.statusCode})');
    }
  }

  // file: lib/Models/services/rapat_api_service.dart
// Tambahkan method ini di dalam class RapatApiService


// GANTI METHOD LAMA ANDA DENGAN INI
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    // Endpoint sudah benar: /userPIC
    final uri = Uri.parse('$_baseUrl/userPIC');

    final response = await http
        .get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    })
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // === PERUBAHAN UTAMA DI SINI ===
      // Sekarang kita cek key 'users' sesuai dengan respons API Anda.
      if (data is Map && data['users'] is List) {
        return (data['users'] as List).cast<Map<String, dynamic>>();
      }

      // Pengecekan lain bisa dihapus atau disimpan sebagai fallback
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }

      // Memberikan pesan error yang lebih informatif jika formatnya masih salah
      throw Exception('Format data user tidak dikenali. Respons: $data');
    }
    throw Exception('Gagal memuat data user (status: ${response.statusCode})');
  }


}



