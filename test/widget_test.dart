import 'package:flutter_test/flutter_test.dart';
import 'package:vitiligo_connect/main.dart';

void main() {
  testWidgets('Vitiligo Connect app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const VitiligoConnectApp());

    expect(find.text('Vitiligo Connect'), findsOneWidget);
  });
}