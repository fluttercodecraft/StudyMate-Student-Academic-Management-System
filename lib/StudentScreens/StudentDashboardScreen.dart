import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/AuthScreens/LoginScreen.dart';
import 'package:study_mate/StudentScreens/courcesScreen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  static const Color primary = Color(0xFF1355D6);
  static const Color primaryDark = Color(0xFF0B3A9E);
  static const Color background = Color(0xFFF4F6FB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  // ---------- helpers ----------
  String _firstLetter(String name) {
    final v = name.trim();
    return v.isEmpty ? 'S' : v[0].toUpperCase();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  DateTime? _toDate(dynamic v) => v is Timestamp ? v.toDate() : null;

  String _formatDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month - 1]}';
  }

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

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in again.')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final name = (data['name'] ?? user.displayName ?? 'Student').toString();
        final email = (data['email'] ?? user.email ?? 'No email').toString();
        final photoUrl = (data['profileImageUrl'] ?? '').toString();

        return Scaffold(
          backgroundColor: background,
          body: RefreshIndicator(
            color: primary,
            onRefresh: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _header(context, user.uid, name, photoUrl),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Study Tools'),
                        _studyTools(context),
                        const SizedBox(height: 26),
                        _sectionTitle("Today's Classes"),
                        _todayClasses(user.uid),
                        const SizedBox(height: 26),
                        _sectionTitle('Upcoming Assignments'),
                        _assignments(user.uid),
                        const SizedBox(height: 26),
                        _sectionTitle('Quizzes'),
                        _quizzes(user.uid),
                        const SizedBox(height: 26),
                        _accountCard(context, name, email, photoUrl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- header ----------
  Widget _header(
      BuildContext context, String uid, String name, String photoUrl) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 24),
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
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/studentProfile'),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFE8EFFF),
                    backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(
                      _firstLetter(name),
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white24,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => _showNotifications(context),
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Stay organized and\nkeep learning 🚀',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _stats(uid),
        ],
      ),
    );
  }

  Widget _stats(String uid) {
    return Row(
      children: [
        Expanded(
          // Courses live in Realtime Database
          child: StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance.ref('courses').onValue,
            builder: (context, snap) {
              final v = snap.data?.snapshot.value;
              final count = v is Map ? v.length : 0;
              return _statCard(Icons.menu_book_rounded, '$count', 'Courses');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _firestoreStat(uid, 'assignments', Icons.assignment_rounded, 'Assignments')),
        const SizedBox(width: 10),
        Expanded(child: _firestoreStat(uid, 'quizzes', Icons.quiz_rounded, 'Quizzes')),
      ],
    );
  }

  Widget _firestoreStat(
      String uid, String collection, IconData icon, String label) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('studentIds', arrayContains: uid)
          .snapshots(),
      builder: (context, snap) =>
          _statCard(icon, '${snap.data?.docs.length ?? 0}', label),
    );
  }

  Widget _statCard(IconData icon, String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  // ---------- sections ----------
  Widget _sectionTitle(String title) {
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
            title,
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

  Widget _studyTools(BuildContext context) {
    final tools = <_Tool>[
      _Tool(Icons.menu_book_rounded, 'Courses', const Color(0xFF1355D6),
          const Color(0xFFE8EFFF), () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CoursesScreen()));
          }),
      _Tool(Icons.assignment_rounded, 'Assignments', const Color(0xFFF59E0B),
          const Color(0xFFFEF3C7),
              () => Navigator.pushNamed(context, '/studentAssignments')),
      _Tool(Icons.quiz_rounded, 'Quizzes', const Color(0xFF8B5CF6),
          const Color(0xFFEDE9FE),
              () => Navigator.pushNamed(context, '/studentQuizzes')),
      _Tool(Icons.fact_check_rounded, 'Attendance', const Color(0xFF10B981),
          const Color(0xFFD1FAE5),
              () => Navigator.pushNamed(context, '/studentAttendance')),
      _Tool(Icons.bar_chart_rounded, 'Marks', const Color(0xFFEF4444),
          const Color(0xFFFEE2E2),
              () => Navigator.pushNamed(context, '/studentMarks')),
      _Tool(Icons.calendar_month_rounded, 'Timetable', const Color(0xFF0EA5E9),
          const Color(0xFFE0F2FE),
              () => Navigator.pushNamed(context, '/studentTimetable')),
      _Tool(Icons.sticky_note_2_rounded, 'Notes', const Color(0xFFEC4899),
          const Color(0xFFFCE7F3),
              () => Navigator.pushNamed(context, '/studentNotes')),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 14,
      crossAxisSpacing: 10,
      childAspectRatio: .78,
      children: tools.map(_toolItem).toList(),
    );
  }

  Widget _toolItem(_Tool t) {
    return GestureDetector(
      onTap: t.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: t.bg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(t.icon, color: t.color, size: 28),
          ),
          const SizedBox(height: 7),
          Text(
            t.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- classes ----------
  Widget _todayClasses(String uid) {
    final now = DateTime.now();
    final start = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final end = Timestamp.fromDate(DateTime(now.year, now.month, now.day + 1));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('studentIds', arrayContains: uid)
          .where('startAt', isGreaterThanOrEqualTo: start)
          .where('startAt', isLessThan: end)
          .orderBy('startAt')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _emptyCard(Icons.error_outline_rounded,
              "Could not load today's classes.");
        }
        if (!snap.hasData) return _loadingCard();
        if (snap.data!.docs.isEmpty) {
          return _emptyCard(
              Icons.free_breakfast_rounded, 'No classes scheduled today.');
        }

        return Column(
          children: snap.data!.docs.map((doc) {
            final d = doc.data();
            final subject = (d['subject'] ?? 'Class').toString();
            final teacher = (d['teacher'] ?? '').toString();
            final room = (d['room'] ?? '').toString();
            final s = _toDate(d['startAt']);
            final e = _toDate(d['endAt']);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: _card(),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 46,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subject,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (teacher.isNotEmpty) teacher,
                            if (room.isNotEmpty) 'Room $room',
                          ].join('  •  '),
                          style: const TextStyle(
                              color: textGrey, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  if (s != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EFFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        e == null
                            ? TimeOfDay.fromDateTime(s).format(context)
                            : '${TimeOfDay.fromDateTime(s).format(context)}\n'
                            '${TimeOfDay.fromDateTime(e).format(context)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
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

  // ---------- assignments ----------
  Widget _assignments(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('assignments')
          .where('studentIds', arrayContains: uid)
          .orderBy('dueDate')
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _emptyCard(
              Icons.error_outline_rounded, 'Could not load assignments.');
        }
        if (!snap.hasData) return _loadingCard();
        if (snap.data!.docs.isEmpty) {
          return _emptyCard(
              Icons.task_alt_rounded, 'No assignments available.');
        }

        return Column(
          children: snap.data!.docs.map((doc) {
            final d = doc.data();
            final title = (d['title'] ?? 'Assignment').toString();
            final course = (d['courseName'] ?? '').toString();
            final due = _toDate(d['dueDate']);

            return _listTile(
              icon: Icons.assignment_rounded,
              color: const Color(0xFFF59E0B),
              bg: const Color(0xFFFEF3C7),
              title: title,
              subtitle: course,
              trailing: due == null
                  ? null
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Due',
                      style: TextStyle(color: textGrey, fontSize: 10)),
                  Text(
                    _formatDate(due),
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 12,
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

  // ---------- quizzes ----------
  Widget _quizzes(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('quizzes')
          .where('studentIds', arrayContains: uid)
          .orderBy('date')
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _emptyCard(
              Icons.error_outline_rounded, 'Could not load quizzes.');
        }
        if (!snap.hasData) return _loadingCard();
        if (snap.data!.docs.isEmpty) {
          return _emptyCard(Icons.lightbulb_outline_rounded,
              'No quizzes available.');
        }

        return Column(
          children: snap.data!.docs.map((doc) {
            final d = doc.data();
            final title = (d['title'] ?? 'Quiz').toString();
            final course = (d['courseName'] ?? '').toString();
            final q = d['questionCount'];
            final m = d['durationMinutes'];

            return _listTile(
              icon: Icons.quiz_rounded,
              color: const Color(0xFF8B5CF6),
              bg: const Color(0xFFEDE9FE),
              title: title,
              subtitle: course,
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (q != null)
                    Text('$q Questions',
                        style:
                        const TextStyle(color: textGrey, fontSize: 10.5)),
                  if (m != null)
                    Text('$m min',
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        )),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _listTile({
    required IconData icon,
    required Color color,
    required Color bg,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                        const TextStyle(color: textGrey, fontSize: 11.5)),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ---------- account ----------
  Widget _accountCard(
      BuildContext context, String name, String email, String photoUrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: const Color(0xFFE8EFFF),
            backgroundImage:
            photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Text(_firstLetter(name),
                style: const TextStyle(
                    color: primary, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: textGrey, fontSize: 12)),
              ],
            ),
          ),
          Material(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- misc ----------
  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_rounded,
                  size: 42, color: primary),
              SizedBox(height: 12),
              Text('Notifications',
                  style:
                  TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Your teacher updates will appear here.',
                  style: TextStyle(color: Colors.grey)),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _card(),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: primary),
        ),
      ),
    );
  }

  Widget _emptyCard(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: _card(),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFB6C2DA), size: 34),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: textGrey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Tool {
  final IconData icon;
  final String title;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _Tool(this.icon, this.title, this.color, this.bg, this.onTap);
}