import 'package:absen_app/Models/models/meeting.dart';
import 'package:absen_app/Models/models/meeting_request.dart';
import 'package:absen_app/Models/services/meeting_repo.dart' show MeetingRepo;
import 'package:absen_app/Models/services/meeting_request_repo.dart';
import 'package:flutter/material.dart';
import 'package:absen_app/screens/pic/pic_dashboard.dart' show PICDashboard;
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

class CreatePengajuan extends StatefulWidget {
  const CreatePengajuan({super.key});

  @override
  State<CreatePengajuan> createState() => _CreatePengajuanState();
}

class _CreatePengajuanState extends State<CreatePengajuan> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController(); // Tambahan field deskripsi
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  String? _selectedRoom;
  String? _selectedResponsible;
  bool _isIndefinite = false;
  bool _isPending = true; // Status pengajuan (pending/approved)

  // List ruangan yang tersedia
  final List<String> _availableRooms = [
    'Ruang Rapat A',
    'Ruang Rapat B',
    'Ruang Rapat C',
    'Ruang Konferensi',
    'Auditorium',
    'Meeting Room 1',
    'Meeting Room 2',
    'Ruang Diskusi',
  ];

  // List penanggung jawab yang tersedia
  final List<String> _availableResponsible = [
    'Ahmad Fadli',
    'Siti Nurhaliza',
    'Budi Santoso',
    'Maya Sari',
    'Dedi Kurniawan',
    'Rina Wijayanti',
    'Agus Prasetyo',
    'Lina Maharani',
    'Rudi Hermawan',
    'Dewi Kartika',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50), // Hijau untuk PIC
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
      initialTime: TimeOfDay.now(),
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
      if (_selectedEndTime == null || _isTimeAfter(time, _selectedEndTime!)) {
        _selectedEndTime = null;
      }
    });
  }

  Future<void> _pickEndTime() async {
    if (_selectedStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih jam mulai terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 1)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Jam selesai harus setelah jam mulai'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _ajukan() {
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
    if (_selectedRoom == null) {
      _showErrorSnackbar('Pilih ruangan rapat');
      return;
    }
    if (_selectedResponsible == null) {
      _showErrorSnackbar('Pilih penanggung jawab');
      return;
    }

    // Combine date dengan start time
    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );

    // Combine date dengan end time (jika tidak indefinite)
    DateTime? endDateTime;
    if (!_isIndefinite && _selectedEndTime != null) {
      endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedEndTime!.hour,
        _selectedEndTime!.minute,
      );
    }

    // Untuk PIC, buat meeting dengan status pending
    // Di kode PIC ketika mengajukan rapat
MeetingRequestRepo.add(MeetingRequest(
  id: 'unique_id_${DateTime.now().millisecondsSinceEpoch}',
  title: _titleCtrl.text.trim(),
  description: _descriptionCtrl.text.trim(),
  room: _selectedRoom!,
  proposedTime: DateTime.now().add(const Duration(days: 2)),
  requester: _selectedResponsible!,
  requesterId: 'user_id_pic',
  requestTime: DateTime.now(),
  status: 'pending',
));

    // Tampilkan konfirmasi pengajuan berhasil
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Pengajuan rapat berhasil dikirim ke Admin'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    // Kembali ke PIC Dashboard setelah pengajuan
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PICDashboard()),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Belum dipilih';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Ajukan Rapat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4CAF50), // Hijau untuk PIC
                Color(0xFF66BB6A),
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.event_note, size: 48, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Ajukan Rapat Baru',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ajukan rapat untuk disetujui Admin',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul Rapat
                        const Text(
                          'Informasi Pengajuan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _titleCtrl,
                          decoration: InputDecoration(
                            labelText: 'Judul Rapat',
                            prefixIcon: const Icon(
                              Icons.title,
                              color: Color(0xFF4CAF50),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF4CAF50),
                                width: 2,
                              ),
                            ),
                            labelStyle: const TextStyle(
                              color: Color(0xFF4CAF50),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Judul wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // Deskripsi Rapat
                        TextFormField(
                          controller: _descriptionCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi Rapat (Opsional)',
                            alignLabelWithHint: true,
                            prefixIcon: const Icon(
                              Icons.description,
                              color: Color(0xFF4CAF50),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF4CAF50),
                                width: 2,
                              ),
                            ),
                            labelStyle: const TextStyle(
                              color: Color(0xFF4CAF50),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Dropdown Ruangan
                        DropdownButtonFormField<String>(
                          value: _selectedRoom,
                          decoration: InputDecoration(
                            labelText: 'Ruangan Rapat',
                            prefixIcon: const Icon(
                              Icons.meeting_room,
                              color: Color(0xFF4CAF50),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF4CAF50),
                                width: 2,
                              ),
                            ),
                            labelStyle: const TextStyle(
                              color: Color(0xFF4CAF50),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: _availableRooms.map((String room) {
                            return DropdownMenuItem<String>(
                              value: room,
                              child: Text(room),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedRoom = newValue;
                            });
                          },
                          validator: (v) => v == null ? 'Pilih ruangan rapat' : null,
                        ),
                        const SizedBox(height: 20),

                        // Dropdown Penanggung Jawab
                        DropdownButtonFormField<String>(
                          value: _selectedResponsible,
                          decoration: InputDecoration(
                            labelText: 'Penanggung Jawab',
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Color(0xFF4CAF50),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF4CAF50),
                                width: 2,
                              ),
                            ),
                            labelStyle: const TextStyle(
                              color: Color(0xFF4CAF50),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: _availableResponsible.map((String person) {
                            return DropdownMenuItem<String>(
                              value: person,
                              child: Text(person),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedResponsible = newValue;
                            });
                          },
                          validator: (v) => v == null ? 'Pilih penanggung jawab' : null,
                        ),
                        const SizedBox(height: 20),

                        // Tanggal & Waktu Rapat
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: Color(0xFF4CAF50),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Jadwal Rapat yang Diajukan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Tanggal
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const Text('Tanggal: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    _selectedDate == null 
                                      ? 'Belum dipilih' 
                                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                    style: TextStyle(
                                      color: _selectedDate == null ? Colors.grey[600] : const Color(0xFF4CAF50),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.calendar_today, size: 18, color: Colors.white),
                                      onPressed: _pickDate,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Jam Mulai
                              Row(
                                children: [
                                  const Icon(Icons.play_arrow, size: 18, color: Colors.green),
                                  const SizedBox(width: 8),
                                  const Text('Jam Mulai: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    _formatTime(_selectedStartTime),
                                    style: TextStyle(
                                      color: _selectedStartTime == null ? Colors.grey[600] : const Color(0xFF4CAF50),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.access_time, size: 18, color: Colors.white),
                                      onPressed: _pickStartTime,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Jam Selesai
                              if (!_isIndefinite) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.stop, size: 18, color: Colors.red),
                                    const SizedBox(width: 8),
                                    const Text('Jam Selesai: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      _formatTime(_selectedEndTime),
                                      style: TextStyle(
                                        color: _selectedEndTime == null ? Colors.grey[600] : const Color(0xFF4CAF50),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.access_time, size: 18, color: Colors.white),
                                        onPressed: _pickEndTime,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Checkbox Selesai Tidak Menentu
                              Row(
                                children: [
                                  Checkbox(
                                    value: _isIndefinite,
                                    onChanged: (value) {
                                      setState(() {
                                        _isIndefinite = value ?? false;
                                        if (_isIndefinite) {
                                          _selectedEndTime = null;
                                        }
                                      });
                                    },
                                    activeColor: const Color(0xFF4CAF50),
                                  ),
                                  const Text('Selesai tidak menentu'),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.help_outline, size: 16, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Ajukan
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _ajukan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text(
                    'Ajukan ke Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}