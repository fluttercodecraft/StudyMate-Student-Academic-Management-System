import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/AuthScreens/LoginScreen.dart';
import 'package:study_mate/StudentScreens/courcesScreen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  static const Color primary = Color(0xFF1355D6);
  static const Color background = Color(0xFFF5F7FB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color border = Color(0xFFE6EAF0);

  String _firstLetter(String name) {
    final value = name.trim();
    if (value.isEmpty) return 'S';
    return value[0].toUpperCase();
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in again.'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? {};

        final name = (userData['name'] ??
            user.displayName ??
            'Student')
            .toString();

        final email = (userData['email'] ??
            user.email ??
            'No email')
            .toString();

        final photoUrl =
        (userData['profileImageUrl'] ?? '').toString();

        return Scaffold(
          backgroundColor: background,
          appBar: _buildAppBar(
            context,
            name,
            photoUrl,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _welcomeCard(name),
                  const SizedBox(height: 22),

                  const Text(
                    "Today's Overview",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _overview(
                    context,
                    user.uid,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Today's Classes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _todayClasses(user.uid),

                  const SizedBox(height: 24),

                  const Text(
                    'Upcoming Assignments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _assignments(user.uid),

                  const SizedBox(height: 24),

                  const Text(
                    "Today's Quizzes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _quizzes(user.uid),

                  const SizedBox(height: 24),

                  const Text(
                    'Study Tools',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _studyTools(context),

                  const SizedBox(height: 24),

                  _accountCard(
                    context,
                    name,
                    email,
                    photoUrl,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context,
      String name,
      String photoUrl,
      ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'StudyMate',
            style: TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Student Dashboard',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            _showNotifications(context);
          },
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: textDark,
            size: 27,
          ),
        ),

        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/studentProfile',
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFFE8EFFF),
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Text(
                _firstLetter(name),
                style: const TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _welcomeCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $name 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Stay organized and keep learning.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Learn Smarter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overview(
      BuildContext context,
      String studentId,
      ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('studentIds', arrayContains: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        final courses = snapshot.data?.docs.length ?? 0;

        return Row(
          children: [
            Expanded(
              child: _overviewCard(
                Icons.menu_book_rounded,
                '$courses',
                'Courses',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _countAssignments(studentId),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _countQuizzes(studentId),
            ),
          ],
        );
      },
    );
  }

  Widget _overviewCard(
      IconData icon,
      String number,
      String title,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(
            icon,
            color: primary,
            size: 22,
          ),
          const SizedBox(height: 7),
          Text(
            number,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countAssignments(String studentId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('assignments')
          .where('studentIds', arrayContains: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        return _overviewCard(
          Icons.assignment_rounded,
          '${snapshot.data?.docs.length ?? 0}',
          'Assignments',
        );
      },
    );
  }

  Widget _countQuizzes(String studentId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('quizzes')
          .where('studentIds', arrayContains: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        return _overviewCard(
          Icons.quiz_rounded,
          '${snapshot.data?.docs.length ?? 0}',
          'Quizzes',
        );
      },
    );
  }

  Widget _todayClasses(String studentId) {
    final now = DateTime.now();

    final start = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day),
    );

    final end = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day + 1),
    );

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where(
        'studentIds',
        arrayContains: studentId,
      )
          .where(
        'startAt',
        isGreaterThanOrEqualTo: start,
      )
          .where(
        'startAt',
        isLessThan: end,
      )
          .orderBy('startAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyCard(
            'Could not load today\'s classes.',
          );
        }

        if (!snapshot.hasData) {
          return _loadingCard();
        }

        if (snapshot.data!.docs.isEmpty) {
          return _emptyCard(
            'No classes scheduled today.',
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data();

            final subject =
            (data['subject'] ?? 'Class').toString();

            final teacher =
            (data['teacher'] ?? '').toString();

            final room =
            (data['room'] ?? '').toString();

            final startTime =
            _toDate(data['startAt']);

            final endTime =
            _toDate(data['endAt']);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  _iconBox(
                    Icons.menu_book_rounded,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),

                        if (teacher.isNotEmpty)
                          Padding(
                            padding:
                            const EdgeInsets.only(top: 4),
                            child: Text(
                              teacher,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ),

                        if (room.isNotEmpty)
                          Padding(
                            padding:
                            const EdgeInsets.only(top: 4),
                            child: Text(
                              'Room $room',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (startTime != null)
                    Text(
                      endTime == null
                          ? TimeOfDay.fromDateTime(
                        startTime,
                      ).format(context)
                          : '${TimeOfDay.fromDateTime(startTime).format(context)}\n'
                          '${TimeOfDay.fromDateTime(endTime).format(context)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _assignments(String studentId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('assignments')
          .where(
        'studentIds',
        arrayContains: studentId,
      )
          .orderBy('dueDate')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyCard(
            'Could not load assignments.',
          );
        }

        if (!snapshot.hasData) {
          return _loadingCard();
        }

        if (snapshot.data!.docs.isEmpty) {
          return _emptyCard(
            'No assignments available.',
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data();

            final title =
            (data['title'] ?? 'Assignment').toString();

            final course =
            (data['courseName'] ?? '').toString();

            final due =
            _toDate(data['dueDate']);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  _iconBox(
                    Icons.assignment_rounded,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (course.isNotEmpty)
                          Padding(
                            padding:
                            const EdgeInsets.only(top: 4),
                            child: Text(
                              course,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (due != null)
                    Text(
                      _formatDate(due),
                      style: const TextStyle(
                        color: primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _quizzes(String studentId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('quizzes')
          .where(
        'studentIds',
        arrayContains: studentId,
      )
          .orderBy('date')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyCard(
            'Could not load quizzes.',
          );
        }

        if (!snapshot.hasData) {
          return _loadingCard();
        }

        if (snapshot.data!.docs.isEmpty) {
          return _emptyCard(
            'No quizzes available.',
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data();

            final title =
            (data['title'] ?? 'Quiz').toString();

            final course =
            (data['courseName'] ?? '').toString();

            final questions =
            data['questionCount'];

            final minutes =
            data['durationMinutes'];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  _iconBox(
                    Icons.quiz_rounded,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (course.isNotEmpty)
                          Padding(
                            padding:
                            const EdgeInsets.only(top: 4),
                            child: Text(
                              course,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    children: [
                      if (questions != null)
                        Text(
                          '$questions Questions',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      if (minutes != null)
                        Text(
                          '$minutes Minutes',
                          style: const TextStyle(
                            color: primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _studyTools(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: .95,
      children: [
        _tool(
          context,
          Icons.menu_book_rounded,
          'Courses',
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CoursesScreen(),
              ),
            );
          },
        ),
        _tool(
          context,
          Icons.assignment_rounded,
          'Assignments',
              () {
            Navigator.pushNamed(
              context,
              '/studentAssignments',
            );
          },
        ),
        _tool(
          context,
          Icons.quiz_rounded,
          'Quizzes',
              () {
            Navigator.pushNamed(
              context,
              '/studentQuizzes',
            );
          },
        ),
        _tool(
          context,
          Icons.fact_check_rounded,
          'Attendance',
              () {
            Navigator.pushNamed(
              context,
              '/studentAttendance',
            );
          },
        ),
        _tool(
          context,
          Icons.bar_chart_rounded,
          'Marks',
              () {
            Navigator.pushNamed(
              context,
              '/studentMarks',
            );
          },
        ),
        _tool(
          context,
          Icons.calendar_month_rounded,
          'Timetable',
              () {
            Navigator.pushNamed(
              context,
              '/studentTimetable',
            );
          },
        ),
        _tool(
          context,
          Icons.sticky_note_2_rounded,
          'Notes',
              () {
            Navigator.pushNamed(
              context,
              '/studentNotes',
            );
          },
        ),
      ],
    );
  }

  Widget _tool(
      BuildContext context,
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconBox(
                icon,
                size: 42,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountCard(
      BuildContext context,
      String name,
      String email,
      String photoUrl,
      ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: const Color(0xFFE8EFFF),
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl.isEmpty
                ? Text(
              _firstLetter(name),
              style: const TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreen())
              );
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (_) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Your teacher updates will appear here.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _iconBox(
      IconData icon, {
        double size = 46,
      }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: primary,
        size: 22,
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: _cardDecoration(),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: border,
      ),
    );
  }
}