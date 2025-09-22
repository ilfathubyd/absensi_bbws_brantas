import 'package:absen_app/Models/models/meeting.dart';
import 'package:absen_app/Models/services/meeting_repo.dart' show MeetingRepo;
import 'package:flutter/material.dart';
import 'meeting_qr.dart';

class CreateMeeting extends StatefulWidget {
  const CreateMeeting({super.key});

  @override
  State<CreateMeeting> createState() => _CreateMeetingState();
}

class _CreateMeetingState extends State<CreateMeeting> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  String? _selectedRoom;
  String? _selectedResponsible;
  bool _isIndefinite = false;

  // List ruangan yang tersedia
  final List<String> _availableRooms = [
    'Ruang Pertemuan Bendungan Bagong (Bid. OP)',
    'Ruang Pertemuan Bendungan Sutami',
    'Ruang Pertemuan Bendungan Tugu',
    'Ruang Pertemuan Gunung Semeru (PJSA Bawah)',
    'Ruang Rapat Bendungan Nipah',
    'Ruang Rapat Bidang KPI SDA',
    'Ruang Rapat KPISDA',
    'Ruang Rapat PPK Program',
    'Ruang Rapat Satker PJPA (PJSA Atas)',
    'Ruang Rapat Semantok (PJSA Atas / Bendungan)',
  ];

  // List penanggung jawab yang tersedia
  final List<String> _availableResponsible = [
    'Bagian Tata Usaha',
    'Bidang KPI',
    'Bidang OP',
    'Bidang PJPA',
    'Bidang PJSA',
    'PPK ATAB 1',
    'PPK ATAB 2',
    'PPK ATAB 3',
    'PPK BMN',
    'PPK Bendungan 1',
    'PPK Bendungan 2',
    'PPK Bendungan 3',
    'PPK IRWA 1',
    'PPK IRWA 2',
    'PPK OP 1',
    'PPK OP 2',
    'PPK OP 3',
    'PPK OP 4',
    'PPK OP 5',
    'PPK PSDA',
    'PPK Perencanaan Bendungan',
    'PPK Perencanaan Program',
    'PPK SP 1',
    'PPK SP 2',
    'PPK SP 3',
    'PPK SP 4',
    'PPK Tanah Balai',
    'PPK Tanah Bendungan',
    'PPK Tata Laksana',
    'Satker ATAB',
    'Satker Balai',
    'Satker Bendungan',
    'Satker OP',
    'Satker PJPA',
    'Satker PJSA',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
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

  void _save() {
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

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );

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

    final meeting = MeetingRepo.add(
      title: _titleCtrl.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      room: _selectedRoom!,
      responsible: _selectedResponsible!,
      pic: 'default_pic.jpg',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Rapat berhasil dibuat!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
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
          'Buat Rapat',
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
                Color(0xFF1565C0),
                Color(0xFF42A5F5),
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmallScreen = constraints.maxWidth < 600;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
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
                      child: Column(
                        children: [
                          Icon(Icons.event_note, 
                              size: isSmallScreen ? 36 : 48, 
                              color: Colors.white),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          Text(
                            'Buat Rapat Baru',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Text(
                            'Lengkapi informasi rapat di bawah ini',
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: isSmallScreen ? 12 : 14
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Form Card
                    Expanded(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
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
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1565C0),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 20),

                                // Judul Rapat
                                TextFormField(
                                  controller: _titleCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Judul Rapat',
                                    prefixIcon: const Icon(
                                      Icons.title,
                                      color: Color(0xFF1565C0),
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
                                        color: Color(0xFF1565C0),
                                        width: 2,
                                      ),
                                    ),
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF1565C0),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Judul wajib diisi'
                                      : null,
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 20),

                                // Dropdown Ruangan
                                DropdownButtonFormField<String>(
                                  value: _selectedRoom,
                                  isExpanded: true, // Penting untuk responsivitas
                                  decoration: InputDecoration(
                                    labelText: 'Ruangan Rapat',
                                    prefixIcon: const Icon(
                                      Icons.meeting_room,
                                      color: Color(0xFF1565C0),
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
                                        color: Color(0xFF1565C0),
                                        width: 2,
                                      ),
                                    ),
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF1565C0),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: _availableRooms.map((String room) {
                                    return DropdownMenuItem<String>(
                                      value: room,
                                      child: Text(
                                        room,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedRoom = newValue;
                                    });
                                  },
                                  validator: (v) => v == null ? 'Pilih ruangan rapat' : null,
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 20),

                                // Dropdown Penanggung Jawab
                                DropdownButtonFormField<String>(
                                  value: _selectedResponsible,
                                  isExpanded: true, // Penting untuk responsivitas
                                  decoration: InputDecoration(
                                    labelText: 'Penanggung Jawab',
                                    prefixIcon: const Icon(
                                      Icons.person,
                                      color: Color(0xFF1565C0),
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
                                        color: Color(0xFF1565C0),
                                        width: 2,
                                      ),
                                    ),
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF1565C0),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: _availableResponsible.map((String person) {
                                    return DropdownMenuItem<String>(
                                      value: person,
                                      child: Text(
                                        person,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedResponsible = newValue;
                                    });
                                  },
                                  validator: (v) => v == null ? 'Pilih penanggung jawab' : null,
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 20),

                                // Tanggal & Waktu Rapat
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                                          Icon(
                                            Icons.schedule,
                                            color: const Color(0xFF1565C0),
                                            size: isSmallScreen ? 16 : 20,
                                          ),
                                          SizedBox(width: isSmallScreen ? 4 : 8),
                                          Text(
                                            'Jadwal Rapat',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1565C0),
                                              fontSize: isSmallScreen ? 14 : 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isSmallScreen ? 8 : 12),

                                      // Tanggal
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, 
                                              size: isSmallScreen ? 14 : 18, 
                                              color: Colors.grey),
                                          SizedBox(width: isSmallScreen ? 4 : 8),
                                          Text('Tanggal: ', 
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isSmallScreen ? 12 : 14
                                              )),
                                          Expanded(
                                            child: Text(
                                              _selectedDate == null 
                                                ? 'Belum dipilih' 
                                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                              style: TextStyle(
                                                color: _selectedDate == null 
                                                  ? Colors.grey[600] 
                                                  : const Color(0xFF1565C0),
                                                fontSize: isSmallScreen ? 12 : 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: isSmallScreen ? 4 : 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFC107),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.calendar_today, 
                                                        size: isSmallScreen ? 14 : 18, 
                                                        color: Colors.white),
                                              onPressed: _pickDate,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isSmallScreen ? 8 : 12),

                                      // Jam Mulai
                                      Row(
                                        children: [
                                          Icon(Icons.play_arrow, 
                                              size: isSmallScreen ? 14 : 18, 
                                              color: Colors.green),
                                          SizedBox(width: isSmallScreen ? 4 : 8),
                                          Text('Jam Mulai: ', 
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isSmallScreen ? 12 : 14
                                              )),
                                          Expanded(
                                            child: Text(
                                              _formatTime(_selectedStartTime),
                                              style: TextStyle(
                                                color: _selectedStartTime == null 
                                                  ? Colors.grey[600] 
                                                  : const Color(0xFF1565C0),
                                                fontSize: isSmallScreen ? 12 : 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: isSmallScreen ? 4 : 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4CAF50),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.access_time, 
                                                        size: isSmallScreen ? 14 : 18, 
                                                        color: Colors.white),
                                              onPressed: _pickStartTime,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isSmallScreen ? 8 : 12),

                                      // Jam Selesai
                                      if (!_isIndefinite) ...[
                                        Row(
                                          children: [
                                            Icon(Icons.stop, 
                                                size: isSmallScreen ? 14 : 18, 
                                                color: Colors.red),
                                            SizedBox(width: isSmallScreen ? 4 : 8),
                                            Text('Jam Selesai: ', 
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isSmallScreen ? 12 : 14
                                                )),
                                            Expanded(
                                              child: Text(
                                                _formatTime(_selectedEndTime),
                                                style: TextStyle(
                                                  color: _selectedEndTime == null 
                                                    ? Colors.grey[600] 
                                                    : const Color(0xFF1565C0),
                                                  fontSize: isSmallScreen ? 12 : 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(width: isSmallScreen ? 4 : 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF44336),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: IconButton(
                                                icon: Icon(Icons.access_time, 
                                                          size: isSmallScreen ? 14 : 18, 
                                                          color: Colors.white),
                                                onPressed: _pickEndTime,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isSmallScreen ? 8 : 12),
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
                                            activeColor: const Color(0xFF1565C0),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          Text(
                                            'Selesai tidak menentu',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 12 : 14
                                            ),
                                          ),
                                          SizedBox(width: isSmallScreen ? 2 : 4),
                                          Icon(Icons.help_outline, 
                                              size: isSmallScreen ? 12 : 16, 
                                              color: Colors.grey),
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
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: isSmallScreen ? 45 : 55,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: const Color(0xFF1565C0).withOpacity(0.4),
                        ),
                        icon: const Icon(Icons.save),
                        label: Text(
                          'Simpan Rapat',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}