import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/TeacherScreens/AddClassScreen.dart';

class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  static const Color ink = Color(0xFF1B1F3B);
  static const Color paper = Color(0xFFF3F5FA);
  static const Color violet = Color(0xFF6C5CE7);

  bool _showPast = false;

  DateTime? _toDate(dynamic v) =>
      v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;

  String _day(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${m[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: paper,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddClassScreen()),
        ),
        backgroundColor: violet,
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
              stream: FirebaseDatabase.instance.ref('classes').onValue,
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
                final all = <Map<String, dynamic>>[];

                if (raw is Map) {
                  raw.forEach((key, value) {
                    if (value is Map) {
                      final c = Map<String, dynamic>.from(value);
                      if (c['teacherId']?.toString() == user.uid) {
                        c['classId'] = c['classId'] ?? key;
                        all.add(c);
                      }
                    }
                  });
                }

                final now = DateTime.now();
                int byStart(Map<String, dynamic> a, Map<String, dynamic> b) {
                  final x = _toDate(a['startAt']);
                  final y = _toDate(b['startAt']);
                  if (x == null || y == null) return 0;
                  return x.compareTo(y);
                }

                final upcoming = all.where((c) {
                  final e = _toDate(c['endAt']);
                  return e == null || !e.isBefore(now);
                }).toList()
                  ..sort(byStart);
                final past = all.where((c) {
                  final e = _toDate(c['endAt']);
                  return e != null && e.isBefore(now);
                }).toList()
                  ..sort((a, b) => byStart(b, a));

                final list = _showPast ? past : upcoming;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                      child: Row(
                        children: [
                          _chip('Upcoming (${upcoming.length})',
                              !_showPast,
                                  () => setState(() => _showPast = false)),
                          const SizedBox(width: 10),
                          _chip('Past (${past.length})', _showPast,
                                  () => setState(() => _showPast = true)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: list.isEmpty
                          ? _state(
                        Icons.calendar_month_rounded,
                        _showPast
                            ? 'No past classes'
                            : 'No classes scheduled',
                        _showPast
                            ? 'Finished classes will appear here.'
                            : 'Tap "New" to schedule your first class.',
                      )
                          : ListView(
                        padding: const EdgeInsets.fromLTRB(
                            20, 12, 20, 90),
                        children:
                        list.map((c) => _card(context, c)).toList(),
                      ),
                    ),
                  ],
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
              'My Classes',
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

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? violet : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? violet : const Color(0xFFE6EAF0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> c) {
    final id = c['classId'].toString();
    final subject = (c['subject'] ?? 'Class').toString();
    final room = (c['room'] ?? '').toString();
    final s = _toDate(c['startAt']);
    final e = _toDate(c['endAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: violet.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: violet.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: violet),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ink)),
                const SizedBox(height: 4),
                if (s != null)
                  Text(
                    '${_day(s)}  •  ${TimeOfDay.fromDateTime(s).format(context)}'
                        '${e == null ? '' : ' - ${TimeOfDay.fromDateTime(e).format(context)}'}',
                    style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                if (room.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('Room $room',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, id, subject),
            icon:
            Icon(Icons.delete_outline_rounded, color: Colors.red.shade300),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String id, String subject) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete class?'),
        content: Text('This "$subject" class will be removed for students.'),
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
      await FirebaseDatabase.instance.ref('classes/$id').remove();
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