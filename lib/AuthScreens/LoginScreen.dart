import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:study_mate/StudentScreens/StudentDashboardScreen.dart';
import 'package:study_mate/AuthScreens/ForgetPassward.dart';
import 'package:study_mate/AuthScreens/RegisterScreen.dart';
import 'package:study_mate/TeacherScreens/TeacherDashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // IMPORTANT:
  // Form needs GlobalKey<FormState>
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisible = false;
  bool _loading = false;

  // ============================================================
  // LOGIN USER
  // ============================================================

  Future<void> _loginUser() async {
    // Validate email and password fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Remove keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {
      // ========================================================
      // STEP 1: LOGIN WITH FIREBASE AUTHENTICATION
      // ========================================================

      final String email =
      _emailController.text.trim().toLowerCase();

      final String password = _passwordController.text;

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        _showMessage('Unable to login. Please try again.');
        return;
      }

      // ========================================================
      // STEP 2: GET USER DATA FROM FIRESTORE
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>> userDocument =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // ========================================================
      // STEP 3: CHECK USER DOCUMENT
      // ========================================================

      if (!userDocument.exists) {
        _showMessage(
          'User profile not found. Please contact administrator.',
        );

        await FirebaseAuth.instance.signOut();
        return;
      }

      // ========================================================
      // STEP 4: GET USER DATA
      // ========================================================

      final Map<String, dynamic>? data = userDocument.data();

      if (data == null) {
        _showMessage(
          'User data is missing. Please contact administrator.',
        );

        await FirebaseAuth.instance.signOut();
        return;
      }

      // Get role from Firestore
      final String role =
          data['role']?.toString().trim().toLowerCase() ?? '';

      debugPrint('Logged in user: ${user.email}');
      debugPrint('User UID: ${user.uid}');
      debugPrint('User Role: $role');

      if (!mounted) return;

      // ========================================================
      // STEP 5: NAVIGATE ACCORDING TO ROLE
      // ========================================================

      if (role == 'student') {
        // Student Dashboard

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
            const StudentDashboardScreen(),
          ),
        );
      } else if (role == 'teacher') {
        // Teacher Dashboard

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
            const TeacherDashboard(),
          ),
        );
      } else if (role == 'admin') {
        // Admin Dashboard
        //
        // We don't have your AdminDashboardScreen yet.
        // For now show a message.

        _showMessage(
          'Admin login successful, but Admin Dashboard is not created yet.',
        );
      } else {
        // Unknown role

        _showMessage(
          'Invalid user role. Please contact administrator.',
        );

        await FirebaseAuth.instance.signOut();
      }
    }

    // ============================================================
    // FIREBASE AUTHENTICATION ERRORS
    // ============================================================

    on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;

        case 'wrong-password':
          message = 'Incorrect password.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message =
          'Too many login attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message =
          'Network error. Please check your internet connection.';
          break;

        default:
          message = e.message ?? 'Login failed.';
      }

      if (mounted) {
        _showMessage(message);
      }
    }

    // ============================================================
    // OTHER ERRORS
    // ============================================================

    catch (e) {
      debugPrint('Login error: $e');

      if (mounted) {
        _showMessage(
          'An unexpected error occurred. Please try again.',
        );
      }
    }

    // ============================================================
    // STOP LOADING
    // ============================================================

    finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const SizedBox(height: 30),

                // ==================================================
                // APP LOGO
                // ==================================================

                Center(
                  child: Container(
                    width: 85,
                    height: 85,

                    decoration: BoxDecoration(
                      color: const Color(0xFF1355D6),
                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // WELCOME TEXT
                // ==================================================

                const Center(
                  child: Text(
                    'Welcome Back!',

                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    'Login to continue to StudyMate',

                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ==================================================
                // EMAIL
                // ==================================================

                const Text(
                  'Email',

                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _emailController,

                  keyboardType: TextInputType.emailAddress,

                  textInputAction: TextInputAction.next,

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    final String email = value.trim();

                    final RegExp emailRegExp = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

                    if (!emailRegExp.hasMatch(email)) {
                      return 'Please enter a valid email address';
                    }

                    return null;
                  },

                  decoration: _buildInputDecoration(
                    hintText: 'Enter your email',
                    icon: Icons.email_outlined,
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // PASSWORD
                // ==================================================

                const Text(
                  'Password',

                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _passwordController,

                  obscureText: !_passwordVisible,

                  textInputAction: TextInputAction.done,

                  onFieldSubmitted: (_) {
                    if (!_loading) {
                      _loginUser();
                    }
                  },

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },

                  decoration: _buildInputDecoration(
                    hintText: 'Enter your password',
                    icon: Icons.lock_outline,

                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),

                      onPressed: () {
                        setState(() {
                          _passwordVisible =
                          !_passwordVisible;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // FORGOT PASSWORD
                // ==================================================

                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const ForgotPasswordScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      'Forgot Password?',

                      style: TextStyle(
                        color: Color(0xFF1355D6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // LOGIN BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed: _loading ? null : _loginUser,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF1355D6),

                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),

                    child: _loading
                        ? const SizedBox(
                      width: 24,
                      height: 24,

                      child:
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )

                        : const Text(
                      'Login',

                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // REGISTER
                // ==================================================

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [
                    const Text(
                      "Don't have an account?",

                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const RegisterScreen(),
                          ),
                        );
                      },

                      child: const Text(
                        'Register',

                        style: TextStyle(
                          color: Color(0xFF1355D6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,

      prefixIcon: Icon(icon),

      suffixIcon: suffixIcon,

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Color(0xFF1355D6),
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}