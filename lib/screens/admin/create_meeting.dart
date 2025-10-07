import 'package:absen_app/Models/models/user.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';
import 'package:absen_app/screens/admin/admin_dashboard.dart';
import 'package:absen_app/screens/pic/pic_dashboard.dart' show PICDashboard;
import 'package:absen_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class CreateRapat extends StatefulWidget {
  const CreateRapat({super.key});

  @override
  State<CreateRapat> createState() => _CreateRapatState();
}

class _CreateRapatState extends State<CreateRapat> {
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
  List<Map<String, dynamic>> _rooms = []; // Akan berisi ruangan untuk cabang yang dipilih

  // Variabel State untuk Kontrol UI
  bool _loadingCabang = true; // Hanya untuk memuat data master awal (cabang)
  bool _loadingRooms = false; // Untuk memuat ruangan setelah cabang dipilih
  bool _submitting = false;
  bool _isIndefinite = false;
  AppUser? _currentUser;

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
    setState(() {
      _loadingCabang = true;
    });
    try {
      // Muat data user dan cabang secara bersamaan
      await Future.wait([
        _loadCurrentUser(),
        _loadCabang(),
      ]);
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _loadingCabang = false;
        });
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final authService = AuthService();
      final user = await authService.getProfile();
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
      final svc = RapatApiService();
      final cabangs = await svc.fetchCabang();
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

  // Fungsi baru untuk memuat ruangan berdasarkan cabang yang dipilih
  Future<void> _loadRoomsForCabang(int cabangId) async {
    setState(() {
      _loadingRooms = true;
      _rooms = []; // Kosongkan list ruangan sebelumnya
      _selectedRoomId = null; // Reset pilihan ruangan
    });

    try {
      final svc = RapatApiService();
      final rooms = await svc.fetchRoomsByCabang(cabangId);
      if (mounted) {
        setState(() {
          _rooms = rooms;
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
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF4CAF50),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    setState(() {
      _selectedDate = date;
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
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF4CAF50),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    setState(() {
      _selectedStartTime = time;
      // Jika jam selesai lebih awal dari jam mulai baru, reset jam selesai
      if (_selectedEndTime != null && !_isTimeAfter(time, _selectedEndTime!)) {
        _selectedEndTime = null;
      }
    });
  }

  Future<void> _pickEndTime() async {
    if (_selectedStartTime == null) {
      _showErrorSnackbar('Pilih jam mulai terlebih dahulu');
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.fromDateTime(
        DateTime(0, 0, 0, _selectedStartTime!.hour, _selectedStartTime!.minute)
            .add(const Duration(hours: 1)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF4CAF50),
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
    });
  }

  bool _isTimeAfter(TimeOfDay time1, TimeOfDay time2) {
    final now = DateTime.now();
    final datetime1 = DateTime(now.year, now.month, now.day, time1.hour, time1.minute);
    final datetime2 = DateTime(now.year, now.month, now.day, time2.hour, time2.minute);
    return datetime1.isAfter(datetime2);
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  Future<void> _ajukan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null) {
      _showErrorSnackbar('Pilih tanggal rapat');
      return;
    }
    if (_selectedStartTime == null) {
      _showErrorSnackbar('Pilih jam mulai rapat');
      return;
    }
    if (!_isIndefinite && _selectedEndTime == null) {
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
      _showErrorSnackbar('Data user tidak ditemukan, coba muat ulang halaman');
      return;
    }

    final tanggal = '${_selectedDate!.year}-${_two(_selectedDate!.month)}-${_two(_selectedDate!.day)}';
    final start = '${_two(_selectedStartTime!.hour)}:${_two(_selectedStartTime!.minute)}';
    final end = !_isIndefinite && _selectedEndTime != null
        ? '${_two(_selectedEndTime!.hour)}:${_two(_selectedEndTime!.minute)}'
        : null;

    setState(() {
      _submitting = true;
    });

    try {
      final svc = RapatApiService();
      await svc.createRapat(
        idCabang: _selectedCabangId!,
        idRoom: _selectedRoomId!,
        judul: _titleCtrl.text.trim(),
        tanggal: tanggal,
        waktuStart: start,
        waktuEnd: end,
        desc: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Pengajuan rapat berhasil dikirim'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
              (route) => false,
        );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Belum dipilih';
    return time.format(context);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Belum dipilih';
    return '${date.day}/${date.month}/${date.year}';
  }


  @override
  Widget build(BuildContext context) {
    // Responsive layout variables
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Ajukan Rapat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
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
                      gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.event_note, size: isSmallScreen ? 48 : 56, color: Colors.white),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Text(
                          'Formulir Pengajuan Rapat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 20 : 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        Text(
                          'Isi detail rapat untuk diajukan kepada Admin.',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: isSmallScreen ? 14 : 16),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informasi Pengajuan',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Cabang
                            DropdownButtonFormField<int>(
                              value: _selectedCabangId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: _loadingCabang ? 'Memuat Cabang...' : 'Pilih Cabang',
                                prefixIcon: const Icon(Icons.business, color: Color(0xFF4CAF50)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _cabangs.map((e) {
                                final id = (e['id'] ?? e['id_cabang']) as int;
                                final name = (e['nama'] ?? e['name'] ?? e['cabang'] ?? 'Cabang $id').toString();
                                return DropdownMenuItem<int>(value: id, child: Text(name, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: _loadingCabang ? null : (int? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedCabangId = newValue;
                                  });
                                  _loadRoomsForCabang(newValue);
                                }
                              },
                              validator: (v) => v == null ? 'Pilih cabang' : null,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Ruangan
                            DropdownButtonFormField<int>(
                              value: _selectedRoomId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: _loadingRooms
                                    ? 'Memuat Ruangan...'
                                    : (_selectedCabangId == null
                                    ? 'Pilih Cabang Terlebih Dahulu'
                                    : (_rooms.isEmpty ? 'Tidak ada ruangan tersedia' : 'Pilih Ruangan')),
                                prefixIcon: Icon(
                                  Icons.meeting_room,
                                  color: _selectedCabangId == null ? Colors.grey : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                fillColor: _selectedCabangId == null ? Colors.grey[200] : null,
                                filled: _selectedCabangId == null,
                              ),
                              items: _rooms.map((e) {
                                final id = e['id_room'] as int;
                                final name = e['room']?.toString() ?? 'Ruangan Tanpa Nama';
                                return DropdownMenuItem<int>(value: id, child: Text(name, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: _loadingRooms || _selectedCabangId == null || _rooms.isEmpty
                                  ? null // Menonaktifkan dropdown
                                  : (int? newValue) {
                                setState(() {
                                  _selectedRoomId = newValue;
                                });
                              },
                              validator: (v) {
                                if (_selectedCabangId != null && _rooms.isNotEmpty && v == null) {
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
                                prefixIcon: const Icon(Icons.title, color: Color(0xFF4CAF50)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Deskripsi Rapat
                            TextFormField(
                              controller: _descriptionCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Deskripsi Rapat (Opsional)',
                                alignLabelWithHint: true,
                                prefixIcon: const Icon(Icons.description, color: Color(0xFF4CAF50)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Penanggung Jawab
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person, color: Color(0xFF4CAF50)),
                                  const SizedBox(width: 12),
                                  const Text('Penanggung Jawab: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      _currentUser?.name ?? 'Memuat...',
                                      style: const TextStyle(fontWeight: FontWeight.normal),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Jadwal Rapat
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
                                  const Text('Jadwal Rapat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4CAF50))),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(Icons.calendar_today, color: Color(0xFF4CAF50)),
                                    title: const Text('Tanggal'),
                                    subtitle: Text(_formatDate(_selectedDate)),
                                    onTap: _pickDate,
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.access_time_filled, color: Colors.green),
                                    title: const Text('Jam Mulai'),
                                    subtitle: Text(_formatTime(_selectedStartTime)),
                                    onTap: _pickStartTime,
                                  ),
                                  if (!_isIndefinite)
                                    ListTile(
                                      leading: const Icon(Icons.access_time, color: Colors.red),
                                      title: const Text('Jam Selesai'),
                                      subtitle: Text(_formatTime(_selectedEndTime)),
                                      onTap: _pickEndTime,
                                    ),
                                  SwitchListTile(
                                    title: const Text('Selesai tidak menentu'),
                                    value: _isIndefinite,
                                    onChanged: (value) {
                                      setState(() {
                                        _isIndefinite = value;
                                        if (value) _selectedEndTime = null;
                                      });
                                    },
                                    activeColor: const Color(0xFF4CAF50),
                                    secondary: const Icon(Icons.help_outline, color: Colors.grey),
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

                  // Tombol Ajukan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _ajukan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      icon: _submitting
                          ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                          : const Icon(Icons.send),
                      label: Text(_submitting ? 'Mengirim...' : 'Ajukan ke Admin'),
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