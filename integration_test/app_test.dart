import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_notes/main.dart' as app;
import 'package:life_notes/data/app_store.dart';
import 'package:life_notes/ui/theme.dart';
import 'package:life_notes/ui/shell.dart';

import '../test/support/input.dart';

late IntegrationTestWidgetsFlutterBinding binding;
final testTitle = '模拟器笔记-${DateTime.now().millisecondsSinceEpoch}';

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pump();
  await binding.takeScreenshot(name);
}

Future<void> dismissKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester);
}

Future<void> clearToasts(WidgetTester tester) async {
  for (var i = 0; i < 40 && find.byType(SnackBar).evaluate().isNotEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> browseAndSave(WidgetTester tester) async {
  final before = await AppStore.load();
  await tester.tap(find.text('英国萨福克郡童话般的春日').first);
  await settle(tester);
  final author = before.seedNotes.firstWhere((n) => n.id == '9').authorId;
  if (!before.followed.contains(author)) {
    await tester.tap(find.text('关注').first);
  }
  await settle(tester);
  expect(
    (await AppStore.load()).followed.contains(
      before.seedNotes.firstWhere((n) => n.id == '9').authorId,
    ),
    true,
  );
  await tester.tap(find.byTooltip('下一张图片'));
  await settle(tester);
  await tester.tap(find.byTooltip('上一张图片'));
  await settle(tester);
  await touchType(tester, 'note-comment', '模拟器中文评论');
  await capture(tester, '14-comment-keyboard');
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await settle(tester);
  expect((await AppStore.load()).addedComments['9']!.last.text, '模拟器中文评论');
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
  await tester.tap(find.byTooltip('复制笔记内容'));
  await settle(tester);
  expect(
    (await Clipboard.getData(Clipboard.kTextPlain))?.text,
    contains('英国萨福克郡童话般的春日'),
  );
  await tester.binding.handlePopRoute();
  await settle(tester);
  await tester.tap(find.text('我').last);
  await settle(tester);
  await tester.tap(find.text('收藏').last);
  await settle(tester);
  expect(find.text('英国萨福克郡童话般的春日'), findsOneWidget);
  await capture(tester, '03-profile-saved');
  await tester.tap(find.text('编辑资料'));
  await settle(tester);
  await touchType(tester, 'profile-name', '');
  await tester.tap(find.widgetWithText(FilledButton, '保存'));
  await settle(tester);
  expect(find.text('昵称不能为空'), findsOneWidget);
  await touchType(tester, 'profile-name', '模拟器漫游者');
  await tester.testTextInput.receiveAction(TextInputAction.next);
  await settle(tester);
  await touchType(tester, 'profile-bio', '第一行简介\n第二行中文');
  await capture(tester, '15-profile-keyboard');
  await dismissKeyboard(tester);
  await tester.tap(find.widgetWithText(FilledButton, '保存'));
  await settle(tester);
  expect((await AppStore.load()).nickname, '模拟器漫游者');
}

Future<void> searchNotes(WidgetTester tester) async {
  await tester.tap(find.text('发现').last);
  await settle(tester);
  await tester.tap(find.byTooltip('搜索笔记'));
  await settle(tester);
  await touchType(tester, 'note-search', '不存在的笔记xyz');
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await settle(tester);
  expect(find.text('还没找到相关笔记'), findsOneWidget);
  await tester.tap(find.byTooltip('清空'));
  await settle(tester);
  await tester.tap(find.byTooltip('删除搜索历史'));
  await settle(tester);
  expect((await AppStore.load()).history, isEmpty);
  await touchType(tester, 'note-search', '猫咪');
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await settle(tester);
  expect(find.text('让我抱抱，一起温暖，真的好治愈'), findsOneWidget);
  await capture(tester, '04-search');
  await tester.binding.handlePopRoute();
  await settle(tester);
}

Future<void> publishNote(WidgetTester tester) async {
  final store = tester.widget<AppShell>(find.byType(AppShell)).store;
  await store.saveDraft({'tags': '只有话题'});
  await tester.tap(find.byIcon(CupertinoIcons.plus));
  await settle(tester);
  await tester.tap(find.byTooltip('关闭编辑'));
  await settle(tester);
  expect(find.text('把灵感留在草稿里？'), findsOneWidget);
  await tester.tap(find.text('继续编辑'));
  await settle(tester);
  await tester.tap(find.byKey(const ValueKey('publish-submit')));
  await settle(tester);
  expect(find.text('请输入笔记标题'), findsOneWidget);
  await touchType(tester, 'publish-title', testTitle);
  await tester.testTextInput.receiveAction(TextInputAction.next);
  await settle(tester);
  await touchType(tester, 'publish-body', '用 Flutter 记录日常的小美好。\n中文第二行');
  await dismissKeyboard(tester);
  await tester.tap(find.byKey(const ValueKey('publish-submit')));
  await settle(tester);
  expect(find.text('先为这篇笔记添加一张图片吧'), findsOneWidget);
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('publish-tags')),
    200,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('publish-form-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await touchType(tester, 'publish-tags', '#日常 中文话题');
  await dismissKeyboard(tester);
  await tester.tap(find.byType(DropdownButton<String>));
  await settle(tester);
  await tester.tap(find.text('摄影').last);
  await settle(tester);
  await tester.drag(
    find.byKey(const ValueKey('publish-form-scroll')),
    const Offset(0, 700),
  );
  await settle(tester);
  await tester.tap(find.byType(AppImage).first);
  await settle(tester);
  await tester.tap(find.byTooltip('删除图片'));
  await settle(tester);
  expect(find.text('添加图片 0/9'), findsOneWidget);
  await tester.tap(find.byType(AppImage).first);
  await settle(tester);
  await tester.tap(find.text('存草稿'));
  await settle(tester);
  expect((await AppStore.load()).draft?['title'], testTitle);
  expect((await AppStore.load()).draft?['tags'], '#日常 中文话题');
  await capture(tester, '05-publish-draft');
  await tester.tap(find.byTooltip('关闭编辑'));
  await settle(tester);
  await tester.tap(find.text('保存草稿'));
  await settle(tester);
  expect(find.text('记录这一刻'), findsNothing);
  await tester.tap(find.byIcon(CupertinoIcons.plus));
  await settle(tester);
  expect(find.widgetWithText(TextFormField, testTitle), findsOneWidget);
  await clearToasts(tester);
  final publish = find.widgetWithText(FilledButton, '发布笔记');
  await tester.tap(publish);
  await settle(tester);
  expect(find.text('记录这一刻'), findsNothing);
  expect(find.text(testTitle), findsOneWidget);
  final reloaded = await AppStore.load();
  expect(reloaded.published.any((n) => n.title == testTitle), true);
  expect(reloaded.draft, isNull);
  final created = reloaded.published.firstWhere((n) => n.title == testTitle);
  expect(created.tags, ['日常', '中文话题']);
  expect(created.category, '摄影');
  await capture(tester, '06-published');
}

Future<void> shopAndMessages(WidgetTester tester) async {
  await tester.tap(find.text('购物').last);
  await settle(tester);
  expect(find.text('好物商店'), findsOneWidget);
  await touchType(tester, 'shop-search', '不存在商品xyz');
  expect(find.text('还没有找到这件好物'), findsOneWidget);
  await tester.tap(find.byTooltip('清空商品搜索'));
  await dismissKeyboard(tester);
  await capture(tester, '07-shop');
  await tester.tap(find.byType(AppImage).at(3));
  await settle(tester);
  await tester.tap(find.text('加入购物袋'));
  await settle(tester);
  await tester.tap(find.byTooltip('购物袋'));
  await settle(tester);
  expect(find.text('合计'), findsOneWidget);
  expect((await AppStore.load()).cartCount, greaterThan(0));
  final before = (await AppStore.load()).cartCount;
  await tester.tap(find.byTooltip('增加数量').first);
  await settle(tester);
  expect((await AppStore.load()).cartCount, before + 1);
  await tester.tap(find.byTooltip('减少数量').first);
  await settle(tester);
  expect((await AppStore.load()).cartCount, before);
  await capture(tester, '08-cart');
  await tester.binding.handlePopRoute();
  await settle(tester);
  await tester.tap(find.text('消息').last);
  await settle(tester);
  await tester.tap(find.text('拾光小助手'));
  await settle(tester);
  await touchType(tester, 'chat-message', '模拟器消息测试');
  await capture(tester, '16-chat-keyboard');
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await dismissKeyboard(tester);
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
