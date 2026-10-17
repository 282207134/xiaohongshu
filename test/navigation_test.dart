import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_notes/ui/shell.dart';

import 'support/app.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(320, 740),
    const Size(1440, 900),
  ]) {
    testWidgets('Browse, save, search and navigate at ${size.width}px', (
      tester,
    ) async {
      final store = await loadTestStore(tester, size: size);
      await pumpTestApp(tester, AppShell(store: store));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('英国萨福克郡童话般的春日').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('note-action-收藏')));
      await tester.pumpAndSettle();
      expect(store.saved.contains('9'), true);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('购物').last);
      await tester.pumpAndSettle();
      expect(find.text('好物商店'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('消息').last);
      await tester.pumpAndSettle();
      expect(find.text('最近聊天'), findsOneWidget);
      await tester.tap(find.text('我').last);
      await tester.pumpAndSettle();
      expect(find.text('拾光漫游者').first, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
