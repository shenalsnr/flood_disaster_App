import 'package:flutter_test/flutter_test.dart';
import 'package:flood_disaster/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WeSafeApp());
    expect(find.text('Camp Relief & Logistics'), findsOneWidget);
  });
}
