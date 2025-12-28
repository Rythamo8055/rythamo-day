import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('OnboardingScreen renders correctly and navigates', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    // Verify Welcome Page
    expect(find.text('Welcome to\nRythamo Day'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify Name Page
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Enter Name
    await tester.enterText(find.byType(TextField), 'Test User');
    await tester.pump();

    // Tap Continue
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify Theme Selection Page
    expect(find.text('Choose your vibe'), findsOneWidget);
    
    // Tap Continue (Default theme is selected)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify Avatar Selection Page
    expect(find.text('Choose your avatar'), findsOneWidget);

    // Tap Continue (Default avatar is selected)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify Why Page
    expect(find.text('Why do you journal?'), findsOneWidget);
    
    // Enter Why
    await tester.enterText(find.byType(TextField), 'To reflect');
    await tester.pump();

    // Tap Continue
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify Ready Page
    expect(find.text('You\'re all set,\nTest User!'), findsOneWidget);
    expect(find.text('Start Journaling'), findsOneWidget);
  });
}
