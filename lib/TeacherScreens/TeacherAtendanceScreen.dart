import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

const Color _ink = Color(0xFF1B1F3B);
const Color _paper = Color(0xFFF3F5FA);
const Color _violet = Color(0xFF6C5CE7);
const Color _green = Color(0xFF10B981);
const Color _red = Color(0xFFEF4444);
const Color _amber = Color(0xFFF59E0B);

DateTime? _toDate(dynamic v) =>
    v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;

String _dayLabel(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${days[d.weekday - 1]}, ${d.day} ${m[d.month - 1]}';
}

Widget _teacherHeader(BuildContext context, String title, {String? subtitle}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
        12, MediaQuery.of(context).padding.top + 8, 18, 26),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_ink, Color(0xFF3B3F8F)],
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12.5)),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _emptyState(IconData icon, String title, String message) {
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
              color: _violet.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: _violet, size: 42),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w700, color: _ink)),
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

// =====================================================================
//  Step 1: choose a class
// =====================================================================
class TeacherAttendanceScreen extends StatelessWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _paper,
      body: Column(
        children: [
          _teacherHeader(context, 'Attendance',
              subtitle: 'Choose a class to mark'),
          Expanded(
            child: user == null
                ? const Center(child: Text('Please log in again.'))
                : StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('classes').onValue,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _emptyState(Icons.error_outline_rounded,
                      'Unable to load', '${snap.error}');
                }
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _violet),
                  );
                }

                final raw = snap.data!.snapshot.value;
                final endOfToday = DateTime.now()
                    .copyWith(hour: 23, minute: 59, second: 59);
                final classes = <Map<String, dynamic>>[];

                if (raw is Map) {
                  raw.forEach((key, value) {
                    if (value is Map) {
                      final c = Map<String, dynamic>.from(value);
                      final s = _toDate(c['startAt']);
                      if (c['teacherId']?.toString() == user.uid &&
                          s != null &&
                          !s.isAfter(endOfToday)) {
                        c['classId'] = c['classId'] ?? key;
                        classes.add(c);
                      }
                    }
                  });
                }

                classes.sort((a, b) => _toDate(b['startAt'])!
                    .compareTo(_toDate(a['startAt'])!));

                if (classes.isEmpty) {
                  return _emptyState(
                    Icons.fact_check_rounded,
                    'No classes to mark',
                    'Schedule a class first. Classes up to today appear here.',
                  );
                }

                return StreamBuilder<DatabaseEvent>(
                  stream:
                  FirebaseDatabase.instance.ref('attendance').onValue,
                  builder: (context, attSnap) {
                    final att = attSnap.data?.snapshot.value;

                    return ListView(
                      padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 30),
                      children: classes.map((c) {
                        var marked = 0;
                        if (att is Map && att[c['classId']] is Map) {
                          marked = (att[c['classId']] as Map).length;
                        }
                        return _classCard(context, c, marked);
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

  Widget _classCard(BuildContext context, Map<String, dynamic> c, int marked) {
    final subject = (c['subject'] ?? 'Class').toString();
    final room = (c['room'] ?? '').toString();
    final s = _toDate(c['startAt'])!;
    final e = _toDate(c['endAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _violet.withValues(alpha: .18)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AttendanceMarkScreen(classData: c)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _violet.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.fact_check_rounded, color: _violet),
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
                              color: _ink)),
                      const SizedBox(height: 4),
                      Text(
                        '${_dayLabel(s)}  •  ${TimeOfDay.fromDateTime(s).format(context)}'
                            '${e == null ? '' : ' - ${TimeOfDay.fromDateTime(e).format(context)}'}'
                            '${room.isEmpty ? '' : '  •  Room $room'}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: marked > 0
                        ? _green.withValues(alpha: .12)
                        : _amber.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    marked > 0 ? 'Marked' : 'Mark',
                    style: TextStyle(
                      color: marked > 0
                          ? const Color(0xFF059669)
                          : const Color(0xFFD97706),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  Step 2: mark students
// =====================================================================
class AttendanceMarkScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const AttendanceMarkScreen({super.key, required this.classData});

  @override
  State<AttendanceMarkScreen> createState() => _AttendanceMarkScreenState();
}

class _AttendanceMarkScreenState extends State<AttendanceMarkScreen> {
  final List<({String id, String name})> _students = [];
  final Map<String, String> _status = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  String get _classId => widget.classData['classId'].toString();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = FirebaseDatabase.instance;
      final results = await Future.wait([
        db.ref('users').get(),
        db.ref('attendance/$_classId').get(),
      ]);

      final users = results[0].value;
      final existing = results[1].value;

      final list = <({String id, String name})>[];
      if (users is Map) {
        users.forEach((uid, value) {
          if (value is Map &&
              value['role']?.toString().toLowerCase() == 'student') {
            final name =
            (value['name'] ?? value['email'] ?? 'Student').toString();
            list.add((id: uid.toString(), name: name));
          }
        });
      }
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      for (final s in list) {
        var status = 'present';
        if (existing is Map && existing[s.id] is Map) {
          status = (existing[s.id] as Map)['status']?.toString() ?? 'present';
        }
        _status[s.id] = status;
      }

      if (!mounted) return;
      setState(() {
        _students
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _count(String status) => _status.values.where((s) => s == status).length;

  Future<void> _save() async {
    if (_students.isEmpty) return;
    setState(() => _saving = true);

    try {
      await FirebaseDatabase.instance.ref('attendance/$_classId').set({
        for (final s in _students)
          s.id: {'status': _status[s.id], 'name': s.name},
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Attendance saved.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _toDate(widget.classData['startAt']);

    return Scaffold(
      backgroundColor: _paper,
      body: Column(
        children: [
          _teacherHeader(
            context,
            (widget.classData['subject'] ?? 'Class').toString(),
            subtitle: s == null
                ? null
                : '${_dayLabel(s)}  •  ${TimeOfDay.fromDateTime(s).format(context)}',
          ),
          Expanded(child: _body()),
          if (!_loading && _students.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _violet,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                        : const Text('Save Attendance',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _violet));
    }
    if (_error != null) {
      return _emptyState(Icons.error_outline_rounded, 'Unable to load', _error!);
    }
    if (_students.isEmpty) {
      return _emptyState(
        Icons.groups_rounded,
        'No students found',
        'Students are read from the "users" node where role is "student".',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      children: [
        Row(
          children: [
            _summary('Present', _count('present'), _green),
            const SizedBox(width: 10),
            _summary('Absent', _count('absent'), _red),
            const SizedBox(width: 10),
            _summary('Late', _count('late'), _amber),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() {
              for (final s in _students) {
                _status[s.id] = 'present';
              }
            }),
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Mark all present'),
            style: TextButton.styleFrom(foregroundColor: _violet),
          ),
        ),
        ..._students.map(_studentRow),
      ],
    );
  }

  Widget _summary(String label, int n, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text('$n',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(fontSize: 11.5, color: color.withValues(alpha: .9))),
          ],
        ),
      ),
    );
  }

  Widget _studentRow(({String id, String name}) s) {
    final current = _status[s.id] ?? 'present';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _violet.withValues(alpha: .12),
            child: Text(
              s.name.isEmpty ? 'S' : s.name[0].toUpperCase(),
              style: const TextStyle(
                  color: _violet, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: _ink),
            ),
          ),
          _statusButton(s.id, 'present', 'P', _green, current),
          const SizedBox(width: 6),
          _statusButton(s.id, 'absent', 'A', _red, current),
          const SizedBox(width: 6),
          _statusButton(s.id, 'late', 'L', _amber, current),
        ],
      ),
    );
  }

  Widget _statusButton(
      String id, String value, String label, Color color, String current) {
    final selected = current == value;

    return GestureDetector(
      onTap: () => setState(() => _status[id] = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}