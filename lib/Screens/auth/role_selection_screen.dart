import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/role_card.dart';
import '../onboarding/onboarding_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String? registeredName;
  final String? registeredEmail;

  const RoleSelectionScreen({
    super.key,
    this.registeredName,
    this.registeredEmail,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.student;

  void _handleContinue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(
          selectedRole: _selectedRole,
          userName: widget.registeredName ?? 'Ahmed',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Title
              const Text(
                'Select Your Role 🎓',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Choose your role to get the best tailored experience in StudyMate.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Role 1: Student
              RoleCard(
                title: 'STUDENT',
                description: 'Access courses, assignments, quizzes, view timetables, and track academic progress.',
                icon: Icons.school_rounded,
                isSelected: _selectedRole == UserRole.student,
                activeColor: AppColors.primary,
                onTap: () {
                  setState(() => _selectedRole = UserRole.student);
                },
              ),

              // Role 2: Teacher
              RoleCard(
                title: 'TEACHER',
                description: 'Manage courses, create assignments, upload lecture notes, and record student attendance.',
                icon: Icons.co_present_rounded,
                isSelected: _selectedRole == UserRole.teacher,
                activeColor: AppColors.indigo,
                onTap: () {
                  setState(() => _selectedRole = UserRole.teacher);
                },
              ),

              // Role 3: Admin
              RoleCard(
                title: 'ADMIN',
                description: 'Manage users, departments, course catalogs, academic calendars, and system settings.',
                icon: Icons.admin_panel_settings_rounded,
                isSelected: _selectedRole == UserRole.admin,
                activeColor: AppColors.teal,
                onTap: () {
                  setState(() => _selectedRole = UserRole.admin);
                },
              ),

              const Spacer(),

              // Continue Button
              CustomButton(
                text: 'Continue',
                onPressed: _handleContinue,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
