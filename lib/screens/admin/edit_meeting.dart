import 'package:absen_app/Models/models/rapat.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  bool _isDeleting = false; // <-- State untuk tombol delete
  bool _isLoadingRooms = false;

  // Controller
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  // State untuk data dropdown
  List<Map<String, dynamic>> _cabangList = [];
  List<Map<String, dynamic>> _ruanganList = [];
  List<Map<String, dynamic>> _userList = [];

  // <-- TAMBAHAN: Daftar status rapat (hardcoded)
  final List<Map<String, dynamic>> _statusList = [
    {'id': 1, 'name': 'Menunggu'},
    {'id': 2, 'name': 'Disetujui'},
    {'id': 3, 'name': 'Berlangsung'},
    {'id': 4, 'name': 'Selesai'},
    {'id': 5, 'name': 'Ditolak'},
  ];

  // State untuk nilai terpilih
  late int _selectedCabangId;
  int? _selectedRuanganId;
  late int _selectedPengajuId;
  late int _selectedStatusId; // <-- State untuk status terpilih
  late DateTime _selectedStartTime;
  DateTime? _selectedEndTime;
  bool _isEndTimeIndefinite = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.rapat.judul);
    _descriptionController = TextEditingController(text: widget.rapat.deskripsi);
    _selectedCabangId = widget.rapat.idCabang;
    _selectedRuanganId = widget.rapat.idRuangan;
    _selectedPengajuId = widget.rapat.idPengaju;
    _selectedStatusId = widget.rapat.idStatus; // <-- Inisialisasi status
    _selectedStartTime = widget.rapat.waktuMulai;
    _selectedEndTime = widget.rapat.waktuSelesai;
    _isEndTimeIndefinite = widget.rapat.waktuSelesai == null;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingDependencies = true);
    try {
      final results = await Future.wait([
        _rapatApiService.fetchCabang(),
        _rapatApiService.fetchRoomsByCabang(_selectedCabangId),
        _rapatApiService.fetchUsers(),
      ]);
      _cabangList = results[0];
      _ruanganList = results[1];
      _userList = results[2];

      if (!_ruanganList.any((r) => r['id_room'] == _selectedRuanganId)) {
        _selectedRuanganId = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data awal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingDependencies = false);
    }
  }

  Future<void> _fetchRoomsForSelectedCabang(int idCabang) async {
    setState(() {
      _isLoadingRooms = true;
      _ruanganList = [];
      _selectedRuanganId = null;
    });
    try {
      final rooms = await _rapatApiService.fetchRoomsByCabang(idCabang);
      if (mounted) setState(() => _ruanganList = rooms);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat ruangan: $e'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Edit Rapat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        // <-- TAMBAHAN: Tombol Delete di AppBar
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.delete_outline),
            onPressed: _isDeleting ? null : _showDeleteConfirmation,
          ),
        ],
      ),
      body: _isLoadingDependencies
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Detail Rapat', Icons.article),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _titleController,
                      label: 'Judul Rapat',
                      icon: Icons.title,
                      validator: (value) => value == null || value.isEmpty ? 'Judul tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _descriptionController,
                      label: 'Deskripsi',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // <-- TAMBAHAN: Dropdown Status
                    _buildDropdownField<int>(
                      value: _selectedStatusId,
                      items: _statusList.map((status) {
                        return DropdownMenuItem<int>(
                          value: status['id'],
                          child: Text(status['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedStatusId = value);
                      },
                      label: 'Status Rapat',
                      icon: Icons.flag,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Logistik', Icons.business),
                    const SizedBox(height: 16),
                    _buildDropdownField<int>(
                      value: _selectedCabangId,
                      items: _cabangList.map((cabang) => DropdownMenuItem<int>(value: cabang['id'], child: Text(cabang['cabang']))).toList(),
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
                      const Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Center(child: CircularProgressIndicator()))
                    else
                      _buildDropdownField<int?>(
                        value: _selectedRuanganId,
                        items: _ruanganList.map((ruangan) => DropdownMenuItem<int>(value: ruangan['id_room'], child: Text(ruangan['room']))).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedRuanganId = value);
                        },
                        label: 'Pilih Ruangan',
                        icon: Icons.meeting_room,
                      ),
                    const SizedBox(height: 16),
                    _buildDropdownField<int>(
                      value: _selectedPengajuId,
                      items: _userList.map((user) => DropdownMenuItem<int>(value: user['id_user'], child: Text(user['name']))).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedPengajuId = value);
                      },
                      label: 'Penanggung Jawab',
                      icon: Icons.person,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Jadwal', Icons.calendar_today),
                    const SizedBox(height: 16),
                    _buildDateTimePicker(
                      label: 'Waktu Mulai',
                      dateTime: _selectedStartTime,
                      onTap: () => _selectDateTime(isStartTime: true),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Waktu selesai tidak menentu', style: TextStyle(fontSize: 15)),
                      value: _isEndTimeIndefinite,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _isEndTimeIndefinite = newValue ?? false;
                          if (_isEndTimeIndefinite) {
                            _selectedEndTime = null;
                          } else {
                            _selectedEndTime = _selectedStartTime;
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF1565C0),
                    ),
                    if (!_isEndTimeIndefinite)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _buildDateTimePicker(
                          label: 'Waktu Selesai',
                          dateTime: _selectedEndTime,
                          onTap: () => _selectDateTime(isStartTime: false),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _updateMeeting,
              icon: _isSubmitting ? const SizedBox() : const Icon(Icons.save, color: Colors.white),
              label: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Update Rapat', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
      ],
    );
  }

  Widget _buildTextFormField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2)),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField<T>({required T value, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged, required String label, required IconData icon}) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.isEmpty ? null : items,
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

  Widget _buildDateTimePicker({required String label, required DateTime? dateTime, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF1565C0)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dateTime != null ? DateFormat('EEEE, dd MMM yyyy HH:mm', 'id_ID').format(dateTime) : 'Pilih waktu...',
                    style: TextStyle(fontSize: 16, color: dateTime != null ? Colors.black87 : Colors.grey),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- LOGIC FUNCTIONS ---
  Future<void> _selectDateTime({required bool isStartTime}) async {
    final selectedDate = await showDatePicker(context: context, initialDate: (isStartTime ? _selectedStartTime : _selectedEndTime) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (selectedDate == null) return;
    final selectedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime((isStartTime ? _selectedStartTime : _selectedEndTime) ?? DateTime.now()));
    if (selectedTime == null) return;
    final finalDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
    setState(() {
      if (isStartTime) {
        _selectedStartTime = finalDateTime;
      } else {
        _selectedEndTime = finalDateTime;
      }
    });
  }

  void _updateMeeting() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _rapatApiService.updateRapat(
        idRapat: widget.rapat.idRapat,
        judul: _titleController.text.trim(),
        desc: _descriptionController.text.trim(),
        idCabang: _selectedCabangId,
        idRuangan: _selectedRuanganId!,
        idPengaju: _selectedPengajuId,
        idStatus: _selectedStatusId, // <-- Kirim status ID yang baru
        tanggal: DateFormat('yyyy-MM-dd').format(_selectedStartTime),
        waktuStart: DateFormat('HH:mm').format(_selectedStartTime),
        waktuEnd: _selectedEndTime != null ? DateFormat('HH:mm').format(_selectedEndTime!) : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapat berhasil diperbarui ✅'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui rapat: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // <-- FUNGSI BARU UNTUK DELETE -->
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus rapat "${widget.rapat.judul}"? Tindakan ini tidak dapat diurungkan.'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapat berhasil dihapus 🗑️'), backgroundColor: Colors.orange));
        // Pop dua kali: sekali untuk halaman edit, sekali lagi agar dashboard refresh
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus rapat: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}