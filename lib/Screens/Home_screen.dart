import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../widgets/section_header.dart';
import '../widgets/course_card.dart';
import '../widgets/schedule_card.dart';
import '../widgets/assignment_card.dart';
import 'courses/courses_screen.dart';
import 'assignments/assignments_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToCourses;
  final VoidCallback? onNavigateToAssignments;
  final VoidCallback? onNavigateToNotifications;
  final VoidCallback? onNavigateToProfile;

  const HomeScreen({
    super.key,
    this.onNavigateToCourses,
    this.onNavigateToAssignments,
    this.onNavigateToNotifications,
    this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;
    final ongoingCourse = MockData.courses.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Greeting & Profile Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Good Morning, ${user.name} 👋',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Keep learning, keep growing!',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onNavigateToProfile,
                    child: Stack(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryLight,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 26,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            height: 12,
                            width: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Search Bar
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.search_rounded, size: 22, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search courses, assignments, notes...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Academic Overview Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF196EEE), Color(0xFF0F4CB8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Spring Semester 2026',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.verified_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem('GPA Score', '${user.gpa} / 4.0'),
                        _buildStatDivider(),
                        _buildStatItem('Enrolled', '${MockData.courses.length} Courses'),
                        _buildStatDivider(),
                        _buildStatItem('Attendance', '${user.attendanceRate}%'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Next: ${ongoingCourse.title} • Room 302',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Access Categories
              SectionHeader(
                title: 'Quick Access',
                actionText: 'View All',
                onActionTap: onNavigateToCourses,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAccessItem(
                    title: 'Courses',
                    icon: Icons.menu_book_rounded,
                    color: AppColors.primary,
                    badge: '${MockData.courses.length}',
                    onTap: onNavigateToCourses,
                  ),
                  _buildQuickAccessItem(
                    title: 'Tasks',
                    icon: Icons.assignment_outlined,
                    color: AppColors.indigo,
                    badge: '3',
                    onTap: onNavigateToAssignments,
                  ),
                  _buildQuickAccessItem(
                    title: 'Quizzes',
                    icon: Icons.quiz_outlined,
                    color: AppColors.warning,
                    badge: '1',
                    onTap: () {},
                  ),
                  _buildQuickAccessItem(
                    title: 'Notes',
                    icon: Icons.note_alt_outlined,
                    color: AppColors.teal,
                    onTap: () {},
                  ),
                  _buildQuickAccessItem(
                    title: 'Timetable',
                    icon: Icons.calendar_today_rounded,
                    color: AppColors.purple,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // My Courses Section (Horizontal Scroll)
              SectionHeader(
                title: 'Enrolled Courses',
                actionText: 'See All',
                onActionTap: onNavigateToCourses,
              ),

              SizedBox(
                height: 185,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: MockData.courses.length,
                  itemBuilder: (context, index) {
                    final course = MockData.courses[index];
                    return CourseCard(
                      course: course,
                      isCompact: true,
                      onTap: onNavigateToCourses,
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Today's Schedule Section
              const SectionHeader(
                title: "Today's Schedule",
              ),

              ...MockData.todaySchedule.map(
                (item) => ScheduleCard(item: item),
              ),

              const SizedBox(height: 20),

              // Recent Updates / Assignments Section
              SectionHeader(
                title: 'Pending Assignments',
                actionText: 'View All',
                onActionTap: onNavigateToAssignments,
              ),

              ...MockData.assignments.take(2).map(
                (assignment) => AssignmentCard(
                  assignment: assignment,
                  onTap: onNavigateToAssignments,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 28,
      width: 1,
      color: Colors.white.withOpacity(0.25),
    );
  }

  Widget _buildQuickAccessItem({
    required String title,
    required IconData icon,
    required Color color,
    String? badge,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Center(
                  child: Icon(icon, size: 24, color: color),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
