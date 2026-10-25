import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

const categories = ['推荐', '旅行', '美食', '穿搭', '摄影', '家居', '萌宠', '读书', '生活'];

/// Local demo repository. Replace loading and persistence here when adding an API.
class AppStore extends ChangeNotifier {
  AppStore._(this._prefs, this.seedNotes, this.products);
  final SharedPreferences _prefs;
  final List<Note> seedNotes;
  final List<Product> products;
  final Set<String> liked = {}, saved = {}, followed = {}, readChats = {};
  final List<Note> published = [];
  final Map<String, List<NoteComment>> addedComments = {};
  final Map<String, List<String>> sentMessages = {};
  final Map<int, int> cart = {};
  final List<String> history = [];
  String nickname = '拾光漫游者', bio = '把平凡的日子，过成喜欢的样子。';
  Map<String, dynamic>? draft;
  String? storageError;
  Future<void> _pendingSave = Future.value();

  static Future<AppStore> load() async {
    final results = await Future.wait([
      rootBundle.loadString('assets/notes.json'),
      rootBundle.loadString('assets/products.json'),
    ]);
    final store = AppStore._(
      await SharedPreferences.getInstance(),
      (jsonDecode(results[0]) as List)
          .map((e) => Note.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      (jsonDecode(results[1]) as List)
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
    final raw = store._prefs.getString('life_notes_v1');
    if (raw != null) {
      try {
        store._restore(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {
        store.storageError = '本地记录读取失败，已载入示例内容。';
      }
    }
    return store;
  }

  void _restore(Map<String, dynamic> j) {
    for (final pair in [
      (liked, 'liked'),
      (saved, 'saved'),
      (followed, 'followed'),
      (readChats, 'readChats'),
    ]) {
      pair.$1.addAll(List<String>.from(j[pair.$2] as List? ?? []));
    }
    published.addAll(
      (j['published'] as List? ?? []).map(
        (e) => Note.fromJson(Map<String, dynamic>.from(e as Map)),
      ),
    );
    nickname = j['nickname'] as String? ?? nickname;
    bio = j['bio'] as String? ?? bio;
    history.addAll(List<String>.from(j['history'] as List? ?? []));
    draft = j['draft'] == null
        ? null
        : Map<String, dynamic>.from(j['draft'] as Map);
    (j['comments'] as Map? ?? {}).forEach((k, v) {
      addedComments[k as String] = (v as List)
          .map((c) => NoteComment.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();
    });
    (j['messages'] as Map? ?? {}).forEach((k, v) {
      sentMessages[k as String] = List<String>.from(v as List);
    });
    (j['cart'] as Map? ?? {}).forEach((k, v) {
      cart[int.parse(k as String)] = v as int;
    });
  }

  List<Note> get notes => [...published, ...seedNotes];
  String get avatar => 'assets/images/avatar_avatar_01.png';
  List<Note> filter({
    String category = '推荐',
    String query = '',
    bool following = false,
  }) {
    final q = query.trim().toLowerCase();
    return notes
        .where(
          (n) =>
              (category == '推荐' || n.category == category) &&
              (!following || followed.contains(n.authorId)) &&
              (q.isEmpty ||
                  '${n.title} ${n.body} ${n.authorId == 'me' ? nickname : n.author} ${n.tags.join(' ')}'
                      .toLowerCase()
                      .contains(q)),
        )
        .toList();
  }

  List<NoteComment> commentsFor(Note n) => [
    ...n.comments,
    ...?addedComments[n.id],
  ];
  int get cartCount => cart.values.fold(0, (a, b) => a + b);
  double get cartTotal =>
      products.fold(0.0, (a, p) => a + p.price * (cart[p.id] ?? 0));

  Future<void> persist() {
    final snapshot = jsonEncode({
      'liked': liked.toList(),
      'saved': saved.toList(),
      'followed': followed.toList(),
      'readChats': readChats.toList(),
      'published': published.map((n) => n.toJson()).toList(),
      'nickname': nickname,
      'bio': bio,
      'history': history,
      'draft': draft,
      'comments': addedComments.map(
        (k, v) => MapEntry(k, v.map((c) => c.toJson()).toList()),
      ),
      'messages': sentMessages,
      'cart': cart.map((k, v) => MapEntry('$k', v)),
    });
    _pendingSave = _pendingSave.then((_) async {
      try {
        if (!await _prefs.setString('life_notes_v1', snapshot)) {
          throw StateError('Storage unavailable');
        }
        storageError = null;
      } catch (_) {
        storageError = '设备存储空间不足，修改暂未保存，请清理后重试。';
        notifyListeners();
      }
    });
    return _pendingSave;
  }

  void _toggle(Set<String> set, String id) {
    if (!set.add(id)) {
      set.remove(id);
    }
    notifyListeners();
    persist();
  }

  void toggleLike(Note n) => _toggle(liked, n.id);
  void toggleSave(Note n) => _toggle(saved, n.id);
  void toggleFollow(Note n) => _toggle(followed, n.authorId);
  Future<void> comment(Note n, String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    (addedComments[n.id] ??= []).add(
      NoteComment(author: nickname, avatar: avatar, text: text.trim()),
    );
    notifyListeners();
    await persist();
  }

  Future<void> publish(Note n) async {
    final previousDraft = draft;
    published.insert(0, n);
    draft = null;
    await persist();
    if (storageError != null) {
      published.removeWhere((item) => item.id == n.id);
      draft = previousDraft;
    }
    notifyListeners();
  }

  Future<void> saveDraft(Map<String, dynamic> value) async {
    draft = value;
    notifyListeners();
    await persist();
  }

  Future<void> updateProfile(String name, String description) async {
    nickname = name.trim();
    bio = description.trim();
    notifyListeners();
    await persist();
  }

  void addSearch(String q) {
    q = q.trim();
    if (q.isEmpty) {
      return;
    }
    history.remove(q);
    history.insert(0, q);
    if (history.length > 8) {
      history.removeLast();
    }
    persist();
  }

  void clearHistory() {
    history.clear();
    notifyListeners();
    persist();
  }

  void addToCart(Product p) => changeQuantity(p, 1);

  void changeQuantity(Product p, int delta) {
    final n = (cart[p.id] ?? 0) + delta;
    if (n <= 0) {
      cart.remove(p.id);
    } else {
      cart[p.id] = n;
    }
    notifyListeners();
    persist();
  }

  void markRead(String id) {
    readChats.add(id);
    notifyListeners();
    persist();
  }

  Future<void> send(String id, String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    (sentMessages[id] ??= []).add(text.trim());
    notifyListeners();
    await persist();
  }
}
