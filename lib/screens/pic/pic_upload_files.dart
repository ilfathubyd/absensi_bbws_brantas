import 'dart:io';
import 'package:absen_app/services/file_upload_service.dart';
import 'package:absen_app/widgets/upload_progress_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:absen_app/utils/snackbar_helper.dart';
import 'package:absen_app/Models/services/rapat_api_service.dart';

class PICUploadFiles extends StatefulWidget {
  final String rapatId;
  final String rapatTitle;

  const PICUploadFiles({
    super.key,
    required this.rapatId,
    required this.rapatTitle,
  });

  @override
  State<PICUploadFiles> createState() => _PICUploadFilesState();
}

class _PICUploadFilesState extends State<PICUploadFiles> {
  final RapatApiService _rapatApiService = RapatApiService();

  // File lists for each category
  final List<File> _filesMateri = [];
  final List<File> _filesNotulensi = [];
  final List<File> _filesDokumentasi = [];
  final List<File> _filesLainnya = [];

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Upload File Rapat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meeting info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.meeting_room,
                        color: Color(0xFF1976D2),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rapat',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.rapatTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
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
                      'Pilih file untuk setiap kategori, lalu klik Upload',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // File picker sections
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

            const SizedBox(height: 32),

            // Upload button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadFiles,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Upload File',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
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
        borderRadius: BorderRadius.circular(16),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(_getCategoryIcon(category), color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        '${files.length} file${files.length != 1 ? 's' : ''} dipilih',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickFiles(category),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Pilih'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // File list
          if (files.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: files.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: color.withOpacity(0.1),
              ),
              itemBuilder: (context, index) {
                final file = files[index];
                final fileName = FileUploadService.getFileName(file);
                final fileSize = FileUploadService.getFileSize(file);
                final fileExt = FileUploadService.getFileExtension(file);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      fileSize,
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.close, color: Colors.red, size: 20),
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

  Future<void> _uploadFiles() async {
    // Check if any files selected
    final totalFiles = _filesMateri.length +
        _filesNotulensi.length +
        _filesDokumentasi.length +
        _filesLainnya.length;

    if (totalFiles == 0) {
      SnackBarHelper.warning(
        context,
        'Pilih minimal satu file untuk diupload',
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadProgressDialog(
        progress: _uploadProgress,
        currentFile: 1,
        totalFiles: totalFiles,
      ),
    );

    try {
      // Use the existing updateRapat API to upload files
      // We need to get the current meeting data first, then update with files
      await _rapatApiService.updateRapat(
        idRapat: widget.rapatId,
        // We'll need to pass existing meeting data here
        // For now, we'll create a simplified version that only uploads files
        judul: '', // These will be ignored by backend if not changed
        idCabang: 0,
        idRuangan: 0,
        idStatus: 0,
        tanggal: '',
        waktuStart: '',
        filesMateri: _filesMateri.isEmpty ? null : _filesMateri,
        filesNotulensi: _filesNotulensi.isEmpty ? null : _filesNotulensi,
        filesDokumentasi: _filesDokumentasi.isEmpty ? null : _filesDokumentasi,
        filesLainnya: _filesLainnya.isEmpty ? null : _filesLainnya,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        SnackBarHelper.success(context, 'File berhasil diupload!');
        Navigator.of(context).pop(true); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        SnackBarHelper.error(
          context,
          'Gagal upload file: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}
