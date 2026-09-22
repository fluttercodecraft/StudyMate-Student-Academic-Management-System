import 'dart:async';
import 'package:flutter/material.dart';
import 'package:study_mate/Screens/Home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: const Color(0xffEAF2FF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 70,
                color: Color(0xff1355D6),
              ),
            ),

            const SizedBox(height: 25),

            // App Name
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: "Study",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff14213D),
                    ),
                  ),
                  TextSpan(
                    text: "Mate",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1976F3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            const Text(
              "Learn • Connect • Succeed",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 45),

            // Loading indicator
            const SizedBox(
              height: 25,
              width: 25,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xff1355D6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

