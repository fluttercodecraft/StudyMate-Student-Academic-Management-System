
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/common/AcadmicOption.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  static const Color ink = Color(0xFF1B1F3B);
  static const Color paper = Color(0xFFF3F5FA);
  static const Color violet = Color(0xFF6C5CE7);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color line = Color(0xFFE6EAF0);

  static const int _maxPdfBytes = 3 * 1024 * 1024;

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();

  List<Map<String, String>> _courses = [];

  String? _courseId;
  String? _dept;
  int? _sem;
  String? _section;

  Uint8List? _fileBytes;
  String? _fileName;

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
    _contentCtrl.dispose();
    super.dispose();
  }

  // Convert bytes into a readable file size.
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _loadCourses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() => _loadingCourses = false);
        _snack('Please log in again.');
        return;
      }

      final snapshot =
      await FirebaseDatabase.instance.ref('courses').get();

      final value = snapshot.value;
      final List<Map<String, String>> list = [];

      if (value is Map) {
        value.forEach((key, value) {
          if (value is! Map) return;

          final course = Map<String, dynamic>.from(value);

          final owner = course['teacherId']?.toString();

          // Show courses belonging to this teacher.
          // Courses without an owner are also included.
          if (owner != null &&
              owner.isNotEmpty &&
              owner != user.uid) {
            return;
          }

          list.add({
            'id': (course['courseId'] ?? key).toString(),
            'name':
            (course['courseName'] ?? 'Unnamed Course').toString(),
            'code': (course['courseCode'] ?? '').toString(),
          });
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

  // Select and validate a PDF.
  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null) {
        _snack('Could not read that file.');
        return;
      }

      if (bytes.length > _maxPdfBytes) {
        _snack(
          'PDF is ${formatFileSize(bytes.length)}. '
              'The limit is 3 MB.',
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _fileBytes = bytes;
        _fileName = file.name;
      });
    } catch (e) {
      _snack('Could not pick the file: $e');
    }
  }

  // Save the note and optional PDF to Firebase Realtime Database.
  Future<void> _save() async {
    if (_saving) return;

    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (_courseId == null) {
      _snack('Please select a course.');
      return;
    }

    if (_dept == null || _sem == null || _section == null) {
      _snack('Please choose department, semester and section.');
      return;
    }

    if (title.isEmpty) {
      _snack('Please enter a title.');
      return;
    }

    if (content.isEmpty && _fileBytes == null) {
      _snack('Write some notes or attach a PDF.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _snack('Please log in again.');
      return;
    }

    setState(() => _saving = true);

    try {
      final course = _courses.firstWhere(
            (c) => c['id'] == _courseId,
      );

      final nameSnapshot = await FirebaseDatabase.instance
          .ref('users/${user.uid}/name')
          .get();

      final teacherName =
      nameSnapshot.value?.toString().trim().isNotEmpty == true
          ? nameSnapshot.value.toString()
          : (user.displayName ?? 'Teacher');

      final notesRef = FirebaseDatabase.instance.ref('notes');
      final id = notesRef.push().key;

      if (id == null) {
        throw Exception('Could not generate a note ID.');
      }

      final hasFile = _fileBytes != null;

      // Save the note and optional PDF in one atomic update.
      final Map<String, Object?> updates = {
        'notes/$id': {
          'noteId': id,
          'title': title,
          'content': content,
          'courseId': _courseId,
          'courseName': course['name'],
          'department': _dept,
          'semester': _sem,
          'section': _section,
          'teacherId': user.uid,
          'teacherName': teacherName,
          'createdAt': ServerValue.timestamp,
          'hasFile': hasFile,
          if (hasFile) 'fileName': _fileName,
          if (hasFile) 'fileSize': _fileBytes!.length,
        },
        if (hasFile)
          'noteFiles/$id': {
            'fileName': _fileName,
            'size': _fileBytes!.length,
            'data': base64Encode(_fileBytes!),
          },
      };

      await FirebaseDatabase.instance.ref().update(updates);

      if (!mounted) return;

      _snack('Notes posted successfully.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _snack('Could not save notes: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _snack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Who is this for?'),
                      AcademicPicker(
                        accent: violet,
                        department: _dept,
                        semester: _sem,
                        section: _section,
                        onDepartment: (v) {
                          setState(() => _dept = v);
                        },
                        onSemester: (v) {
                          setState(() => _sem = v);
                        },
                        onSection: (v) {
                          setState(() => _section = v);
                        },
                      ),
                      const SizedBox(height: 18),

                      _label('Course'),
                      _courseField(),
                      const SizedBox(height: 18),

                      _label('Title'),
                      TextField(
                        controller: _titleCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _decoration(
                          'e.g. Chapter 3: Linked Lists',
                        ),
                      ),
                      const SizedBox(height: 18),

                      _label('Notes'),
                      TextField(
                        controller: _contentCtrl,
                        maxLines: 8,
                        minLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _decoration(
                          'Write the lesson notes here '
                              '(optional if you attach a PDF)',
                        ),
                      ),
                      const SizedBox(height: 18),

                      _label('Attachment (PDF, optional)'),
                      _attachField(),
                      const SizedBox(height: 28),

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
                            'Post Notes',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachField() {
    if (_fileBytes == null) {
      return InkWell(
        onTap: _pickPdf,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: violet.withValues(alpha: 0.35),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.attach_file_rounded,
                color: violet,
                size: 21,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Attach a PDF (max 3 MB)',
                  style: TextStyle(
                    fontSize: 14,
                    color: violet,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? 'document.pdf',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatFileSize(_fileBytes!.length),
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove PDF',
            onPressed: _saving
                ? null
                : () {
              setState(() {
                _fileBytes = null;
                _fileName = null;
              });
            },
            icon: const Icon(
              Icons.close_rounded,
              color: textGrey,
            ),
          ),
        ],
      ),
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
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: violet,
            ),
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Text(
          'You have no courses yet. Create a course first.',
          style: TextStyle(
            color: Color(0xFF92400E),
            fontSize: 13,
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _courseId,
      isExpanded: true,
      decoration: _decoration('Select a course'),
      items: _courses.map((course) {
        final code = course['code'] ?? '';
        final name = course['name'] ?? 'Unnamed Course';

        return DropdownMenuItem<String>(
          value: course['id'],
          child: Text(
            code.isEmpty ? name : '$name ($code)',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: _saving
          ? null
          : (value) {
        setState(() => _courseId = value);
      },
    );
  }

  Widget _label(String text) {
    return Padding(
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
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: textGrey,
        fontSize: 13,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
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
        borderSide: const BorderSide(
          color: violet,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.of(context).padding.top + 8,
        18,
        26,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ink,
            Color(0xFF3B3F8F),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(34),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'New Notes',
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
}
