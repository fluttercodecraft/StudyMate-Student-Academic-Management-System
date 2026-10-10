// ignore_for_file: file_names
import 'package:flutter/material.dart';

/// Academic data helpers for departments, semesters, and sections.
class Academic {
  static const List<String> departments = [
    'Computer Science',
    'Software Engineering',
    'Information Technology',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Business Administration',
    'Mathematics',
    'Physics',
  ];

  static const List<int> semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  static const List<String> sections = ['A', 'B', 'C', 'D'];

  /// "Computer Science • Sem 3 • Sec A"
  static String label(Map<dynamic, dynamic> data) {
    final d = data['department']?.toString() ?? '';
    final s = data['semester']?.toString() ?? '';
    final c = data['section']?.toString() ?? '';
    return [
      if (d.isNotEmpty) d,
      if (s.isNotEmpty) 'Sem $s',
      if (c.isNotEmpty) 'Sec $c',
    ].join(' • ');
  }
}

/// "850 B", "12.4 KB", "2.1 MB". Used by the Notes and Assignments screens.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// True when the profile (student) belongs to the class's section.
/// Old classes created before sections existed are visible to everyone.
bool matchesAcademic(Map<dynamic, dynamic> cls, Map<dynamic, dynamic> profile) {
  final dept = cls['department']?.toString() ?? '';
  if (dept.isEmpty) return true;

  return profile['department']?.toString() == dept &&
      profile['semester']?.toString() == cls['semester']?.toString() &&
      (profile['section']?.toString().toUpperCase() ?? '') ==
          (cls['section']?.toString().toUpperCase() ?? '');
}

bool hasAcademicProfile(Map<dynamic, dynamic> data) {
  bool filled(String k) => (data[k]?.toString() ?? '').isNotEmpty;
  return filled('department') && filled('semester') && filled('section');
}

/// Department + Semester + Section dropdowns.
/// Used in registration, profile completion, classes and attendance.
class AcademicPicker extends StatelessWidget {
  final String? department;
  final int? semester;
  final String? section;
  final ValueChanged<String?> onDepartment;
  final ValueChanged<int?> onSemester;
  final ValueChanged<String?> onSection;
  final Color accent;

  const AcademicPicker({
    super.key,
    required this.department,
    required this.semester,
    required this.section,
    required this.onDepartment,
    required this.onSemester,
    required this.onSection,
    this.accent = const Color(0xFF1355D6),
  });

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
    labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: accent, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: department,
          isExpanded: true,
          decoration: _decoration('Department', Icons.account_balance_rounded),
          items: Academic.departments
              .map((d) => DropdownMenuItem(
            value: d,
            child: Text(d,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14)),
          ))
              .toList(),
          onChanged: onDepartment,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: semester,
                isExpanded: true,
                decoration: _decoration('Semester', Icons.timeline_rounded),
                items: Academic.semesters
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text('Semester $s',
                      style: const TextStyle(fontSize: 14)),
                ))
                    .toList(),
                onChanged: onSemester,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: section,
                isExpanded: true,
                decoration: _decoration('Section', Icons.group_work_rounded),
                items: Academic.sections
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text('Section $s',
                      style: const TextStyle(fontSize: 14)),
                ))
                    .toList(),
                onChanged: onSection,
              ),
            ),
          ],
        ),
      ],
    );
  }
}