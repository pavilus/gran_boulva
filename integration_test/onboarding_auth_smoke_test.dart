import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gran_boulva/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'signed-out first launch onboarding and auth navigation smoke test',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await app.bootstrapGranBoulvaApp(resetAuthSession: true);
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    expect(find.text('Debat'), findsOneWidget);
    expect(find.text('Kontinye'), findsOneWidget);

    await tester.tap(find.text('Sote').last);
    await tester.pumpAndSettle();

    expect(find.text('Konekte pou kontinye'), findsOneWidget);
    expect(find.text('Konekte'), findsOneWidget);

    final prefsAfterSkip = await SharedPreferences.getInstance();
    expect(prefsAfterSkip.getBool('onboarding_done'), isTrue);

    final createAccountLink = _richTextContaining('Kreye yon kont');
    await tester.ensureVisible(createAccountLink);
    await tester.tap(createAccountLink);
    await tester.pumpAndSettle();

    expect(find.text('Kreye kont ou'), findsOneWidget);

    final context = tester.element(find.text('Kreye kont ou'));
    GoRouter.of(context).go('/home');
    await tester.pumpAndSettle();

    expect(find.text('Konekte pou kontinye'), findsOneWidget);
  });
}

Finder _richTextContaining(String text) {
  return find.byWidgetPredicate((widget) {
    return widget is RichText && widget.text.toPlainText().contains(text);
  });
}
