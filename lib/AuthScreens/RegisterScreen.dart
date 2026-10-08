import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:study_mate/AuthScreens/LoginScreen.dart';
import 'package:study_mate/StudentScreens/StudentDashboardScreen.dart';
import 'package:study_mate/TeacherScreens/TeacherDashboard.dart';
import 'package:study_mate/common/AcadmicOption.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color studentColor = Color(0xFF1355D6);
  static const Color teacherColor = Color(0xFF6C5CE7);
  static const Color background = Color(0xFFF4F6FB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  bool _isStudent = true;
  String? _dept;
  int? _sem;
  String? _section;
  bool _obscure = true;
  bool _loading = false;

  Color get _accent => _isStudent ? studentColor : teacherColor;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  String _authMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Registration failed ($code).';
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dept == null) return _snack('Please select your department.');
    if (_isStudent && (_sem == null || _section == null)) {
      return _snack('Please select your semester and section.');
    }

    final isStudent = _isStudent;
    setState(() => _loading = true);

    UserCredential? cred;

    try {
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final user = cred.user!;
      final name = _nameCtrl.text.trim();
      await user.updateDisplayName(name);

      await FirebaseDatabase.instance.ref('users/${user.uid}').set({
        'uid': user.uid,
        'name': name,
        'email': _emailCtrl.text.trim(),
        'role': isStudent ? 'student' : 'teacher',
        'department': _dept,
        if (isStudent) 'semester': _sem,
        if (isStudent) 'section': _section,
        if (!isStudent && _subjectCtrl.text.trim().isNotEmpty)
          'subject': _subjectCtrl.text.trim(),
        'createdAt': ServerValue.timestamp,
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
          isStudent ? const StudentDashboardScreen() : const TeacherDashboard(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _snack(_authMessage(e.code));
    } catch (e) {
      // Profile could not be saved: remove the half-created account so the
      // person can simply try again with the same email.
      try {
        await cred?.user?.delete();
      } catch (_) {}
      _snack('Could not save your profile: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToLogin() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'I am a',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _roleCard(
                            'Student',
                            Icons.school_rounded,
                            true,
                            studentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _roleCard(
                            'Teacher',
                            Icons.co_present_rounded,
                            false,
                            teacherColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _field(
                      controller: _nameCtrl,
                      label: 'Full name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      controller: _emailCtrl,
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                      keyboard: TextInputType.emailAddress,
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Please enter your email';
                        if (!t.contains('@') || !t.contains('.')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _field(
                      controller: _passCtrl,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: textGrey,
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Use at least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      controller: _confirmCtrl,
                      label: 'Confirm password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      validator: (v) => v != _passCtrl.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                    const SizedBox(height: 26),

                    // ---------- role specific ----------
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _isStudent
                          ? _studentFields()
                          : _teacherFields(),
                    ),

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          _isStudent
                              ? 'Create Student Account'
                              : 'Create Teacher Account',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Already have an account? ',
                              style: TextStyle(color: textGrey, fontSize: 13)),
                          GestureDetector(
                            onTap: _goToLogin,
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- role specific sections ----------
  Widget _studentFields() {
    return Column(
      key: const ValueKey('student'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Your class', 'Used to show you the right classes and attendance.'),
        AcademicPicker(
          accent: _accent,
          department: _dept,
          semester: _sem,
          section: _section,
          onDepartment: (v) => setState(() => _dept = v),
          onSemester: (v) => setState(() => _sem = v),
          onSection: (v) => setState(() => _section = v),
        ),
      ],
    );
  }

  Widget _teacherFields() {
    return Column(
      key: const ValueKey('teacher'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Your department', 'Tell us where you teach.'),
        DropdownButtonFormField<String>(
          value: _dept,
          isExpanded: true,
          decoration: _decoration('Department', Icons.apartment_rounded),
          items: Academic.departments
              .map((d) => DropdownMenuItem(
            value: d,
            child: Text(d,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14)),
          ))
              .toList(),
          onChanged: (v) => setState(() => _dept = v),
        ),
        const SizedBox(height: 14),
        _field(
          controller: _subjectCtrl,
          label: 'Subject / specialization (optional)',
          icon: Icons.menu_book_outlined,
        ),
      ],
    );
  }

  Widget _sectionLabel(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(color: textGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _roleCard(String label, IconData icon, bool student, Color color) {
    final selected = _isStudent == student;

    return GestureDetector(
      onTap: () => setState(() {
        _isStudent = student;
        _dept = null;
        _sem = null;
        _section = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : const Color(0xFFE6EAF0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : textGrey, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? color : textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 28, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent,
            _isStudent ? const Color(0xFF0B3A9E) : const Color(0xFF1B1F3B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 18),
          const Text(
            'Create your account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isStudent
                ? 'Join your class on StudyMate.'
                : 'Set up your teacher profile.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGrey, fontSize: 13.5),
      prefixIcon: Icon(icon, color: textGrey, size: 21),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6EAF0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6EAF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(fontSize: 14.5),
      decoration: _decoration(label, icon, suffix: suffix),
    );
  }
}