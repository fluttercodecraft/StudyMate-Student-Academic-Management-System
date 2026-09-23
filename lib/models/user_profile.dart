enum UserRole { student, teacher, admin }

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String department;
  final String semester;
  final double gpa;
  final int attendanceRate;
  final int completedCourses;
  final UserRole role;
  final String avatarUrl;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.department,
    required this.semester,
    required this.gpa,
    required this.attendanceRate,
    required this.completedCourses,
    this.role = UserRole.student,
    this.avatarUrl = '',
  });

  String get roleDisplay {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
