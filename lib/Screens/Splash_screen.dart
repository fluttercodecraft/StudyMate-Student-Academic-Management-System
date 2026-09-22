import 'dart:async';
import 'package:flutter/material.dart';
import 'package:study_mate/Screens/Home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controls the logo: fade + scale ("pop in")
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // Controls the text: fade + slide up
  late final AnimationController _textController;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;

  // Continuous gentle pulse on the logo container
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  // Loading indicator fade-in
  late final AnimationController _loaderController;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loaderFade = CurvedAnimation(parent: _loaderController, curve: Curves.easeIn);

    _runSequence();
  }

  Future<void> _runSequence() async {
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _loaderController.forward();

    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 750),
        pageBuilder: (context, animation, secondaryAnimation) =>
        const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return _CurtainWipeTransition(
            animation: curved,
            newPage: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_logoController, _pulseController]),
              builder: (context, child) {
                return Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value * _pulseScale.value,
                    child: child,
                  ),
                );
              },
              child: _LogoBadge(),
            ),
            const SizedBox(height: 25),
            FadeTransition(
              opacity: _textFade,
              child: SlideTransition(
                position: _textSlide,
                child: const _AppTitle(),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _textFade,
              child: const _Tagline(),
            ),
            const SizedBox(height: 45),
            FadeTransition(
              opacity: _loaderFade,
              child: const _Loader(),
            ),
          ],
        ),
      ),
    );
  }
}

/// The curtain/wipe transition: the splash screen splits down the middle
/// into two halves that slide apart (like opening a curtain / cape),
/// revealing the new page underneath.
class _CurtainWipeTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget newPage;

  const _CurtainWipeTransition({
    required this.animation,
    required this.newPage,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value; // 0 -> 1
            final panelOffset = width * t; // how far each half has slid

            return Stack(
              fit: StackFit.expand,
              children: [
                // New page revealed underneath
                newPage,

                // Left half of the splash slides left off-screen
                Positioned(
                  left: -panelOffset,
                  top: 0,
                  width: width / 2,
                  height: height,
                  child: ClipRect(
                    child: OverflowBox(
                      maxWidth: width,
                      maxHeight: height,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: const _FrozenSplashContent(),
                      ),
                    ),
                  ),
                ),

                // Right half of the splash slides right off-screen
                Positioned(
                  right: -panelOffset,
                  top: 0,
                  width: width / 2,
                  height: height,
                  child: ClipRect(
                    child: OverflowBox(
                      maxWidth: width,
                      maxHeight: height,
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: const _FrozenSplashContent(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// A static (non-animated) snapshot of the splash screen's final look,
/// used to fill the two curtain panels during the wipe transition.
class _FrozenSplashContent extends StatelessWidget {
  const _FrozenSplashContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LogoBadge(),
            SizedBox(height: 25),
            _AppTitle(),
            SizedBox(height: 8),
            _Tagline(),
            SizedBox(height: 45),
            _Loader(),
          ],
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        color: const Color(0xffEAF2FF),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1355D6).withOpacity(0.18),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.school_outlined,
        size: 70,
        color: Color(0xff1355D6),
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return RichText(
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
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Learn • Connect • Succeed",
      style: TextStyle(
        fontSize: 15,
        color: Colors.grey,
        letterSpacing: 1,
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 25,
      width: 25,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: Color(0xff1355D6),
      ),
    );
  }
}