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
  static const Color paper = Color(0xFFF3F5FA);
  static const Color violet = Color(0xFF6C5CE7);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);
  static const Color amber = Color(0xFFF59E0B);
  static const Color line = Color(0xFFE6EAF0);
  static const Color textGrey = Color(0xFF6B7280);

  // Section selection
  String? _dept;
  int? _sem;
  String? _section;

  // Course + date
  List<Map<String, String>> _courses = [];
  bool _loadingCourses = true;
  String? _courseId;
  DateTime _date = DateTime.now();

  // Marks: studentId -> present | absent | late  (default present)
  final Map<String, String> _status = {};
  bool _alreadyMarked = false;
  bool _saving = false;

  bool get _ready => _dept != null && _sem != null && _section != null;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  // ------------------------------------------------------------------ data
  Future<void> _loadCourses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      final snap = await FirebaseDatabase.instance.ref('courses').get();
      final v = snap.value;
      final list = <Map<String, String>>[];

      if (v is Map) {
        v.forEach((key, value) {
          if (value is Map) {
            final c = Map<String, dynamic>.from(value);
            final owner = c['teacherId']?.toString();
            if (owner != null && owner.isNotEmpty && owner != uid) return;
            list.add({
              'id': (c['courseId'] ?? key).toString(),
              'name': (c['courseName'] ?? 'Unnamed Course').toString(),
              'code': (c['courseCode'] ?? '').toString(),
            });
          }
        });
      }

      if (!mounted) return;
      setState(() {
        _courses = list;
        _loadingCourses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCourses = false);
      _snack('Could not load courses: $e');
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  /// One attendance sheet per day + course + section, so marking the same
  /// day again edits the same sheet instead of creating a duplicate.
  String _sessionId() {
    final d = _date;
    final deptIndex = Academic.departments.indexOf(_dept!);
    return '${d.year}${_pad(d.month)}${_pad(d.day)}_${_courseId}_d${deptIndex}s$_sem$_section';
  }

  /// Loads an already-saved sheet (if any) for the current selection.
  Future<void> _reload() async {
    setState(() {
      _status.clear();
      _alreadyMarked = false;
    });

    if (!_ready || _courseId == null) return;

    try {
      final snap = await FirebaseDatabase.instance
          .ref('attendance/${_sessionId()}/records')
          .get();
      if (!mounted) return;

      setState(() {
        _alreadyMarked = snap.exists;
        final v = snap.value;
        if (v is Map) {
          v.forEach((uid, rec) {
            if (rec is Map) {
              _status[uid.toString()] = rec['status']?.toString() ?? 'present';
            }
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _save(List<({String id, String name})> students) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _snack('Please log in again.');
    if (_courseId == null) return _snack('Please choose a course first.');

    setState(() => _saving = true);

    try {
      final course = _courses.firstWhere((c) => c['id'] == _courseId);
      final d = _date;

      await FirebaseDatabase.instance.ref('attendance/${_sessionId()}').set({
        'sessionId': _sessionId(),
        'date': DateTime(d.year, d.month, d.day).millisecondsSinceEpoch,
        'courseId': _courseId,
        'courseName': course['name'],
        'department': _dept,
        'semester': _sem,
        'section': _section,
        'teacherId': user.uid,
        'updatedAt': ServerValue.timestamp,
        'records': {
          for (final s in students)
            s.id: {'status': _status[s.id] ?? 'present', 'name': s.name},
        },
      });

      if (!mounted) return;
      setState(() {
        _saving = false;
        _alreadyMarked = true;
      });
      _snack('Attendance saved for ${students.length} students.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Could not save: $e');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (d == null) return;
    setState(() => _date = d);
    _reload();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${m[d.month - 1]} ${d.year}';
  }

  // ----------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: StreamBuilder<DatabaseEvent>(
        // Live list: students who register later appear automatically.
        stream: FirebaseDatabase.instance.ref('users').onValue,
        builder: (context, snap) {
          final students = <({String id, String name, String email})>[];
          final raw = snap.data?.snapshot.value;

          if (_ready && raw is Map) {
            raw.forEach((uid, value) {
              if (value is Map &&
                  value['role']?.toString().toLowerCase() == 'student' &&
                  value['department']?.toString() == _dept &&
                  value['semester']?.toString() == '$_sem' &&
                  (value['section']?.toString().toUpperCase() ?? '') ==
                      _section) {
                students.add((
                id: uid.toString(),
                name: (value['name'] ?? value['email'] ?? 'Student')
                    .toString(),
                email: (value['email'] ?? '').toString(),
                ));
              }
            });
            students.sort(
                    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          }

          final canSave = _ready && students.isNotEmpty && _courseId != null;

          return Column(
            children: [
              _header(context),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      children: [
                        AcademicPicker(
                          accent: violet,
                          department: _dept,
                          semester: _sem,
                          section: _section,
                          onDepartment: (v) {
                            setState(() => _dept = v);
                            _reload();
                          },
                          onSemester: (v) {
                            setState(() => _sem = v);
                            _reload();
                          },
                          onSection: (v) {
                            setState(() => _section = v);
                            _reload();
                          },
                        ),
                        const SizedBox(height: 16),
                        ..._sectionContent(students),
                      ],
                    ),
                  ),
                ),
              ),
              if (_ready)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (canSave && !_saving)
                                ? () => _save([
                              for (final s in students)
                                (id: s.id, name: s.name)
                            ])
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: violet,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                                : Text(
                              _courseId == null
                                  ? 'Choose a course to save'
                                  : _alreadyMarked
                                  ? 'Update Attendance'
                                  : 'Save Attendance',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _sectionContent(
      List<({String id, String name, String email})> students) {
    if (!_ready) {
      return [
        const SizedBox(height: 50),
        _hint(
          Icons.touch_app_rounded,
          'Select a section',
          'Choose a department, semester and section to see its students.',
        ),
      ];
    }

    return [
      // Course + date
      _courseField(),
      const SizedBox(height: 12),
      InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: line),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_rounded, color: violet, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_formatDate(_date),
                    style: const TextStyle(fontSize: 14, color: ink)),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: textGrey),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),

      if (students.isEmpty)
        _hint(
          Icons.groups_rounded,
          'No students in this section yet',
          'Students appear here after they register as $_dept, '
              'Semester $_sem, Section $_section.',
        )
      else ...[
        Row(
          children: [
            _summary('Present', _count(students, 'present'), green),
            const SizedBox(width: 10),
            _summary('Absent', _count(students, 'absent'), red),
            const SizedBox(width: 10),
            _summary('Late', _count(students, 'late'), amber),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${students.length} student${students.length == 1 ? '' : 's'}'
                      '${_alreadyMarked ? '  •  already marked' : ''}',
                  style: const TextStyle(
                      color: textGrey,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  for (final s in students) {
                    _status[s.id] = 'present';
                  }
                }),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Mark all present'),
                style: TextButton.styleFrom(foregroundColor: violet),
              ),
            ],
          ),
        ),
        ...students.map(_studentRow),
      ],
    ];
  }

  int _count(List<({String id, String name, String email})> students,
      String status) {
    return students.where((s) => (_status[s.id] ?? 'present') == status).length;
  }

  Widget _courseField() {
    if (_loadingCourses) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: violet),
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Text(
          'You have no courses yet. Create a course first, then mark attendance.',
          style: TextStyle(color: Color(0xFF92400E), fontSize: 13),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _courseId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Course',
        labelStyle: const TextStyle(color: textGrey, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: violet, width: 1.5),
        ),
      ),
      items: _courses
          .map(
            (c) => DropdownMenuItem<String>(
          value: c['id'],
          child: Text(
            c['code']!.isEmpty ? c['name']! : '${c['name']} (${c['code']})',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      )
          .toList(),
      onChanged: (v) {
        setState(() => _courseId = v);
        _reload();
      },
    );
  }

  Widget _summary(String label, int n, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text('$n',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11.5, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _studentRow(({String id, String name, String email}) s) {
    final current = _status[s.id] ?? 'present';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: violet.withValues(alpha: .12),
            child: Text(
              s.name.isEmpty ? 'S' : s.name[0].toUpperCase(),
              style: const TextStyle(
                  color: violet, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: ink),
                ),
                if (s.email.isNotEmpty)
                  Text(
                    s.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: textGrey, fontSize: 11.5),
                  ),
              ],
            ),
          ),
          _statusButton(s.id, 'present', 'P', green, current),
          const SizedBox(width: 6),
          _statusButton(s.id, 'absent', 'A', red, current),
          const SizedBox(width: 6),
          _statusButton(s.id, 'late', 'L', amber, current),
        ],
      ),
    );
  }

  Widget _statusButton(
      String id, String value, String label, Color color, String current) {
    final selected = current == value;

    return GestureDetector(
      onTap: () => setState(() => _status[id] = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _hint(IconData icon, String title, String message) {
    return Column(
      children: [
        Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            color: violet.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: violet, size: 42),
        ),
        const SizedBox(height: 20),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 13, height: 1.5)),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          12, MediaQuery.of(context).padding.top + 8, 18, 26),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Department  →  Semester  →  Section',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}