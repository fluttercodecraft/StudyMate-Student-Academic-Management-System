import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  static const Color primary = Color(0xFF1355D6);
  static const Color primaryDark = Color(0xFF0B3A9E);
  static const Color background = Color(0xFFF4F6FB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberBg = Color(0xFFFEF3C7);

  bool _showPast = false;

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

  DateTime? _toDate(dynamic v) =>
      v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;

  String _formatDue(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final t = TimeOfDay.fromDateTime(d).format(context);
    return '${d.day} ${m[d.month - 1]}, $t';
  }

  // Returns label + colors for the status badge.
  (String, Color, Color) _status(DateTime? due) {
    if (due == null) return ('No due date', textGrey, const Color(0xFFF3F4F6));
    final now = DateTime.now();
    if (due.isBefore(now)) {
      return ('Overdue', const Color(0xFFDC2626), const Color(0xFFFEE2E2));
    }
    final days = DateTime(due.year, due.month, due.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days == 0) {
      return ('Due today', const Color(0xFFD97706), amberBg);
    }
    if (days == 1) {
      return ('Tomorrow', const Color(0xFFD97706), amberBg);
    }
    return ('$days days left', const Color(0xFF059669), const Color(0xFFD1FAE5));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: user == null
                ? _stateView(Icons.lock_outline_rounded, 'Please log in again',
                'Your session has expired.')
                : StreamBuilder<DatabaseEvent>(
              stream:
              FirebaseDatabase.instance.ref('assignments').onValue,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _stateView(Icons.error_outline_rounded,
                      'Unable to load assignments', '${snap.error}');
                }
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                final now = DateTime.now();
                final raw = snap.data!.snapshot.value;
                final all = <Map<String, dynamic>>[];
                if (raw is Map) {
                  raw.forEach((k, v) {
                    if (v is Map) all.add(Map<String, dynamic>.from(v));
                  });
                }

                final upcoming = all.where((a) {
                  final due = _toDate(a['dueDate']);
                  return due == null || !due.isBefore(now);
                }).toList()
                  ..sort(_byDueAsc);

                final past = all.where((a) {
                  final due = _toDate(a['dueDate']);
                  return due != null && due.isBefore(now);
                }).toList()
                  ..sort((a, b) => _byDueAsc(b, a));

                final list = _showPast ? past : upcoming;

                return Column(
                  children: [
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(18, 18, 18, 6),
                      child: Row(
                        children: [
                          _chip('Upcoming (${upcoming.length})',
                              !_showPast, () {
                                setState(() => _showPast = false);
                              }),
                          const SizedBox(width: 10),
                          _chip('Past (${past.length})', _showPast, () {
                            setState(() => _showPast = true);
                          }),
                        ],
                      ),
                    ),
                    Expanded(
                      child: list.isEmpty
                          ? _stateView(
                        Icons.task_alt_rounded,
                        _showPast
                            ? 'No past assignments'
                            : 'All caught up!',
                        _showPast
                            ? 'Finished assignments will appear here.'
                            : 'New assignments from your teachers will appear here.',
                      )
                          : ListView(
                        padding: const EdgeInsets.fromLTRB(
                            18, 10, 18, 30),
                        children: list.map(_assignmentCard).toList(),
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

  int _byDueAsc(Map<String, dynamic> a, Map<String, dynamic> b) {
    final x = _toDate(a['dueDate']);
    final y = _toDate(b['dueDate']);
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          12, MediaQuery.of(context).padding.top + 8, 18, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
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
              'Assignments',
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
            child: const Icon(Icons.assignment_rounded,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primary : const Color(0xFFE6EAF0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : textGrey,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _assignmentCard(Map<String, dynamic> a) {
    final title = (a['title'] ?? 'Assignment').toString();
    final course = (a['courseName'] ?? '').toString();
    final due = _toDate(a['dueDate']);
    final status = _status(due);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: _card(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showDetails(a),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: amberBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.assignment_rounded,
                        color: amber, size: 24),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: textDark,
                          ),
                        ),
                        if (course.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              course,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: textGrey, fontSize: 12),
                            ),
                          ),
                        if (due != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule_rounded,
                                    size: 14, color: textGrey),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDue(due),
                                  style: const TextStyle(
                                      color: textGrey, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: status.$3,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status.$1,
                      style: TextStyle(
                        color: status.$2,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
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

  void _showDetails(Map<String, dynamic> a) {
    final title = (a['title'] ?? 'Assignment').toString();
    final course = (a['courseName'] ?? '').toString();
    final desc = (a['description'] ?? '').toString();
    final due = _toDate(a['dueDate']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              if (course.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(course,
                    style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
              if (due != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.event_rounded, size: 18, color: amber),
                    const SizedBox(width: 8),
                    Text('Due ${_formatDue(due)}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              const Text('Instructions',
                  style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                desc.isEmpty ? 'No instructions provided.' : desc,
                style: const TextStyle(
                    color: textGrey, fontSize: 13.5, height: 1.6),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Close',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
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
            Text(title,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: textGrey, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}