import 'package:flutter_test/flutter_test.dart';

import 'package:autopulse_task/main.dart';

void main() {
  testWidgets('AutoPulse app renders the upload screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AutoPulseApp());

    expect(find.text('Upload Record'), findsOneWidget);
    expect(find.text('Capture with Camera'), findsOneWidget);
  });
}
