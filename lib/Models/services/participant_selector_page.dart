import 'package:flutter/material.dart';

class ItemSelectorPage<T> extends StatefulWidget {
  final List<T> allItems;
  final List<T> initialSelection;
  final String Function(T) itemTitleBuilder;
  final String? Function(T) itemSubtitleBuilder;
  final String pageTitle;
  final String searchHint;

  const ItemSelectorPage({
    super.key,
    required this.allItems,
    required this.initialSelection,
    required this.itemTitleBuilder,
    required this.itemSubtitleBuilder,
    required this.pageTitle,
    this.searchHint = 'Cari...',
  });

  @override
  State<ItemSelectorPage<T>> createState() => _ItemSelectorPageState<T>();
}

class _ItemSelectorPageState<T> extends State<ItemSelectorPage<T>> {
  late List<T> _selectedItems;
  List<T> _filteredItems = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelection);
    _filteredItems = widget.allItems;
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.allItems.where((item) {
        final titleMatch =
            widget.itemTitleBuilder(item).toLowerCase().contains(query);
        return titleMatch;
      }).toList();
    });
  }

  void _onItemSelected(T item, bool isSelected) {
    setState(() {
      if (isSelected) {
        if (!_selectedItems.contains(item)) {
          _selectedItems.add(item);
        }
      } else {
        _selectedItems.remove(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pageTitle} (${_selectedItems.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedItems);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint,
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
          ),
          // Daftar User
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isSelected = _selectedItems.contains(item);
                final title = widget.itemTitleBuilder(item);
                final subtitle = widget.itemSubtitleBuilder(item);

                return CheckboxListTile(
                  title: Text(title),
                  subtitle: subtitle != null ? Text(subtitle) : null,
                  value: isSelected,
                  onChanged: (bool? value) {
                    if (value != null) {
                      _onItemSelected(item, value);
                    }
                  },
                  secondary: CircleAvatar(
                    child:
                        Text(title.isNotEmpty ? title[0].toUpperCase() : '?'),
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
          label: Text('Simpan Pilihan (${_selectedItems.length})'),
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
            Navigator.pop(context, _selectedItems);
          },
        ),
      ),
    );
  }
}
