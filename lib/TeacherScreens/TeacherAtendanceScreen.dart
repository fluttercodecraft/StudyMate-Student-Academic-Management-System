import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/common/AcadmicOption.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  static const Color ink = Color(0xFF1B1F3B);
  static const Color teal = Color(0xFF14B8A6);
  static const Color emerald = Color(0xFF10B981);
  static const Color coral = Color(0xFFEF4444);
  static const Color amber = Color(0xFFF59E0B);
  static const Color violet = Color(0xFF6C5CE7);

  String? _selectedDepartment;
  int? _selectedSemester;
  String? _selectedSection;
  DateTime _selectedDate = DateTime.now();

  String? _courseId;
  String? _courseName;
  List<Map<String, String>> _courses = [];
  bool _loadingCourses = true;
  bool _saving = false;

  // Map of studentId -> status ('present', 'absent', 'late')
  final Map<String, String> _attendanceState = {};

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingCourses = false);
      return;
    }

    try {
      final snap = await FirebaseDatabase.instance.ref('courses').get();
      final raw = snap.value;
      final list = <Map<String, String>>[];

      if (raw is Map) {
        raw.forEach((k, v) {
          if (v is Map && v['teacherId']?.toString() == uid) {
            list.add({
              'id': (v['courseId'] ?? k).toString(),
              'name': (v['courseName'] ?? 'Course').toString(),
              'code': (v['courseCode'] ?? '').toString(),
            });
          }
        });
      }

      if (mounted) {
        setState(() {
          _courses = list;
          if (list.isNotEmpty) {
            _courseId = list.first['id'];
            _courseName = list.first['name'];
          }
          _loadingCourses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _saveAttendance(List<Map<String, dynamic>> students) async {
    if (students.isEmpty) {
      _showMsg('No students to mark attendance for.', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final dateStr = _dateKey(_selectedDate);
      final teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final Map<String, dynamic> updates = {};

      for (final student in students) {
        final sid = student['uid'] ?? student['id'] ?? '';
        if (sid.isEmpty) continue;

        final status = _attendanceState[sid] ?? 'present';
        final key = '${student['uid']}_${dateStr}_${_courseId ?? 'general'}';

        updates['attendance/$key'] = {
          'id': key,
          'studentId': sid,
          'studentName': student['name'] ?? 'Student',
          'department': _selectedDepartment ?? student['department'] ?? '',
          'semester': _selectedSemester ?? student['semester'],
          'section': _selectedSection ?? student['section'] ?? '',
          'courseId': _courseId ?? '',
          'courseName': _courseName ?? 'General Attendance',
          'teacherId': teacherId,
          'date': dateStr,
          'timestamp': _selectedDate.millisecondsSinceEpoch,
          'status': status,
        };
      }

      await FirebaseDatabase.instance.ref().update(updates);

      if (mounted) {
        _showMsg('Attendance saved successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showMsg('Failed to save attendance: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? coral : emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _markAll(List<Map<String, dynamic>> students, String status) {
    setState(() {
      for (final s in students) {
        final id = (s['uid'] ?? s['id'] ?? '').toString();
        if (id.isNotEmpty) {
          _attendanceState[id] = status;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _filterCard(),
                  const SizedBox(height: 18),
                  _studentsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          12, MediaQuery.of(context).padding.top + 8, 18, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ink, Color(0xFF3B3F8F)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mark Attendance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Track and record student presence',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Class & Date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 14),
          if (!_loadingCourses && _courses.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _courseId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Course',
                prefixIcon: const Icon(Icons.menu_book_rounded, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              ),
              items: _courses.map((c) {
                return DropdownMenuItem(
                  value: c['id'],
                  child: Text(
                    c['code']!.isEmpty
                        ? c['name']!
                        : '${c['name']} (${c['code']})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _courseId = v;
                  _courseName = _courses.firstWhere(
                      (c) => c['id'] == v,
                      orElse: () => {'name': 'Course'})['name'];
                });
              },
            ),
            const SizedBox(height: 12),
          ],
          AcademicPicker(
            department: _selectedDepartment,
            semester: _selectedSemester,
            section: _selectedSection,
            onDepartment: (v) => setState(() => _selectedDepartment = v),
            onSemester: (v) => setState(() => _selectedSemester = v),
            onSection: (v) => setState(() => _selectedSection = v),
            accent: violet,
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFF8FAFC),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 20, color: violet),
                  const SizedBox(width: 10),
                  Text(
                    'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_calendar_rounded,
                      size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentsSection() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('users').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(color: violet),
            ),
          );
        }

        final raw = snapshot.data?.snapshot.value;
        final students = <Map<String, dynamic>>[];

        if (raw is Map) {
          raw.forEach((k, v) {
            if (v is Map && v['role']?.toString().toLowerCase() == 'student') {
              final s = Map<String, dynamic>.from(v);
              s['uid'] = s['uid'] ?? k;

              // Filter by academic if selected
              bool matches = true;
              if (_selectedDepartment != null &&
                  _selectedDepartment!.isNotEmpty) {
                if (s['department']?.toString() != _selectedDepartment) {
                  matches = false;
                }
              }
              if (_selectedSemester != null) {
                if (s['semester']?.toString() !=
                    _selectedSemester.toString()) {
                  matches = false;
                }
              }
              if (_selectedSection != null && _selectedSection!.isNotEmpty) {
                if (s['section']?.toString().toUpperCase() !=
                    _selectedSection!.toUpperCase()) {
                  matches = false;
                }
              }

              if (matches) {
                students.add(s);
              }
            }
          });
        }

        students.sort((a, b) =>
            (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

        if (students.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.group_off_rounded,
                      size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No students found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try selecting different department or section filters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        // Stats
        int presentCount = 0;
        int absentCount = 0;
        int lateCount = 0;

        for (final s in students) {
          final sid = s['uid'] ?? '';
          final status = _attendanceState[sid] ?? 'present';
          if (status == 'present') presentCount++;
          if (status == 'absent') absentCount++;
          if (status == 'late') lateCount++;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Students (${students.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _markAll(students, 'present'),
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('All Present'),
                  style: TextButton.styleFrom(
                    foregroundColor: emerald,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quick summary bar
            Row(
              children: [
                _badge('Present: $presentCount', emerald),
                const SizedBox(width: 8),
                _badge('Absent: $absentCount', coral),
                const SizedBox(width: 8),
                _badge('Late: $lateCount', amber),
              ],
            ),
            const SizedBox(height: 14),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: students.length,
              itemBuilder: (context, i) {
                final student = students[i];
                final sid = student['uid'] ?? '';
                final currentStatus = _attendanceState[sid] ?? 'present';
                final name = (student['name'] ?? 'Student').toString();
                final dept = (student['department'] ?? '').toString();
                final sem = student['semester']?.toString() ?? '';
                final sec = student['section']?.toString() ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: violet.withValues(alpha: 0.12),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            color: violet,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (dept.isNotEmpty) dept,
                                if (sem.isNotEmpty) 'Sem $sem',
                                if (sec.isNotEmpty) 'Sec $sec',
                              ].join(' • '),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3-way toggle button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _statusBtn(
                            sid,
                            'present',
                            'P',
                            emerald,
                            currentStatus == 'present',
                          ),
                          const SizedBox(width: 4),
                          _statusBtn(
                            sid,
                            'late',
                            'L',
                            amber,
                            currentStatus == 'late',
                          ),
                          const SizedBox(width: 4),
                          _statusBtn(
                            sid,
                            'absent',
                            'A',
                            coral,
                            currentStatus == 'absent',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () => _saveAttendance(students),
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _saving ? 'Saving...' : 'Save Attendance Record',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: violet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusBtn(
    String studentId,
    String status,
    String label,
    Color color,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _attendanceState[studentId] = status;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
