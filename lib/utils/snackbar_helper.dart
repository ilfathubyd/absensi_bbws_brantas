import 'package:flutter/material.dart';

class SnackBarHelper {
  static DateTime? _lastShownTime;
  static String? _lastMessage;
  static const Duration _cooldownDuration = Duration(milliseconds: 500);

  /// Show a modern, professional SnackBar with anti-spam protection
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    bool forceShow = false,
  }) {
    // Anti-spam check
    final now = DateTime.now();
    if (!forceShow &&
        _lastShownTime != null &&
        _lastMessage == message &&
        now.difference(_lastShownTime!) < _cooldownDuration) {
      return; // Skip showing duplicate message too quickly
    }

    _lastShownTime = now;
    _lastMessage = message;

    // Remove any existing SnackBar
    ScaffoldMessenger.of(context).clearSnackBars();

    // Get color and icon based on type
    final config = _getConfig(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                config.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: config.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        elevation: 6,
      ),
    );
  }

  static _SnackBarConfig _getConfig(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarConfig(
          color: const Color(0xFF4CAF50),
          icon: Icons.check_circle,
        );
      case SnackBarType.error:
        return _SnackBarConfig(
          color: const Color(0xFFE53935),
          icon: Icons.error,
        );
      case SnackBarType.warning:
        return _SnackBarConfig(
          color: const Color(0xFFFFA726),
          icon: Icons.warning,
        );
      case SnackBarType.info:
        return _SnackBarConfig(
          color: const Color(0xFF1565C0),
          icon: Icons.info,
        );
    }
  }

  /// Quick success message
  static void success(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.success);
  }

  /// Quick error message
  static void error(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.error);
  }

  /// Quick warning message
  static void warning(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.warning);
  }

  /// Quick info message
  static void info(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.info);
  }
}

enum SnackBarType {
  success,
  error,
  warning,
  info,
}

class _SnackBarConfig {
  final Color color;
  final IconData icon;

  _SnackBarConfig({
    required this.color,
    required this.icon,
  });
}
