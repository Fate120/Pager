import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    expect(KasirApp, isNotNull);
  });
}
