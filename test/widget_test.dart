import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MiniShopApp builds and renders Landing page', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MiniShopApp());
    await tester.pumpAndSettle();
    expect(find.text('Andalus'), findsWidgets);
  });
}
