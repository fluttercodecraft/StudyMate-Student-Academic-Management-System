import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/common/AcadmicOption.dart';

class TimetableScreen extends StatelessWidget {
  final Map<String, dynamic> profile;

  const TimetableScreen({super.key, this.profile = const {}});

  static const Color primary = Color(0xFF1355D6);
  static const Color primaryDark = Color(0xFF0B3A9E);
  static const Color background = Color(0xFFF4F6FB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  DateTime? _toDate(dynamic v) =>
      v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = that.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';

    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('classes').onValue,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _state(Icons.error_outline_rounded,
                      'Unable to load timetable', '${snap.error}');
                }
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                final raw = snap.data!.snapshot.value;
                final now = DateTime.now();
                final startOfToday = DateTime(now.year, now.month, now.day);
                final items = <Map<String, dynamic>>[];

                if (raw is Map) {
                  raw.forEach((key, value) {
                    if (value is Map) {
                      final c = Map<String, dynamic>.from(value);
                      final s = _toDate(c['startAt']);
                      if (s != null &&
                          !s.isBefore(startOfToday) &&
                          matchesAcademic(c, profile)) {
                        items.add(c);
                      }
                    }
                  });
                }

                items.sort((a, b) => _toDate(a['startAt'])!
                    .compareTo(_toDate(b['startAt'])!));

                if (items.isEmpty) {
                  return _state(
                    Icons.calendar_month_rounded,
                    'No upcoming classes',
                    'Classes scheduled by your teachers will appear here.',
                  );
                }

                // Group by day, keeping order.
                final groups = <String, List<Map<String, dynamic>>>{};
                for (final c in items) {
                  final label = _dayLabel(_toDate(c['startAt'])!);
                  groups.putIfAbsent(label, () => []).add(c);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 4),
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
                              entry.key,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...entry.value.map((c) => _classCard(context, c)),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _classCard(BuildContext context, Map<String, dynamic> c) {
    final subject = (c['subject'] ?? 'Class').toString();
    final teacher = (c['teacher'] ?? '').toString();
    final room = (c['room'] ?? '').toString();
    final s = _toDate(c['startAt'])!;
    final e = _toDate(c['endAt']);
    final now = DateTime.now();
    final live = !s.isAfter(now) && e != null && e.isAfter(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _card(),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 82,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: live ? primary : const Color(0xFFE8EFFF),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    TimeOfDay.fromDateTime(s).format(context),
                    style: TextStyle(
                      color: live ? Colors.white : primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  if (e != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      TimeOfDay.fromDateTime(e).format(context),
                      style: TextStyle(
                        color: live ? Colors.white70 : textGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: textDark,
                            ),
                          ),
                        ),
                        if (live)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Live now',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        if (teacher.isNotEmpty) teacher,
                        if (room.isNotEmpty) 'Room $room',
                      ].join('  •  '),
                      style: const TextStyle(color: textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
              'Timetable',
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
            child: const Icon(Icons.calendar_month_rounded,
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