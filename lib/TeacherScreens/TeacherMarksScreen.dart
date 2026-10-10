import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/common/AcadmicOption.dart';


class TeacherMarksScreen extends StatefulWidget {
  const TeacherMarksScreen({super.key});

  @override
  State<TeacherMarksScreen> createState() => _TeacherMarksScreenState();
}

class _TeacherMarksScreenState extends State<TeacherMarksScreen> {
  static const Color ink = Color(0xFF1B1F3B);
  static const Color paper = Color(0xFFF3F5FA);
  static const Color violet = Color(0xFF6C5CE7);
  static const Color line = Color(0xFFE6EAF0);
  static const Color textGrey = Color(0xFF6B7280);

  static const List<String> types = [
    'Quiz',
    'Assignment',
    'Midterm',
    'Final',
    'Lab',
    'Project',
  ];

  String? _dept;
  int? _sem;
  String? _section;

  List<Map<String, String>> _courses = [];
  bool _loadingCourses = true;
  String? _courseId;
  String _type = 'Quiz';

  final _titleCtrl = TextEditingController();
  final _totalCtrl = TextEditingController(text: '100');
  final Map<String, TextEditingController> _ctrls = {};
  Timer? _debounce;

  bool _existing = false;
  bool _saving = false;

  bool get _ready => _dept != null && _sem != null && _section != null;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.dispose();
    _totalCtrl.dispose();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
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

  /// One sheet per course + assessment + section, so entering the same
  /// assessment again edits the existing sheet.
  String _sheetId() {
    final slug = _titleCtrl.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    final deptIndex = Academic.departments.indexOf(_dept!);
    return '${_courseId}_${_type.toLowerCase()}'
        '${slug.isEmpty ? '' : '_$slug'}_d${deptIndex}s$_sem$_section';
  }

  TextEditingController _ctrl(String id) =>
      _ctrls.putIfAbsent(id, () => TextEditingController());

  Future<void> _reload() async {
    for (final c in _ctrls.values) {
      c.clear();
    }
    setState(() => _existing = false);

    if (!_ready || _courseId == null) return;

    try {
      final snap =
      await FirebaseDatabase.instance.ref('marks/${_sheetId()}').get();
      if (!mounted || !snap.exists || snap.value is! Map) return;

      final m = snap.value as Map;
      final recs = m['records'];

      setState(() {
        _existing = true;
        if (m['totalMarks'] != null) _totalCtrl.text = m['totalMarks'].toString();
        if (recs is Map) {
          recs.forEach((uid, rec) {
            if (rec is Map && rec['obtained'] != null) {
              _ctrl(uid.toString()).text = rec['obtained'].toString();
            }
          });
        }
      });
    } catch (_) {}
  }

  void _reloadSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _reload);
  }

  Future<void> _save(List<({String id, String name})> students) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _snack('Please log in again.');
    if (_courseId == null) return _snack('Please choose a course first.');

    final total = double.tryParse(_totalCtrl.text.trim());
    if (total == null || total <= 0) {
      return _snack('Enter the total marks (a number above 0).');
    }

    final records = <String, Map<String, Object?>>{};
    for (final s in students) {
      final text = _ctrls[s.id]?.text.trim() ?? '';
      if (text.isEmpty) continue; // not graded yet

      final v = double.tryParse(text);
      if (v == null || v < 0 || v > total) {
        return _snack('${s.name}: enter a number from 0 to ${_fmt(total)}.');
      }
      records[s.id] = {'obtained': v, 'name': s.name};
    }

    if (records.isEmpty) return _snack('Enter marks for at least one student.');

    setState(() => _saving = true);

    try {
      final course = _courses.firstWhere((c) => c['id'] == _courseId);

      await FirebaseDatabase.instance.ref('marks/${_sheetId()}').set({
        'sheetId': _sheetId(),
        'courseId': _courseId,
        'courseName': course['name'],
        'type': _type,
        'title': _titleCtrl.text.trim(),
        'totalMarks': total,
        'department': _dept,
        'semester': _sem,
        'section': _section,
        'teacherId': user.uid,
        'updatedAt': ServerValue.timestamp,
        'records': records,
      });

      if (!mounted) return;
      setState(() {
        _saving = false;
        _existing = true;
      });
      _snack('Marks saved for ${records.length} students.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Could not save: $e');
    }
  }

  String _fmt(num n) => n == n.roundToDouble() ? '${n.round()}' : '$n';

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ----------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: StreamBuilder<DatabaseEvent>(
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
                        ..._content(students),
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
                                  : _existing
                                  ? 'Update Marks'
                                  : 'Save Marks',
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

  List<Widget> _content(List<({String id, String name, String email})> students) {
    if (!_ready) {
      return [
        const SizedBox(height: 50),
        _hint(
          Icons.touch_app_rounded,
          'Select a section',
          'Choose a department, semester and section to enter marks.',
        ),
      ];
    }

    final total = double.tryParse(_totalCtrl.text.trim()) ?? 0;

    // class average of the marks typed so far
    final entered = <double>[];
    for (final s in students) {
      final v = double.tryParse(_ctrls[s.id]?.text.trim() ?? '');
      if (v != null) entered.add(v);
    }
    final average = entered.isEmpty
        ? null
        : entered.reduce((a, b) => a + b) / entered.length;

    return [
      _courseField(),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            flex: 5,
            child: DropdownButtonFormField<String>(
              value: _type,
              isExpanded: true,
              decoration: _decoration('Assessment'),
              items: types
                  .map((t) => DropdownMenuItem(
                value: t,
                child: Text(t, style: const TextStyle(fontSize: 14)),
              ))
                  .toList(),
              onChanged: (v) {
                setState(() => _type = v ?? 'Quiz');
                _reload();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _totalCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: _decoration('Total marks'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _titleCtrl,
        onChanged: (_) => _reloadSoon(),
        decoration: _decoration('Title (optional, e.g. "Quiz 2")'),
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
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: violet.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.insights_rounded, color: violet, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${entered.length} of ${students.length} graded'
                      '${average == null ? '' : '   •   Class average ${_fmt(double.parse(average.toStringAsFixed(1)))}'
                      '${total > 0 ? ' / ${_fmt(total)}' : ''}'}'
                      '${_existing ? '   •   already saved' : ''}',
                  style: const TextStyle(
                      color: violet,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...students.map((s) => _studentRow(s, total)),
      ],
    ];
  }

  Widget _studentRow(({String id, String name, String email}) s, double total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
          SizedBox(
            width: 72,
            child: TextField(
              controller: _ctrl(s.id),
              textAlign: TextAlign.center,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              decoration: InputDecoration(
                hintText: '—',
                isDense: true,
                filled: true,
                fillColor: paper,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: violet, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            child: Text(
              '/ ${total > 0 ? _fmt(total) : '-'}',
              style: const TextStyle(color: textGrey, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
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
          'You have no courses yet. Create a course first, then enter marks.',
          style: TextStyle(color: Color(0xFF92400E), fontSize: 13),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _courseId,
      isExpanded: true,
      decoration: _decoration('Course'),
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

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
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
  );

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
                  'Marks',
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