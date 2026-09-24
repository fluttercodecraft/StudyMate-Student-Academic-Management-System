import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/main.dart';
import 'package:study_mate/Screens/Splash_screen.dart';
import 'package:study_mate/Screens/auth/login_screen.dart';

void main() {
  testWidgets('StudyMate App full launch and splash navigation test', (WidgetTester tester) async {
    // Build our app and trigger first frame.
    await tester.pumpWidget(const StudyMateApp());

    // Verify SplashScreen is loaded
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Your Academic Companion'), findsOneWidget);

    // Advance through the splash timer (3 seconds) and animation transitions
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Verify LoginScreen is now shown
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome back! 👋'), findsOneWidget);
  });
}
