import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AddAssignmentScreen extends StatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF1B1F3B);
  static const Color background = Color(0xFFF3F5FA);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _sectionCtrl = TextEditingController();

  List<Map<String, String>> _courses = [];

  String? _courseId;
  String? _department;
  String? _semester;
  DateTime? _due;

  bool _loadingCourses = true;
  bool _saving = false;

  final List<String> _departments = [
    'Civil',
    'Electrical',
    'Mechanical',
    'Computer Science',
    'Software',
    'Telecommunication',
  ];

  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      final snapshot = await FirebaseDatabase.instance.ref('courses').get();

      final value = snapshot.value;
      final List<Map<String, String>> list = [];

      if (value is Map) {
        value.forEach((key, value) {
          if (value is Map) {
            final course = Map<String, dynamic>.from(value);

            final owner = course['teacherId']?.toString();

            // Exclude courses owned by another teacher when an owner
            // ID is stored. Courses without teacherId remain included,
            // matching the behavior of the original screen.
            if (owner != null && owner.isNotEmpty && owner != uid) {
              return;
            }

            list.add({
              'id': (course['courseId'] ?? key).toString(),
              'name': (course['courseName'] ?? 'Unnamed Course').toString(),
              'code': (course['courseCode'] ?? '').toString(),
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
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );

    if (time == null || !mounted) return;

    setState(() {
      _due = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }


  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final section = _sectionCtrl.text.trim().toUpperCase();

    if (_courseId == null) {
      _snack('Please select a course.');
      return;
    }
    if (_department == null) {
      _snack('Please select a department.');
      return;
    }
    if (_semester == null) {
      _snack('Please select a semester.');
      return;
    }
    if (section.isEmpty) {
      _snack('Please enter a section.');
      return;
    }
    if (title.isEmpty) {
      _snack('Please enter a title.');
      return;
    }
    if (_due == null) {
      _snack('Please choose a due date.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Please log in again.');
      return;
    }

    setState(() => _saving = true);

    try {
      final course = _courses.firstWhere(
            (item) => item['id'] == _courseId,
      );

      final database = FirebaseDatabase.instance;
      final assignmentRef = database.ref('assignments').push();
      final assignmentId = assignmentRef.key;

      if (assignmentId == null) {
        throw Exception('Could not create assignment ID.');
      }

      // Read registered users to find matching students.
      final usersSnapshot = await database.ref('users').get();
      final updates = <String, dynamic>{};

      final assignmentData = <String, dynamic>{
        'assignmentId': assignmentId,
        'title': title,
        'description': description,
        'courseId': _courseId,
        'courseName': course['name'],
        'dueDate': _due!.millisecondsSinceEpoch,
        'teacherId': user.uid,
        'department': _department,
        'semester': _semester,
        'section': section,
        'createdAt': ServerValue.timestamp,
      };

      updates['assignments/$assignmentId'] = assignmentData;

      int notificationCount = 0;

      final usersValue = usersSnapshot.value;

      if (usersValue is Map) {
        usersValue.forEach((uid, value) {
          if (value is! Map) return;

          final student = Map<String, dynamic>.from(value);
          final studentUid = uid.toString();

          final role = (student['role'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

          final department = (student['department'] ?? '')
              .toString()
              .trim();

          final semester = (student['semester'] ?? '')
              .toString()
              .trim();

          final studentSection = (student['section'] ?? '')
              .toString()
              .trim()
              .toUpperCase();

          // Notify students in the selected department and semester.
          if (role != 'student') return;
          if (studentUid == user.uid) return;
          if (department != _department) return;
          if (semester != _semester) return;

          // If the student's profile has a section, match it.
          // If section is not stored in the profile, department and
          // semester are used until section data is added.
          if (studentSection.isNotEmpty &&
              studentSection != section) {
            return;
          }

          final notificationRef =
          database.ref('notifications/$studentUid').push();

          final notificationId = notificationRef.key;
          if (notificationId == null) return;

          updates[
          'notifications/$studentUid/$notificationId'
          ] = <String, dynamic>{
            'notificationId': notificationId,
            'recipientId': studentUid,
            'type': 'assignment',
            'title': 'New Assignment: $title',
            'body':
            '${course['name']} — Due ${_formatDue(_due!)}',
            'assignmentId': assignmentId,
            'courseId': _courseId,
            'courseName': course['name'],
            'teacherId': user.uid,
            'department': _department,
            'semester': _semester,
            'section': section,
            'createdAt': ServerValue.timestamp,
            'isRead': false,
          };

          notificationCount++;
        });
      }

      // Save the assignment and all student notifications together.
      await database.ref().update(updates);

      if (!mounted) return;

      final message = notificationCount > 0
          ? 'Assignment created. $notificationCount student(s) notified in the app.'
          : 'Assignment created, but no matching students were found.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);
      _snack('Could not save assignment: $e');
    }
  }


  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDue(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final time = TimeOfDay.fromDateTime(date).format(context);

    return '${date.day} ${months[date.month - 1]} '
        '${date.year}, $time';
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
                  _label('Department'),
                  _departmentField(),

                  const SizedBox(height: 18),
                  _label('Semester'),
                  _semesterField(),

                  const SizedBox(height: 18),
                  _label('Section'),
                  TextField(
                    controller: _sectionCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 14),
                    decoration: _decoration('e.g. B'),
                  ),

                  const SizedBox(height: 18),
                  _label('Title'),
                  _input(_titleCtrl, 'e.g. Assignment 1: Linked Lists'),

                  const SizedBox(height: 18),
                  _label('Description'),
                  _input(
                    _descCtrl,
                    'Instructions for students (optional)',
                    lines: 4,
                  ),

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
        12,
        MediaQuery.of(context).padding.top + 8,
        18,
        24,
      ),
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
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
            child: const Icon(
              Icons.assignment_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
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
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: textGrey, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    int lines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: lines,
      style: const TextStyle(fontSize: 14),
      decoration: _decoration(hint),
    );
  }

  Widget _departmentField() {
    return DropdownButtonFormField<String>(
      initialValue: _department,
      isExpanded: true,
      decoration: _decoration('Select department'),
      items: _departments.map((department) {
        return DropdownMenuItem<String>(
          value: department,
          child: Text(department, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _department = value);
      },
    );
  }

  Widget _semesterField() {
    return DropdownButtonFormField<String>(
      initialValue: _semester,
      isExpanded: true,
      decoration: _decoration('Select semester'),
      items: _semesters.map((semester) {
        return DropdownMenuItem<String>(
          value: semester,
          child: Text(
            'Semester $semester',
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _semester = value);
      },
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
      initialValue: _courseId,
      isExpanded: true,
      decoration: _decoration('Select a course'),
      items: _courses.map((course) {
        final code = course['code']!;
        final name = course['name']!;

        return DropdownMenuItem<String>(
          value: course['id'],
          child: Text(
            code.isEmpty ? name : '$name ($code)',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _courseId = value);
      },
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
