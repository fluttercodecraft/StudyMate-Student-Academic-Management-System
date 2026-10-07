import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  static const Color primary = Color(0xFF1355D6);
  static const Color primaryDark = Color(0xFF0B3A9E);
  static const Color background = Color(0xFFF4F6FB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);
  static const Color amber = Color(0xFFF59E0B);

  /// Minimum percentage considered healthy.
  static const int requiredPercent = 75;

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

  Color _color(String status) {
    switch (status) {
      case 'present':
        return green;
      case 'late':
        return amber;
      default:
        return red;
    }
  }

  String _label(String status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'late':
        return 'Late';
      default:
        return 'Absent';
    }
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
                ? const Center(child: Text('Please log in again.'))
                : StreamBuilder<DatabaseEvent>(
              stream:
              FirebaseDatabase.instance.ref('attendance').onValue,
              builder: (context, attSnap) {
                if (attSnap.hasError) {
                  return _state(Icons.error_outline_rounded,
                      'Unable to load attendance', '${attSnap.error}');
                }
                if (!attSnap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                return StreamBuilder<DatabaseEvent>(
                  stream:
                  FirebaseDatabase.instance.ref('classes').onValue,
                  builder: (context, classSnap) {
                    if (!classSnap.hasData) {
                      return const Center(
                        child:
                        CircularProgressIndicator(color: primary),
                      );
                    }

                    final att = attSnap.data!.snapshot.value;
                    final classes = classSnap.data!.snapshot.value;
                    final records = <Map<String, dynamic>>[];

                    if (att is Map && classes is Map) {
                      att.forEach((classId, students) {
                        if (students is Map &&
                            students[user.uid] is Map &&
                            classes[classId] is Map) {
                          final cls = Map<String, dynamic>.from(
                              classes[classId] as Map);
                          final status = (students[user.uid]
                          as Map)['status']
                              ?.toString() ??
                              'absent';
                          records.add({
                            'subject':
                            (cls['subject'] ?? 'Class').toString(),
                            'startAt': cls['startAt'],
                            'status': status,
                          });
                        }
                      });
                    }

                    if (records.isEmpty) {
                      return _state(
                        Icons.fact_check_rounded,
                        'No attendance yet',
                        'Your attendance will appear here once your teachers mark it.',
                      );
                    }

                    records.sort((a, b) {
                      final x = _toDate(a['startAt']);
                      final y = _toDate(b['startAt']);
                      if (x == null || y == null) return 0;
                      return y.compareTo(x);
                    });

                    return _content(context, records);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, List<Map<String, dynamic>> records) {
    final total = records.length;
    final present = records.where((r) => r['status'] == 'present').length;
    final late = records.where((r) => r['status'] == 'late').length;
    final absent = total - present - late;
    final attended = present + late;
    final percent = (attended * 100 / total).round();
    final healthy = percent >= requiredPercent;

    // Per course
    final byCourse = <String, List<int>>{}; // subject -> [attended, total]
    for (final r in records) {
      final list = byCourse.putIfAbsent(r['subject'] as String, () => [0, 0]);
      list[1]++;
      if (r['status'] != 'absent') list[0]++;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _card(),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: attended / total,
                        strokeWidth: 9,
                        backgroundColor: const Color(0xFFE9EDF5),
                        color: healthy ? green : red,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: healthy ? green : red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      healthy ? 'Good attendance' : 'Attendance is low',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      healthy
                          ? 'You attended $attended of $total classes.'
                          : 'Below $requiredPercent%. You attended $attended of $total classes.',
                      style: const TextStyle(
                          color: textGrey, fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _dot(green, '$present Present'),
                        const SizedBox(width: 10),
                        _dot(amber, '$late Late'),
                        const SizedBox(width: 10),
                        _dot(red, '$absent Absent'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _title('By course'),
        ...byCourse.entries.map((e) {
          final pct = (e.value[0] * 100 / e.value[1]).round();
          final ok = pct >= requiredPercent;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _card(),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: textDark),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ok ? green : red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${e.value[0]} of ${e.value[1]} classes',
                    style: const TextStyle(color: textGrey, fontSize: 11.5),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: e.value[0] / e.value[1],
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE9EDF5),
                    color: ok ? green : red,
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 14),
        _title('History'),
        ...records.map((r) {
          final s = _toDate(r['startAt']);
          final status = r['status'] as String;
          final color = _color(status);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _card(),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['subject'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: textDark),
                      ),
                      if (s != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '${_day(s)}  •  ${TimeOfDay.fromDateTime(s).format(context)}',
                            style: const TextStyle(
                                color: textGrey, fontSize: 11.5),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _label(status),
                    style: TextStyle(
                      color: color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _dot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10.5, color: textGrey)),
      ],
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
              'Attendance',
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
            child: const Icon(Icons.fact_check_rounded,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
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