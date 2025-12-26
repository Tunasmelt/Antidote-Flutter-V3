import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:antidote_flutter/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('complete playlist analysis flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to home
      expect(find.text('ANTIDOTE'), findsOneWidget);
      
      // Find URL input field
      final urlField = find.byType(TextField);
      expect(urlField, findsOneWidget);
      
      // Enter playlist URL
      await tester.enterText(
        urlField,
        'https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd',
      );
      
      // Tap analyze button
      await tester.tap(find.text('REVEAL MY DESTINY'));
      await tester.pumpAndSettle();
      
      // Wait for navigation
      await tester.pump(const Duration(seconds: 1));
      
      // Verify we navigated to analysis screen
      // Note: Actual API call would need backend running
      expect(find.text('Analyzing Playlist...'), findsOneWidget);
    });
    
    testWidgets('battle screen input flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to battle screen
      await tester.tap(find.text('Battle'));
      await tester.pumpAndSettle();
      
      // Verify battle screen elements
      expect(find.text('Playlist Battle'), findsOneWidget);
      expect(find.text('Contender 1'), findsOneWidget);
      expect(find.text('Contender 2'), findsOneWidget);
      
      // Find input fields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));
      
      // Enter URLs
      await tester.enterText(textFields.first, 'https://open.spotify.com/playlist/1');
      await tester.enterText(textFields.last, 'https://open.spotify.com/playlist/2');
      
      // Tap start battle button
      await tester.tap(find.text('START BATTLE'));
      await tester.pumpAndSettle();
      
      // Verify loading state
      expect(find.text('Battling Playlists...'), findsOneWidget);
    });
  });
}

