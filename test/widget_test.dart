import 'package:claims_field/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Claims Field loads home', (tester) async {
    await tester.pumpWidget(const ClaimsFieldApp());
    expect(find.text('Claims Field'), findsOneWidget);
    expect(find.textContaining('Qwen2-VL'), findsWidgets);
    expect(find.textContaining('Auto-describe'), findsOneWidget);
  });
}
