import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_notes/data/app_store.dart';
import 'package:life_notes/data/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('All reference notes, images, comments and products load', () async {
    final store = await AppStore.load();
    expect(store.seedNotes.length, 15);
    expect(store.products.length, 20);
    expect(store.seedNotes.every((n) => n.images.isNotEmpty), true);
    expect(store.filter(query: '猫咪'), isNotEmpty);
    expect(store.filter(category: '萌宠').every((n) => n.category == '萌宠'), true);
    expect(store.filter(query: 'not-a-real-title'), isEmpty);
  });

  test(
    'Interactions survive reload and follow feed uses author identity',
    () async {
      final store = await AppStore.load(), noteIndex = 0;
      final note = store.seedNotes[noteIndex];
      store.toggleLike(note);
      store.toggleSave(note);
      store.toggleFollow(note);
      await store.comment(note, '记录里的小美好');
      await store.send('1', '周末见');
      store.addToCart(store.products.first);
      store.addToCart(store.products.first);
      await store.updateProfile('新昵称', '慢慢发现生活');
      await store.persist();
      final restored = await AppStore.load();
      expect(restored.liked.contains(note.id), true);
      expect(restored.saved.contains(note.id), true);
      expect(
        restored.filter(following: true).any((n) => n.id == note.id),
        true,
      );
      expect(restored.commentsFor(note).last.text, '记录里的小美好');
      expect(restored.sentMessages['1'], ['周末见']);
      expect(restored.nickname, '新昵称');
      expect(restored.cartCount, 2);
      expect(restored.cartTotal, store.products.first.price * 2);
      restored.toggleLike(note);
      restored.toggleSave(note);
      restored.toggleFollow(note);
      restored.changeQuantity(restored.products.first, -2);
      await restored.persist();
      final empty = await AppStore.load();
      expect(empty.liked, isEmpty);
      expect(empty.saved, isEmpty);
      expect(empty.followed, isEmpty);
      expect(empty.cart, isEmpty);
    },
  );

  test(
    'Draft, publish and search history persist without duplicate queries',
    () async {
      final store = await AppStore.load();
      await store.saveDraft({'title': '我的草稿', 'images': []});
      expect((await AppStore.load()).draft?['title'], '我的草稿');
      final note = Note(
        id: 'local-test',
        title: '周末日记',
        body: '今天很好',
        category: '生活',
        author: store.nickname,
        authorId: 'me',
        avatar: store.avatar,
        location: '本地',
        date: '2026-10-17',
        tags: ['周末'],
        images: [store.seedNotes.first.images.first],
      );
      await store.publish(note);
      store.addSearch('春日');
      store.addSearch('猫咪');
      store.addSearch('春日');
      await store.persist();
      final restored = await AppStore.load();
      expect(restored.draft, isNull);
      expect(restored.notes.first.id, 'local-test');
      expect(restored.filter(query: '周末').first.title, '周末日记');
      expect(restored.history, ['春日', '猫咪']);
    },
  );
}
