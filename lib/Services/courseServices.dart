import 'package:firebase_database/firebase_database.dart';

class CourseService {
  final DatabaseReference _coursesRef =
  FirebaseDatabase.instance.ref('courses');

  // Add a new course
  Future<void> addCourse({
    required String courseName,
    required String courseCode,
    required String description,
    required String teacherId,
    required String teacherName,
  }) async {
    final courseId = _coursesRef.push().key;

    if (courseId == null) {
      throw Exception('Could not create course ID');
    }

    await _coursesRef.child(courseId).set({
      'courseId': courseId,
      'courseName': courseName,
      'courseCode': courseCode,
      'description': description,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'createdAt': ServerValue.timestamp,
    });
  }

  // Get all courses
  Stream<DatabaseEvent> getCourses() {
    return _coursesRef.onValue;
  }

  // Delete a course
  Future<void> deleteCourse(String courseId) async {
    await _coursesRef.child(courseId).remove();
  }
}