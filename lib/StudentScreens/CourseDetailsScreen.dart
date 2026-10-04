import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class CourseDetailsScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  static const Color primary = Color(0xFF1355D6);
  static const Color primaryDark = Color(0xFF0B3A9E);
  static const Color background = Color(0xFFF4F6FB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0F1355D6),
        blurRadius: 14,
        offset: Offset(0, 5),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('courses/$courseId');

    return Scaffold(
      backgroundColor: background,
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primary),
            );
          }

          if (snapshot.hasError) {
            return _message(context, 'Unable to load course.\n${snapshot.error}');
          }

          final value = snapshot.data?.snapshot.value;
          if (value is! Map) {
            return _message(context, 'This course no longer exists.');
          }

          final course = Map<String, dynamic>.from(value);
          final name = (course['courseName'] ?? 'Unnamed Course').toString();
          final code = (course['courseCode'] ?? 'No Code').toString();
          final description =
          (course['description'] ?? 'No description available.').toString();
          final teacher = (course['teacherName'] ?? 'Teacher').toString();

          return SingleChildScrollView(
            child: Column(
              children: [
                _header(context, name, code),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title('About this course'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: _card(),
                        child: Text(
                          description,
                          style: const TextStyle(
                            color: textGrey,
                            fontSize: 13.5,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _title('Instructor'),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: _card(),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFE8EFFF),
                              child: Text(
                                teacher.isEmpty
                                    ? 'T'
                                    : teacher[0].toUpperCase(),
                                style: const TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    teacher,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Course Teacher',
                                    style: TextStyle(
                                      color: textGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _title('Course Content'),
                      Row(
                        children: [
                          Expanded(
                            child: _contentTile(
                              Icons.assignment_rounded,
                              'Assignments',
                              const Color(0xFFF59E0B),
                              const Color(0xFFFEF3C7),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _contentTile(
                              Icons.quiz_rounded,
                              'Quizzes',
                              const Color(0xFF8B5CF6),
                              const Color(0xFFEDE9FE),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _contentTile(
                              Icons.folder_rounded,
                              'Materials',
                              const Color(0xFF10B981),
                              const Color(0xFFD1FAE5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, String name, String code) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.of(context).padding.top + 8,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentTile(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _card(),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Coming soon',
            style: TextStyle(color: textGrey, fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  Widget _message(BuildContext context, String text) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textGrey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}