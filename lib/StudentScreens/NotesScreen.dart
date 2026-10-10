import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart' show OpenFilex, ResultType;
import 'package:path_provider/path_provider.dart';
import 'package:study_mate/common/AcadmicOption.dart';

/// Student side of Notes.
/// Reads notes/{noteId} and shows only the ones for the student's
/// department + semester + section. PDFs are stored as base64 in noteFiles/{noteId}.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const Color primary = Color(0xFF1355D6);
  static const Color primaryDark = Color(0xFF0B3A9E);
  static const Color background = Color(0xFFF4F6FB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color pink = Color(0xFFEC4899);
  static const Color pinkBg = Color(0xFFFCE7F3);

  String _query = '';
  String? _openingId;

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

  String _date(dynamic ms) {
    if (ms is! int) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  Future<void> _openPdf(Map<String, dynamic> note) async {
    final id = note['noteId'].toString();
    setState(() => _openingId = id);

    try {
      final snap =
      await FirebaseDatabase.instance.ref('noteFiles/$id/data').get();
      final b64 = snap.value?.toString();
      if (b64 == null || b64.isEmpty) {
        _snack('This file is no longer available.');
        return;
      }

      final dir = await getTemporaryDirectory();
      final rawName = (note['fileName'] ?? '$id.pdf').toString();
      final safeName = rawName.replaceAll(RegExp(r'[^\w.\- ]'), '_');
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(base64Decode(b64), flush: true);

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        _snack('Could not open the PDF: ${result.message}');
      }
    } catch (e) {
      _snack('Could not open the PDF: $e');
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
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
                ? _state(Icons.lock_outline_rounded, 'Please log in again',
                'Your session has expired.')
                : StreamBuilder<DatabaseEvent>(
              stream:
              FirebaseDatabase.instance.ref('users/${user.uid}').onValue,
              builder: (context, profileSnap) {
                if (!profileSnap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: primary));
                }
                final raw = profileSnap.data!.snapshot.value;
                final profile = raw is Map
                    ? Map<String, dynamic>.from(raw)
                    : <String, dynamic>{};

                if (!hasAcademicProfile(profile)) {
                  return _state(
                    Icons.info_outline_rounded,
                    'Complete your profile',
                    'Add your department, semester and section on the dashboard to see your notes.',
                  );
                }
                return _notesList(profile);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesList(Map<String, dynamic> profile) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('notes').onValue,
      builder: (context, snap) {
        if (snap.hasError) {
          return _state(Icons.error_outline_rounded, 'Unable to load notes',
              '${snap.error}');
        }
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: primary));
        }

        final raw = snap.data!.snapshot.value;
        final notes = <Map<String, dynamic>>[];
        if (raw is Map) {
          raw.forEach((key, value) {
            if (value is Map) {
              final n = Map<String, dynamic>.from(value);
              n['noteId'] = n['noteId'] ?? key;
              if (matchesAcademic(n, profile)) notes.add(n);
            }
          });
        }

        notes.sort((a, b) {
          final x = a['createdAt'];
          final y = b['createdAt'];
          if (x is! int || y is! int) return 0;
          return y.compareTo(x);
        });

        final q = _query.trim().toLowerCase();
        final filtered = q.isEmpty
            ? notes
            : notes.where((n) {
          return (n['title'] ?? '').toString().toLowerCase().contains(q) ||
              (n['courseName'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q) ||
              (n['teacherName'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q);
        }).toList();

        if (notes.isEmpty) {
          return _state(
            Icons.sticky_note_2_rounded,
            'No notes yet',
            'Notes your teachers post for your section will appear here.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${filtered.length} note${filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    color: textGrey,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600),
              ),
            ),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: _state(Icons.search_off_rounded, 'No matches',
                    'Try a different title, course or teacher.'),
              )
            else
              ...filtered.map(_noteCard),
          ],
        );
      },
    );
  }

  Widget _noteCard(Map<String, dynamic> n) {
    final title = (n['title'] ?? 'Untitled').toString();
    final course = (n['courseName'] ?? '').toString();
    final teacher = (n['teacherName'] ?? '').toString();
    final content = (n['content'] ?? '').toString();
    final hasFile = n['hasFile'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: _card(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showNote(n),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: pinkBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      hasFile
                          ? Icons.picture_as_pdf_rounded
                          : Icons.sticky_note_2_rounded,
                      color: pink,
                      size: 24,
                    ),
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
                                color: textDark)),
                        if (course.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(course,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        if (content.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: textGrey,
                                    fontSize: 12,
                                    height: 1.4)),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          [
                            if (teacher.isNotEmpty) teacher,
                            _date(n['createdAt']),
                            if (hasFile) 'PDF attached',
                          ].where((e) => e.isNotEmpty).join('  •  '),
                          style: const TextStyle(
                              color: textGrey, fontSize: 11.5),
                        ),
                      ],
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

  void _showNote(Map<String, dynamic> n) {
    final title = (n['title'] ?? 'Untitled').toString();
    final course = (n['courseName'] ?? '').toString();
    final teacher = (n['teacherName'] ?? '').toString();
    final content = (n['content'] ?? '').toString();
    final hasFile = n['hasFile'] == true;
    final fileName = (n['fileName'] ?? 'document.pdf').toString();
    final size = n['fileSize'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (sheetContext, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(22),
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
              Text(title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark)),
              if (course.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(course,
                    style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
              const SizedBox(height: 6),
              Text(
                [
                  if (teacher.isNotEmpty) teacher,
                  _date(n['createdAt']),
                ].where((e) => e.isNotEmpty).join('  •  '),
                style: const TextStyle(color: textGrey, fontSize: 12),
              ),
              const SizedBox(height: 18),
              if (content.isNotEmpty)
                Text(content,
                    style: const TextStyle(
                        color: textDark, fontSize: 14, height: 1.6)),
              if (hasFile) ...[
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          color: Color(0xFFDC2626)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            if (size is int)
                              Text(formatFileSize(size),
                                  style: const TextStyle(
                                      color: textGrey, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _openingId == n['noteId'].toString()
                        ? null
                        : () => _openPdf(n),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open PDF',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          12, MediaQuery.of(context).padding.top + 8, 18, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
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
                        fontWeight: FontWeight.bold)),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.sticky_note_2_rounded,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search notes, courses, teachers...',
                hintStyle: const TextStyle(color: textGrey, fontSize: 13),
                prefixIcon:
                const Icon(Icons.search_rounded, color: textGrey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
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