import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State {
  // FIXED 1: Replaced GlobalKey with GlobalKey explicit typing
  final _formKey = GlobalKey();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List _roles = ['Student', 'Teacher', 'Admin'];
  String _selectedRole = 'Student';

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _loading = false;

  Future _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      _showMessage('Account created successfully as $_selectedRole');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address';
          break;
        case 'weak-password':
          message = 'The password provided is too weak';
          break;
        case 'operation-not-allowed':
          message = 'Email/Password sign-in is not enabled in Firebase';
          break;
        default:
          message = e.message ?? message;
      }

      // FIXED 6: Wrapped if-statement body inside curly braces {}
      if (mounted) {
        _showMessage(message);
      }
    } catch (e) {
      // FIXED 6: Wrapped if-statement body inside curly braces {}
      if (mounted) {
        _showMessage('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );

    final errorBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1),
    );

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
                const SizedBox(height: 25),

                // Logo Header
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

                const SizedBox(height: 25),

                const Center(
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
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

                // Full Name Input
                const Text(
                  'Full Name',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: borderStyle,
                    focusedBorder: borderStyle,
                    errorBorder: errorBorderStyle,
                    focusedErrorBorder: errorBorderStyle,
                  ),
                ),

                const SizedBox(height: 18),

                // Role Dropdown Input
                const Text(
                  'Select Role',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField(
                  // FIXED 4: Replaced 'value:' with 'initialValue:' (Flutter 3.33+ deprecation)
                  initialValue: _selectedRole,
                  icon: const Icon(Icons.arrow_drop_down),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: borderStyle,
                    focusedBorder: borderStyle,
                    errorBorder: errorBorderStyle,
                    focusedErrorBorder: errorBorderStyle,
                  ),
                  // FIXED 2 & 3: Explicitly type mapped list as List>
                  items: _roles.map>((String role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedRole = newValue;
                      });
                    }
                  },
                ),

                const SizedBox(height: 18),

                // Email Input
                const Text(
                  'Email',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    final emailRegExp =
                    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegExp.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: borderStyle,
                    focusedBorder: borderStyle,
                    errorBorder: errorBorderStyle,
                    focusedErrorBorder: errorBorderStyle,
                  ),
                ),

                const SizedBox(height: 18),

                // Password Input
                const Text(
                  'Password',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.trim().length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Create a password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: borderStyle,
                    focusedBorder: borderStyle,
                    errorBorder: errorBorderStyle,
                    focusedErrorBorder: errorBorderStyle,
                  ),
                ),

                const SizedBox(height: 18),

                // Confirm Password Input
                const Text(
                  'Confirm Password',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_confirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value.trim() != _passwordController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Confirm your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: borderStyle,
                    focusedBorder: borderStyle,
                    errorBorder: errorBorderStyle,
                    focusedErrorBorder: errorBorderStyle,
                  ),
                ),

                const SizedBox(height: 25),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1355D6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Navigation Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFF1355D6),
                          fontWeight: FontWeight.bold,
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