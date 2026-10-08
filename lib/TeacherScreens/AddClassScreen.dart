import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/common/AcadmicOption.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  static const Color ink = Color(0xFF1B1F3B);
  static const Color paper = Color(0xFFF3F5FA);
  static const Color violet = Color(0xFF6C5CE7);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color line = Color(0xFFE6EAF0);

  final _roomCtrl = TextEditingController();

  List<Map<String, String>> _courses = [];
  String? _courseId;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  int _weeks = 1;
  String? _dept;
  int? _sem;
  String? _section;
  bool _loadingCourses = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

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
              'teacher': (c['teacherName'] ?? '').toString(),
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: (isStart ? _start : _end) ??
          (isStart
              ? const TimeOfDay(hour: 9, minute: 0)
              : const TimeOfDay(hour: 10, minute: 0)),
    );
    if (t == null) return;
    setState(() {
      if (isStart) {
        _start = t;
      } else {
        _end = t;
      }
    });
  }

  Future<void> _save() async {
    if (_courseId == null) return _snack('Please select a course.');
    if (_dept == null || _sem == null || _section == null) {
      return _snack('Please choose department, semester and section.');
    }
    if (_date == null) return _snack('Please choose the date.');
    if (_start == null || _end == null) {
      return _snack('Please choose the start and end time.');
    }

    final startMin = _start!.hour * 60 + _start!.minute;
    final endMin = _end!.hour * 60 + _end!.minute;
    if (endMin <= startMin) {
      return _snack('End time must be after the start time.');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _snack('Please log in again.');

    setState(() => _saving = true);

    try {
      final course = _courses.firstWhere((c) => c['id'] == _courseId);

      // Teacher name: course -> users node -> auth profile.
      var teacher = course['teacher'] ?? '';
      if (teacher.isEmpty) {
        final n = await FirebaseDatabase.instance
            .ref('users/${user.uid}/name')
            .get();
        teacher = n.value?.toString() ?? user.displayName ?? 'Teacher';
      }

      final root = FirebaseDatabase.instance.ref();
      final d = _date!;
      final updates = <String, Object?>{};

      for (var w = 0; w < _weeks; w++) {
        final id = root.child('classes').push().key!;
        final start = DateTime(
            d.year, d.month, d.day + 7 * w, _start!.hour, _start!.minute);
        final end =
        DateTime(d.year, d.month, d.day + 7 * w, _end!.hour, _end!.minute);

        updates['classes/$id'] = {
          'classId': id,
          'courseId': _courseId,
          'subject': course['name'],
          'teacher': teacher,
          'room': _roomCtrl.text.trim(),
          'department': _dept,
          'semester': _sem,
          'section': _section,
          'startAt': start.millisecondsSinceEpoch,
          'endAt': end.millisecondsSinceEpoch,
          'teacherId': user.uid,
          'createdAt': ServerValue.timestamp,
        };
      }

      await root.update(updates);

      if (!mounted) return;
      _snack(_weeks == 1
          ? 'Class scheduled.'
          : '$_weeks weekly classes scheduled.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Could not save: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Course'),
                  _courseField(),
                  const SizedBox(height: 18),
                  _label('Department, semester & section'),
                  AcademicPicker(
                    accent: violet,
                    department: _dept,
                    semester: _sem,
                    section: _section,
                    onDepartment: (v) => setState(() => _dept = v),
                    onSemester: (v) => setState(() => _sem = v),
                    onSection: (v) => setState(() => _section = v),
                  ),
                  const SizedBox(height: 18),
                  _label('Date'),
                  _pickerTile(
                    Icons.event_rounded,
                    _date == null ? 'Choose date' : _formatDate(_date!),
                    _date != null,
                    _pickDate,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Starts'),
                            _pickerTile(
                              Icons.schedule_rounded,
                              _start?.format(context) ?? 'Start',
                              _start != null,
                                  () => _pickTime(true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Ends'),
                            _pickerTile(
                              Icons.schedule_rounded,
                              _end?.format(context) ?? 'End',
                              _end != null,
                                  () => _pickTime(false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _label('Room'),
                  TextField(
                    controller: _roomCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: _decoration('e.g. 204 (optional)'),
                  ),
                  const SizedBox(height: 18),
                  _label('Repeat weekly'),
                  _weeksStepper(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
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
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Schedule Class',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeksStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _weeks > 1 ? () => setState(() => _weeks--) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: violet,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _weeks == 1 ? 'Just once' : 'Every week for $_weeks weeks',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: ink),
                ),
                if (_weeks > 1)
                  const Text(
                    'Creates one class per week',
                    style: TextStyle(color: textGrey, fontSize: 11),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _weeks < 16 ? () => setState(() => _weeks++) : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: violet,
          ),
        ],
      ),
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
            child: Text(
              'Schedule Class',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13.5,
        color: ink,
      ),
    ),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: textGrey, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Widget _pickerTile(
      IconData icon, String text, bool filled, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Icon(icon, color: violet, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: filled ? ink : textGrey,
                ),
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'You have no courses yet. Create a course first.',
          style: TextStyle(color: Color(0xFF92400E), fontSize: 13),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _courseId,
      isExpanded: true,
      decoration: _decoration('Select a course'),
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
      onChanged: (v) => setState(() => _courseId = v),
    );
  }
}