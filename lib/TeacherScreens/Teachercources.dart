import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateCourse extends StatefulWidget {
  const CreateCourse({super.key});

  @override
  State<CreateCourse> createState() => _CreateCourseState();
}

class _CreateCourseState extends State<CreateCourse> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _courseNameController =
  TextEditingController();

  final TextEditingController _courseCodeController =
  TextEditingController();

  final TextEditingController _descriptionController =
  TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedDepartment;
  String? _selectedSemester;

  bool _isLoading = false;

  final List<String> _departments = [
    'Software Engineering',
    'Computer Science',
    'Information Technology',
    'Electrical Engineering',
    'Civil Engineering',
  ];

  final List<String> _semesters = [
    '1st Semester',
    '2nd Semester',
    '3rd Semester',
    '4th Semester',
    '5th Semester',
    '6th Semester',
    '7th Semester',
    '8th Semester',
  ];

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDepartment == null) {
      _showMessage('Please select a department');
      return;
    }

    if (_selectedSemester == null) {
      _showMessage('Please select a semester');
      return;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage('Teacher is not logged in');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String teacherName = user.displayName ?? 'Teacher';

      // Try to get the teacher's name from Firestore
      final userDocument =
      await _firestore.collection('users').doc(user.uid).get();

      if (userDocument.exists) {
        final data = userDocument.data();

        if (data != null && data['name'] != null) {
          teacherName = data['name'].toString();
        }
      }

      // Create a new course document
      final DocumentReference courseReference =
      _firestore.collection('courses').doc();

      await courseReference.set({
        'courseId': courseReference.id,
        'courseName': _courseNameController.text.trim(),
        'courseCode': _courseCodeController.text.trim().toUpperCase(),
        'description': _descriptionController.text.trim(),
        'department': _selectedDepartment,
        'semester': _selectedSemester,

        // Teacher information
        'teacherId': user.uid,
        'teacherName': teacherName,
        'teacherEmail': user.email ?? '',

        // Students will be added later
        'studentIds': <String>[],

        // Course status
        'isActive': true,

        // Firebase server time
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage('Course created successfully');

      // Clear the form
      _courseNameController.clear();
      _courseCodeController.clear();
      _descriptionController.clear();

      setState(() {
        _selectedDepartment = null;
        _selectedSemester = null;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage('Failed to create course: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF6C5CE7),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text(
          'Create Course',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Header
                const Text(
                  'Create a New Course',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1F3B),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Add course information so students can access it from their dashboard.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // Course Name
                TextFormField(
                  controller: _courseNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Course Name',
                    hint: 'Example: Data Structures',
                    icon: Icons.menu_book_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter course name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Course Code
                TextFormField(
                  controller: _courseCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(
                    label: 'Course Code',
                    hint: 'Example: DSA-201',
                    icon: Icons.code_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter course code';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Department
                DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: _inputDecoration(
                    label: 'Department',
                    icon: Icons.school_rounded,
                  ),
                  items: _departments.map((department) {
                    return DropdownMenuItem(
                      value: department,
                      child: Text(department),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select department';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Semester
                DropdownButtonFormField<String>(
                  value: _selectedSemester,
                  decoration: _inputDecoration(
                    label: 'Semester',
                    icon: Icons.calendar_month_rounded,
                  ),
                  items: _semesters.map((semester) {
                    return DropdownMenuItem(
                      value: semester,
                      child: Text(semester),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSemester = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select semester';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    label: 'Course Description',
                    hint: 'Write a short description about this course...',
                    icon: Icons.description_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter course description';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // Create button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createCourse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded),
                        SizedBox(width: 8),
                        Text(
                          'Create Course',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Information box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF6C5CE7),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'After creating the course, you can add students and then create assignments, quizzes, and classes for this course.',
                          style: TextStyle(
                            color: Color(0xFF4C1D95),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
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