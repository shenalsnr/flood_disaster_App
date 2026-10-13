import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flood_disaster/features/component1_evacuation/presentation/screens/citizen_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'c1_push_notifications': true,
      'c1_sound_alerts': true,
      'c1_vibration_alerts': true,
    });
  });

  testWidgets('CitizenSettingsScreen pumps, renders, and responds to interactions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: CitizenSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify main sections and headers
    expect(find.text('Settings & Preferences'), findsOneWidget);
    expect(find.text('Early Warning System Active'), findsOneWidget);
    expect(find.text('Push Notifications'), findsOneWidget);
    expect(find.text('Emergency Sound Siren'), findsOneWidget);
    expect(find.text('Haptic Vibration'), findsOneWidget);

    // Verify Clear Map Cache
    await tester.scrollUntilVisible(find.text('Clear Offline Map Cache'), 100);
    expect(find.text('Clear Offline Map Cache'), findsOneWidget);
    final clearBtn = find.text('CLEAR');
    expect(clearBtn, findsOneWidget);
    await tester.tap(clearBtn);
    await tester.pump();
    expect(find.text('Offline emergency map tiles cleared successfully.'), findsOneWidget);

    // Verify Emergency hotlines
    await tester.scrollUntilVisible(find.text('Disaster Management Centre'), 100);
    expect(find.text('Disaster Management Centre'), findsOneWidget);
    expect(find.text('Emergency Police Control'), findsOneWidget);
    expect(find.text('Suwa Seriya Ambulance'), findsOneWidget);
  });
}
