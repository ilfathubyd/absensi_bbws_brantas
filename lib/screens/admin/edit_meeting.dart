import 'dart:io';
import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:absen_app/Models/services/participant_selector_page.dart';
import 'package:absen_app/services/file_upload_service.dart';
import 'package:absen_app/widgets/upload_progress_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:absen_app/utils/snackbar_helper.dart';
import 'package:intl/intl.dart';
import 'package:absen_app/Models/models/division.dart';

class EditMeeting extends StatefulWidget {
  final Rapat rapat;
  const EditMeeting({super.key, required this.rapat});

  @override
  State<EditMeeting> createState() => _EditMeetingState();
}

class _EditMeetingState extends State<EditMeeting> {
  final _formKey = GlobalKey<FormState>();
  final RapatApiService _rapatApiService = RapatApiService();

  // State untuk loading dan proses
  bool _isLoadingDependencies = true;
  bool _isSubmitting = false;
  bool _isDeleting = false;
  bool _isLoadingRooms = false;

  // Controller
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  // State untuk data dropdown
  List<Map<String, dynamic>> _cabangList = [];
  List<Map<String, dynamic>> _ruanganList = [];
  List<Map<String, dynamic>> _userList = []; // Untuk pengaju
  List<Division> _allDivisions = []; // Untuk peserta

  final List<Map<String, dynamic>> _statusList = [
    {'id': 1, 'name': 'Menunggu'},
    {'id': 2, 'name': 'Disetujui'},
    {'id': 3, 'name': 'Ditolak'},
    {'id': 4, 'name': 'Berlangsung'},
    {'id': 5, 'name': 'Selesai'},
  ];

  // State untuk nilai terpilih
  int? _selectedCabangId;
  int? _selectedRuanganId;
  String? _selectedPengajuId;
  int? _selectedStatusId;

  // TAMBAHAN: File upload state
  List<File> _filesMateri = [];
  List<File> _filesNotulensi = [];
  List<File> _filesDokumentasi = [];
  List<File> _filesLainnya = [];

  // Upload progress tracking
  bool _isUploadingFiles = false;
  double _uploadProgress = 0.0;

  // State untuk existing files dari server
  List<Map<String, dynamic>> _existingFiles = [];
  bool _isLoadingFiles = false;
  List<Division> _selectedDivisions = [];

  // State untuk tanggal dan waktu (disamakan dengan create_meeting)
  late DateTime _selectedDate;
  late TimeOfDay _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isEndTimeIndefinite =
      false; // Unused but kept to match state initialization if needed, or remove completely. Better remove logic.

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.rapat.judul);
    _descriptionController =
        TextEditingController(text: widget.rapat.deskripsi);
    // _isEndTimeIndefinite = widget.rapat.waktuSelesai == null;

    _selectedDate = widget.rapat.waktuMulai;
    _selectedStartTime = TimeOfDay.fromDateTime(widget.rapat.waktuMulai);
    _selectedEndTime = widget.rapat.waktuSelesai != null
        ? TimeOfDay.fromDateTime(widget.rapat.waktuSelesai!)
        : null;

    _loadInitialData();
    _loadExistingFiles();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingDependencies = true);
    try {
      // Ambil semua data dari API secara bersamaan
      final results = await Future.wait([
        _rapatApiService.fetchCabang(),
        // Ambil ruangan berdasarkan cabang awal dari rapat yang diedit
        _rapatApiService.fetchRoomsByCabang(widget.rapat.idCabang),
        // PERBAIKAN: Urutan fetch ditukar agar sesuai
        _rapatApiService.fetchUsers(), // fetch divisions (untuk peserta)
        _rapatApiService
            .fetchUsersPIC(), // fetch PIC users (untuk penanggung jawab)
      ]);

      setState(() {
        _cabangList = results[0] as List<Map<String, dynamic>>;
        _ruanganList = results[1];
        final divisionsData = results[2] as List<Map<String, dynamic>>;
        _userList = results[3]; // <-- Diambil dari hasil ke-4
        _allDivisions =
            divisionsData.map((json) => Division.fromJson(json)).toList();

        if (_cabangList.any((c) => c['id'] == widget.rapat.idCabang)) {
          _selectedCabangId = widget.rapat.idCabang;
        }

        if (_ruanganList.any((r) => r['id_room'] == widget.rapat.idRuangan)) {
          _selectedRuanganId = widget.rapat.idRuangan;
        }

        if (_userList
            .any((u) => u['id_user']?.toString() == widget.rapat.idPengaju)) {
          _selectedPengajuId = widget.rapat.idPengaju;
        }

        final initialStatus = _statusList.firstWhere(
          (s) => s['name'] == widget.rapat.statusRapat,
          orElse: () => {'id': 1},
        );
        _selectedStatusId = initialStatus['id'];

        _selectedDivisions = _allDivisions
            .where((div) => widget.rapat.divisions
                .any((selectedDiv) => selectedDiv['id_division'] == div.id))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.error(context, 'Gagal memuat data awal: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingDependencies = false);
    }
  }

  Future<void> _fetchRoomsForSelectedCabang(int idCabang) async {
    setState(() {
      _isLoadingRooms = true;
      _ruanganList = []; // Kosongkan daftar ruangan
      _selectedRuanganId = null; // Reset pilihan ruangan
    });
    try {
      final rooms = await _rapatApiService.fetchRoomsByCabang(idCabang);
      if (mounted) setState(() => _ruanganList = rooms);
    } catch (e) {
      if (mounted) {
        SnackBarHelper.error(context, 'Gagal memuat ruangan: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingRooms = false);
    }
  }

  Future<void> _loadExistingFiles() async {
    setState(() => _isLoadingFiles = true);
    try {
      final rapatDetail =
          await _rapatApiService.fetchRapatDetail(widget.rapat.idRapat);
      final files = rapatDetail['files'] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          _existingFiles = files.map((f) => f as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.error(context, 'Gagal memuat file: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingFiles = false);
    }
  }

  Future<void> _deleteExistingFile(String fileId) async {
    try {
      await _rapatApiService.deleteFile(fileId);

      setState(() {
        _existingFiles.removeWhere((f) => f['id_file'].toString() == fileId);
      });

      if (mounted) {
        SnackBarHelper.success(context, 'File berhasil dihapus');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.error(context, 'Gagal menghapus file: $e');
      }
    }
  }

  int _getCategoryId(String category) {
    switch (category) {
      case 'materi':
        return 1;
      case 'notulensi':
        return 2;
      case 'dokumentasi':
        return 3;
      case 'lainnya':
        return 4;
      default:
        return 4;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectParticipants() async {
    final result = await Navigator.push<List<Division>>(
      context,
      MaterialPageRoute(
        builder: (context) => ItemSelectorPage<Division>(
          pageTitle: 'Pilih Peserta (Divisi)',
          allItems: _allDivisions,
          initialSelection: _selectedDivisions,
          itemTitleBuilder: (item) => item.name,
          itemSubtitleBuilder: (item) => 'ID: ${item.id}',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDivisions = result;
      });
    }
  }

  // Fungsi untuk memilih tanggal & waktu (disamakan dengan create_meeting)
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
    );
    if (time != null) setState(() => _selectedStartTime = time);
  }

  Future<void> _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? _selectedStartTime,
    );
    if (time != null) {
      final now = DateTime.now();
      final startDateTime = DateTime(now.year, now.month, now.day,
          _selectedStartTime.hour, _selectedStartTime.minute);
      final endDateTime =
          DateTime(now.year, now.month, now.day, time.hour, time.minute);

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Waktu selesai tidak boleh sebelum waktu mulai'),
          backgroundColor: Colors.red,
        ));
      } else {
        setState(() => _selectedEndTime = time);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Belum dipilih';
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Belum dipilih';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Edit Rapat',
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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus Rapat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoadingDependencies
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return SingleChildScrollView(
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
                    Icon(Icons.edit_note,
                        size: isSmallScreen ? 48 : 56, color: Colors.white),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Text(
                      'Formulir Edit Rapat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.bold,
                      ),
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
                        _buildSectionHeader('Informasi Rapat', Icons.article),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _titleController,
                          label: 'Judul Rapat',
                          icon: Icons.title,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Judul tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _descriptionController,
                          label: 'Deskripsi',
                          icon: Icons.description,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField<int?>(
                          value: _selectedStatusId, // Sudah nullable
                          items: _statusList.map((status) {
                            return DropdownMenuItem<int>(
                              value: status['id'],
                              child: Text(status['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null)
                              setState(() => _selectedStatusId = value);
                          },
                          label: 'Status Rapat',
                          icon: Icons.flag,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                            'Logistik & Peserta', Icons.business),
                        const SizedBox(height: 16),
                        _buildDropdownField<int?>(
                          value: _selectedCabangId, // Sudah nullable
                          items: _cabangList.map((cabang) {
                            final id = cabang['id'] as int;
                            // PERBAIKAN: Menangani jika nama cabang null atau key berbeda
                            final name = (cabang['cabang'] ??
                                    cabang['nama'] ??
                                    'Cabang Tanpa Nama')
                                .toString();
                            return DropdownMenuItem<int>(
                                value: id, child: Text(name));
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && value != _selectedCabangId) {
                              setState(() => _selectedCabangId = value);
                              _fetchRoomsForSelectedCabang(value);
                            }
                          },
                          label: 'Pilih Cabang',
                          icon: Icons.location_city,
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingRooms)
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(child: CircularProgressIndicator()))
                        else
                          _buildDropdownField<int?>(
                            value: _selectedRuanganId,
                            items: _ruanganList.map((ruangan) {
                              final id = ruangan['id_room'] as int;
                              // PERBAIKAN: Menangani jika nama ruangan null
                              final name =
                                  (ruangan['room'] ?? 'Ruangan Tanpa Nama')
                                      .toString();
                              return DropdownMenuItem<int>(
                                  value: id, child: Text(name));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null)
                                setState(() => _selectedRuanganId = value);
                            },
                            label: 'Pilih Ruangan',
                            icon: Icons.meeting_room,
                          ),
                        const SizedBox(height: 16),
                        _buildDropdownField<String?>(
                          value: _selectedPengajuId, // Sudah nullable
                          items: _userList.map((user) {
                            // Pastikan key 'id_user' ada dan diubah ke String
                            final id = user['id_user']?.toString();
                            // PERBAIKAN: Menangani jika nama user null
                            final name =
                                (user['name'] ?? 'User Tanpa Nama').toString();
                            return DropdownMenuItem<String>(
                                value: id, child: Text(name));
                          }).toList(),
                          onChanged: (value) {
                            if (value != null)
                              setState(() => _selectedPengajuId = value);
                          },
                          label: 'Penanggung Jawab',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.group_add,
                              color: Color(0xFF1565C0), size: 28),
                          title: const Text('Divisi Peserta',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${_selectedDivisions.length} divisi dipilih'),
                          trailing: const Icon(Icons.chevron_right),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          onTap: _selectParticipants,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                  'Jadwal Rapat', Icons.calendar_today),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.calendar_today,
                                    color: Color(0xFF1565C0)),
                                title: const Text('Tanggal'),
                                subtitle: Text(_formatDate(_selectedDate)),
                                onTap: _pickDate,
                              ),
                              ListTile(
                                leading: const Icon(Icons.access_time_filled,
                                    color: Colors.green),
                                title: const Text('Jam Mulai'),
                                subtitle: Text(_formatTime(_selectedStartTime)),
                                onTap: _pickStartTime,
                              ),
                              ListTile(
                                leading: const Icon(Icons.access_time,
                                    color: Colors.red),
                                title: const Text('Jam Selesai'),
                                subtitle: Text(_formatTime(_selectedEndTime)),
                                onTap: _pickEndTime,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // File Management Section
              SizedBox(height: isSmallScreen ? 24 : 32),
              _buildFileManagementSection(isSmallScreen),

              SizedBox(height: isSmallScreen ? 24 : 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _updateMeeting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  icon: _isSubmitting
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                        )
                      : const Icon(Icons.save_as),
                  label: Text(_isSubmitting
                      ? (_isUploadingFiles
                          ? 'Mengupload File...'
                          : 'Menyimpan...')
                      : 'Simpan Perubahan'),
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0))),
      ],
    );
  }

  Widget _buildTextFormField(
      {TextEditingController? controller,
      required String label,
      required IconData icon,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2)),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDropdownField<T>(
      {required T value,
      required List<DropdownMenuItem<T>> items,
      required void Function(T?) onChanged,
      required String label,
      required IconData icon}) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.isEmpty ? [] : items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) => value == null ? '$label harus dipilih' : null,
      isExpanded: true,
    );
  }

  void _updateMeeting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCabangId == null ||
        _selectedRuanganId == null ||
        _selectedPengajuId == null ||
        _selectedStatusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Harap lengkapi semua field dropdown'),
          backgroundColor: Colors.red));
      return;
    }

    final tanggal =
        '${_selectedDate.year}-${_two(_selectedDate.month)}-${_two(_selectedDate.day)}';
    final start =
        '${_two(_selectedStartTime.hour)}:${_two(_selectedStartTime.minute)}';
    final end =
        '${_two(_selectedEndTime!.hour)}:${_two(_selectedEndTime!.minute)}';

    setState(() {
      _isSubmitting = true;
      _isUploadingFiles = true;
      _uploadProgress = 0.0;
    });

    // Show progress dialog if there are files to upload
    final totalFiles = _filesMateri.length +
        _filesNotulensi.length +
        _filesDokumentasi.length +
        _filesLainnya.length;

    if (totalFiles > 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UploadProgressDialog(
          progress: _uploadProgress,
          currentFile: 1,
          totalFiles: totalFiles,
        ),
      );
    }

    try {
      await _rapatApiService.updateRapat(
        idRapat: widget.rapat.idRapat,
        judul: _titleController.text.trim(),
        desc: _descriptionController.text.trim(),
        idCabang: _selectedCabangId!,
        idRuangan: _selectedRuanganId!,
        idPengaju: _selectedPengajuId, // Kirim ID pengaju (String) jika diubah
        idStatus: _selectedStatusId!,
        tanggal: tanggal,
        waktuStart: start,
        waktuEnd: end,
        divisionIds: _selectedDivisions.map((d) => d.id).toList(),
        // Add files
        filesMateri: _filesMateri.isEmpty ? null : _filesMateri,
        filesNotulensi: _filesNotulensi.isEmpty ? null : _filesNotulensi,
        filesDokumentasi: _filesDokumentasi.isEmpty ? null : _filesDokumentasi,
        filesLainnya: _filesLainnya.isEmpty ? null : _filesLainnya,
      );

      if (mounted) {
        // Close progress dialog if it was shown
        if (totalFiles > 0) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Rapat berhasil diperbarui ✅'),
            backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // Close progress dialog if it was shown
        if (totalFiles > 0) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal memperbarui rapat: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted)
        setState(() {
          _isSubmitting = false;
          _isUploadingFiles = false;
        });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
            'Apakah Anda yakin ingin menghapus rapat "${widget.rapat.judul}"? Tindakan ini tidak dapat diurungkan.'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteMeeting();
            },
          ),
        ],
      ),
    );
  }

  void _deleteMeeting() async {
    setState(() => _isDeleting = true);
    try {
      await _rapatApiService.deleteRapat(widget.rapat.idRapat);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Rapat berhasil dihapus 🗑️'),
            backgroundColor: Colors.orange));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal menghapus rapat: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ============ FILE MANAGEMENT METHODS ============

  Widget _buildFileManagementSection(bool isSmallScreen) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Lampiran File Rapat', Icons.attach_file),
            const SizedBox(height: 16),

            // Instructions
            if (_existingFiles.isEmpty &&
                _filesMateri.isEmpty &&
                _filesNotulensi.isEmpty &&
                _filesDokumentasi.isEmpty &&
                _filesLainnya.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Belum ada file terlampir. Klik tombol "Pilih" untuk menambahkan file.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Existing Files Section
            if (_isLoadingFiles)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_existingFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'File yang Sudah Terlampir',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              _buildExistingFilesGrid(),
              const Divider(height: 32),
            ],

            const SizedBox(height: 16),

            // File picker sections for each category
            _buildFilePickerButton(
              'Materi',
              'materi',
              const Color(0xFF2563EB),
              _filesMateri,
            ),
            const SizedBox(height: 16),
            _buildFilePickerButton(
              'Notulensi',
              'notulensi',
              const Color(0xFF10B981),
              _filesNotulensi,
            ),
            const SizedBox(height: 16),
            _buildFilePickerButton(
              'Dokumentasi',
              'dokumentasi',
              const Color(0xFFF59E0B),
              _filesDokumentasi,
            ),
            const SizedBox(height: 16),
            _buildFilePickerButton(
              'Lainnya',
              'lainnya',
              const Color(0xFF8B5CF6),
              _filesLainnya,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingFilesGrid() {
    // Group files by category
    final filesByCategory = <String, List<Map<String, dynamic>>>{};
    for (var file in _existingFiles) {
      final categoryId = file['id_category']?.toString() ?? '4';
      String categoryName;
      switch (categoryId) {
        case '1':
          categoryName = 'Materi';
          break;
        case '2':
          categoryName = 'Notulensi';
          break;
        case '3':
          categoryName = 'Dokumentasi';
          break;
        default:
          categoryName = 'Lainnya';
      }
      filesByCategory.putIfAbsent(categoryName, () => []);
      filesByCategory[categoryName]!.add(file);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filesByCategory.entries.map((entry) {
        final categoryName = entry.key;
        final files = entry.value;
        Color categoryColor;
        switch (categoryName) {
          case 'Materi':
            categoryColor = const Color(0xFF2563EB);
            break;
          case 'Notulensi':
            categoryColor = const Color(0xFF10B981);
            break;
          case 'Dokumentasi':
            categoryColor = const Color(0xFFF59E0B);
            break;
          default:
            categoryColor = const Color(0xFF8B5CF6);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                ],
              ),
            ),
            ...files.map((file) => _buildExistingFileItem(file, categoryColor)),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildExistingFileItem(Map<String, dynamic> file, Color color) {
    final fileName = file['file_name']?.toString() ?? 'Unknown';
    final fileId = file['id_file']?.toString() ?? '';
    final fileExt = fileName.split('.').last.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              fileExt,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
        title: Text(
          fileName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'File terlampir',
          style: TextStyle(
            fontSize: 11,
            color: color.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: () => _confirmDeleteExistingFile(fileId, fileName),
          tooltip: 'Hapus',
        ),
      ),
    );
  }

  Widget _buildFilePickerButton(
    String label,
    String category,
    Color color,
    List<File> files,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(_getCategoryIcon(category), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        '${files.length} file${files.length != 1 ? 's' : ''} baru dipilih',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickFiles(category),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Pilih', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // New file list
          if (files.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: files.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final file = files[index];
                final fileName = FileUploadService.getFileName(file);
                final fileSize = FileUploadService.getFileSize(file);
                final fileExt = FileUploadService.getFileExtension(file);

                return Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          fileExt,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      fileSize,
                      style: TextStyle(
                        fontSize: 10,
                        color: color.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.close, color: Colors.red, size: 18),
                      onPressed: () => _removeFile(category, index),
                      tooltip: 'Hapus',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'materi':
        return Icons.book_rounded;
      case 'notulensi':
        return Icons.edit_note_rounded;
      case 'dokumentasi':
        return Icons.image_rounded;
      case 'lainnya':
        return Icons.folder_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Future<void> _pickFiles(String category) async {
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
        List<File> selectedFiles =
            result.paths.map((path) => File(path!)).toList();

        // Validate each file
        List<File> validFiles = [];
        for (var file in selectedFiles) {
          StringBuffer errorMsg = StringBuffer();
          if (FileUploadService.validateFile(file, errorMessage: errorMsg)) {
            validFiles.add(file);
          } else {
            SnackBarHelper.error(context, errorMsg.toString());
          }
        }

        if (validFiles.isNotEmpty) {
          setState(() {
            switch (category) {
              case 'materi':
                _filesMateri.addAll(validFiles);
                break;
              case 'notulensi':
                _filesNotulensi.addAll(validFiles);
                break;
              case 'dokumentasi':
                _filesDokumentasi.addAll(validFiles);
                break;
              case 'lainnya':
                _filesLainnya.addAll(validFiles);
                break;
            }
          });

          SnackBarHelper.success(
            context,
            '✓ ${validFiles.length} file ditambahkan ke $category',
          );
        }
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

  void _confirmDeleteExistingFile(String fileId, String fileName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus File'),
        content: Text(
            'Apakah Anda yakin ingin menghapus file "$fileName"? Tindakan ini tidak dapat diurungkan.'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteExistingFile(fileId);
            },
          ),
        ],
      ),
    );
  }
}
