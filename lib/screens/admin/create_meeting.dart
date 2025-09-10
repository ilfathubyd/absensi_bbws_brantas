import 'package:absen_app/Models/services/meeting_repo.dart' show MeetingRepo;
import 'package:flutter/material.dart';
import '../../models/meeting.dart';
import 'meeting_qr.dart';

class CreateMeeting extends StatefulWidget {
  const CreateMeeting({super.key});

  @override
  State<CreateMeeting> createState() => _CreateMeetingState();
}

class _CreateMeetingState extends State<CreateMeeting> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  DateTime? _selectedDateTime;
  String? _selectedRoom;

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

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      initialDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0), // Biru
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
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0), // Biru
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
    
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Pilih tanggal & waktu rapat'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Pilih ruangan rapat'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    
    final Meeting meeting = MeetingRepo.add(
      title: _titleCtrl.text.trim(),
      dateTime: _selectedDateTime!,
      room: _selectedRoom!,
    );
    
    // Tampilkan QR setelah membuat
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MeetingQR(meeting: meeting)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Buat Rapat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1565C0), // Biru tua
                Color(0xFF42A5F5), // Biru muda
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
                    colors: [
                      Color(0xFFFFC107),
                      Color(0xFFFFB300),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Buat Rapat Baru',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lengkapi informasi rapat di bawah ini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
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
                          'Informasi Rapat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: InputDecoration(
                            labelText: 'Judul Rapat',
                            prefixIcon: const Icon(Icons.title, color: Color(0xFF1565C0)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1565C0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                            ),
                            labelStyle: const TextStyle(color: Color(0xFF1565C0)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Judul wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        
                        // Dropdown Ruangan
                        DropdownButtonFormField<String>(
                          value: _selectedRoom,
                          decoration: InputDecoration(
                            labelText: 'Ruangan Rapat',
                            prefixIcon: const Icon(Icons.meeting_room, color: Color(0xFF1565C0)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1565C0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                            ),
                            labelStyle: const TextStyle(color: Color(0xFF1565C0)),
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
                        
                        // Tanggal & Waktu
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F8FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1565C0).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: Color(0xFF1565C0),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Jadwal Rapat',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedDateTime == null
                                    ? 'Belum pilih tanggal & waktu'
                                    : MeetingRepo.formatDate(_selectedDateTime!),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedDateTime == null 
                                    ? Colors.grey[600] 
                                    : const Color(0xFF1565C0),
                                  fontWeight: _selectedDateTime == null 
                                    ? FontWeight.normal 
                                    : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFC107),
                                      Color(0xFFFFB300),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextButton.icon(
                                  onPressed: _pickDateTime,
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                                  label: const Text(
                                    'Pilih Tanggal & Waktu',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
              
              // Tombol Simpan
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1565C0),
                      Color(0xFF42A5F5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Simpan & Tampilkan QR',
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