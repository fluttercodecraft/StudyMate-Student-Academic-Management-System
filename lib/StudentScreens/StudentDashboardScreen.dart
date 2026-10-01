import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/StudentScreens/courcesScreen.dart';

// ============================================================
// SIMPLE DATA MODEL (replace with Firestore data later)
// ============================================================
class _Notice {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _Notice({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });
}

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  static const Color _primary = Color(0xFF1355D6);
  static const Color _primarySoft = Color(0xFFE8EFFF);
  static const Color _border = Color(0xFFE6EAF0);
  static const Color _textDark = Color(0xFF1F2937);

  // Demo notifications. If this list is empty, the red dot is hidden.
  static const List<_Notice> _notices = [
    _Notice(
      icon: Icons.assignment_rounded,
      title: 'Assignment Due Today',
      message: 'Linked List Implementation is due today.',
      color: Colors.orange,
    ),
    _Notice(
      icon: Icons.quiz_rounded,
      title: 'Quiz Today',
      message: 'Flutter & Firebase Quiz starts at 3:00 PM.',
      color: _primary,
    ),
    _Notice(
      icon: Icons.event_busy_rounded,
      title: 'Class Cancelled',
      message: 'Operating Systems class has been cancelled today.',
      color: Colors.redAccent,
    ),
  ];

  // ============================================================
  // ACTIONS
  // ============================================================

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature is coming soon')),
      );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    if (!context.mounted) return;

    await _handleLogout(context);
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
            (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;

        final displayName = user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : 'Student';

        final userEmail = user?.email ?? 'No email available';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          appBar: _buildAppBar(context),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(displayName),
                const SizedBox(height: 22),

                // ---------------- OVERVIEW ----------------
                _buildTitle("Today's Overview"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildOverviewCard(
                        icon: Icons.menu_book_rounded,
                        number: '5',
                        label: 'Courses',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildOverviewCard(
                        icon: Icons.assignment_rounded,
                        number: '2',
                        label: 'Assignments',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildOverviewCard(
                        icon: Icons.quiz_rounded,
                        number: '1',
                        label: 'Quiz Today',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ---------------- CLASSES ----------------
                _buildSectionHeader(
                  title: "Today's Classes",
                  action: 'View All',
                  onTap: () => _comingSoon(context, 'Timetable'),
                ),
                const SizedBox(height: 12),
                _buildClassCard(
                  subject: 'Data Structures & Algorithms',
                  teacher: 'Dr. Ahmed',
                  time: '10:00 AM - 11:00 AM',
                  room: 'Room 204',
                  icon: Icons.account_tree_rounded,
                  status: 'Upcoming',
                  statusColor: Colors.orange,
                ),
                const SizedBox(height: 10),
                _buildClassCard(
                  subject: 'Database Systems',
                  teacher: 'Mr. Imran',
                  time: '12:00 PM - 01:00 PM',
                  room: 'Lab 2',
                  icon: Icons.storage_rounded,
                  status: 'Upcoming',
                  statusColor: Colors.orange,
                ),
                const SizedBox(height: 10),
                _buildCancelledClassCard(
                  subject: 'Operating Systems',
                  time: '02:00 PM - 03:00 PM',
                  room: 'Room 105',
                ),
                const SizedBox(height: 24),

                // ---------------- ASSIGNMENTS ----------------
                _buildSectionHeader(
                  title: 'Upcoming Assignments',
                  action: 'View All',
                  onTap: () => _comingSoon(context, 'Assignments'),
                ),
                const SizedBox(height: 12),
                _buildAssignmentCard(
                  title: 'Linked List Implementation',
                  course: 'Data Structures',
                  due: 'Due Today',
                  urgent: true,
                ),
                const SizedBox(height: 10),
                _buildAssignmentCard(
                  title: 'Database ER Diagram',
                  course: 'Database Systems',
                  due: 'Due Tomorrow',
                  urgent: false,
                ),
                const SizedBox(height: 24),

                // ---------------- QUIZ ----------------
                _buildSectionHeader(
                  title: "Today's Quiz",
                  action: 'View Quiz',
                  onTap: () => _comingSoon(context, 'Quizzes'),
                ),
                const SizedBox(height: 12),
                _buildQuizCard(),
                const SizedBox(height: 24),

                // ---------------- STUDY TOOLS ----------------
                _buildTitle('Study Tools'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: [
                    _buildStudyCard(
                      icon: Icons.menu_book_rounded,
                      title: 'Courses',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CoursesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildStudyCard(
                      icon: Icons.assignment_rounded,
                      title: 'Assignments',
                      onTap: () => _comingSoon(context, 'Assignments'),
                    ),
                    _buildStudyCard(
                      icon: Icons.quiz_rounded,
                      title: 'Quizzes',
                      onTap: () => _comingSoon(context, 'Quizzes'),
                    ),
                    _buildStudyCard(
                      icon: Icons.fact_check_rounded,
                      title: 'Attendance',
                      onTap: () => _comingSoon(context, 'Attendance'),
                    ),
                    _buildStudyCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Marks',
                      onTap: () => _comingSoon(context, 'Marks'),
                    ),
                    _buildStudyCard(
                      icon: Icons.calendar_month_rounded,
                      title: 'Timetable',
                      onTap: () => _comingSoon(context, 'Timetable'),
                    ),
                    _buildStudyCard(
                      icon: Icons.sticky_note_2_rounded,
                      title: 'Notes',
                      onTap: () => _comingSoon(context, 'Notes'),
                    ),
                    _buildStudyCard(
                      icon: Icons.campaign_rounded,
                      title: 'Notices',
                      onTap: () => _comingSoon(context, 'Notices'),
                    ),
                    _buildStudyCard(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () => _comingSoon(context, 'Settings'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ---------------- ACCOUNT ----------------
                _buildAccountCard(context, displayName, userEmail),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SHARED HELPERS
  // ============================================================

  BoxDecoration _cardDecoration({
    Color color = Colors.white,
    Color borderColor = _border,
    double radius = 15,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _textDark,
      ),
    );
  }

  Widget _iconBox({
    required IconData icon,
    Color color = _primary,
    Color background = _primarySoft,
    double size = 46,
    double iconSize = 23,
    double radius = 12,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'StudyMate',
            style: TextStyle(
              color: _primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Student Dashboard',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showNotifications(context),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: _textDark,
                size: 27,
              ),
              if (_notices.isNotEmpty)
                Positioned(
                  right: -1,
                  top: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 14),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: _primarySoft,
            child: Icon(Icons.person_rounded, color: _primary, size: 21),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _buildWelcomeCard(String displayName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $displayName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                const Text(
                  'Stay organized and keep learning.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Learn Smarter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OVERVIEW CARD
  // ============================================================

  Widget _buildOverviewCard({
    required IconData icon,
    required String number,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: _primary, size: 22),
          const SizedBox(height: 7),
          Text(
            number,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    required String action,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(child: _buildTitle(title)),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: const TextStyle(
              color: _primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CLASS CARD
  // ============================================================

  Widget _buildClassCard({
    required String subject,
    required String teacher,
    required String time,
    required String room,
    required IconData icon,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  teacher,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time • $room',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF555E6D),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CANCELLED CLASS CARD
  // ============================================================

  Widget _buildCancelledClassCard({
    required String subject,
    required String time,
    required String room,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(
        color: const Color(0xFFFFF5F5),
        borderColor: const Color(0xFFFFD6D6),
      ),
      child: Row(
        children: [
          _iconBox(
            icon: Icons.event_busy_rounded,
            color: Colors.redAccent,
            background: const Color(0xFFFFE4E4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time • $room',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Class cancelled today',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ASSIGNMENT CARD
  // ============================================================

  Widget _buildAssignmentCard({
    required String title,
    required String course,
    required String due,
    required bool urgent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(icon: Icons.assignment_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  course,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: urgent
                  ? const Color(0xFFFFE8E8)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              due,
              style: TextStyle(
                color: urgent ? Colors.redAccent : Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUIZ CARD
  // ============================================================

  Widget _buildQuizCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 16),
      child: Row(
        children: [
          _iconBox(
            icon: Icons.quiz_rounded,
            size: 48,
            iconSize: 24,
            radius: 13,
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flutter & Firebase Quiz',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 5),
                Text(
                  '15 Questions • 20 Minutes',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Today',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDY TOOL CARD
  // ============================================================

  Widget _buildStudyCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconBox(icon: icon, size: 42, iconSize: 22, radius: 11),
              const SizedBox(height: 9),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACCOUNT CARD
  // ============================================================

  Widget _buildAccountCard(
      BuildContext context,
      String displayName,
      String userEmail,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(radius: 16),
      child: Row(
        children: [
          _iconBox(
            icon: Icons.person_rounded,
            size: 45,
            iconSize: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                if (_notices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No new notifications',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ..._notices.map(_buildNotificationItem),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(_Notice notice) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(
            icon: notice.icon,
            color: notice.color,
            background: notice.color.withValues(alpha: 0.1),
            size: 38,
            iconSize: 20,
            radius: 10,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notice.message,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}