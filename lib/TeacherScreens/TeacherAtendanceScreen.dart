import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/AuthScreens/LoginScreen.dart';
import 'package:study_mate/StudentScreens/AssignmentsScreen.dart';
import 'package:study_mate/StudentScreens/AttendanceScreen.dart';
import 'package:study_mate/StudentScreens/QuizzesScreen.dart';
import 'package:study_mate/StudentScreens/TimetableScreen.dart';
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

  DateTime? _toDate(dynamic v) {
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  /// Streams every child of a Realtime Database node as a list of maps.
  Stream<List<Map<String, dynamic>>> _list(String node) {
    return FirebaseDatabase.instance.ref(node).onValue.map((e) {
      final v = e.snapshot.value;
      final out = <Map<String, dynamic>>[];
      if (v is Map) {
        v.forEach((k, val) {
          if (val is Map) out.add(Map<String, dynamic>.from(val));
        });
      }
      return out;
    });
  }

  String _formatDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month - 1]}';
  }

  List<Map<String, dynamic>> _sorted(
      List<Map<String, dynamic>> items,
      String field, {
        DateTime? from,
        DateTime? to,
        bool upcomingOnly = false,
        int limit = 10,
      }) {
    final now = DateTime.now();
    final list = items.where((d) {
      final t = _toDate(d[field]);
      if (from != null && to != null) {
        return t != null && !t.isBefore(from) && t.isBefore(to);
      }
      if (upcomingOnly) return t == null || !t.isBefore(now);
      return true;
    }).toList();

    list.sort((a, b) {
      final x = _toDate(a[field]);
      final y = _toDate(b[field]);
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    });
    return list.take(limit).toList();
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

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('users/${user.uid}').onValue,
      builder: (context, snap) {
        final raw = snap.data?.snapshot.value;
        final data =
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        final name = (data['name'] ?? user.displayName ?? 'Student').toString();
        final email = (data['email'] ?? user.email ?? 'No email').toString();
        final photoUrl = (data['profileImageUrl'] ?? '').toString();

        return Scaffold(
          backgroundColor: background,
          body: RefreshIndicator(
            color: primary,
            onRefresh: () async {
              await FirebaseDatabase.instance.ref('users/${user.uid}').get();
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
        Expanded(child: _rtdbStat('assignments', Icons.assignment_rounded, 'Assignments')),
        const SizedBox(width: 10),
        Expanded(child: _rtdbStat('quizzes', Icons.quiz_rounded, 'Quizzes')),
      ],
    );
  }

  Widget _rtdbStat(String node, IconData icon, String label) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _list(node),
      builder: (context, snap) =>
          _statCard(icon, '${snap.data?.length ?? 0}', label),
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
              () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AssignmentsScreen()))),
      _Tool(Icons.quiz_rounded, 'Quizzes', const Color(0xFF8B5CF6),
          const Color(0xFFEDE9FE),
              () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const QuizzesScreen()))),
      _Tool(Icons.fact_check_rounded, 'Attendance', const Color(0xFF10B981),
          const Color(0xFFD1FAE5),
              () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AttendanceScreen()))),
      _Tool(Icons.bar_chart_rounded, 'Marks', const Color(0xFFEF4444),
          const Color(0xFFFEE2E2),
              () => Navigator.pushNamed(context, '/studentMarks')),
      _Tool(Icons.calendar_month_rounded, 'Timetable', const Color(0xFF0EA5E9),
          const Color(0xFFE0F2FE),
              () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TimetableScreen()))),
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
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 1);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _list('classes'),
      builder: (context, snap) {
        if (snap.hasError) {
          return _emptyCard(Icons.error_outline_rounded,
              "Could not load today's classes.");
        }
        if (!snap.hasData) return _loadingCard();

        final items =
        _sorted(snap.data!, 'startAt', from: start, to: end, limit: 50);
        if (items.isEmpty) {
          return _emptyCard(
              Icons.free_breakfast_rounded, 'No classes scheduled today.');
        }

        return Column(
          children: items.map((d) {
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _list('assignments'),
      builder: (context, snap) {
        if (snap.hasError) {
          return _emptyCard(
              Icons.error_outline_rounded, 'Could not load assignments.');
        }
        if (!snap.hasData) return _loadingCard();

        final items = _sorted(snap.data!, 'dueDate', upcomingOnly: true);
        if (items.isEmpty) {
          return _emptyCard(
              Icons.task_alt_rounded, 'No upcoming assignments.');
        }

        return Column(
          children: items.map((d) {
            final due = _toDate(d['dueDate']);

            return _listTile(
              icon: Icons.assignment_rounded,
              color: const Color(0xFFF59E0B),
              bg: const Color(0xFFFEF3C7),
              title: (d['title'] ?? 'Assignment').toString(),
              subtitle: (d['courseName'] ?? '').toString(),
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _list('quizzes'),
      builder: (context, snap) {
        if (snap.hasError) {
          return _emptyCard(
              Icons.error_outline_rounded, 'Could not load quizzes.');
        }
        if (!snap.hasData) return _loadingCard();

        final items = _sorted(snap.data!, 'date', upcomingOnly: true);
        if (items.isEmpty) {
          return _emptyCard(
              Icons.lightbulb_outline_rounded, 'No upcoming quizzes.');
        }

        return Column(
          children: items.map((d) {
            final q = d['questionCount'];
            final m = d['durationMinutes'];

            return _listTile(
              icon: Icons.quiz_rounded,
              color: const Color(0xFF8B5CF6),
              bg: const Color(0xFFEDE9FE),
              title: (d['title'] ?? 'Quiz').toString(),
              subtitle: (d['courseName'] ?? '').toString(),
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