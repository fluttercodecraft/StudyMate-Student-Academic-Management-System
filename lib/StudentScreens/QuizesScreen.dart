import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

const Color _primary = Color(0xFF1355D6);
const Color _primaryDark = Color(0xFF0B3A9E);
const Color _background = Color(0xFFF4F6FB);
const Color _textDark = Color(0xFF1F2937);
const Color _textGrey = Color(0xFF6B7280);
const Color _purple = Color(0xFF8B5CF6);
const Color _purpleBg = Color(0xFFEDE9FE);

DateTime? _toDate(dynamic v) =>
    v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;

String _formatDate(BuildContext context, DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${m[d.month - 1]}, '
      '${TimeOfDay.fromDateTime(d).format(context)}';
}

Widget _gradientHeader(BuildContext context, String title, {Widget? trailing}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
        12, MediaQuery.of(context).padding.top + 8, 18, 24),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_primary, _primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    ),
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
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

// =====================================================================
//  Quiz list
// =====================================================================
class QuizzesScreen extends StatelessWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _background,
      body: Column(
        children: [
          _gradientHeader(context, 'Quizzes'),
          Expanded(
            child: user == null
                ? const Center(child: Text('Please log in again.'))
                : StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('quizzes').onValue,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _stateView(Icons.error_outline_rounded,
                      'Unable to load quizzes', '${snap.error}');
                }
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }

                final raw = snap.data!.snapshot.value;
                final quizzes = <Map<String, dynamic>>[];

                if (raw is Map) {
                  raw.forEach((key, value) {
                    if (value is Map) {
                      final q = Map<String, dynamic>.from(value);
                      q['quizId'] = q['quizId'] ?? key;
                      quizzes.add(q);
                    }
                  });
                }

                quizzes.sort((a, b) {
                  final x = _toDate(a['date']);
                  final y = _toDate(b['date']);
                  if (x == null || y == null) return 0;
                  return y.compareTo(x);
                });

                if (quizzes.isEmpty) {
                  return _stateView(
                    Icons.quiz_rounded,
                    'No quizzes yet',
                    'Quizzes from your teachers will appear here.',
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
                      const EdgeInsets.fromLTRB(18, 20, 18, 30),
                      children: quizzes.map((q) {
                        Map<String, dynamic>? mine;
                        if (results is Map) {
                          final r = results[q['quizId']];
                          if (r is Map && r[user.uid] is Map) {
                            mine = Map<String, dynamic>.from(
                                r[user.uid] as Map);
                          }
                        }
                        return _quizCard(context, q, mine);
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

  Widget _quizCard(
      BuildContext context, Map<String, dynamic> q, Map<String, dynamic>? mine) {
    final title = (q['title'] ?? 'Quiz').toString();
    final course = (q['courseName'] ?? '').toString();
    final date = _toDate(q['date']);
    final count = q['questionCount'] ?? 0;
    final minutes = q['durationMinutes'] ?? 0;
    final now = DateTime.now();

    late String badge;
    late Color badgeColor;
    late Color badgeBg;

    if (mine != null) {
      badge = 'Score ${mine['score']}/${mine['total']}';
      badgeColor = const Color(0xFF059669);
      badgeBg = const Color(0xFFD1FAE5);
    } else if (date != null && date.isAfter(now)) {
      badge = 'Upcoming';
      badgeColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFEF3C7);
    } else {
      badge = 'Start';
      badgeColor = Colors.white;
      badgeBg = _primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (mine != null) {
              _snack(context,
                  'You already completed this quiz: ${mine['score']}/${mine['total']}.');
            } else if (date != null && date.isAfter(now)) {
              _snack(context, 'This quiz opens on ${_formatDate(context, date)}.');
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuizPlayScreen(quiz: q)),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _purpleBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.quiz_rounded, color: _purple),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: _textDark)),
                      if (course.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(course,
                              style: const TextStyle(
                                  color: _textGrey, fontSize: 12)),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (date != null) _formatDate(context, date),
                          '$count questions',
                          '$minutes min',
                        ].join('  •  '),
                        style:
                        const TextStyle(color: _textGrey, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
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

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
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
            child: Icon(icon, color: _primary, size: 42),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _textGrey, fontSize: 13, height: 1.5)),
        ],
      ),
    ),
  );
}

// =====================================================================
//  Taking a quiz
// =====================================================================
class QuizPlayScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;

  const QuizPlayScreen({super.key, required this.quiz});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  late final List<Map<String, dynamic>> _questions;
  late final List<int?> _answers;
  late int _secondsLeft;

  Timer? _timer;
  int _index = 0;
  int _score = 0;
  bool _finished = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final raw = widget.quiz['questions'];
    _questions = [];
    if (raw is List) {
      for (final q in raw) {
        if (q is Map) _questions.add(Map<String, dynamic>.from(q));
      }
    } else if (raw is Map) {
      for (final q in raw.values) {
        if (q is Map) _questions.add(Map<String, dynamic>.from(q));
      }
    }

    _answers = List<int?>.filled(_questions.length, null);

    final minutes = widget.quiz['durationMinutes'];
    _secondsLeft = (minutes is int && minutes > 0 ? minutes : 10) * 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
        _submit();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _clock {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _submit() async {
    if (_finished || _saving) return;
    _timer?.cancel();

    var score = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] != null && _answers[i] == _questions[i]['correctIndex']) {
        score++;
      }
    }

    setState(() {
      _score = score;
      _saving = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final quizId = widget.quiz['quizId'];
      if (uid != null) {
        await FirebaseDatabase.instance.ref('quizResults/$quizId/$uid').set({
          'score': score,
          'total': _questions.length,
          'submittedAt': ServerValue.timestamp,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your result: $e')),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      _finished = true;
    });
  }

  Future<void> _confirmSubmit() async {
    final unanswered = _answers.where((a) => a == null).length;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Submit quiz?'),
        content: Text(unanswered == 0
            ? 'You answered every question.'
            : 'You have $unanswered unanswered question${unanswered == 1 ? '' : 's'}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (ok == true) _submit();
  }

  Future<bool> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Leave quiz?'),
        content: const Text('Your answers will be lost and the quiz will not be submitted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: _background,
        body: Column(
          children: [
            _gradientHeader(context, 'Quiz'),
            Expanded(
              child: _stateView(Icons.help_outline_rounded, 'No questions',
                  'This quiz has no questions yet.'),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: _finished,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: _background,
        body: _finished ? _resultView() : _questionView(),
      ),
    );
  }

  Widget _questionView() {
    final q = _questions[_index];
    final options = (q['options'] is List) ? List.from(q['options']) : [];
    final isLast = _index == _questions.length - 1;
    final lowTime = _secondsLeft <= 60;

    return Column(
      children: [
        _gradientHeader(
          context,
          (widget.quiz['title'] ?? 'Quiz').toString(),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: lowTime ? const Color(0xFFDC2626) : Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 5),
                Text(
                  _clock,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Question ${_index + 1} of ${_questions.length}',
                      style: const TextStyle(
                        color: _textGrey,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_answers.where((a) => a != null).length} answered',
                      style: const TextStyle(color: _primary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _questions.length,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E9F2),
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Text(
                    (q['question'] ?? '').toString(),
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < options.length; i++) _option(i, options[i]),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
            child: Row(
              children: [
                if (_index > 0)
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _index--),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  ),
                if (_index > 0) const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : isLast
                          ? _confirmSubmit
                          : () => setState(() => _index++),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLast
                            ? const Color(0xFF10B981)
                            : _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isLast ? 'Submit' : 'Next',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _option(int i, dynamic text) {
    final selected = _answers[_index] == i;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _answers[_index] = i),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8EFFF) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? _primary : const Color(0xFFE6EAF0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? _primary : const Color(0xFFF1F3F9),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'ABCD'[i % 4],
                  style: TextStyle(
                    color: selected ? Colors.white : _textGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text.toString(),
                  style: const TextStyle(fontSize: 14, color: _textDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultView() {
    final total = _questions.length;
    final percent = total == 0 ? 0 : (_score * 100 / total).round();
    final good = percent >= 50;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: good
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEE2E2),
                ),
                child: Center(
                  child: Text(
                    '$_score/$total',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: good
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                good ? 'Great job!' : 'Keep practising!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You scored $percent% on ${(widget.quiz['title'] ?? 'this quiz')}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textGrey, fontSize: 14),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}