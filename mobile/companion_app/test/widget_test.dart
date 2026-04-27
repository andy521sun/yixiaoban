import 'package:flutter_test/flutter_test.dart';
import 'package:companion_app/app.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    // 验证登录页显示
    expect(find.text('医小伴'), findsOneWidget);
  });
}
