import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 200),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 45),
);

// enterText requests focus itself, which can hide broken tap targets.
Future<void> touchType(WidgetTester tester, String key, String text) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await settle(tester);
  final editable = tester.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );
  expect(
    editable.focusNode.hasFocus,
    isTrue,
    reason: '$key accepts touch focus',
  );
  tester.testTextInput.enterText(text);
  await settle(tester);
  expect(editable.controller.text, text);
}
