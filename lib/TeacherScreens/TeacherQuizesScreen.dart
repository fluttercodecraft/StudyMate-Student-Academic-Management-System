import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/TeacherScreens/AddQuizesScreen.dart';


class TeacherQuizzesScreen extends StatelessWidget {
  const TeacherQuizzesScreen({super.key});

  static const Color ink = Color(0xFF1B1F3B);
  static const Color paper = Color(0xFFF3F5FA);
  static const Color violet = Color(0xFF6C5CE7);
  static const Color amber = Color(0xFFF59E0B);

  DateTime? _toDate(dynamic v) =>
      v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;

  String _formatDate(BuildContext context, DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}, '
        '${TimeOfDay.fromDateTime(d).format(context)}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: paper,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddQuizScreen()),
        ),
        backgroundColor: amber,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label:
        const Text('New', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: user == null
                ? const Center(child: Text('Please log in again.'))
                : StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('quizzes').onValue,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _state(Icons.error_outline_rounded,
                      'Unable to load', '${snap.error}');
                }
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: violet),
                  );
                }

                final raw = snap.data!.snapshot.value;
                final items = <Map<String, dynamic>>[];

                if (raw is Map) {
                  raw.forEach((key, value) {
                    if (value is Map) {
                      final q = Map<String, dynamic>.from(value);
                      if (q['teacherId']?.toString() == user.uid) {
                        q['quizId'] = q['quizId'] ?? key;
                        items.add(q);
                      }
                    }
                  });
                }

                items.sort((a, b) {
                  final x = _toDate(a['date']);
                  final y = _toDate(b['date']);
                  if (x == null || y == null) return 0;
                  return y.compareTo(x);
                });

                if (items.isEmpty) {
                  return _state(
                    Icons.quiz_rounded,
                    'No quizzes yet',
                    'Tap "New" to create your first quiz.',
                  );
                }

                return StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref('quizResults')
                      .onValue,
                  builder: (context, resSnap) {
                    final results = resSnap.data?.snapshot.value;

                    return ListView(
                      padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 90),
                      children: items.map((q) {
                        var submitted = 0;
                        if (results is Map) {
                          final r = results[q['quizId']];
                          if (r is Map) submitted = r.length;
                        }
                        return _card(context, q, submitted);
                      }).toList(),
                    );
                  },
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
              'My Quizzes',
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

  Widget _card(BuildContext context, Map<String, dynamic> q, int submitted) {
    final id = q['quizId'].toString();
    final title = (q['title'] ?? 'Quiz').toString();
    final course = (q['courseName'] ?? '').toString();
    final date = _toDate(q['date']);
    final count = q['questionCount'] ?? 0;
    final minutes = q['durationMinutes'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: amber.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: amber.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.quiz_rounded, color: amber),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ink)),
                if (course.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(course,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (date != null) _formatDate(context, date),
                    '$count questions',
                    '$minutes min',
                  ].join('  •  '),
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$submitted submitted',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: violet,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, id, title),
            icon:
            Icon(Icons.delete_outline_rounded, color: Colors.red.shade300),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String id, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete quiz?'),
        content: Text('"$title" and all student results will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseDatabase.instance.ref('quizzes/$id').remove();
      await FirebaseDatabase.instance.ref('quizResults/$id').remove();
    }
  }

  Widget _state(IconData icon, String title, String message) {
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
                color: violet.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: violet, size: 42),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}