import 'package:flutter/material.dart';

class ScheduleItem {
  final String id;
  final String courseCode;
  final String courseTitle;
  final String time;
  final String room;
  final String instructor;
  final Color color;
  final bool isOngoing;

  const ScheduleItem({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.time,
    required this.room,
    required this.instructor,
    required this.color,
    this.isOngoing = false,
  });
}
