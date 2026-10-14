import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/StudentScreens/AssignmentScrren.dart';
import 'package:study_mate/StudentScreens/AttandanceScreen.dart';
import 'package:study_mate/StudentScreens/NotesScreen.dart';
import 'package:study_mate/StudentScreens/QuizesScreen.dart';
import 'package:study_mate/StudentScreens/TimetableScreen.dart';
import 'package:study_mate/common/AcadmicOption.dart';

class NotificationsScreen extends StatelessWidget {
  final Map<String, dynamic> profile;

  const NotificationsScreen({super.key, this.profile = const {}});

  static const Color primary = Color(0xFF1355D6);
  static const Color primaryDark = Color(0xFF0B3A9E);
  static const Color background = Color(0xFFF4F6FB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  DateTime? _toDate(dynamic v) =>
      v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;

  String _formatTime(BuildContext context, DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month - 1]}, ${TimeOfDay.fromDateTime(d).format(context)}';
  }

  IconData _getIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'assignment':
        return Icons.assignment_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'note':
        return Icons.sticky_note_2_rounded;
      case 'attendance':
        return Icons.fact_check_rounded;
      case 'class':
        return Icons.calendar_month_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'assignment':
        return const Color(0xFFF59E0B);
      case 'quiz':
        return const Color(0xFF8B5CF6);
      case 'note':
        return const Color(0xFFEC4899);
      case 'attendance':
        return const Color(0xFF10B981);
      case 'class':
        return const Color(0xFF0EA5E9);
      default:
        return primary;
    }
  }

  void _navigateToTarget(BuildContext context, String? type) {
    if (type == 'assignment') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen()));
    } else if (type == 'note') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
    } else if (type == 'quiz') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizzesScreen()));
    } else if (type == 'attendance') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
    } else if (type == 'class') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TimetableScreen(profile: profile)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('notifications').onValue,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Unable to load alerts: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: primary));
                }

                final raw = snap.data!.snapshot.value;
                final items = <Map<String, dynamic>>[];

                if (raw is Map) {
                  raw.forEach((key, value) {
                    if (value is Map) {
                      final n = Map<String, dynamic>.from(value);
                      n['notificationId'] = n['notificationId'] ?? key;
                      if (matchesAcademic(n, profile)) {
                        items.add(n);
                      }
                    }
                  });
                }

                items.sort((a, b) {
                  final x = a['createdAt'];
                  final y = b['createdAt'];
                  if (x is! int || y is! int) return 0;
                  return y.compareTo(x);
                });

                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_rounded, size: 54, color: textGrey),
                        SizedBox(height: 12),
                        Text('No notifications yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                        SizedBox(height: 6),
                        Text('Teacher updates for your section will show here.', style: TextStyle(color: textGrey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final title = item['title']?.toString() ?? 'Update';
                    final body = item['body']?.toString() ?? '';
                    final type = item['type']?.toString();
                    final time = _toDate(item['createdAt']);
                    final color = _getColor(type);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F1355D6),
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _navigateToTarget(context, type),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(_getIcon(type), color: color, size: 23),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5,
                                          color: textDark,
                                        ),
                                      ),
                                      if (body.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          body,
                                          style: const TextStyle(color: textGrey, fontSize: 13, height: 1.4),
                                        ),
                                      ],
                                      if (time != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _formatTime(context, time),
                                          style: const TextStyle(color: textGrey, fontSize: 11),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textGrey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + 8, 18, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}