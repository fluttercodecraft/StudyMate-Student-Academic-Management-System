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

class _CoursesScreenState extends State<CoursesScreen> {
  static const Color _primaryColor = Color(0xFF1355D6);

  late Future<_CoursesLoadResult> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _loadCourses();
  }

  Future<_CoursesLoadResult> _loadCourses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _CoursesLoadResult(
        department: null,
        semester: null,
        courses: [],
      );
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final department = userDoc.data()?['department'] as String?;
    final semester = userDoc.data()?['semester'] as String?;

    if (department == null || semester == null) {
      return _CoursesLoadResult(
        department: department,
        semester: semester,
        courses: const [],
      );
    }

    final coursesSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('department', isEqualTo: department)
        .where('semester', isEqualTo: semester)
        .get();

    final courses = coursesSnapshot.docs
        .map((doc) => _Course.fromMap(doc.id, doc.data()))
        .toList();

    return _CoursesLoadResult(
      department: department,
      semester: semester,
      courses: courses,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _coursesFuture = _loadCourses();
    });
    await _coursesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Courses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<_CoursesLoadResult>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildMessage(
              icon: Icons.error_outline_rounded,
              title: 'Something went wrong',
              subtitle: '${snapshot.error}',
            );
          }

          final result = snapshot.data!;

          if (result.department == null || result.semester == null) {
            return _buildMessage(
              icon: Icons.info_outline_rounded,
              title: 'Profile incomplete',
              subtitle:
              'We couldn\'t find a department and semester on your account. Please update your profile.',
            );
          }

          if (result.courses.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  _buildMessage(
                    icon: Icons.menu_book_outlined,
                    title: 'No courses yet',
                    subtitle:
                    'No courses have been added for ${result.department}, Semester ${result.semester}.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${result.department}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Semester ${result.semester} · ${result.courses.length} course${result.courses.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 18),
                ...result.courses.map((course) => _buildCourseCard(course)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(_Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFFF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: _primaryColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (course.code.isNotEmpty)
                  Text(
                    course.code,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (course.instructor.isNotEmpty)
                      _buildTag(Icons.person_outline, course.instructor),
                    if (course.creditHours != null)
                      _buildTag(
                        Icons.timelapse_rounded,
                        '${course.creditHours} Cr Hr',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
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