import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/Services/courseServices.dart';


class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _courseNameController =
  TextEditingController();

  final TextEditingController _courseCodeController =
  TextEditingController();

  final TextEditingController _descriptionController =
  TextEditingController();

  final CourseService _courseService = CourseService();

  bool _isLoading = false;

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _courseService.addCourse(
        courseName: _courseNameController.text.trim(),
        courseCode: _courseCodeController.text.trim(),
        description: _descriptionController.text.trim(),
        teacherId: user.uid,
        teacherName: user.displayName?.isNotEmpty == true
            ? user.displayName!
            : 'Teacher',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add course: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Add Course',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1355D6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1355D6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Create New Course',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Add course information for your students.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Course Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 15),

              // Course Name
              _buildLabel('Course Name'),

              const SizedBox(height: 7),

              TextFormField(
                controller: _courseNameController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  hintText: 'e.g. Data Structures & Algorithms',
                  icon: Icons.book_rounded,
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
              _buildLabel('Course Code'),

              const SizedBox(height: 7),

              TextFormField(
                controller: _courseCodeController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration(
                  hintText: 'e.g. CSE-301',
                  icon: Icons.tag_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter course code';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Description
              _buildLabel('Description'),

              const SizedBox(height: 7),

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: _inputDecoration(
                  hintText: 'Enter a short course description...',
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

              // Add Course Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1355D6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add Course',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Center(
                child: Text(
                  'The course will be saved to Firebase.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF374151),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF1355D6),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFE3E7EE),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFF1355D6),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}