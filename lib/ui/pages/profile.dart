import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../theme.dart';
import '../widgets/note_grid.dart';
import 'publish.dart';

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({required this.nickname, required this.description});
  final String nickname, description;

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final name = TextEditingController(text: widget.nickname);
  late final bio = TextEditingController(text: widget.description);
  final bioFocus = FocusNode();
  final form = GlobalKey<FormState>();

  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    bioFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    title: const Text('编辑资料'),
    content: SizedBox(
      width: 360,
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('profile-name'),
              controller: name,
              maxLength: 20,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => bioFocus.requestFocus(),
              decoration: const InputDecoration(labelText: '昵称'),
              validator: (v) => (v ?? '').trim().isEmpty ? '昵称不能为空' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('profile-bio'),
              controller: bio,
              focusNode: bioFocus,
              maxLength: 100,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '简介'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, (name: name.text, bio: bio.text));
          }
        },
        child: const Text('保存'),
      ),
    ],
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.store});
  final AppStore store;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int tab = 0;
  Future<void> edit() async {
    final result = await showDialog<({String name, String bio})>(
      context: context,
      builder: (_) => _ProfileEditor(
        nickname: widget.store.nickname,
        description: widget.store.bio,
      ),
    );
    if (result != null) {
      await widget.store.updateProfile(result.name, result.bio);
      if (mounted) toast(context, widget.store.storageError ?? '资料已更新');
    }
  }

  void settings() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关于拾光',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            const Text('一个用来记录、分享与发现日常美好的生活社区。'),
            const SizedBox(height: 12),
            const Text(
              '当前为本地体验版本，内容和互动保存在本机。真实账号、消息同步与商品交易将在接入服务端后开放。',
              style: TextStyle(color: muted, height: 1.7),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.doc_text),
              title: const Text('我的草稿'),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
              onTap: () {
                Navigator.pop(c);
                Navigator.push(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => PublishPage(store: widget.store),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
  void follows() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (c) {
      final authors = <String, String>{};
      for (final n in widget.store.notes) {
        if (widget.store.followed.contains(n.authorId)) {
          authors[n.authorId] = n.author;
        }
      }
      return SafeArea(
        child: authors.isEmpty
            ? const SizedBox(
                height: 260,
                child: EmptyState(
                  title: '还没有关注创作者',
                  subtitle: '在喜欢的笔记中点一下关注，下次就不会错过。',
                ),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  const ListTile(
                    title: Text(
                      '我的关注',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ...authors.entries.map((e) {
                    final n = widget.store.notes.firstWhere(
                      (n) => n.authorId == e.key,
                    );
                    return ListTile(
                      leading: Avatar(n.avatar, size: 40),
                      title: Text(e.value),
                      trailing: TextButton(
                        onPressed: () {
                          widget.store.toggleFollow(n);
                          Navigator.pop(c);
                        },
                        child: const Text('取消关注'),
                      ),
                    );
                  }),
                ],
              ),
      );
    },
  );
  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final notes = tab == 0
        ? s.published
        : s.notes
              .where((n) => (tab == 1 ? s.saved : s.liked).contains(n.id))
              .toList();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      '我的主页',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: settings,
                      tooltip: '设置与帮助',
                      icon: const Icon(
                        CupertinoIcons.line_horizontal_3,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 12, 26, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(s.avatar, size: 78),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.nickname,
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '拾光号：10000001',
                                style: TextStyle(color: muted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      s.bio,
                      style: const TextStyle(fontSize: 14, height: 1.8),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 28,
                      runSpacing: 18,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        InkWell(
                          onTap: follows,
                          child: _stat('${s.followed.length}', '关注'),
                        ),
                        _stat('${s.published.length}', '笔记'),
                        _stat('${s.saved.length}', '收藏'),
                        OutlinedButton(
                          onPressed: edit,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ink,
                            side: const BorderSide(color: Color(0xFFE2E2E5)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('编辑资料'),
                        ),
                        if (s.draft != null)
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<bool>(
                                builder: (_) => PublishPage(store: s),
                              ),
                            ),
                            icon: const Icon(CupertinoIcons.doc_text, size: 17),
                            label: const Text('草稿箱'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['笔记', '收藏', '赞过']
                    .asMap()
                    .entries
                    .map(
                      (e) => InkWell(
                        onTap: () => setState(() => tab = e.key),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 18,
                          ),
                          child: Column(
                            children: [
                              Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: tab == e.key
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: tab == e.key ? ink : muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 20,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: tab == e.key
                                      ? accent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        if (notes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              title: ['生活的第一篇，等你来写', '把喜欢的笔记收藏在这里', '喜欢，就轻轻点个赞'][tab],
              subtitle: [
                '记录今天的小美好，让更多人看见。',
                '在笔记详情中点击星星，下次就能轻松找到。',
                '你点赞的笔记都会出现在这里。',
              ][tab],
              icon: [
                CupertinoIcons.pencil_ellipsis_rectangle,
                CupertinoIcons.star,
                CupertinoIcons.heart,
              ][tab],
              action: tab == 0
                  ? FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<bool>(
                          builder: (_) => PublishPage(store: s),
                        ),
                      ),
                      child: const Text('发布第一篇笔记'),
                    )
                  : null,
            ),
          )
        else
          SliverToBoxAdapter(
            child: NoteGrid(notes: notes, store: s, embedded: true),
          ),
      ],
    );
  }

  Widget _stat(String value, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: muted)),
    ],
  );
}
