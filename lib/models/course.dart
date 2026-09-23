import 'package:flutter/material.dart';

class Course {
  final String id;
  final String title;
  final String code;
  final String instructor;
  final double progress; // 0.0 to 1.0
  final int totalLessons;
  final int completedLessons;
  final Color color;
  final IconData icon;
  final String scheduleTime;
  final String room;
  final String description;

  const Course({
    required this.id,
    required this.title,
    required this.code,
    required this.instructor,
    required this.progress,
    required this.totalLessons,
    required this.completedLessons,
    required this.color,
    required this.icon,
    required this.scheduleTime,
    required this.room,
    this.description = '',
  });
}
