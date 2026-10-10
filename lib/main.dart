import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:study_mate/AuthScreens/LoginScreen.dart';
import 'package:study_mate/StudentScreens/NotesScreen.dart';
import 'package:study_mate/StudentScreens/StudentDashboardScreen.dart';
import 'package:study_mate/StudentScreens/Studentprofilescreen.dart';
import 'package:study_mate/TeacherScreens/Addcourcesscreen.dart';
import 'package:study_mate/TeacherScreens/MyCourcesScreen.dart';
import 'package:study_mate/TeacherScreens/TeacherAssignementScreen.dart';
import 'package:study_mate/TeacherScreens/TeacherClassScreen.dart';
import 'package:study_mate/TeacherScreens/TeacherClassesScreen.dart';
import 'package:study_mate/TeacherScreens/TeacherDashboard.dart';
import 'package:study_mate/TeacherScreens/TeacherMarksScreen.dart';
import 'package:study_mate/TeacherScreens/TeacherNotesScreen.dart';
import 'package:study_mate/TeacherScreens/TeacherQuizesScreen.dart';
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
      title: 'StudyMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1355D6),
          primary: const Color(0xFF1355D6),
          secondary: const Color(0xFF6C5CE7),
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1E293B),
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF1355D6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1355D6), width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
          ),
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/studentDashboard': (context) => const StudentDashboardScreen(),
        '/teacherDashboard': (context) => const TeacherDashboard(),
        '/createCourse': (context) => const AddCourseScreen(),
        '/teacherCourses': (context) => const MyCoursesScreen(),
        '/studentNotes': (context) => const NotesScreen(),
        '/studentProfile': (context) => const StudentProfileScreen(),
        '/teacherProfile': (context) => const StudentProfileScreen(),
        '/teacherAssignments': (context) => const TeacherAssignmentsScreen(),
        '/teacherNotes': (context) => const TeacherNotesScreen(),
        '/teacherQuizzes': (context) => const TeacherQuizzesScreen(),
        '/teacherAttendance': (context) => const TeacherAttendanceScreen(),
        '/teacherMarks': (context) => const TeacherMarksScreen(),
        '/teacherClasses': (context) => const TeacherClassesScreen(),
      },
      home: const SplashScreen(),
    );
  }
}