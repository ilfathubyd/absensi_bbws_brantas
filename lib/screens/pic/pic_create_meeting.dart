//PIC Create Meeting

import 'dart:io';
import 'package:absen_app/Models/models/division.dart';
import 'package:absen_app/Models/models/user.dart';
import 'package:absen_app/Models/services/participant_selector_page.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:absen_app/services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:absen_app/utils/snackbar_helper.dart';

class PICCreateRapat extends StatefulWidget {
  const PICCreateRapat({super.key});

  @override
  State<PICCreateRapat> createState() => _PICCreateRapatState();
}

class _PICCreateRapatState extends State<PICCreateRapat> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  // Variabel State untuk Dropdown
  int? _selectedCabangId;
  int? _selectedRoomId;
  List<Map<String, dynamic>> _cabangs = [];
  List<Map<String, dynamic>> _rooms =
      []; // Akan berisi ruangan untuk cabang yang dipilih
  List<Division> _allDivisions = [];
  List<Division> _selectedDivisions = [];

  // Variabel State untuk Kontrol UI
  bool _loadingInitialData = true;
  bool _loadingRooms = false; // Untuk memuat ruangan setelah cabang dipilih
  bool _submitting = false;
  // bool _isIndefinite = false; // DIHAPUS
  AppUser? _currentUser;
  final RapatApiService _rapatApiService = RapatApiService();
  final AuthService _authService = AuthService();

  // TAMBAHAN: File upload state
  List<File> _filesMateri = [];
  List<File> _filesNotulensi = [];
  List<File> _filesDokumentasi = [];
  List<File> _filesLainnya = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // Menggabungkan pemuat data awal
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _loadingInitialData = true);

    try {
      // Muat data user dan cabang secara bersamaan
      final results = await Future.wait([
        _loadCurrentUser(),
        _loadCabang(),
        _loadDivisions(),
      ]);
      final divisionsData = results[2] as List<Map<String, dynamic>>;
      if (mounted) {
        setState(() {
          _allDivisions =
              divisionsData.map((json) => Division.fromJson(json)).toList();
        });
      }
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingInitialData = false);
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      // Menangani error secara spesifik jika diperlukan
      print("Gagal memuat data user: $e");
      rethrow; // Lemparkan lagi agar ditangkap oleh _loadInitialData
    }
  }

  Future<void> _loadCabang() async {
    try {
      final cabangs = await _rapatApiService.fetchCabang();
      if (mounted) {
        setState(() {
          _cabangs = cabangs;
        });
      }
    } catch (e) {
      print("Gagal memuat data cabang: $e");
      rethrow; // Lemparkan lagi agar ditangkap oleh _loadInitialData
    }
  }

  Future<List<Map<String, dynamic>>> _loadDivisions() async {
    try {
      return await _rapatApiService.fetchUsers();
    } catch (e) {
      print("Gagal memuat data divisi: $e");
      rethrow;
    }
  }

  // Fungsi baru untuk memuat ruangan berdasarkan cabang yang dipilih
  Future<void> _loadRooms() async {
    if (_selectedCabangId == null) {
      return; // Cukup cek cabang saja
    }

    setState(() {
      _loadingRooms = true;
      _rooms = []; // Kosongkan list ruangan sebelumnya
      _selectedRoomId = null; // Reset pilihan ruangan
    });

    // Optional params
    final tanggal = _selectedDate != null
        ? '${_selectedDate!.year}-${_two(_selectedDate!.month)}-${_two(_selectedDate!.day)}'
        : null;
    final start = _selectedStartTime != null
        ? '${_two(_selectedStartTime!.hour)}:${_two(_selectedStartTime!.minute)}'
        : null;
    final end = _selectedEndTime != null
        ? '${_two(_selectedEndTime!.hour)}:${_two(_selectedEndTime!.minute)}'
        : null;

    try {
      final rooms = await _rapatApiService.fetchRoomsByCabang(
          _selectedCabangId!,
          tanggal: tanggal,
          waktuStart: start,
          waktuEnd: end); // <-- Kirim waktu selesai ke API
      if (mounted) {
        setState(() {
          _rooms = rooms;
          // AUTO-SELECT LOGIC:
          // Jika list ruangan tidak kosong, coba cari ruangan pertama yang tersedia (status_ruangan_id == 1/null jika API belum handle).
          // Asumsi backend kirim status_ruangan_id 1 = Tersedia.
          // Jika tidak ada yang id=1, jangan select apa-apa.
          if (_rooms.isNotEmpty) {
            // Cek apakah ada ruangan yang tersedia
            // (Sesuaikan key 'status_ruangan_id' dengan response API)
            final availableRoom = _rooms.firstWhere(
              (r) => r['status_ruangan_id'] == 1,
              orElse: () => {}, // Return map kosong jika tidak ketemu
            );

            if (availableRoom.isNotEmpty) {
              _selectedRoomId = availableRoom['id_room'] as int?;
            } else {
              _selectedRoomId = null;
            }
          } else {
            _selectedRoomId = null;
          }
        });
      }
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _loadingRooms = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _selectedDate ?? now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1565C0),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    setState(() {
      _selectedDate = date;
      _loadRooms(); // Muat ulang ruangan saat tanggal berubah
    });
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1565C0),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    // --- VALIDASI WAKTU MASA LALU ---
    final now = DateTime.now();
    // Gunakan tanggal yang dipilih, atau hari ini jika belum dipilih, untuk validasi
    final validationDate =
        _selectedDate ?? DateTime(now.year, now.month, now.day);

    final selectedDateTime = DateTime(
      validationDate.year,
      validationDate.month,
      validationDate.day,
      time.hour,
      time.minute,
    );

    // Cek jika waktu yang dipilih sudah lewat dari waktu sekarang (dengan buffer 1 menit)
    if (selectedDateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
      _showErrorSnackbar('Waktu mulai tidak boleh di masa lalu.');
      return;
    }

    setState(() {
      _selectedStartTime = time;
      // Jika jam selesai lebih awal dari jam mulai baru, reset jam selesai
      if (_selectedEndTime != null && !_isTimeAfter(time, _selectedEndTime!)) {
        _selectedEndTime = null;
      }
      _loadRooms(); // Muat ulang ruangan saat waktu mulai berubah
    });
  }

  Future<void> _pickEndTime() async {
    if (_selectedStartTime == null) {
      _showErrorSnackbar('Pilih jam mulai terlebih dahulu');
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ??
          TimeOfDay.fromDateTime(
            DateTime(0, 0, 0, _selectedStartTime!.hour,
                    _selectedStartTime!.minute)
                .add(const Duration(hours: 1)),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1565C0),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    if (!_isTimeAfter(time, _selectedStartTime!)) {
      _showErrorSnackbar('Jam selesai harus setelah jam mulai');
      return;
    }

    setState(() {
      _selectedEndTime = time;
      _loadRooms(); // PERBAIKAN: Muat ulang ruangan saat waktu selesai berubah
    });
  }

  bool _isTimeAfter(TimeOfDay time1, TimeOfDay time2) {
    final now = DateTime.now();
    final datetime1 =
        DateTime(now.year, now.month, now.day, time1.hour, time1.minute);
    final datetime2 =
        DateTime(now.year, now.month, now.day, time2.hour, time2.minute);
    return datetime1.isAfter(datetime2);
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  // TAMBAHAN: File picker helper method
  Future<void> _pickFiles(String category) async {
    // Check if running on web
    if (kIsWeb) {
      SnackBarHelper.warning(
        context,
        'Upload file tidak didukung di versi web. Silakan gunakan aplikasi mobile.',
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'txt',
          'zip',
          'rar',
          '7z',
          'mp4',
          'mp3',
          'wav'
        ],
      );

      if (result != null) {
        List<File> files = result.paths.map((path) => File(path!)).toList();

        setState(() {
          switch (category) {
            case 'materi':
              _filesMateri.addAll(files);
              break;
            case 'notulensi':
              _filesNotulensi.addAll(files);
              break;
            case 'dokumentasi':
              _filesDokumentasi.addAll(files);
              break;
            case 'lainnya':
              _filesLainnya.addAll(files);
              break;
          }
        });

        SnackBarHelper.success(
          context,
          '✓ ${files.length} file ditambahkan ke $category',
        );
      }
    } catch (e) {
      SnackBarHelper.error(context, 'Gagal memilih file: $e');
    }
  }

  void _removeFile(String category, int index) {
    setState(() {
      switch (category) {
        case 'materi':
          _filesMateri.removeAt(index);
          break;
        case 'notulensi':
          _filesNotulensi.removeAt(index);
          break;
        case 'dokumentasi':
          _filesDokumentasi.removeAt(index);
          break;
        case 'lainnya':
          _filesLainnya.removeAt(index);
          break;
      }
    });
  }

  Widget _buildFilePickerButton(
      String label, String category, Color color, List<File> files) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _pickFiles(category),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.cloud_upload_outlined,
                        color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            if (files.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${files.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          files.isEmpty
                              ? 'Tap untuk pilih file'
                              : '${files.length} file dipilih',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    files.isEmpty
                        ? Icons.add_circle_outline
                        : Icons.check_circle,
                    color: files.isEmpty ? Colors.grey : color,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (files.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: files.asMap().entries.map((entry) {
                  int index = entry.key;
                  File file = entry.value;
                  String fileName = file.path.split('/').last;
                  String fileSize =
                      (file.lengthSync() / 1024).toStringAsFixed(1);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file, color: color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$fileSize KB',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.red,
                          onPressed: () => _removeFile(category, index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Hapus file',
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createRapat() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null) {
      _showErrorSnackbar('Pilih tanggal rapat');
      return;
    }
    if (_selectedStartTime == null) {
      _showErrorSnackbar('Pilih jam mulai rapat');
      return;
    }
    if (_selectedEndTime == null) {
      _showErrorSnackbar('Pilih jam selesai rapat');
      return;
    }
    if (_selectedCabangId == null) {
      _showErrorSnackbar('Pilih cabang');
      return;
    }
    if (_selectedRoomId == null) {
      _showErrorSnackbar('Pilih ruangan rapat');
      return;
    }
    if (_currentUser == null) {
      _showErrorSnackbar('User tidak terautentikasi');
      return;
    }

    final tanggal =
        '${_selectedDate!.year}-${_two(_selectedDate!.month)}-${_two(_selectedDate!.day)}';
    final start =
        '${_two(_selectedStartTime!.hour)}:${_two(_selectedStartTime!.minute)}';
    final end =
        '${_two(_selectedEndTime!.hour)}:${_two(_selectedEndTime!.minute)}';

    setState(() {
      _submitting = true;
    });

    try {
      final List<int> divisionIds =
          _selectedDivisions.map((d) => d.id).toList();
      await _rapatApiService.createRapat(
        idCabang: _selectedCabangId!,
        idRoom: _selectedRoomId!,
        judul: _titleCtrl.text.trim(),
        tanggal: tanggal,
        waktuStart: start,
        waktuEnd: end,
        desc: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        idUserPengaju: _currentUser!.id_user, // Auto-set current PIC user
        divisions: divisionIds, // Mengirim ID divisi
        // TAMBAHAN: Kirim files
        filesMateri: _filesMateri.isEmpty ? null : _filesMateri,
        filesNotulensi: _filesNotulensi.isEmpty ? null : _filesNotulensi,
        filesDokumentasi: _filesDokumentasi.isEmpty ? null : _filesDokumentasi,
        filesLainnya: _filesLainnya.isEmpty ? null : _filesLainnya,
      );

      SnackBarHelper.success(context, 'Rapat berhasil dibuat!');

      if (mounted) {
        Navigator.of(context)
            .pop(true); // Kembali ke halaman sebelumnya dan kirim sinyal sukses
      }
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    SnackBarHelper.error(context, message);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Belum dipilih';
    return time.format(context);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Belum dipilih';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _openParticipantSelector() async {
    if (_loadingInitialData) {
      _showErrorSnackbar('Data pengguna masih dimuat, harap tunggu.');
      return;
    }

    final selected = await Navigator.push<List<Division>>(
      context,
      MaterialPageRoute(
        builder: (_) => ItemSelectorPage<Division>(
          allItems: _allDivisions,
          initialSelection: _selectedDivisions,
          pageTitle: 'Pilih Divisi',
          searchHint: 'Cari nama divisi...',
          itemTitleBuilder: (division) => division.name,
          itemSubtitleBuilder: (division) => 'ID: ${division.id}',
        ),
      ),
    );

    if (selected != null) setState(() => _selectedDivisions = selected);
  }

  // Method untuk compact time item
  Widget _buildCompactTimeItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Color(0xFF1565C0)),
            SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive layout variables
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Buat Rapat Baru',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.event_note,
                            size: isSmallScreen ? 48 : 56, color: Colors.white),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Text(
                          'Formulir Pembuatan Rapat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 20 : 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        Text(
                          'Isi detail rapat untuk dibuat.',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isSmallScreen ? 14 : 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),

                  // Form Card
                  Card(
                    elevation: 4,
                    shadowColor: Colors.grey.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informasi Rapat',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1565C0),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Cabang
                            DropdownButtonFormField<int>(
                              value: _selectedCabangId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: _loadingInitialData
                                    ? 'Memuat Data...'
                                    : 'Pilih Cabang',
                                prefixIcon: const Icon(Icons.business,
                                    color: Color(0xFF1565C0)),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _cabangs.map((e) {
                                final id = (e['id'] ?? e['id_cabang']) as int;
                                final name = (e['cabang'] ??
                                        e['nama_cabang'] ??
                                        'Cabang $id')
                                    .toString();
                                return DropdownMenuItem<int>(
                                    value: id,
                                    child: Text(name,
                                        overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: _loadingInitialData
                                  ? null
                                  : (int? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedCabangId = newValue;
                                        });
                                        _loadRooms();
                                      }
                                    },
                              validator: (v) =>
                                  v == null ? 'Pilih cabang' : null,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Jadwal Rapat - DIPINDAHKAN SETELAH CABANG
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Jadwal Rapat',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1565C0))),
                                  SizedBox(height: 12),

                                  // Horizontal layout
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCompactTimeItem(
                                          icon: Icons.calendar_today,
                                          label: 'Tanggal',
                                          value: _formatDate(_selectedDate),
                                          onTap: _pickDate,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: _buildCompactTimeItem(
                                          icon: Icons.access_time,
                                          label: 'Mulai',
                                          value:
                                              _formatTime(_selectedStartTime),
                                          onTap: _pickStartTime,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: _buildCompactTimeItem(
                                          icon: Icons.timelapse,
                                          label: 'Selesai',
                                          value: _formatTime(_selectedEndTime),
                                          onTap: _pickEndTime,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 12),
                                  // Selesai Tidak Menentu Removed
                                ],
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Ruangan
                            DropdownButtonFormField<int>(
                              value: _selectedRoomId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: _loadingRooms
                                    ? 'Memuat Ruangan...'
                                    : (_selectedCabangId == null ||
                                            _selectedDate == null ||
                                            _selectedStartTime == null
                                        ? 'Pilih Cabang & Waktu Dahulu'
                                        : (_rooms.isEmpty
                                            ? 'Tidak ada ruangan tersedia'
                                            : 'Pilih Ruangan')),
                                prefixIcon: Icon(
                                  Icons.meeting_room_outlined,
                                  color: _selectedCabangId == null
                                      ? Colors.grey
                                      : const Color(0xFF1565C0),
                                ),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                fillColor: _selectedCabangId == null
                                    ? Colors.grey[200]
                                    : null,
                                filled: _selectedCabangId == null,
                              ),
                              items: _rooms.map((e) {
                                final id = e['id_room'] as int?;
                                final name = e['room']?.toString() ??
                                    'Ruangan Tanpa Nama';
                                final statusId = e['status_ruangan_id'] as int?;
                                final isAvailable = statusId == 1;
                                final textColor =
                                    isAvailable ? Colors.black87 : Colors.grey;

                                // Ambil info booking jika tidak tersedia
                                String displayName = name;
                                if (!isAvailable && e['booking_info'] != null) {
                                  final bookingInfo =
                                      e['booking_info'] as Map<String, dynamic>;
                                  final startTime = bookingInfo['waktu_start']
                                          ?.toString()
                                          .substring(0, 5) ??
                                      '';
                                  final endTime =
                                      bookingInfo['waktu_end'] != null
                                          ? bookingInfo['waktu_end']
                                              .toString()
                                              .substring(0, 5)
                                          : 'Tidak Menentu';
                                  displayName =
                                      '$name\n(Terpakai: $startTime - $endTime)';
                                }

                                return DropdownMenuItem<int>(
                                    value: id,
                                    enabled:
                                        isAvailable, // Menonaktifkan item jika tidak tersedia
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: isAvailable
                                                ? Colors.green
                                                : Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text(
                                          displayName,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 13,
                                          ),
                                        )),
                                      ],
                                    ));
                              }).toList(),
                              onChanged: _loadingRooms ||
                                      _selectedCabangId == null ||
                                      _selectedDate == null ||
                                      _selectedStartTime == null ||
                                      _rooms.isEmpty
                                  ? null // Menonaktifkan dropdown
                                  : (int? newValue) {
                                      setState(() {
                                        _selectedRoomId = newValue;
                                      });
                                    },
                              validator: (v) {
                                if (_selectedCabangId != null &&
                                    _selectedDate != null &&
                                    _selectedStartTime != null &&
                                    _rooms.isNotEmpty &&
                                    v == null) {
                                  return 'Pilih ruangan rapat';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Judul Rapat
                            TextFormField(
                              controller: _titleCtrl,
                              decoration: InputDecoration(
                                labelText: 'Judul Rapat',
                                prefixIcon: const Icon(Icons.title,
                                    color: Color(0xFF1565C0)),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Judul wajib diisi'
                                  : null,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Deskripsi Rapat
                            TextFormField(
                              controller: _descriptionCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Deskripsi Rapat (Opsional)',
                                alignLabelWithHint: true,
                                prefixIcon: const Icon(Icons.description,
                                    color: Color(0xFF1565C0)),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Pemilihan Peserta
                            ListTile(
                              // Diubah menjadi pemilihan divisi
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.group_add,
                                  color: Color(0xFF1565C0), size: 28),
                              title: const Text('Divisi Peserta',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${_selectedDivisions.length} divisi dipilih'),
                              trailing: const Icon(Icons.chevron_right),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              onTap: _openParticipantSelector,
                            ),
                            if (_selectedDivisions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: _selectedDivisions
                                      .map((division) =>
                                          Chip(label: Text(division.name)))
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),

                  // TAMBAHAN: File Upload Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upload Dokumen (Opsional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildFilePickerButton(
                              'Materi', 'materi', Colors.blue, _filesMateri),
                          const SizedBox(height: 8),
                          _buildFilePickerButton('Notulensi', 'notulensi',
                              Colors.green, _filesNotulensi),
                          const SizedBox(height: 8),
                          _buildFilePickerButton('Dokumentasi', 'dokumentasi',
                              Colors.cyan, _filesDokumentasi),
                          const SizedBox(height: 8),
                          _buildFilePickerButton(
                              'Lainnya', 'lainnya', Colors.grey, _filesLainnya),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),

                  // Tombol Ajukan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _createRapat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      icon: _submitting
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : const Icon(Icons.send),
                      label: Text(_submitting ? 'Membuat...' : 'Buat Rapat'),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
