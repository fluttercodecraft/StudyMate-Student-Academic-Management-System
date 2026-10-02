import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isUploading = false;

  User? get currentUser => _auth.currentUser;

  // Get first letter of student's name
  String getFirstLetter(String name) {
    if (name.trim().isEmpty) {
      return '?';
    }

    return name.trim()[0].toUpperCase();
  }

  // Pick image from gallery
  Future<void> _changeProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (image == null) {
        return;
      }

      await _uploadProfilePicture(File(image.path));
    } catch (e) {
      _showMessage('Failed to select image.');
    }
  }

  // Upload image to Firebase Storage
  Future<void> _uploadProfilePicture(File imageFile) async {
    final User? user = currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final Reference storageReference = _storage
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile')
          .child('profile.jpg');

      await storageReference.putFile(imageFile);

      final String downloadUrl =
      await storageReference.getDownloadURL();

      // Save URL in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': downloadUrl,
      });

      // Also update Firebase Auth photoURL
      await user.updatePhotoURL(downloadUrl);
      await user.reload();

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }

      _showMessage('Profile picture updated successfully.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }

      _showMessage('Failed to upload profile picture.');
    }
  }

  // Remove profile picture
  Future<void> _removeProfilePicture() async {
    final User? user = currentUser;

    if (user == null) {
      return;
    }

    try {
      setState(() {
        _isUploading = true;
      });

      final Reference storageReference = _storage
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile')
          .child('profile.jpg');

      try {
        await storageReference.delete();
      } catch (_) {
        // Image may not exist in Storage.
      }

      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': null,
      });

      await user.updatePhotoURL(null);
      await user.reload();

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }

      _showMessage('Profile picture removed.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }

      _showMessage('Failed to remove profile picture.');
    }
  }

  // Show change/remove menu
  void _showProfilePictureOptions(String? profileImageUrl) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _changeProfilePicture();
                },
              ),
              if (profileImageUrl != null &&
                  profileImageUrl.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Profile Picture'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePicture();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user is currently logged in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        centerTitle: true,
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text('Student profile not found.'),
            );
          }

          final data = snapshot.data!.data()!;

          final String name =
              data['name'] ?? 'Student';

          final String email =
              data['email'] ?? user.email ?? '';

          final String registrationNo =
              data['registrationNo'] ?? 'Not added';

          final String department =
              data['department'] ?? 'Not added';

          final String semester =
              data['semester']?.toString() ?? 'Not added';

          final String? profileImageUrl =
          data['profileImageUrl'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // Profile picture
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage:
                      profileImageUrl != null &&
                          profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,

                      child: profileImageUrl == null ||
                          profileImageUrl.isEmpty
                          ? Text(
                        getFirstLetter(name),
                        style: const TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading
                            ? null
                            : () {
                          _showProfilePictureOptions(
                            profileImageUrl,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: _isUploading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                // Email
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 30),

                _profileItem(
                  icon: Icons.badge,
                  title: 'Registration Number',
                  value: registrationNo,
                ),

                _profileItem(
                  icon: Icons.school,
                  title: 'Department',
                  value: department,
                ),

                _profileItem(
                  icon: Icons.menu_book,
                  title: 'Semester',
                  value: semester,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue,
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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