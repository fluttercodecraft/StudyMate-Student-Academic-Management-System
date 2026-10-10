import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:study_mate/StudentScreens/NotesScreen.dart';
import 'package:study_mate/StudentScreens/Studentprofilescreen.dart';
import 'package:study_mate/TeacherScreens/Addcourcesscreen.dart';
import 'package:study_mate/TeacherScreens/MyCourcesScreen.dart';
import 'package:study_mate/splashScreen/splashScreen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(const StudyMateApp());
}

class StudyMateApp extends StatelessWidget {
  const StudyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/createCourse': (context) => const AddCourseScreen(),
        '/teacherCourses': (context) => const MyCoursesScreen(),
        '/studentNotes': (context) => const NotesScreen(),
        '/studentProfile': (context) => const StudentProfileScreen(),
      },
      title: 'StudyMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(),
    );
  }
}