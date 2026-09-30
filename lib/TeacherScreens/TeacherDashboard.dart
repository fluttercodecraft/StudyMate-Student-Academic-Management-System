import 'package:flutter/material.dart';
import 'package:study_mate/TeacherScreens/createCourse.dart';


class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Welcome, Teacher',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Manage your courses, assignments and students.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [

                Expanded(
                  child: _dashboardCard(
                    icon: Icons.menu_book,
                    title: 'My Courses',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const TeacherCourses(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: _dashboardCard(
                    icon: Icons.add,
                    title: 'Create Course',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const CreateCourse(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: _dashboardCard(
                    icon: Icons.assignment,
                    title: 'Assignments',
                    onTap: () {},
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: _dashboardCard(
                    icon: Icons.quiz,
                    title: 'Quizzes',
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: _dashboardCard(
                    icon: Icons.fact_check,
                    title: 'Attendance',
                    onTap: () {},
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: _dashboardCard(
                    icon: Icons.grade,
                    title: 'Marks',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),

      child: Container(
        height: 130,
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(
              icon,
              size: 35,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}