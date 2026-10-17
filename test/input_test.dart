import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_notes/ui/pages/discover.dart';
import 'package:life_notes/ui/pages/messages.dart';
import 'package:life_notes/ui/pages/note_detail.dart';
import 'package:life_notes/ui/pages/profile.dart';
import 'package:life_notes/ui/shell.dart';

import 'support/app.dart';
import 'support/input.dart';

void main() {
  testWidgets(
    'Desktop discovery search accepts text and opens matching results',
    (tester) async {
      final store = await loadTestStore(tester, size: const Size(1440, 900));
      await pumpTestApp(tester, Scaffold(body: DiscoverPage(store: store)));
      await touchType(tester, 'discover-search', '猫咪');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('让我抱抱，一起温暖，真的好治愈'), findsOneWidget);
      await tester.tap(find.byTooltip('清空'));
      await tester.pumpAndSettle();
      await touchType(tester, 'note-search', '找不到的笔记');
      await tester.tap(find.widgetWithText(TextButton, '搜索'));
      await tester.pumpAndSettle();
      expect(find.text('还没找到相关笔记'), findsOneWidget);
      await tester.tap(find.byTooltip('清空'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('删除搜索历史'));
      await tester.pumpAndSettle();
      expect(store.history, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Comment composer stays above keyboard and accepts Chinese composition',
    (tester) async {
      final store = await loadTestStore(tester, size: const Size(320, 640));
      final note = store.seedNotes.first;
      await pumpTestApp(tester, NoteDetail(note: note, store: store));
      await tester.tap(find.byKey(const ValueKey('note-action-评论')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('note-comment'));
      expect(tester.getRect(field).bottom, lessThanOrEqualTo(360));
      await touchType(tester, 'note-comment', '中文评论');
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '中文评论测试',
          selection: TextSelection.collapsed(offset: 6),
          composing: TextRange(start: 4, end: 6),
        ),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, '发送'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(store.addedComments[note.id]!.single.text, '中文评论测试');
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Profile fields remain editable on a small screen with keyboard',
    (tester) async {
      final store = await loadTestStore(tester, size: const Size(320, 640));
      await pumpTestApp(tester, Scaffold(body: ProfilePage(store: store)));
      await tester.tap(find.text('编辑资料'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await touchType(tester, 'profile-name', '');
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pumpAndSettle();
      expect(find.text('昵称不能为空'), findsOneWidget);
      await touchType(tester, 'profile-name', '新的昵称');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      await touchType(tester, 'profile-bio', '简介第一行\n中文第二行');
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pumpAndSettle();
      expect(store.nickname, '新的昵称');
      expect(store.bio, '简介第一行\n中文第二行');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Shop search can type and clear while keyboard is visible', (
    tester,
  ) async {
    final store = await loadTestStore(tester, size: const Size(320, 640));
    await pumpTestApp(tester, AppShell(store: store));
    await tester.tap(find.text('购物').last);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await touchType(tester, 'shop-search', '不存在的商品');
    expect(find.text('还没有找到这件好物'), findsOneWidget);
    await tester.tap(find.byTooltip('清空商品搜索'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('shop-search')))
          .controller!
          .text,
      '',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Chat can focus, send with keyboard and ignore empty submissions',
    (tester) async {
      final store = await loadTestStore(tester, size: const Size(320, 640));
      await pumpTestApp(tester, ChatPage(store: store, index: 0));
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await touchType(tester, 'chat-message', '中文消息');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '发送'));
      await tester.pumpAndSettle();
      expect(store.sentMessages['0'], ['中文消息']);
      expect(tester.takeException(), isNull);
    },
  );
}
