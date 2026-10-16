import 'package:flutter_test/flutter_test.dart';
import 'package:sunvine_epc/main.dart';

void main() {
  testWidgets('App root smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SunvineEpcApp());
    expect(find.byType(SunvineEpcApp), findsOneWidget);
  });
}
