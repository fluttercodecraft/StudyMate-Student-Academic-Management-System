import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MarksScreen extends StatelessWidget {
  const MarksScreen({super.key});

  static const Color primary = Color(0xFF1355D6);
  static const Color primaryDark = Color(0xFF0B3A9E);
  static const Color background = Color(0xFFF4F6FB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  String _fmt(num n) =>
      n == n.roundToDouble() ? '${n.round()}' : n.toStringAsFixed(1);

  String _grade(double p) {
    if (p >= 80) return 'A';
    if (p >= 70) return 'B';
    if (p >= 60) return 'C';
    if (p >= 50) return 'D';
    return 'F';
  }

  Color _gradeColor(double p) {
    if (p >= 80) return const Color(0xFF10B981);
    if (p >= 70) return primary;
    if (p >= 60) return const Color(0xFFF59E0B);
    if (p >= 50) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
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
              stream: FirebaseDatabase.instance.ref('marks').onValue,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _state(Icons.error_outline_rounded,
                      'Unable to load marks', '${snap.error}');
                }
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                final raw = snap.data!.snapshot.value;
                final results = <Map<String, dynamic>>[];

                // marks/{sheetId}/records/{studentId}/obtained
                if (raw is Map) {
                  raw.forEach((id, sheet) {
                    if (sheet is Map &&
                        sheet['records'] is Map &&
                        (sheet['records'] as Map)[user.uid] is Map) {
                      final mine =
                      (sheet['records'] as Map)[user.uid] as Map;
                      final obtained = mine['obtained'];
                      final total = sheet['totalMarks'];

                      if (obtained is num && total is num && total > 0) {
                        results.add({
                          'course':
                          (sheet['courseName'] ?? 'Course').toString(),
                          'type': (sheet['type'] ?? 'Assessment').toString(),
                          'title': (sheet['title'] ?? '').toString(),
                          'obtained': obtained,
                          'total': total,
                          'updatedAt': sheet['updatedAt'],
                        });
                      }
                    }
                  });
                }

                if (results.isEmpty) {
                  return _state(
                    Icons.bar_chart_rounded,
                    'No marks yet',
                    'Your results will appear here once your teachers enter them.',
                  );
                }

                results.sort((a, b) {
                  final x = a['updatedAt'];
                  final y = b['updatedAt'];
                  if (x is! int || y is! int) return 0;
                  return y.compareTo(x);
                });

                return _content(context, results);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, List<Map<String, dynamic>> results) {
    num sumObtained = 0;
    num sumTotal = 0;
    for (final r in results) {
      sumObtained += r['obtained'] as num;
      sumTotal += r['total'] as num;
    }
    final overall = sumObtained * 100 / sumTotal;
    final overallColor = _gradeColor(overall);

    // group by course
    final byCourse = <String, List<Map<String, dynamic>>>{};
    for (final r in results) {
      byCourse.putIfAbsent(r['course'] as String, () => []).add(r);
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          children: [
            // Overall summary
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
                            value: (overall / 100).clamp(0.0, 1.0),
                            strokeWidth: 9,
                            backgroundColor: const Color(0xFFE9EDF5),
                            color: overallColor,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '${overall.round()}%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: overallColor,
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
                        Row(
                          children: [
                            const Text(
                              'Overall',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: overallColor.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Grade ${_grade(overall)}',
                                style: TextStyle(
                                  color: overallColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_fmt(sumObtained)} of ${_fmt(sumTotal)} marks '
                              'across ${results.length} assessment${results.length == 1 ? '' : 's'} '
                              'in ${byCourse.length} course${byCourse.length == 1 ? '' : 's'}.',
                          style: const TextStyle(
                              color: textGrey, fontSize: 12.5, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Per course
            ...byCourse.entries.map((entry) {
              num o = 0, t = 0;
              for (final r in entry.value) {
                o += r['obtained'] as num;
                t += r['total'] as num;
              }
              final pct = o * 100 / t;
              final color = _gradeColor(pct);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: _card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EFFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.menu_book_rounded,
                              color: primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: textDark,
                                ),
                              ),
                              Text(
                                '${_fmt(o)} / ${_fmt(t)} marks',
                                style: const TextStyle(
                                    color: textGrey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pct.round()}%  ${_grade(pct)}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFEEF1F6)),
                    const SizedBox(height: 12),
                    ...entry.value.map((r) {
                      final ob = r['obtained'] as num;
                      final to = r['total'] as num;
                      final p = ob * 100 / to;
                      final c = _gradeColor(p);
                      final title = (r['title'] as String).isEmpty
                          ? r['type'] as String
                          : '${r['type']} • ${r['title']}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_fmt(ob)} / ${_fmt(to)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: c,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (p / 100).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE9EDF5),
                                color: c,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
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
              'Marks',
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
            child: const Icon(Icons.bar_chart_rounded,
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