import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:absen_app/Models/services/participant_selector_page.dart';
import 'package:flutter/material.dart';
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
  List<Division> _selectedDivisions = [];

  // State untuk tanggal dan waktu (disamakan dengan create_meeting)
  late DateTime _selectedDate;
  late TimeOfDay _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isEndTimeIndefinite = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.rapat.judul);
    _descriptionController =
        TextEditingController(text: widget.rapat.deskripsi);
    _isEndTimeIndefinite = widget.rapat.waktuSelesai == null;

    _selectedDate = widget.rapat.waktuMulai;
    _selectedStartTime = TimeOfDay.fromDateTime(widget.rapat.waktuMulai);
    _selectedEndTime = widget.rapat.waktuSelesai != null
        ? TimeOfDay.fromDateTime(widget.rapat.waktuSelesai!)
        : null;

    _loadInitialData();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memuat data awal: $e'),
              backgroundColor: Colors.red),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memuat ruangan: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingRooms = false);
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
                              if (!_isEndTimeIndefinite)
                                ListTile(
                                  leading: const Icon(Icons.access_time,
                                      color: Colors.red),
                                  title: const Text('Jam Selesai'),
                                  subtitle: Text(_formatTime(_selectedEndTime)),
                                  onTap: _pickEndTime,
                                ),
                              SwitchListTile(
                                title: const Text('Selesai tidak menentu'),
                                value: _isEndTimeIndefinite,
                                onChanged: (value) {
                                  setState(() {
                                    _isEndTimeIndefinite = value;
                                    if (value) _selectedEndTime = null;
                                  });
                                },
                                activeColor: const Color(0xFF1565C0),
                                secondary: const Icon(Icons.help_outline,
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                  label:
                      Text(_isSubmitting ? 'Menyimpan...' : 'Simpan Perubahan'),
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
    final end = !_isEndTimeIndefinite && _selectedEndTime != null
        ? '${_two(_selectedEndTime!.hour)}:${_two(_selectedEndTime!.minute)}'
        : null;

    setState(() => _isSubmitting = true);
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
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Rapat berhasil diperbarui ✅'),
            backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal memperbarui rapat: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
}
