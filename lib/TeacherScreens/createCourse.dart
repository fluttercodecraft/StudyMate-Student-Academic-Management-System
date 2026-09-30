import 'package:flutter/material.dart';

class CreateCourse extends StatefulWidget {
  const CreateCourse({super.key});

  @override
  State<CreateCourse> createState() => _CreateCourseState();
}

class _CreateCourseState extends State<CreateCourse> {

  final courseNameController = TextEditingController();
  final courseCodeController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    courseNameController.dispose();
    courseCodeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void createCourse() {
    String courseName = courseNameController.text.trim();
    String courseCode = courseCodeController.text.trim();
    String description = descriptionController.text.trim();

    if (courseName.isEmpty || courseCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter course name and code'),
        ),
      );

      return;
    }

    print('Course Name: $courseName');
    print('Course Code: $courseCode');
    print('Description: $description');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Course created successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Course'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Create New Course',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            const Text('Course Name'),

            const SizedBox(height: 8),

            TextField(
              controller: courseNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Data Structures',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text('Course Code'),

            const SizedBox(height: 8),

            TextField(
              controller: courseCodeController,
              decoration: const InputDecoration(
                hintText: 'e.g. CS-201',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text('Description'),

            const SizedBox(height: 8),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter course description',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: createCourse,

                child: const Text(
                  'Create Course',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}