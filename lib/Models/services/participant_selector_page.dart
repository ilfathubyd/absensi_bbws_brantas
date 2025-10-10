import 'package:absen_app/Models/models/user.dart';
import 'package:flutter/material.dart';

class ParticipantSelectorPage extends StatefulWidget {
  final List<AppUser> allUsers;
  final List<AppUser> initialSelection;

  const ParticipantSelectorPage({
    super.key,
    required this.allUsers,
    required this.initialSelection,
  });

  @override
  State<ParticipantSelectorPage> createState() =>
      _ParticipantSelectorPageState();
}

class _ParticipantSelectorPageState extends State<ParticipantSelectorPage> {
  late List<AppUser> _selectedUsers;
  List<AppUser> _filteredUsers = [];
  List<String> _divisions = [];
  String? _selectedDivision;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Salin initial selection agar tidak mengubah list aslinya
    _selectedUsers = List.from(widget.initialSelection);
    _filteredUsers = widget.allUsers;

    // Ekstrak semua divisi unik dari daftar user
    _divisions = widget.allUsers
        .map((user) => user.division)
        .where((division) => division != null) // 1. Filter null dulu
        .cast<String>() // 2. Konversi tipe ke String non-nullable
        .where((division) => division.isNotEmpty) // 3. Baru filter string kosong
        .toSet()
        .toList()
      ..sort(); // Urutkan divisi berdasarkan abjad

    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = widget.allUsers.where((user) {
        final nameMatch = user.name.toLowerCase().contains(query);
        final divisionMatch =
            _selectedDivision == null || user.division == _selectedDivision;
        return nameMatch && divisionMatch;
      }).toList();
    });
  }

  void _onUserSelected(AppUser user, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedUsers.add(user);
      } else {
        _selectedUsers.removeWhere((u) => u.id_user == user.id_user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Peserta (${_selectedUsers.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedUsers);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama peserta...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Divisi
                if (_divisions.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedDivision,
                    hint: const Text('Filter berdasarkan divisi'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Semua Divisi',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ..._divisions.map((division) {
                        return DropdownMenuItem<String>(
                          value: division,
                          child: Text(division),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDivision = value;
                        _applyFilters();
                      });
                    },
                  ),
              ],
            ),
          ),
          // Daftar User
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                final isSelected =
                    _selectedUsers.any((u) => u.id_user == user.id_user);

                return CheckboxListTile(
                  title: Text(user.name),
                  subtitle: Text(user.division ?? 'Tanpa Divisi'),
                  value: isSelected,
                  onChanged: (bool? value) {
                    if (value != null) {
                      _onUserSelected(user, value);
                    }
                  },
                  secondary: CircleAvatar(
                    child: Text(user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Tombol Aksi di Bawah
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: Text('Simpan Pilihan (${_selectedUsers.length})'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.pop(context, _selectedUsers);
          },
        ),
      ),
    );
  }
}
