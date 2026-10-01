import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {

  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController
  _confirmPasswordController =
  TextEditingController();

  // ============================================================
  // ROLES
  // ============================================================

  // Admin is intentionally not available for public registration.
  final List<String> _roles = [
    'Student',
    'Teacher',
  ];

  String _selectedRole = 'Student';

  // ============================================================
  // SEMESTERS
  // ============================================================

  final List<String> _semesters =
  List<String>.generate(
    8,
        (index) => '${index + 1}',
  );

  String _selectedSemester = '1';

  // ============================================================
  // DEPARTMENTS
  // ============================================================

  final List<String> _departments = [
    'Civil Engineering',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Computer Science',
    'Software Engineering',
    'Telecommunication Engineering',
  ];

  String _selectedDepartment =
      'Civil Engineering';

  // ============================================================
  // VARIABLES
  // ============================================================

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _loading = false;

  // ============================================================
  // REGISTER USER
  // ============================================================

  Future<void> _registerUser() async {

    // ==========================================================
    // STEP 1: VALIDATE FORM
    // ==========================================================

    if (!(_formKey.currentState?.validate() ??
        false)) {
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {

      // ========================================================
      // STEP 2: GET USER INPUT
      // ========================================================

      final String name =
      _nameController.text.trim();

      final String email =
      _emailController.text.trim().toLowerCase();

      final String password =
      _passwordController.text.trim();

      // ========================================================
      // STEP 3: CREATE FIREBASE AUTH ACCOUNT
      // ========================================================

      final UserCredential userCredential =
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user =
          userCredential.user;

      // ========================================================
      // STEP 4: CHECK USER
      // ========================================================

      if (user == null) {
        if (mounted) {
          _showMessage(
            'Unable to create account. Please try again.',
            isSuccess: false,
          );
        }
        return;
      }

      debugPrint(
        'Firebase Auth account created.',
      );

      debugPrint(
        'User UID: ${user.uid}',
      );

      // ========================================================
      // STEP 5: UPDATE DISPLAY NAME
      // ========================================================

      await user.updateDisplayName(name);

      // ========================================================
      // STEP 6: GET REALTIME DATABASE REFERENCE
      // ========================================================

      final DatabaseReference userReference =
      FirebaseDatabase.instance
          .ref('users/${user.uid}');

      // ========================================================
      // STEP 7: SAVE USER DATA
      // ========================================================

      await userReference.set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'role': _selectedRole,
        'department': _selectedDepartment,
        'semester': _selectedSemester,
        'createdAt': ServerValue.timestamp,
      });

      debugPrint(
        'User data saved to Realtime Database.',
      );

      // ========================================================
      // STEP 8: SUCCESS
      // ========================================================

      if (!mounted) return;

      _showMessage(
        'Account created successfully as $_selectedRole.',
        isSuccess: true,
      );

      // Go back to Login screen
      Navigator.pop(context);

    }

    // ==========================================================
    // FIREBASE AUTHENTICATION ERRORS
    // ==========================================================

    on FirebaseAuthException catch (e) {

      String message =
          'Registration failed.';

      switch (e.code) {

        case 'email-already-in-use':
          message =
          'This email is already registered.';
          break;

        case 'invalid-email':
          message =
          'Please enter a valid email address.';
          break;

        case 'weak-password':
          message =
          'The password provided is too weak.';
          break;

        case 'operation-not-allowed':
          message =
          'Email/Password sign-in is not enabled in Firebase.';
          break;

        case 'network-request-failed':
          message =
          'Network error. Please check your internet connection.';
          break;

        default:
          message =
              e.message ?? 'Registration failed.';
      }

      if (mounted) {
        _showMessage(
          message,
          isSuccess: false,
        );
      }
    }

    // ==========================================================
    // OTHER ERRORS
    // ==========================================================

    catch (e) {

      debugPrint(
        'Registration error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to save account data. Please try again.',
          isSuccess: false,
        );
      }
    }

    // ==========================================================
    // STOP LOADING
    // ==========================================================

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
          isSuccess
              ? Colors.green
              : Colors.red,

          behavior:
          SnackBarBehavior.floating,

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(10),
          ),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {

    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {

    final OutlineInputBorder borderStyle =
    OutlineInputBorder(
      borderRadius:
      BorderRadius.circular(14),
      borderSide:
      BorderSide.none,
    );

    final OutlineInputBorder
    errorBorderStyle =
    OutlineInputBorder(
      borderRadius:
      BorderRadius.circular(14),
      borderSide:
      const BorderSide(
        color: Colors.redAccent,
        width: 1,
      ),
    );

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(25),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                const SizedBox(height: 25),

                // ==================================================
                // LOGO
                // ==================================================

                Center(
                  child: Container(
                    width: 85,
                    height: 85,

                    decoration:
                    BoxDecoration(
                      color:
                      const Color(0xFF1355D6),

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

                const SizedBox(height: 25),

                // ==================================================
                // TITLE
                // ==================================================

                const Center(
                  child: Text(
                    'Create Account',

                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    'Create your StudyMate account',

                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // ==================================================
                // FULL NAME
                // ==================================================

                const Text(
                  'Full Name',

                  style: TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                  _nameController,

                  keyboardType:
                  TextInputType.name,

                  textCapitalization:
                  TextCapitalization.words,

                  validator: (value) {

                    if (value == null ||
                        value.trim().isEmpty) {
                      return
                        'Please enter your full name';
                    }

                    return null;
                  },

                  decoration:
                  InputDecoration(
                    hintText:
                    'Enter your full name',

                    prefixIcon:
                    const Icon(
                      Icons.person_outline,
                    ),

                    filled: true,

                    fillColor:
                    Colors.white,

                    border:
                    borderStyle,

                    focusedBorder:
                    borderStyle,

                    errorBorder:
                    errorBorderStyle,

                    focusedErrorBorder:
                    errorBorderStyle,
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // ROLE
                // ==================================================

                const Text(
                  'Select Role',

                  style: TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value:
                  _selectedRole,

                  icon:
                  const Icon(
                    Icons.arrow_drop_down,
                  ),

                  decoration:
                  InputDecoration(
                    prefixIcon:
                    const Icon(
                      Icons.badge_outlined,
                    ),

                    filled: true,

                    fillColor:
                    Colors.white,

                    border:
                    borderStyle,

                    focusedBorder:
                    borderStyle,

                    errorBorder:
                    errorBorderStyle,

                    focusedErrorBorder:
                    errorBorderStyle,
                  ),

                  items:
                  _roles.map(
                        (String role) {

                      return
                        DropdownMenuItem<String>(
                          value: role,

                          child:
                          Text(role),
                        );
                    },
                  ).toList(),

                  onChanged:
                      (String? newValue) {

                    if (newValue != null) {

                      setState(() {
                        _selectedRole =
                            newValue;
                      });
                    }
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // DEPARTMENT
                // ==================================================

                const Text(
                  'Department',

                  style: TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value:
                  _selectedDepartment,

                  icon:
                  const Icon(
                    Icons.arrow_drop_down,
                  ),

                  isExpanded: true,

                  decoration:
                  InputDecoration(
                    prefixIcon:
                    const Icon(
                      Icons.account_balance_outlined,
                    ),

                    filled: true,

                    fillColor:
                    Colors.white,

                    border:
                    borderStyle,

                    focusedBorder:
                    borderStyle,

                    errorBorder:
                    errorBorderStyle,

                    focusedErrorBorder:
                    errorBorderStyle,
                  ),

                  items:
                  _departments.map(
                        (String department) {

                      return
                        DropdownMenuItem<String>(
                          value: department,

                          child: Text(
                            department,

                            overflow:
                            TextOverflow.ellipsis,
                          ),
                        );
                    },
                  ).toList(),

                  onChanged:
                      (String? newValue) {

                    if (newValue != null) {

                      setState(() {
                        _selectedDepartment =
                            newValue;
                      });
                    }
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // SEMESTER
                // ==================================================

                const Text(
                  'Semester',

                  style: TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value:
                  _selectedSemester,

                  icon:
                  const Icon(
                    Icons.arrow_drop_down,
                  ),

                  decoration:
                  InputDecoration(
                    prefixIcon:
                    const Icon(
                      Icons.calendar_today_outlined,
                    ),

                    filled: true,

                    fillColor:
                    Colors.white,

                    border:
                    borderStyle,

                    focusedBorder:
                    borderStyle,

                    errorBorder:
                    errorBorderStyle,

                    focusedErrorBorder:
                    errorBorderStyle,
                  ),

                  items:
                  _semesters.map(
                        (String semester) {

                      return
                        DropdownMenuItem<String>(
                          value: semester,

                          child:
                          Text(
                            'Semester $semester',
                          ),
                        );
                    },
                  ).toList(),

                  onChanged:
                      (String? newValue) {

                    if (newValue != null) {

                      setState(() {
                        _selectedSemester =
                            newValue;
                      });
                    }
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // EMAIL
                // ==================================================

                const Text(
                  'Email',

                  style: TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                  _emailController,

                  keyboardType:
                  TextInputType.emailAddress,

                  validator: (value) {

                    if (value == null ||
                        value.trim().isEmpty) {
                      return
                        'Please enter your email';
                    }

                    final RegExp
                    emailRegExp =
                    RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );

                    if (!emailRegExp.hasMatch(
                        value.trim())) {
                      return
                        'Please enter a valid email address';
                    }

                    return null;
                  },

                  decoration:
                  InputDecoration(
                    hintText:
                    'Enter your email',

                    prefixIcon:
                    const Icon(
                      Icons.email_outlined,
                    ),

                    filled: true,

                    fillColor:
                    Colors.white,

                    border:
                    borderStyle,

                    focusedBorder:
                    borderStyle,

                    errorBorder:
                    errorBorderStyle,

                    focusedErrorBorder:
                    errorBorderStyle,
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // PASSWORD
                // ==================================================

                const Text(
                  'Password',

                  style: TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                  _passwordController,

                  obscureText:
                  !_passwordVisible,

                  validator: (value) {

                    if (value == null ||
                        value.trim().isEmpty) {
                      return
                        'Please enter a password';
                    }

                    if (value.trim().length <
                        6) {
                      return
                        'Password must be at least 6 characters';
                    }

                    return null;
                  },

                  decoration:
                  InputDecoration(
                    hintText:
                    'Create a password',

                    prefixIcon:
                    const Icon(
                      Icons.lock_outline,
                    ),

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

                    filled: true,

                    fillColor:
                    Colors.white,

                    border:
                    borderStyle,

                    focusedBorder:
                    borderStyle,

                    errorBorder:
                    errorBorderStyle,

                    focusedErrorBorder:
                    errorBorderStyle,
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // CONFIRM PASSWORD
                // ==================================================

                const Text(
                  'Confirm Password',

                  style: TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                  _confirmPasswordController,

                  obscureText:
                  !_confirmPasswordVisible,

                  validator: (value) {

                    if (value == null ||
                        value.trim().isEmpty) {
                      return
                        'Please confirm your password';
                    }

                    if (value.trim() !=
                        _passwordController
                            .text
                            .trim()) {
                      return
                        'Passwords do not match';
                    }

                    return null;
                  },

                  decoration:
                  InputDecoration(
                    hintText:
                    'Confirm your password',

                    prefixIcon:
                    const Icon(
                      Icons.lock_outline,
                    ),

                    suffixIcon:
                    IconButton(
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),

                      onPressed: () {

                        setState(() {
                          _confirmPasswordVisible =
                          !_confirmPasswordVisible;
                        });
                      },
                    ),

                    filled: true,

                    fillColor:
                    Colors.white,

                    border:
                    borderStyle,

                    focusedBorder:
                    borderStyle,

                    errorBorder:
                    errorBorderStyle,

                    focusedErrorBorder:
                    errorBorderStyle,
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // CREATE ACCOUNT BUTTON
                // ==================================================

                SizedBox(
                  width:
                  double.infinity,

                  height: 55,

                  child:
                  ElevatedButton(
                    onPressed:
                    _loading
                        ? null
                        : _registerUser,

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(
                        0xFF1355D6,
                      ),

                      foregroundColor:
                      Colors.white,

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),

                    child: _loading
                        ? const SizedBox(
                      width: 24,
                      height: 24,

                      child:
                      CircularProgressIndicator(
                        color:
                        Colors.white,

                        strokeWidth:
                        2.5,
                      ),
                    )

                        : const Text(
                      'Create Account',

                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // LOGIN LINK
                // ==================================================

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [

                    const Text(
                      'Already have an account?',

                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    TextButton(
                      onPressed:
                      _loading
                          ? null
                          : () {
                        Navigator.pop(
                          context,
                        );
                      },

                      child:
                      const Text(
                        'Login',

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

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}