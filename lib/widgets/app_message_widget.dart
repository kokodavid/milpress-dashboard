import 'package:flutter/material.dart';

enum MessageType { error, success, info }

class AppMessageWidget extends StatelessWidget {
  final String message;
  final MessageType type;
  final IconData? icon;

  const AppMessageWidget({
    super.key,
    required this.message,
    required this.type,
    this.icon,
  });

  Color get _color {
    switch (type) {
      case MessageType.error:
        return Colors.red.shade100;
      case MessageType.success:
        return Colors.green.shade100;
      case MessageType.info:
        return Colors.blue.shade100;
    }
  }

  IconData get _defaultIcon {
    switch (type) {
      case MessageType.error:
        return Icons.error_outline;
      case MessageType.success:
        return Icons.check_circle_outline;
      case MessageType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon ?? _defaultIcon, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
