import 'package:flutter/material.dart';

class TeacherCourses extends StatelessWidget {
  const TeacherCourses({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          _courseCard(
            courseName: 'Data Structures',
            courseCode: 'CS-201',
          ),

          _courseCard(
            courseName: 'Database Systems',
            courseCode: 'CS-301',
          ),

        ],
      ),
    );
  }

  Widget _courseCard({
    required String courseName,
    required String courseCode,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),

      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.menu_book),
        ),

        title: Text(
          courseName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(courseCode),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
      ),
    );
  }
}