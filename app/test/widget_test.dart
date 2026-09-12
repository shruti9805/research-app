// Smoke test for Component 1 — the walking skeleton has no counter, so the
// default template's counter test no longer applies. This confirms the app
// builds its widget tree and reaches the health-check screen without
// crashing before the toolchain checks (device, ML Kit) run.

import 'package:flutter_test/flutter_test.dart';

import 'package:questionnaire_capture/main.dart';

void main() {
  testWidgets('CaptureApp builds and shows the health check screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CaptureApp());

    expect(find.text('Component 1 — Walking Skeleton'), findsOneWidget);
  });
}
