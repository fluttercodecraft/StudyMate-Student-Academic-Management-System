import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/TeacherScreens/AddQuizesScreen.dart';
import 'package:study_mate/TeacherScreens/Addcourcesscreen.dart';
import 'package:study_mate/TeacherScreens/AddAssignmentScreen.dart';
import 'package:study_mate/TeacherScreens/AddClassScreen.dart';
import 'package:study_mate/TeacherScreens/TeacherAssignementScreen.dart';
import 'package:study_mate/TeacherScreens/TeacherAtendanceScreen.dart';
import 'package:study_mate/TeacherScreens/TeacherClassScreen.dart';
import 'package:study_mate/TeacherScreens/TeacherQuizesScreen.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  static const Color ink = Color(0xFF1B1F3B);
  static const Color paper = Color(0xFFF3F5FA);
  static const Color violet = Color(0xFF6C5CE7);
  static const Color coral = Color(0xFFFF6B5E);
  static const Color teal = Color(0xFF14B8A6);
  static const Color amber = Color(0xFFF59E0B);

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in again.')));
    }

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('users/${user.uid}').onValue,
      builder: (context, userSnapshot) {
        final raw = userSnapshot.data?.snapshot.value;
        final data =
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        final teacherName =
        (data['name'] ?? user.displayName ?? 'Teacher').toString();

        return Scaffold(
          backgroundColor: paper,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _header(context, teacherName),
                Transform.translate(
                  offset: const Offset(0, -36),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _statsStrip(user.uid),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _createContent(context),
                      const SizedBox(height: 28),
                      const Text(
                        'Your classroom',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _classroomTiles(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, String teacherName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 72),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ink, Color(0xFF3B3F8F)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/teacherProfile'),
                    child: const CircleAvatar(
                      radius: 23,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person_rounded, color: ink),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: () => _comingSoon(context, 'Notifications'),
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                '${_greeting()},',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                teacherName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Here is what is happening in your classes.',
                style: TextStyle(color: Colors.white70, fontSize: 13.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsStrip(String teacherId) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _teacherCourseCount(teacherId),
          _divider(),
          _studentCount(),
          _divider(),
          _teacherAssignmentCount(teacherId),
        ],
      ),
    );
  }

  /// Courses are stored in Realtime Database.
  Widget _teacherCourseCount(String teacherId) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('courses').onValue,
      builder: (context, snapshot) {
        var count = 0;
        final v = snapshot.data?.snapshot.value;

        if (v is Map) {
          for (final course in v.values) {
            if (course is Map && course['teacherId']?.toString() == teacherId) {
              count++;
            }
          }
        }

        return _stat('Courses', '$count', violet);
      },
    );
  }

  /// Students are all users with the student role (Realtime Database).
  Widget _studentCount() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('users').onValue,
      builder: (context, snapshot) {
        var count = 0;
        final v = snapshot.data?.snapshot.value;
        if (v is Map) {
          for (final u in v.values) {
            if (u is Map && u['role']?.toString().toLowerCase() == 'student') {
              count++;
            }
          }
        }
        return _stat('Students', '$count', teal);
      },
    );
  }

  Widget _teacherAssignmentCount(String teacherId) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('assignments').onValue,
      builder: (context, snapshot) {
        var count = 0;
        final v = snapshot.data?.snapshot.value;
        if (v is Map) {
          for (final a in v.values) {
            if (a is Map && a['teacherId']?.toString() == teacherId) count++;
          }
        }
        return _stat('Assignments', '$count', coral);
      },
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 35, color: Colors.grey.shade200);
  }

  Widget _createContent(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCreateMenu(context),
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [coral, Color(0xFFFF9A62)],
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create classroom content',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Create courses, assignments, quizzes and classes.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(Icons.add_rounded, color: coral, size: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                _createOption(Icons.menu_book_rounded, 'Course', () {
                  Navigator.pop(sheetContext);
                  _open(context, const AddCourseScreen());
                }),
                _createOption(Icons.assignment_rounded, 'Assignment', () {
                  Navigator.pop(sheetContext);
                  _open(context, const AddAssignmentScreen());
                }),
                _createOption(Icons.quiz_rounded, 'Quiz', () {
                  Navigator.pop(sheetContext);
                  _open(context, const AddQuizScreen());
                }),
                _createOption(Icons.calendar_month_rounded, 'Class', () {
                  Navigator.pop(sheetContext);
                  _open(context, const AddClassScreen());
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _createOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: violet.withValues(alpha: .1),
        child: Icon(icon, color: violet),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
    );
  }

  Widget _classroomTiles(BuildContext context) {
    return Column(
      children: [
        _tile(
          icon: Icons.menu_book_rounded,
          title: 'My Courses',
          subtitle: 'Create and manage your courses',
          color: violet,
          onTap: () => Navigator.pushNamed(context, '/teacherCourses'),
        ),
        const SizedBox(height: 12),
        _tile(
          icon: Icons.assignment_rounded,
          title: 'Assignments',
          subtitle: 'Create and review student work',
          color: coral,
          onTap: () => _open(context, const TeacherAssignmentsScreen()),
        ),
        const SizedBox(height: 12),
        _tile(
          icon: Icons.quiz_rounded,
          title: 'Quizzes',
          subtitle: 'Create and manage quizzes',
          color: amber,
          onTap: () => _open(context, const TeacherQuizzesScreen()),
        ),
        const SizedBox(height: 12),
        _tile(
          icon: Icons.fact_check_rounded,
          title: 'Attendance',
          subtitle: 'Record student attendance',
          color: teal,
          onTap: () => _open(context, const TeacherAttendanceScreen()),
        ),
        const SizedBox(height: 12),
        _tile(
          icon: Icons.grade_rounded,
          title: 'Marks',
          subtitle: 'Enter and manage student marks',
          color: ink,
          onTap: () => _comingSoon(context, 'Marks'),
        ),
        const SizedBox(height: 12),
        _tile(
          icon: Icons.calendar_month_rounded,
          title: 'Classes',
          subtitle: 'Create and manage class schedules',
          color: violet,
          onTap: () => _open(context, const TeacherClassesScreen()),
        ),
        const SizedBox(height: 12),
        _tile(
          icon: Icons.sticky_note_2_rounded,
          title: 'Notes',
          subtitle: 'Upload learning material',
          color: teal,
          onTap: () => _comingSoon(context, 'Notes'),
        ),
      ],
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: .18)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}