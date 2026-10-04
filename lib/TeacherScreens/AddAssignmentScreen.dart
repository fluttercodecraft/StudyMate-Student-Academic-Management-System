import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AddAssignmentScreen extends StatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  static const Color primary = Color(0xFF1355D6);
  static const Color primaryDark = Color(0xFF0B3A9E);
  static const Color background = Color(0xFFF4F6FB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<Map<String, String>> _courses = [];
  String? _courseId;
  DateTime? _due;
  bool _loadingCourses = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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
            // Only filter when the course actually stores an owner id.
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

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _due ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (time == null) return;

    setState(() {
      _due = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (_courseId == null) return _snack('Please select a course.');
    if (title.isEmpty) return _snack('Please enter a title.');
    if (_due == null) return _snack('Please choose a due date.');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _snack('Please log in again.');

    setState(() => _saving = true);

    try {
      final course = _courses.firstWhere((c) => c['id'] == _courseId);

      // Everyone with the student role gets the assignment.
      final students = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['student', 'Student']).get();
      final studentIds = students.docs.map((d) => d.id).toList();

      await FirebaseFirestore.instance.collection('assignments').add({
        'title': title,
        'description': desc,
        'courseId': _courseId,
        'courseName': course['name'],
        'dueDate': Timestamp.fromDate(_due!),
        'studentIds': studentIds,
        'teacherId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _snack('Assignment sent to ${studentIds.length} student(s).');
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

  String _formatDue(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final t = TimeOfDay.fromDateTime(d).format(context);
    return '${d.day} ${m[d.month - 1]} ${d.year}, $t';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
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
                  _label('Title'),
                  _input(_titleCtrl, 'e.g. Assignment 1: Linked Lists'),
                  const SizedBox(height: 18),
                  _label('Description'),
                  _input(_descCtrl, 'Instructions for students (optional)',
                      lines: 4),
                  const SizedBox(height: 18),
                  _label('Due date'),
                  _dueField(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
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
                        'Create Assignment',
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

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          12, MediaQuery.of(context).padding.top + 8, 18, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
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
              'New Assignment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.assignment_rounded,
                color: Colors.white, size: 22),
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
        color: textDark,
      ),
    ),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: textGrey, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFE6EAF0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFE6EAF0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: primary, width: 1.5),
    ),
  );

  Widget _input(TextEditingController c, String hint, {int lines = 1}) {
    return TextField(
      controller: c,
      maxLines: lines,
      style: const TextStyle(fontSize: 14),
      decoration: _decoration(hint),
    );
  }

  Widget _courseField() {
    if (_loadingCourses) {
      return Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE6EAF0)),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: primary),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(15),
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

  Widget _dueField() {
    return InkWell(
      onTap: _pickDue,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE6EAF0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, color: primary, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _due == null ? 'Choose date & time' : _formatDue(_due!),
                style: TextStyle(
                  fontSize: 14,
                  color: _due == null ? textGrey : textDark,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: textGrey),
          ],
        ),
      ),
    );
  }
}