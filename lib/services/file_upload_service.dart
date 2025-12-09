import 'dart:io';
import 'package:dio/dio.dart';
import 'package:absen_app/services/auth_service.dart';
import 'package:absen_app/config/api_config.dart';

class FileUploadService {
  static const String _baseUrl = ApiConfig.baseUrl;
  final AuthService _authService;
  final Dio _dio;

  FileUploadService({AuthService? authService})
      : _authService = authService ?? AuthService(),
        _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ));

  /// Upload files to a meeting with progress tracking
  ///
  /// [rapatId] - Meeting ID to upload files to
  /// [filesMateri] - List of material files
  /// [filesNotulensi] - List of minutes files
  /// [filesDokumentasi] - List of documentation files
  /// [filesLainnya] - List of other files
  /// [onProgress] - Callback for upload progress (0.0 to 1.0)
  Future<Map<String, dynamic>> uploadMeetingFiles({
    required String rapatId,
    List<File>? filesMateri,
    List<File>? filesNotulensi,
    List<File>? filesDokumentasi,
    List<File>? filesLainnya,
    void Function(double progress)? onProgress,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi');
    }

    // Prepare form data
    final formData = FormData();

    // Add files to form data
    if (filesMateri != null && filesMateri.isNotEmpty) {
      for (var file in filesMateri) {
        formData.files.add(MapEntry(
          'files_materi[]',
          await MultipartFile.fromFile(file.path,
              filename: file.path.split('/').last),
        ));
      }
    }

    if (filesNotulensi != null && filesNotulensi.isNotEmpty) {
      for (var file in filesNotulensi) {
        formData.files.add(MapEntry(
          'files_notulensi[]',
          await MultipartFile.fromFile(file.path,
              filename: file.path.split('/').last),
        ));
      }
    }

    if (filesDokumentasi != null && filesDokumentasi.isNotEmpty) {
      for (var file in filesDokumentasi) {
        formData.files.add(MapEntry(
          'files_dokumentasi[]',
          await MultipartFile.fromFile(file.path,
              filename: file.path.split('/').last),
        ));
      }
    }

    if (filesLainnya != null && filesLainnya.isNotEmpty) {
      for (var file in filesLainnya) {
        formData.files.add(MapEntry(
          'files_lainnya[]',
          await MultipartFile.fromFile(file.path,
              filename: file.path.split('/').last),
        ));
      }
    }

    try {
      final response = await _dio.post(
        '/rapat/$rapatId/upload-files',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            final progress = sent / total;
            onProgress(progress);
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ?? 'Upload gagal';
        throw Exception(message);
      } else {
        throw Exception('Koneksi gagal: ${e.message}');
      }
    }
  }

  /// Validate file before upload
  /// Returns true if file is valid, false otherwise
  static bool validateFile(File file, {StringBuffer? errorMessage}) {
    final allowedExtensions = [
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
    ];

    final fileName = file.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    final fileSize = file.lengthSync();
    final maxSize = 20 * 1024 * 1024; // 20MB

    if (!allowedExtensions.contains(extension)) {
      errorMessage?.write(
          'File "$fileName" memiliki ekstensi tidak valid. Hanya file dengan ekstensi: ${allowedExtensions.join(", ")} yang diperbolehkan.');
      return false;
    }

    if (fileSize > maxSize) {
      final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      errorMessage?.write(
          'File "$fileName" terlalu besar ($sizeMB MB). Maksimal ukuran file adalah 20MB.');
      return false;
    }

    return true;
  }

  /// Get human-readable file size
  static String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// Get file extension
  static String getFileExtension(File file) {
    final fileName = file.path.split('/').last;
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last.toUpperCase();
    }
    return 'FILE';
  }

  /// Get file name without path
  static String getFileName(File file) {
    return file.path.split('/').last;
  }
}
