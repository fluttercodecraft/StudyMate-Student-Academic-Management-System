import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Shows the list of courses for the signed-in user's department and
/// semester. Reads those two fields from the user's document in the
/// `users` collection (the same document created at registration),
/// then queries the `courses` collection for matches.
///
/// Expected Firestore structure for each course document in `courses`:
/// {
///   'title': 'Data Structures',
///   'code': 'CS-201',
///   'instructor': 'Dr. Ahmad Khan',
///   'creditHours': 3,
///   'department': 'Computer Science',
///   'semester': '3',
/// }
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}



class _CoursesLoadResult {
  final String? department;
  final String? semester;
  final List<_Course> courses;

  const _CoursesLoadResult({
    required this.department,
    required this.semester,
    required this.courses,
  });
}

class _Course {
  final String id;
  final String title;
  final String code;
  final String instructor;
  final int? creditHours;

  const _Course({
    required this.id,
    required this.title,
    required this.code,
    required this.instructor,
    required this.creditHours,
  });

  factory _Course.fromMap(String id, Map<String, dynamic> map) {
    return _Course(
      id: id,
      title: (map['title'] as String?) ?? 'Untitled Course',
      code: (map['code'] as String?) ?? '',
      instructor: (map['instructor'] as String?) ?? '',
      creditHours: map['creditHours'] is int
          ? map['creditHours'] as int
          : int.tryParse('${map['creditHours']}'),
    );
  }
}