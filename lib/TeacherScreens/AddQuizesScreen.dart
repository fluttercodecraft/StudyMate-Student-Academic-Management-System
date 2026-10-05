import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class _Draft {
  final q = TextEditingController();
  final opts = List.generate(4, (_) => TextEditingController());
  int correct = 0;

  void dispose() {
    q.dispose();
    for (final c in opts) {
      c.dispose();
    }
  }
}

class AddQuizScreen extends StatefulWidget {
  const AddQuizScreen({super.key});

  @override
  State<AddQuizScreen> createState() => _AddQuizScreenState();
}

class _AddQuizScreenState extends State<AddQuizScreen> {
  static const Color ink = Color(0xFF1B1F3B);
  static const Color paper = Color(0xFFF3F5FA);
  static const Color violet = Color(0xFF6C5CE7);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color line = Color(0xFFE6EAF0);

  final _titleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '10');
  final List<_Draft> _drafts = [_Draft()];

  List<Map<String, String>> _courses = [];
  String? _courseId;
  DateTime? _date;
  bool _loadingCourses = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      final snap = await FirebaseDatabase.instance.ref('courses').get();
      final v = snap.value;
      final list = <Map<String, String>>[];

      if (v is Map) {
        v.forEach((key, value) {
          if (value is Map) {
            final c = Map<String, dynamic>.from(value);
            final owner = c['teacherId']?.toString();
            if (owner != null && owner.isNotEmpty && owner != uid) return;
            list.add({
              'id': (c['courseId'] ?? key).toString(),
              'name': (c['courseName'] ?? 'Unnamed Course').toString(),
              'code': (c['courseCode'] ?? '').toString(),
            });
          }
        });
      }

      if (!mounted) return;
      setState(() {
        _courses = list;
        _loadingCourses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCourses = false);
      _snack('Could not load courses: $e');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    setState(() {
      _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final minutes = int.tryParse(_durationCtrl.text.trim());

    if (_courseId == null) return _snack('Please select a course.');
    if (title.isEmpty) return _snack('Please enter a quiz title.');
    if (_date == null) return _snack('Please choose the quiz date.');
    if (minutes == null || minutes <= 0) {
      return _snack('Please enter a valid duration in minutes.');
    }

    for (var i = 0; i < _drafts.length; i++) {
      final d = _drafts[i];
      if (d.q.text.trim().isEmpty ||
          d.opts.any((c) => c.text.trim().isEmpty)) {
        return _snack('Question ${i + 1}: fill in the question and all 4 options.');
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _snack('Please log in again.');

    setState(() => _saving = true);

    try {
      final course = _courses.firstWhere((c) => c['id'] == _courseId);
      final ref = FirebaseDatabase.instance.ref('quizzes').push();

      await ref.set({
        'quizId': ref.key,
        'title': title,
        'courseId': _courseId,
        'courseName': course['name'],
        'date': _date!.millisecondsSinceEpoch,
        'durationMinutes': minutes,
        'questionCount': _drafts.length,
        'teacherId': user.uid,
        'createdAt': ServerValue.timestamp,
        'questions': _drafts
            .map((d) => {
          'question': d.q.text.trim(),
          'options': d.opts.map((c) => c.text.trim()).toList(),
          'correctIndex': d.correct,
        })
            .toList(),
      });

      if (!mounted) return;
      _snack('Quiz created.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Could not save: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}, '
        '${TimeOfDay.fromDateTime(d).format(context)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Course'),
                  _courseField(),
                  const SizedBox(height: 18),
                  _label('Quiz title'),
                  _input(_titleCtrl, 'e.g. Quiz 1: Arrays'),
                  const SizedBox(height: 18),
                  _label('Date & time'),
                  _dateField(),
                  const SizedBox(height: 18),
                  _label('Duration (minutes)'),
                  _input(_durationCtrl, '10', number: true),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Questions',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                      ),
                      Text('${_drafts.length} added',
                          style:
                          const TextStyle(color: textGrey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _drafts.length; i++) _questionCard(i),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _drafts.add(_Draft())),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add question'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: violet,
                        side: const BorderSide(color: violet),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: violet,
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
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Create Quiz',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(int i) {
    final d = _drafts[i];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: violet.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Question ${i + 1}',
                  style: const TextStyle(
                    color: violet,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (_drafts.length > 1)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() {
                    _drafts.removeAt(i).dispose();
                  }),
                  icon: Icon(Icons.delete_outline_rounded,
                      color: Colors.red.shade300),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _input(d.q, 'Type the question', lines: 2),
          const SizedBox(height: 12),
          const Text(
            'Options (tap the circle to mark the correct answer)',
            style: TextStyle(color: textGrey, fontSize: 11.5),
          ),
          const SizedBox(height: 8),
          for (var o = 0; o < 4; o++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => d.correct = o),
                    child: Icon(
                      d.correct == o
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: d.correct == o ? const Color(0xFF10B981) : textGrey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _input(d.opts[o], 'Option ${'ABCD'[o]}'),
                  ),
                ],
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
              'New Quiz',
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13.5,
        color: ink,
      ),
    ),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: textGrey, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: violet, width: 1.5),
    ),
  );

  Widget _input(TextEditingController c, String hint,
      {int lines = 1, bool number = false}) {
    return TextField(
      controller: c,
      maxLines: lines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14),
      decoration: _decoration(hint),
    );
  }

  Widget _courseField() {
    if (_loadingCourses) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: violet),
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'You have no courses yet. Create a course first.',
          style: TextStyle(color: Color(0xFF92400E), fontSize: 13),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _courseId,
      isExpanded: true,
      decoration: _decoration('Select a course'),
      items: _courses
          .map(
            (c) => DropdownMenuItem<String>(
          value: c['id'],
          child: Text(
            c['code']!.isEmpty ? c['name']! : '${c['name']} (${c['code']})',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      )
          .toList(),
      onChanged: (v) => setState(() => _courseId = v),
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, color: violet, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _date == null ? 'Choose date & time' : _formatDate(_date!),
                style: TextStyle(
                  fontSize: 14,
                  color: _date == null ? textGrey : ink,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: textGrey),
          ],
        ),
      ),
    );
  }
}