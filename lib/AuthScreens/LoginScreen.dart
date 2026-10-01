import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  bool _passwordVisible = false;
  bool _loading = false;

  // ============================================================
  // LOGIN USER
  // ============================================================

  Future<void> _loginUser() async {
    // Validate form
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {
      // ========================================================
      // STEP 1: GET LOGIN INFORMATION
      // ========================================================

      final String email =
      _emailController.text.trim().toLowerCase();

      final String password =
          _passwordController.text;

      // ========================================================
      // STEP 2: LOGIN WITH FIREBASE AUTHENTICATION
      // ========================================================

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        if (mounted) {
          _showMessage(
            'Unable to login. Please try again.',
            isSuccess: false,
          );
        }
        return;
      }

      debugPrint('Login successful');
      debugPrint('User Email: ${user.email}');
      debugPrint('User UID: ${user.uid}');

      // ========================================================
      // STEP 3: GET USER DATA FROM REALTIME DATABASE
      // ========================================================

      final DatabaseReference userReference =
      FirebaseDatabase.instance.ref('users/${user.uid}');

      final DataSnapshot snapshot =
      await userReference.get();

      // ========================================================
      // STEP 4: CHECK USER PROFILE
      // ========================================================

      if (!snapshot.exists) {
        if (mounted) {
          _showMessage(
            'User profile not found. Please contact administrator.',
            isSuccess: false,
          );
        }

        await FirebaseAuth.instance.signOut();
        return;
      }

      // ========================================================
      // STEP 5: READ USER DATA
      // ========================================================

      final dynamic rawData = snapshot.value;

      if (rawData == null || rawData is! Map) {
        if (mounted) {
          _showMessage(
            'User data is missing. Please contact administrator.',
            isSuccess: false,
          );
        }

        await FirebaseAuth.instance.signOut();
        return;
      }

      // Convert Firebase map to normal Dart map
      final Map<String, dynamic> userData =
      Map<String, dynamic>.from(
        rawData.map(
              (key, value) => MapEntry(
            key.toString(),
            value,
          ),
        ),
      );

      // ========================================================
      // STEP 6: GET ROLE
      // ========================================================

      final String role =
          userData['role']?.toString().trim().toLowerCase() ?? '';

      debugPrint('User Role: $role');

      // ========================================================
      // STEP 7: CHECK ROLE
      // ========================================================

      if (!mounted) return;

      switch (role) {
      // ======================================================
      // STUDENT
      // ======================================================

        case 'student':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const StudentDashboardScreen(),
            ),
          );
          break;

      // ======================================================
      // TEACHER
      // ======================================================

        case 'teacher':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const TeacherDashboard(),
            ),
          );
          break;

      // ======================================================
      // ADMIN
      // ======================================================

        case 'admin':
          _showMessage(
            'Admin login successful, but Admin Dashboard is not created yet.',
            isSuccess: true,
          );
          break;

      // ======================================================
      // UNKNOWN ROLE
      // ======================================================

        default:
          _showMessage(
            'Invalid user role. Please contact administrator.',
            isSuccess: false,
          );

          await FirebaseAuth.instance.signOut();
          break;
      }
    }

    // ============================================================
    // FIREBASE AUTHENTICATION ERRORS
    // ============================================================

    on FirebaseAuthException catch (e) {
      String message = 'Login failed.';

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

        case 'operation-not-allowed':
          message =
          'Email/Password sign-in is not enabled in Firebase.';
          break;

        default:
          message = e.message ?? 'Login failed.';
      }

      if (mounted) {
        _showMessage(
          message,
          isSuccess: false,
        );
      }
    }

    // ============================================================
    // REALTIME DATABASE / OTHER ERRORS
    // ============================================================

    catch (e) {
      debugPrint('Login error: $e');

      if (mounted) {
        _showMessage(
          'An unexpected error occurred. Please try again.',
          isSuccess: false,
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

  void _showMessage(
      String message, {
        required bool isSuccess,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          isSuccess ? Colors.green : Colors.red,
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
              crossAxisAlignment:
              CrossAxisAlignment.start,

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
                      borderRadius:
                      BorderRadius.circular(22),
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

                  keyboardType:
                  TextInputType.emailAddress,

                  textInputAction:
                  TextInputAction.next,

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    final String email =
                    value.trim();

                    final RegExp emailRegExp =
                    RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

                    if (!emailRegExp.hasMatch(email)) {
                      return 'Please enter a valid email address';
                    }

                    return null;
                  },

                  decoration:
                  _buildInputDecoration(
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

                  obscureText:
                  !_passwordVisible,

                  textInputAction:
                  TextInputAction.done,

                  onFieldSubmitted: (_) {
                    if (!_loading) {
                      _loginUser();
                    }
                  },

                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please enter your password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },

                  decoration:
                  _buildInputDecoration(
                    hintText:
                    'Enter your password',

                    icon:
                    Icons.lock_outline,

                    suffixIcon:
                    IconButton(
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
                  alignment:
                  Alignment.centerRight,

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
                        color:
                        Color(0xFF1355D6),
                        fontWeight:
                        FontWeight.w600,
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
                    onPressed:
                    _loading
                        ? null
                        : _loginUser,

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF1355D6),

                      foregroundColor:
                      Colors.white,

                      shape:
                      RoundedRectangleBorder(
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
                        fontWeight:
                        FontWeight.bold,
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
                          color:
                          Color(0xFF1355D6),
                          fontWeight:
                          FontWeight.bold,
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
        borderRadius:
        BorderRadius.circular(14),

        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),

        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Color(0xFF1355D6),
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1,
        ),
      ),

      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}