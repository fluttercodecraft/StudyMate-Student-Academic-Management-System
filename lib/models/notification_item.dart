import 'package:flutter/material.dart';

enum NotificationType { assignment, quiz, course, system }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.assignment:
        return Icons.assignment_outlined;
      case NotificationType.quiz:
        return Icons.quiz_outlined;
      case NotificationType.course:
        return Icons.menu_book_outlined;
      case NotificationType.system:
        return Icons.notifications_active_outlined;
    }
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.assignment:
        return const Color(0xFF196EEE);
      case NotificationType.quiz:
        return const Color(0xFFF59E0B);
      case NotificationType.course:
        return const Color(0xFF8B5CF6);
      case NotificationType.system:
        return const Color(0xFF10B981);
    }
  }
}
