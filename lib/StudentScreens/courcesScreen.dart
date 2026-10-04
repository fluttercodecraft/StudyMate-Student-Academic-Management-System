import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/StudentScreens/CourseDetailsScreen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  static const Color primary = Color(0xFF1355D6);
  static const Color primaryDark = Color(0xFF0B3A9E);
  static const Color background = Color(0xFFF4F6FB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  final DatabaseReference _coursesRef =
  FirebaseDatabase.instance.ref('courses');

  String _query = '';

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
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _coursesRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                if (snapshot.hasError) {
                  return _stateView(
                    Icons.error_outline_rounded,
                    'Unable to load courses',
                    '${snapshot.error}',
                  );
                }

                final data = snapshot.data?.snapshot.value;
                final List<Map<String, dynamic>> courses = [];

                if (data is Map) {
                  data.forEach((key, value) {
                    if (value is Map) {
                      final c = Map<String, dynamic>.from(value);
                      c['courseId'] = c['courseId'] ?? key;
                      courses.add(c);
                    }
                  });
                }

                if (courses.isEmpty) {
                  return _stateView(
                    Icons.menu_book_rounded,
                    'No Courses Available',
                    'Courses created by your teachers will appear here.',
                  );
                }

                final q = _query.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? courses
                    : courses.where((c) {
                  final name =
                  (c['courseName'] ?? '').toString().toLowerCase();
                  final code =
                  (c['courseCode'] ?? '').toString().toLowerCase();
                  final teacher =
                  (c['teacherName'] ?? '').toString().toLowerCase();
                  return name.contains(q) ||
                      code.contains(q) ||
                      teacher.contains(q);
                }).toList();

                return RefreshIndicator(
                  color: primary,
                  onRefresh: () async {
                    await _coursesRef.once();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '${filtered.length} course${filtered.length == 1 ? '' : 's'} available',
                          style: const TextStyle(
                            color: textGrey,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 50),
                          child: _stateView(
                            Icons.search_off_rounded,
                            'No matches',
                            'Try a different name, code, or teacher.',
                          ),
                        )
                      else
                        ...filtered.map(_courseCard),
                    ],
                  ),
                );
              },
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
        22,
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
        children: [
          Row(
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
                  'Courses',
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
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search courses, codes, teachers...',
                hintStyle: const TextStyle(color: textGrey, fontSize: 13),
                prefixIcon:
                const Icon(Icons.search_rounded, color: textGrey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseCard(Map<String, dynamic> course) {
    final courseId = course['courseId']?.toString() ?? '';
    final name = course['courseName']?.toString() ?? 'Unnamed Course';
    final code = course['courseCode']?.toString() ?? 'No Code';
    final description =
        course['description']?.toString() ?? 'No description available';
    final teacher = course['teacherName']?.toString() ?? 'Teacher';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: _card(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailsScreen(courseId: courseId),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFFF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: primary,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EFFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textGrey,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              color: textGrey,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                teacher,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: textGrey,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stateView(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EFFF),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: primary, size: 42),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textGrey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}