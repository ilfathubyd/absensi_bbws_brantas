import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:absen_app/services/auth_service.dart';
import 'package:absen_app/config/api_config.dart'; // <-- Import config

import '../models/rapat.dart';
import 'package:path_provider/path_provider.dart'; // Untuk mendapatkan direktori penyimpanan
import 'package:permission_handler/permission_handler.dart';

class RapatApiService {
  static const String _baseUrl = ApiConfig.baseUrl;

  final AuthService _authService;

  RapatApiService({AuthService? authService})
      : _authService = authService ?? AuthService();

  Future<Map<String, dynamic>> createRapat({
    required int idCabang,
    required int idRoom,
    required String judul,
    required String tanggal, // format YYYY-MM-DD
    required String waktuStart, // HH:mm
    String? waktuEnd, // HH:mm or null
    String? desc,
    String? idUserPengaju,
    List<int>? divisions,
    // TAMBAHAN: File upload parameters
    List<File>? filesMateri,
    List<File>? filesNotulensi,
    List<File>? filesDokumentasi,
    List<File>? filesLainnya,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    final uri = Uri.parse('$_baseUrl/rapat');

    // PERUBAHAN: Gunakan MultipartRequest untuk upload file
    var request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    // Add form fields
    request.fields['id_cabang'] = idCabang.toString();
    request.fields['id_room'] = idRoom.toString();
    request.fields['judul'] = judul;
    request.fields['tanggal'] = tanggal;
    request.fields['waktu_start'] = waktuStart;
    if (waktuEnd != null) request.fields['waktu_end'] = waktuEnd;
    if (desc != null) request.fields['desc'] = desc;
    if (idUserPengaju != null)
      request.fields['id_user_pengaju'] = idUserPengaju;

    // Add divisions
    if (divisions != null && divisions.isNotEmpty) {
      for (int i = 0; i < divisions.length; i++) {
        request.fields['division_ids[$i]'] = divisions[i].toString();
      }
    }

    // Add files - Materi
    if (filesMateri != null) {
      for (var file in filesMateri) {
        request.files.add(await http.MultipartFile.fromPath(
          'files_materi[]',
          file.path,
        ));
      }
    }

    // Add files - Notulensi
    if (filesNotulensi != null) {
      for (var file in filesNotulensi) {
        request.files.add(await http.MultipartFile.fromPath(
          'files_notulensi[]',
          file.path,
        ));
      }
    }

    // Add files - Dokumentasi
    if (filesDokumentasi != null) {
      for (var file in filesDokumentasi) {
        request.files.add(await http.MultipartFile.fromPath(
          'files_dokumentasi[]',
          file.path,
        ));
      }
    }

    // Add files - Lainnya
    if (filesLainnya != null) {
      for (var file in filesLainnya) {
        request.files.add(await http.MultipartFile.fromPath(
          'files_lainnya[]',
          file.path,
        ));
      }
    }

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

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
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 30));

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

  Future<List<Map<String, dynamic>>> fetchRoomsByCabang(
    int idCabang, {
    String? tanggal,
    String? waktuStart,
    String? waktuEnd,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    // PERBAIKAN: Menggunakan endpoint /room dengan filter cabang_id
    // Ini lebih konsisten dengan REST API dan menggunakan method index() di RoomController.
    final queryParams = <String, String>{
      'cabang_id': idCabang.toString(),
    };
    if (tanggal != null) queryParams['tanggal'] = tanggal;
    if (waktuStart != null) queryParams['waktu_start'] = waktuStart;
    if (waktuEnd != null)
      queryParams['waktu_end'] = waktuEnd; // <-- Pastikan ini sudah ada

    // Menggunakan endpoint /room dan melewatkan parameter di query
    final uri =
        Uri.parse('$_baseUrl/room').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Sekarang server mengirim semua ruangan, jadi frontend bisa menampilkan
      // status untuk masing-masing ruangan (Tersedia/Tidak Tersedia).
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
    final uri = Uri.parse('$_baseUrl/absensi/history');
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 30));

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
    throw Exception('Gagal memuat riwayat absensi');
  }

  // PERBAIKAN: Method ini duplikat dan tidak mengirim token. Sebaiknya dihapus dan gunakan fetchRapatByUser.
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

  /// Mengambil daftar rapat yang terkait dengan PIC yang sedang login.
  Future<List<Map<String, dynamic>>> fetchRapatForPIC() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    final uri = Uri.parse('$_baseUrl/rapat/saya');
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Format data rapat PIC tidak dikenali');
    }
    throw Exception(
        'Gagal memuat rapat untuk PIC (status: ${response.statusCode})');
  }

  /// Menyetujui pengajuan rapat dengan mengirim POST request ke endpoint /setujui.
  Future<void> approveRapat(String idRapat) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    // Endpoint spesifik untuk menyetujui rapat
    final uri = Uri.parse('$_baseUrl/rapat/$idRapat/setujui');

    final response = await http.post(
      // Menggunakan metode POST
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
        throw Exception(
            'Gagal menyetujui rapat (status ${response.statusCode})');
      }
    }
  }

  /// Menolak pengajuan rapat dengan mengirim POST request ke endpoint /tolak.
  Future<void> rejectRapat(String idRapat, String reason) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    // Endpoint spesifik untuk menolak rapat
    final uri = Uri.parse('$_baseUrl/rapat/$idRapat/tolak');

    final response = await http.post(
      // Menggunakan metode POST
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

  /// Menyelesaikan rapat dengan mengirim POST request ke endpoint /selesaikan.
  Future<void> endRapat(String idRapat) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    final uri = Uri.parse('$_baseUrl/rapat/$idRapat/selesaikan');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body);
        final msg = (err is Map && err['message'] != null)
            ? err['message'].toString()
            : 'Gagal menyelesaikan rapat';
        throw Exception(msg);
      } catch (_) {
        throw Exception(
            'Gagal menyelesaikan rapat (status ${response.statusCode})');
      }
    }
  }

  /// Mengunduh laporan absensi rapat dalam format Excel.
  /// Mengembalikan path file yang diunduh.
  Future<String> downloadAbsensiRapat(String idRapat, String judulRapat) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    final uri = Uri.parse('$_baseUrl/rapat/$idRapat/export-absensi');

    final response = await http.get(
      uri,
      headers: {
        'Accept':
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // Menerima Excel
        'Authorization': 'Bearer $token',
      },
    ).timeout(
        const Duration(seconds: 60)); // Beri timeout lebih lama untuk download

    if (response.statusCode == 200) {
      Directory? directory;
      if (Platform.isAndroid) {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        // Untuk Android 10 (SDK 29) ke atas, tidak perlu izin khusus
        // untuk menyimpan ke folder Downloads publik.
        // Untuk Android 9 (SDK 28) ke bawah, kita perlu izin storage.
        if (deviceInfo.version.sdkInt <= 28) {
          if (await Permission.storage.request().isGranted) {
            directory = await getExternalStorageDirectory();
          } else {
            throw Exception('Izin penyimpanan ditolak.');
          }
        } else {
          // getExternalStoragePublicDirectory(Downloads) lebih cocok,
          // tapi getExternalStorageDirectory() seringkali cukup dan lebih konsisten.
          // Kita akan coba membuat subdirektori 'Download' jika tidak ada.
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // Di iOS, simpan ke direktori dokumen aplikasi yang bisa diakses via Files app.
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception("Tidak dapat menemukan direktori penyimpanan.");
      }

      // Di Android, kita ingin path ke folder Downloads.
      // Path dari getExternalStorageDirectory() adalah /storage/emulated/0/Android/data/<package_name>/files
      // Kita akan navigasi ke atas untuk mendapatkan path /storage/emulated/0/Download
      String downloadsPath = directory.path;
      if (Platform.isAndroid) {
        // Mencari path yang lebih umum untuk folder Download
        downloadsPath = "/storage/emulated/0/Download";
        final downloadsDir = Directory(downloadsPath);
        // Pastikan folder Download ada, jika tidak, gunakan path default
        if (!await downloadsDir.exists()) {
          // Fallback ke direktori eksternal aplikasi jika /Download tidak ada
          downloadsPath = directory.path;
        }
      }

      final fileName =
          'absensi_${judulRapat.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '$downloadsPath/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // (Opsional) Langsung buka file setelah diunduh

      return filePath; // Mengembalikan path file yang berhasil diunduh
    } else {
      String errorMessage =
          'Gagal mengunduh laporan absensi (status: ${response.statusCode})';
      try {
        // Coba parse body jika ada pesan error dari server
        final err = jsonDecode(response.body);
        if (err is Map && err['message'] != null) {
          errorMessage = err['message'].toString();
        }
      } catch (_) {
        // Abaikan jika body bukan JSON
      }
      throw Exception(errorMessage);
    }
  }

  // Tambahkan ini di dalam class RapatApiService di rapat_api_service.dart

  Future<Map<String, dynamic>> updateRapat({
    required String idRapat,
    required String judul,
    String? desc,
    required int idCabang,
    required int idRuangan,
    String? idPengaju,
    required int idStatus,
    required String tanggal,
    required String waktuStart,
    String? waktuEnd,
    List<int>? divisionIds,
    // TAMBAHAN: File upload parameters
    List<File>? filesMateri,
    List<File>? filesNotulensi,
    List<File>? filesDokumentasi,
    List<File>? filesLainnya,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Tidak terautentikasi');

    final uri = Uri.parse('$_baseUrl/rapat/$idRapat');

    // PERUBAHAN: Gunakan MultipartRequest untuk upload file
    var request = http.MultipartRequest('POST', uri);

    // Add _method field for Laravel PUT emulation
    request.fields['_method'] = 'PUT';

    // Add headers
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    // Add form fields
    request.fields['judul'] = judul;
    request.fields['tanggal'] = tanggal;
    request.fields['id_cabang'] = idCabang.toString();
    request.fields['id_room'] = idRuangan.toString();
    request.fields['id_status'] = idStatus.toString();
    request.fields['waktu_start'] = waktuStart;
    if (desc != null) request.fields['desc'] = desc;
    if (waktuEnd != null) request.fields['waktu_end'] = waktuEnd;

    // Add divisions
    if (divisionIds != null) {
      for (int i = 0; i < divisionIds.length; i++) {
        request.fields['division_ids[$i]'] = divisionIds[i].toString();
      }
    }

    // Add files - Materi
    if (filesMateri != null) {
      for (var file in filesMateri) {
        request.files.add(await http.MultipartFile.fromPath(
          'files_materi[]',
          file.path,
        ));
      }
    }

    // Add files - Notulensi
    if (filesNotulensi != null) {
      for (var file in filesNotulensi) {
        request.files.add(await http.MultipartFile.fromPath(
          'files_notulensi[]',
          file.path,
        ));
      }
    }

    // Add files - Dokumentasi
    if (filesDokumentasi != null) {
      for (var file in filesDokumentasi) {
        request.files.add(await http.MultipartFile.fromPath(
          'files_dokumentasi[]',
          file.path,
        ));
      }
    }

    // Add files - Lainnya
    if (filesLainnya != null) {
      for (var file in filesLainnya) {
        request.files.add(await http.MultipartFile.fromPath(
          'files_lainnya[]',
          file.path,
        ));
      }
    }

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final err = jsonDecode(response.body);
        final msg = err['message']?.toString() ?? 'Gagal memperbarui rapat';
        throw Exception(msg);
      } catch (_) {
        throw Exception(
            'Gagal memperbarui rapat (status ${response.statusCode})');
      }
    }
  }

  Future<void> deleteRapat(String idRapat) async {
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
      throw Exception(
          'Gagal memuat semua data rapat (Status: ${response.statusCode})');
    }
  }

// GANTI METHOD LAMA ANDA DENGAN INI
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    // PERBAIKAN: Menggunakan endpoint yang benar untuk mengambil semua user.
    final uri = Uri.parse('$_baseUrl/pic/get-division');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Menyesuaikan dengan kemungkinan format respons dari endpoint baru.
      // Endpoint ini kemungkinan besar mengembalikan list langsung.
      if (data is Map && data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }

      // PERBAIKAN: Menambahkan pengecekan untuk format respons {"users": [...]}.
      if (data is Map && data['divisions'] is List) {
        return (data['divisions'] as List).cast<Map<String, dynamic>>();
      }

      // Pengecekan lain bisa dihapus atau disimpan sebagai fallback
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }

      // Memberikan pesan error yang lebih informatif jika formatnya masih salah
      throw Exception('Format data user tidak dikenali. Respons: $data');
    }
    if (response.statusCode == 403) {
      throw Exception(
          'Akses ditolak. Anda tidak memiliki izin untuk melihat daftar pengguna.');
    }
    throw Exception('Gagal memuat data user (status: ${response.statusCode})');
  }

  Future<List<Map<String, dynamic>>> fetchUsersPIC() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    // PERBAIKAN: Menggunakan endpoint yang benar untuk mengambil semua user.
    final uri = Uri.parse('$_baseUrl/userPIC');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Menyesuaikan dengan kemungkinan format respons dari endpoint baru.
      // Endpoint ini kemungkinan besar mengembalikan list langsung.
      if (data is Map && data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }

      // PERBAIKAN: Menambahkan pengecekan untuk format respons {"users": [...]}.
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
    if (response.statusCode == 403) {
      throw Exception(
          'Akses ditolak. Anda tidak memiliki izin untuk melihat daftar pengguna.');
    }
    throw Exception('Gagal memuat data user (status: ${response.statusCode})');
  }

  /// Menggunakan QR token yang didapat dari pemindaian.
  Future<Map<String, dynamic>> attendRapat(String qrToken) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    // Endpoint untuk absensi, diasumsikan menggunakan metode POST
    // dan menerima qr_token di body.
    final uri = Uri.parse('$_baseUrl/rapat/scan-absen');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'scanned_token': qrToken,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // PERBAIKAN: Tangani jika respons adalah Map atau String
      if (responseBody is Map<String, dynamic>) {
        // Jika sudah benar Map, langsung kembalikan.
        return responseBody;
      } else if (responseBody is String) {
        // Jika hanya String, bungkus dalam Map agar konsisten.
        return {'message': responseBody};
      } else {
        // Fallback jika format tidak terduga.
        return {'message': 'Absensi berhasil diproses.'};
      }
    }

    // Coba ekstrak pesan error dari server jika status bukan 200
    final errorMessage = (responseBody is Map<String, dynamic>)
        ? responseBody['message']?.toString()
        : responseBody.toString();
    throw Exception(errorMessage ??
        'Gagal melakukan absensi (status ${response.statusCode})');
  }

  // Method lama attendRapat bisa dipertahankan atau dideprecate
  // ...

  /// Validasi QR token dan dapatkan session token untuk foto nanti.
  /// Dipanggil SEGERA setelah QR di-scan, sebelum foto diambil.
  Future<Map<String, dynamic>> validateQrToken(String qrToken) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    final uri = Uri.parse('$_baseUrl/rapat/validate-qr');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'scanned_token': qrToken,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (responseBody is Map<String, dynamic>) {
        return responseBody;
      } else {
        throw Exception('Format respons tidak valid');
      }
    }

    // Handle error
    final errorMessage = (responseBody is Map<String, dynamic>)
        ? responseBody['message']?.toString()
        : responseBody.toString();
    throw Exception(errorMessage ??
        'Gagal validasi QR code (status ${response.statusCode})');
  }

  /// Menggunakan QR token dan foto wajah untuk absensi.
  /// Sekarang mendukung session_token sebagai alternatif dari scanned_token.
  Future<Map<String, dynamic>> attendRapatWithPhoto(String qrToken, File photo,
      {String? sessionToken}) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    final uri = Uri.parse('$_baseUrl/rapat/scan-absen');

    // Gunakan MultipartRequest karena ada file upload
    var request = http.MultipartRequest('POST', uri);

    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    // Kirim session_token jika ada, kalau tidak kirim scanned_token
    if (sessionToken != null && sessionToken.isNotEmpty) {
      request.fields['session_token'] = sessionToken;
    } else {
      request.fields['scanned_token'] = qrToken;
    }

    // Tambahkan file foto
    request.files.add(await http.MultipartFile.fromPath(
      'face_photo',
      photo.path,
    ));

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (responseBody is Map<String, dynamic>) {
        return responseBody;
      } else if (responseBody is String) {
        return {'message': responseBody};
      } else {
        return {'message': 'Absensi berhasil diproses.'};
      }
    }

    final errorMessage = (responseBody is Map<String, dynamic>)
        ? responseBody['message']?.toString()
        : responseBody.toString();
    throw Exception(errorMessage ??
        'Gagal melakukan absensi (status ${response.statusCode})');
  }

  /// Mengambil daftar absensi untuk rapat tertentu.
  Future<List<Map<String, dynamic>>> fetchAbsensiRapat(String idRapat) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    final uri = Uri.parse('$_baseUrl/rapat/$idRapat/absensi');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else if (data is Map && data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      throw Exception('Format data absensi tidak dikenali');
    } else if (response.statusCode == 404) {
      throw Exception('Rapat tidak ditemukan.');
    } else {
      throw Exception(
          'Gagal memuat data absensi (Status: ${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> fetchRapatDetail(String id) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    final uri = Uri.parse('$_baseUrl/rapat/$id');
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw Exception('Rapat tidak ditemukan');
    } else {
      throw Exception(
          'Gagal memuat detail rapat (Status: ${response.statusCode})');
    }
  }

  Future<String> getDownloadUrl(String fileId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Tidak terautentikasi');

    final response = await http.get(
      Uri.parse('$_baseUrl/rapat/files/$fileId/download-url'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['download_url'];
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal mendapatkan link download');
    }
  }

  /// Delete a file from a meeting
  Future<void> deleteFile(String fileId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Tidak terautentikasi');

    final response = await http.delete(
      Uri.parse('$_baseUrl/rapat/files/$fileId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Gagal menghapus file');
      }
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal menghapus file');
    }
  }
}
