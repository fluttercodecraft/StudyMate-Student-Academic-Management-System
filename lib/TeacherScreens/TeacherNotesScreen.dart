import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/TeacherScreens/AddNotesScreen.dart';
import 'package:study_mate/common/AcadmicOption.dart';

/// Teacher side of Notes: lists the notes this teacher posted, with delete.
class TeacherNotesScreen extends StatelessWidget {
  const TeacherNotesScreen({super.key});

  static const Color ink = Color(0xFF1B1F3B);
  static const Color paper = Color(0xFFF3F5FA);
  static const Color violet = Color(0xFF6C5CE7);
  static const Color textGrey = Color(0xFF6B7280);

  String _date(dynamic ms) {
    if (ms is! int) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  Future<void> _delete(BuildContext context, Map<String, dynamic> n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete notes?'),
        content: Text(
            '"${n['title'] ?? 'Untitled'}" will be removed for all students.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final id = n['noteId'].toString();
    try {
      await FirebaseDatabase.instance.ref().update({
        'notes/$id': null,
        'noteFiles/$id': null,
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: paper,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddNoteScreen())),
        backgroundColor: violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Notes'),
      ),
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: uid == null
                ? const Center(child: Text('Please log in again.'))
                : StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('notes').onValue,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                      child: Text('Unable to load notes\n${snap.error}',
                          textAlign: TextAlign.center));
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: violet));
                }

                final raw = snap.data!.snapshot.value;
                final notes = <Map<String, dynamic>>[];
                if (raw is Map) {
                  raw.forEach((key, value) {
                    if (value is Map &&
                        value['teacherId']?.toString() == uid) {
                      final n = Map<String, dynamic>.from(value);
                      n['noteId'] = n['noteId'] ?? key;
                      notes.add(n);
                    }
                  });
                }
                notes.sort((a, b) {
                  final x = a['createdAt'];
                  final y = b['createdAt'];
                  if (x is! int || y is! int) return 0;
                  return y.compareTo(x);
                });

                if (notes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sticky_note_2_rounded,
                              size: 60, color: violet.withValues(alpha: .4)),
                          const SizedBox(height: 14),
                          const Text('No notes posted yet',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ink)),
                          const SizedBox(height: 6),
                          const Text(
                              'Tap "New Notes" to share learning material with a section.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textGrey)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                  itemCount: notes.length,
                  itemBuilder: (_, i) => _card(context, notes[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> n) {
    final hasFile = n['hasFile'] == true;
    final content = (n['content'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: violet.withValues(alpha: .15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: violet.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
                hasFile
                    ? Icons.picture_as_pdf_rounded
                    : Icons.sticky_note_2_rounded,
                color: violet),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((n['title'] ?? 'Untitled').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: ink)),
                const SizedBox(height: 3),
                Text((n['courseName'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: violet,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                if (content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: textGrey, fontSize: 12, height: 1.4)),
                  ),
                const SizedBox(height: 8),
                Text(
                  [
                    Academic.label(n),
                    _date(n['createdAt']),
                    if (hasFile) 'PDF',
                  ].where((e) => e.isNotEmpty).join('  •  '),
                  style: const TextStyle(color: textGrey, fontSize: 11.5),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _delete(context, n),
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
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
            child: Text('Notes',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}