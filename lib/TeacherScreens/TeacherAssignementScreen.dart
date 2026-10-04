import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/TeacherScreens/AddAssignmentScreen.dart';

class TeacherAssignmentsScreen extends StatelessWidget {
  const TeacherAssignmentsScreen({super.key});

  static const Color ink = Color(0xFF1B1F3B);
  static const Color paper = Color(0xFFF3F5FA);
  static const Color violet = Color(0xFF6C5CE7);
  static const Color coral = Color(0xFFFF6B5E);

  DateTime? _toDate(dynamic v) =>
      v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;

  String _formatDue(BuildContext context, DateTime d) {
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
          MaterialPageRoute(builder: (_) => const AddAssignmentScreen()),
        ),
        backgroundColor: coral,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: user == null
                ? const Center(child: Text('Please log in again.'))
                : StreamBuilder<DatabaseEvent>(
              stream:
              FirebaseDatabase.instance.ref('assignments').onValue,
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
                      final a = Map<String, dynamic>.from(value);
                      if (a['teacherId']?.toString() == user.uid) {
                        a['assignmentId'] = a['assignmentId'] ?? key;
                        items.add(a);
                      }
                    }
                  });
                }

                items.sort((a, b) {
                  final x = _toDate(a['dueDate']);
                  final y = _toDate(b['dueDate']);
                  if (x == null || y == null) return 0;
                  return y.compareTo(x); // latest due date first
                });

                if (items.isEmpty) {
                  return _state(
                    Icons.assignment_rounded,
                    'No assignments yet',
                    'Tap "New" to create your first assignment.',
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                  children:
                  items.map((a) => _card(context, a)).toList(),
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
              'My Assignments',
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

  Widget _card(BuildContext context, Map<String, dynamic> d) {
    final id = d['assignmentId'].toString();
    final title = (d['title'] ?? 'Assignment').toString();
    final course = (d['courseName'] ?? '').toString();
    final due = _toDate(d['dueDate']);
    final isPast = due != null && due.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: coral.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: coral.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.assignment_rounded, color: coral),
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
                    if (due != null)
                      '${isPast ? 'Was due' : 'Due'} ${_formatDue(context, due)}'
                    else
                      'No due date',
                  ].join('  •  '),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isPast ? Colors.red.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, id, title),
            icon: Icon(Icons.delete_outline_rounded,
                color: Colors.red.shade300),
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
        title: const Text('Delete assignment?'),
        content: Text('"$title" will be removed for all students.'),
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
      await FirebaseDatabase.instance.ref('assignments/$id').remove();
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