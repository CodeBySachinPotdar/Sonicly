import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_player/presentation/theme/app_theme.dart';
import 'package:music_player/presentation/widgets/artwork_widget.dart';
import 'package:music_player/presentation/widgets/empty_state.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('EmptyState renders title, message, and responds to action button', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.music_note_rounded,
              title: 'No Songs Discovered',
              message: 'Please scan your local storage.',
              actionLabel: 'Scan Now',
              onAction: () {
                actionTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No Songs Discovered'), findsOneWidget);
      expect(find.text('Please scan your local storage.'), findsOneWidget);
      expect(find.text('Scan Now'), findsOneWidget);

      await tester.tap(find.text('Scan Now'));
      expect(actionTapped, isTrue);
    });

    testWidgets('ArtworkWidget renders fallback container when no path is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtworkWidget(
              artworkPath: null,
              size: 80,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    });

    testWidgets('AppTheme provides valid light and dark ThemeData', (tester) async {
      final light = AppTheme.lightTheme();
      final dark = AppTheme.darkTheme();
      final amoled = AppTheme.darkTheme(isAmoled: true);

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(amoled.scaffoldBackgroundColor, Colors.black);
    });
  });
}
