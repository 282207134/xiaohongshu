import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_notes/main.dart' as app;
import 'package:life_notes/data/app_store.dart';
import 'package:life_notes/ui/theme.dart';

late IntegrationTestWidgetsFlutterBinding binding;
final testTitle = '模拟器笔记-${DateTime.now().millisecondsSinceEpoch}';

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 200),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 45),
);

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pump();
  await binding.takeScreenshot(name);
}

Future<void> browseAndSave(WidgetTester tester) async {
  final before = await AppStore.load();
  await tester.tap(find.text('英国萨福克郡童话般的春日').first);
  await settle(tester);
  await tester.tap(find.byKey(const ValueKey('note-action-收藏')));
  await tester.tap(find.byKey(const ValueKey('note-action-点赞')));
  if (before.saved.contains('9')) {
    await tester.tap(find.byKey(const ValueKey('note-action-收藏')));
  }
  if (before.liked.contains('9')) {
    await tester.tap(find.byKey(const ValueKey('note-action-点赞')));
  }
  await settle(tester);
  await capture(tester, '02-note-detail');
  expect((await AppStore.load()).saved.contains('9'), true);
  expect((await AppStore.load()).liked.contains('9'), true);
  await tester.binding.handlePopRoute();
  await settle(tester);
  await tester.tap(find.text('我').last);
  await settle(tester);
  await tester.tap(find.text('收藏').last);
  await settle(tester);
  expect(find.text('英国萨福克郡童话般的春日'), findsOneWidget);
  await capture(tester, '03-profile-saved');
}

Future<void> searchNotes(WidgetTester tester) async {
  await tester.tap(find.text('发现').last);
  await settle(tester);
  await tester.tap(find.byTooltip('搜索笔记'));
  await settle(tester);
  await tester.enterText(find.byType(TextField), '猫咪');
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await settle(tester);
  expect(find.text('让我抱抱，一起温暖，真的好治愈'), findsOneWidget);
  await capture(tester, '04-search');
  await tester.binding.handlePopRoute();
  await settle(tester);
}

Future<void> publishNote(WidgetTester tester) async {
  await tester.tap(find.byIcon(CupertinoIcons.plus));
  await settle(tester);
  await tester.tap(find.byType(AppImage).first);
  await settle(tester);
  await tester.enterText(find.byType(TextFormField).at(0), testTitle);
  await tester.enterText(
    find.byType(TextFormField).at(1),
    '用 Flutter 记录日常的小美好。',
  );
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester);
  await tester.tap(find.text('存草稿'));
  await settle(tester);
  expect((await AppStore.load()).draft?['title'], testTitle);
  await capture(tester, '05-publish-draft');
  await tester.tap(find.byTooltip('关闭编辑'));
  await settle(tester);
  await tester.tap(find.text('保存草稿'));
  await settle(tester);
  expect(find.text('记录这一刻'), findsNothing);
  await tester.tap(find.byIcon(CupertinoIcons.plus));
  await settle(tester);
  expect(find.widgetWithText(TextFormField, testTitle), findsOneWidget);
  for (var i = 0; i < 25 && find.byType(SnackBar).evaluate().isNotEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  final publish = find.widgetWithText(FilledButton, '发布笔记');
  await tester.scrollUntilVisible(
    publish,
    250,
    scrollable: find
        .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
        .first,
  );
  await tester.tap(publish);
  await settle(tester);
  expect(find.text('记录这一刻'), findsNothing);
  expect(find.text(testTitle), findsOneWidget);
  final reloaded = await AppStore.load();
  expect(reloaded.published.any((n) => n.title == testTitle), true);
  expect(reloaded.draft, isNull);
  await capture(tester, '06-published');
}

Future<void> shopAndMessages(WidgetTester tester) async {
  await tester.tap(find.text('购物').last);
  await settle(tester);
  expect(find.text('好物商店'), findsOneWidget);
  await capture(tester, '07-shop');
  await tester.tap(find.byType(AppImage).at(3));
  await settle(tester);
  await tester.tap(find.text('加入购物袋'));
  await settle(tester);
  await tester.tap(find.byTooltip('购物袋'));
  await settle(tester);
  expect(find.text('合计'), findsOneWidget);
  expect((await AppStore.load()).cartCount, greaterThan(0));
  await capture(tester, '08-cart');
  await tester.binding.handlePopRoute();
  await settle(tester);
  await tester.tap(find.text('消息').last);
  await settle(tester);
  await tester.tap(find.text('拾光小助手'));
  await settle(tester);
  await tester.enterText(find.byType(TextField), '模拟器消息测试');
  await tester.tap(find.text('发送'));
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester);
  expect(find.text('模拟器消息测试'), findsOneWidget);
  expect((await AppStore.load()).sentMessages['0'], contains('模拟器消息测试'));
  await capture(tester, '09-chat');
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android emulator: browse, save, search, draft, publish, shop and chat',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final prior = prefs.getString('life_notes_v1');
      addTearDown(() async {
        if (prior == null) {
          await prefs.remove('life_notes_v1');
        } else {
          await prefs.setString('life_notes_v1', prior);
        }
      });
      app.main();
      await settle(tester);
      await binding.convertFlutterSurfaceToImage();
      await settle(tester);
      await capture(tester, '01-home');
      await browseAndSave(tester);
      await searchNotes(tester);
      await publishNote(tester);
      await shopAndMessages(tester);
      expect(tester.takeException(), isNull);
    },
  );
}
