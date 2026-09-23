import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/assignment.dart';
import '../models/schedule_item.dart';
import '../models/notification_item.dart';
import '../models/user_profile.dart';
import '../core/theme.dart';

class MockData {
  static const UserProfile currentUser = UserProfile(
    id: 'usr_001',
    name: 'Ahmed',
    email: 'ahmed.student@studymate.edu',
    studentId: 'STU-2024-8841',
    department: 'Computer Science',
    semester: 'Semester 5',
    gpa: 3.85,
    attendanceRate: 94,
    completedCourses: 12,
    role: UserRole.student,
  );

  static final List<Course> courses = [
    const Course(
      id: 'c_1',
      title: 'Data Structures & Algorithms',
      code: 'CS-301',
      instructor: 'Dr. Sarah Mitchell',
      progress: 0.72,
      totalLessons: 24,
      completedLessons: 17,
      color: AppColors.primary,
      icon: Icons.account_tree_outlined,
      scheduleTime: 'Mon, Wed • 09:00 AM',
      room: 'Hall 302',
      description: 'Master core algorithmic problem solving, trees, graphs, dynamic programming, and complexity analysis.',
    ),
    const Course(
      id: 'c_2',
      title: 'Object-Oriented Programming',
      code: 'CS-302',
      instructor: 'Prof. David Vance',
      progress: 0.85,
      totalLessons: 20,
      completedLessons: 17,
      color: AppColors.indigo,
      icon: Icons.code_rounded,
      scheduleTime: 'Tue, Thu • 11:00 AM',
      room: 'Lab 4',
      description: 'Design robust software using OOP principles, inheritance, polymorphism, design patterns, and clean architecture.',
    ),
    const Course(
      id: 'c_3',
      title: 'Database Management Systems',
      code: 'CS-303',
      instructor: 'Dr. Emily Watson',
      progress: 0.60,
      totalLessons: 18,
      completedLessons: 11,
      color: AppColors.teal,
      icon: Icons.storage_rounded,
      scheduleTime: 'Mon, Wed • 02:00 PM',
      room: 'Hall B',
      description: 'Relational database modeling, advanced SQL indexing, transaction ACID properties, and normalization.',
    ),
    const Course(
      id: 'c_4',
      title: 'Computer Networks & Security',
      code: 'CS-304',
      instructor: 'Prof. Michael Chang',
      progress: 0.45,
      totalLessons: 22,
      completedLessons: 10,
      color: AppColors.purple,
      icon: Icons.wifi_protected_setup_rounded,
      scheduleTime: 'Tue, Thu • 03:30 PM',
      room: 'Room 108',
      description: 'OSI 7-layer stack, TCP/IP socket programming, network protocol security, encryption, and firewalls.',
    ),
    const Course(
      id: 'c_5',
      title: 'Software Engineering Practices',
      code: 'CS-305',
      instructor: 'Dr. Alan Taylor',
      progress: 0.90,
      totalLessons: 16,
      completedLessons: 14,
      color: AppColors.warning,
      icon: Icons.layers_outlined,
      scheduleTime: 'Fri • 10:00 AM',
      room: 'Auditorium 1',
      description: 'Agile & Scrum project management, CI/CD pipelines, automated testing, and software design lifecycles.',
    ),
  ];

  static final List<ScheduleItem> todaySchedule = [
    const ScheduleItem(
      id: 'sch_1',
      courseCode: 'CS-301',
      courseTitle: 'DSA - Data Structures & Algorithms',
      time: '09:00 AM - 10:30 AM',
      room: 'Room 302',
      instructor: 'Dr. Sarah Mitchell',
      color: AppColors.primary,
      isOngoing: true,
    ),
    const ScheduleItem(
      id: 'sch_2',
      courseCode: 'CS-302',
      courseTitle: 'OOP - Object Oriented Programming',
      time: '11:00 AM - 12:30 PM',
      room: 'Lab 4',
      instructor: 'Prof. David Vance',
      color: AppColors.indigo,
    ),
    const ScheduleItem(
      id: 'sch_3',
      courseCode: 'CS-303',
      courseTitle: 'Database Systems & SQL Lab',
      time: '02:00 PM - 03:30 PM',
      room: 'Hall B',
      instructor: 'Dr. Emily Watson',
      color: AppColors.teal,
    ),
  ];

  static final List<Assignment> assignments = [
    Assignment(
      id: 'a_1',
      title: 'Binary Search Trees & AVL Balancing',
      courseCode: 'CS-301',
      courseTitle: 'Data Structures',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      status: AssignmentStatus.pending,
      description: 'Implement a self-balancing AVL Tree in C++/Java with full rotational test coverage.',
    ),
    Assignment(
      id: 'a_2',
      title: 'Complex SQL Queries & Subqueries',
      courseCode: 'CS-303',
      courseTitle: 'Database Systems',
      dueDate: DateTime.now().add(const Duration(days: 4)),
      status: AssignmentStatus.pending,
      description: 'Write optimized relational queries covering GROUP BY, HAVING, complex INNER/OUTER joins.',
    ),
    Assignment(
      id: 'a_3',
      title: 'Design Pattern Implementation Lab',
      courseCode: 'CS-302',
      courseTitle: 'Object-Oriented Programming',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      status: AssignmentStatus.submitted,
      description: 'Factory and Observer patterns implemented for an e-commerce order workflow.',
    ),
    Assignment(
      id: 'a_4',
      title: 'Network Packet Sniffer & Analysis',
      courseCode: 'CS-304',
      courseTitle: 'Computer Networks',
      dueDate: DateTime.now().subtract(const Duration(days: 5)),
      status: AssignmentStatus.graded,
      score: '96 / 100',
      description: 'Packet capture report detailing TCP handshake, latency breakdown, and DNS lookup timings.',
    ),
  ];

  static final List<NotificationItem> notifications = [
    const NotificationItem(
      id: 'notif_1',
      title: 'New Assignment Posted',
      message: 'Dr. Sarah Mitchell posted "Binary Search Trees" in Data Structures.',
      time: '10 mins ago',
      type: NotificationType.assignment,
      isRead: false,
    ),
    const NotificationItem(
      id: 'notif_2',
      title: 'Quiz Reminder Tomorrow',
      message: 'Database Systems Quiz on SQL Joins will begin tomorrow at 02:00 PM.',
      time: '1 hour ago',
      type: NotificationType.quiz,
      isRead: false,
    ),
    const NotificationItem(
      id: 'notif_3',
      title: 'Assignment Graded',
      message: 'Your submission for "Network Packet Sniffer" has been graded: 96/100.',
      time: 'Yesterday',
      type: NotificationType.assignment,
      isRead: true,
    ),
    const NotificationItem(
      id: 'notif_4',
      title: 'Lecture Room Changed',
      message: 'OOP lecture today has been moved from Room 204 to Computer Lab 4.',
      time: '2 days ago',
      type: NotificationType.course,
      isRead: true,
    ),
    const NotificationItem(
      id: 'notif_5',
      title: 'Midterm Timetable Published',
      message: 'The official schedule for Spring 2026 Midterm Exams is now live in Timetable.',
      time: '3 days ago',
      type: NotificationType.system,
      isRead: true,
    ),
  ];
}
