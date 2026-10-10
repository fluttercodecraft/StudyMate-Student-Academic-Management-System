import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:study_mate/AuthScreens/LoginScreen.dart';
import 'package:study_mate/common/AcadmicOption.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isUploading = false;

  User? get currentUser => _auth.currentUser;

  String _firstLetter(String name) {
    if (name.trim().isEmpty) return '?';
    return name.trim()[0].toUpperCase();
  }

  Future<void> _changeProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 800,
      );

      if (image == null) return;
      await _uploadProfilePicture(File(image.path));
    } catch (e) {
      _showMessage('Failed to select image: $e', isError: true);
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    final User? user = currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final Reference storageReference = _storage
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile')
          .child('profile.jpg');

      await storageReference.putFile(imageFile);
      final String downloadUrl = await storageReference.getDownloadURL();

      // Update in Realtime Database
      await FirebaseDatabase.instance
          .ref('users/${user.uid}')
          .update({'profileImageUrl': downloadUrl});

      await user.updatePhotoURL(downloadUrl);

      if (mounted) {
        setState(() => _isUploading = false);
        _showMessage('Profile picture updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showMessage('Failed to upload profile picture: $e', isError: true);
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    final User? user = currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      try {
        final Reference storageReference = _storage
            .ref()
            .child('users')
            .child(user.uid)
            .child('profile')
            .child('profile.jpg');
        await storageReference.delete();
      } catch (_) {}

      await FirebaseDatabase.instance
          .ref('users/${user.uid}')
          .update({'profileImageUrl': null});

      await user.updatePhotoURL(null);

      if (mounted) {
        setState(() => _isUploading = false);
        _showMessage('Profile picture removed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showMessage('Failed to remove picture: $e', isError: true);
      }
    }
  }

  void _showProfilePictureOptions(String? profileImageUrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profile Picture',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EFFF),
                    child: Icon(Icons.photo_library_rounded,
                        color: Color(0xFF1355D6)),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _changeProfilePicture();
                  },
                ),
                if (profileImageUrl != null && profileImageUrl.isNotEmpty)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFEE2E2),
                      child: Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444)),
                    ),
                    title: const Text('Remove Photo',
                        style: TextStyle(color: Color(0xFFEF4444))),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePicture();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editAcademicProfile(Map<String, dynamic> currentData) async {
    String? dept = currentData['department']?.toString();
    int? sem = currentData['semester'] is int
        ? currentData['semester']
        : int.tryParse(currentData['semester']?.toString() ?? '');
    String? sec = currentData['section']?.toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Academic Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  AcademicPicker(
                    department: dept,
                    semester: sem,
                    section: sec,
                    onDepartment: (v) => setModalState(() => dept = v),
                    onSemester: (v) => setModalState(() => sem = v),
                    onSection: (v) => setModalState(() => sec = v),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final uid = currentUser?.uid;
                        if (uid != null) {
                          final updates = <String, dynamic>{};
                          if (dept != null) updates['department'] = dept;
                          if (sem != null) updates['semester'] = sem;
                          if (sec != null) updates['section'] = sec;
                          if (updates.isNotEmpty) {
                            await FirebaseDatabase.instance
                                .ref('users/$uid')
                                .update(updates);
                          }
                        }
                        if (context.mounted) Navigator.pop(context);
                        _showMessage('Profile updated successfully!');
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of StudyMate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user is currently logged in.')),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('users/${user.uid}').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1355D6)),
            ),
          );
        }

        final raw = snapshot.data?.snapshot.value;
        final data =
            raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

        final String name =
            (data['name'] ?? user.displayName ?? 'Student').toString();
        final String email = (data['email'] ?? user.email ?? '').toString();
        final String role = (data['role'] ?? 'Student').toString().toUpperCase();
        final String department = (data['department'] ?? 'Not set').toString();
        final String semester = data['semester']?.toString() ?? 'Not set';
        final String section = (data['section'] ?? 'Not set').toString();
        final String? photoUrl = data['profileImageUrl'] ?? user.photoURL;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FB),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _header(context, name, email, role, photoUrl),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _infoCard(
                        title: 'Academic Details',
                        onEdit: () => _editAcademicProfile(data),
                        children: [
                          _infoRow(Icons.school_rounded, 'Role', role),
                          _infoRow(
                              Icons.account_balance_rounded, 'Department', department),
                          _infoRow(Icons.timeline_rounded, 'Semester',
                              semester == 'Not set' ? semester : 'Semester $semester'),
                          _infoRow(Icons.group_work_rounded, 'Section',
                              section == 'Not set' ? section : 'Section $section'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _infoCard(
                        title: 'Account Settings',
                        children: [
                          _actionTile(
                            icon: Icons.lock_reset_rounded,
                            title: 'Reset Password',
                            subtitle: 'Send reset instructions to your email',
                            onTap: () async {
                              try {
                                await _auth.sendPasswordResetEmail(email: email);
                                _showMessage('Reset link sent to $email');
                              } catch (e) {
                                _showMessage('Failed: $e', isError: true);
                              }
                            },
                          ),
                          _actionTile(
                            icon: Icons.logout_rounded,
                            title: 'Log Out',
                            subtitle: 'Sign out from this device',
                            isDestructive: true,
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, String name, String email, String role,
      String? photoUrl) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 10, 16, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1355D6), Color(0xFF0B3A9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              const Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFFE8EFFF),
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Text(
                          _firstLetter(name),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1355D6),
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploading
                      ? null
                      : () => _showProfilePictureOptions(photoUrl),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C5CE7),
                      shape: BoxShape.circle,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(color: Colors.white70, fontSize: 13.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    VoidCallback? onEdit,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Color(0xFF1355D6),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive ? const Color(0xFFEF4444) : const Color(0xFF1355D6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDestructive ? color : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}