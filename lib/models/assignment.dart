enum AssignmentStatus { pending, submitted, graded }

class Assignment {
  final String id;
  final String title;
  final String courseCode;
  final String courseTitle;
  final DateTime dueDate;
  final AssignmentStatus status;
  final String? score;
  final String description;

  const Assignment({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.courseTitle,
    required this.dueDate,
    required this.status,
    this.score,
    this.description = '',
  });

  String get dueStatusText {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    if (difference.inDays == 0) {
      return 'Due Today';
    } else if (difference.inDays == 1) {
      return 'Due Tomorrow';
    } else if (difference.inDays > 1) {
      return 'Due in ${difference.inDays} days';
    } else {
      return 'Overdue';
    }
  }
}
