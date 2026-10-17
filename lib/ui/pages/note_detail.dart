import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_store.dart';
import '../../data/models.dart';
import '../theme.dart';
import '../widgets/keyboard_bar.dart';
import '../widgets/note_grid.dart';

class NoteDetail extends StatefulWidget {
  const NoteDetail({super.key, required this.note, required this.store});
  final Note note;
  final AppStore store;
  @override
  State<NoteDetail> createState() => _NoteDetailState();
}

class _NoteDetailState extends State<NoteDetail> {
  int imageIndex = 0;
  final galleryController = PageController();
  final comment = TextEditingController();
  final focus = FocusNode();
  bool sending = false;
  @override
  void dispose() {
    galleryController.dispose();
    comment.dispose();
    focus.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final text = comment.text;
    if (text.trim().isEmpty || sending) return;
    setState(() => sending = true);
    await widget.store.comment(widget.note, text);
    if (!mounted) return;
    setState(() => sending = false);
    if (widget.store.storageError == null && comment.text == text) {
      comment.clear();
      focus.unfocus();
    }
    toast(context, widget.store.storageError ?? '评论已发布');
  }

  Widget gallery(Note n) => Stack(
    children: [
      ColoredBox(
        color: canvas,
        child: PageView.builder(
          controller: galleryController,
          itemCount: n.images.length,
          onPageChanged: (i) => setState(() => imageIndex = i),
          itemBuilder: (_, i) => AppImage(n.images[i], fit: BoxFit.contain),
        ),
      ),
      if (n.images.length > 1 && imageIndex > 0)
        Positioned(
          left: 12,
          top: 100,
          child: IconButton.filledTonal(
            tooltip: '上一张图片',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .85),
            ),
            onPressed: () => galleryController.previousPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            ),
            icon: const Icon(CupertinoIcons.chevron_left, size: 18),
          ),
        ),
      if (n.images.length > 1 && imageIndex < n.images.length - 1)
        Positioned(
          right: 12,
          top: 100,
          child: IconButton.filledTonal(
            tooltip: '下一张图片',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .85),
            ),
            onPressed: () => galleryController.nextPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            ),
            icon: const Icon(CupertinoIcons.chevron_right, size: 18),
          ),
        ),
      if (n.images.length > 1)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${imageIndex + 1}/${n.images.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      if (n.images.length > 1)
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              n.images.length,
              (i) => Container(
                margin: const EdgeInsets.all(3),
                width: i == imageIndex ? 16 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: i == imageIndex ? accent : Colors.black26,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
    ],
  );
  Widget content(Note n, AppStore s) => Padding(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          n.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        if (n.body.isNotEmpty)
          Text(n.body, style: const TextStyle(fontSize: 15, height: 1.9)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: n.tags
              .map(
                (t) => Text(
                  '# $t',
                  style: const TextStyle(
                    color: Color(0xFF57718A),
                    fontSize: 14,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        Text(
          '${n.authorId == 'me' ? '刚刚发布' : n.date.split(' ').first} · ${n.location}',
          style: const TextStyle(fontSize: 11, color: muted),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        Text(
          '共 ${s.commentsFor(n).length} 条评论',
          style: const TextStyle(fontSize: 13, color: muted),
        ),
        const SizedBox(height: 20),
        if (s.commentsFor(n).isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('留下第一条友善的评论吧', style: TextStyle(color: muted)),
            ),
          ),
        ...s
            .commentsFor(n)
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Avatar(c.avatar, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.author,
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.text,
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            '一起分享，一起发现',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final n = widget.note;
      final s = widget.store;
      final wide = MediaQuery.sizeOf(context).width > 800;
      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Avatar(n.avatar),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  n.authorId == 'me' ? s.nickname : n.author,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          actions: [
            if (n.authorId != 'me')
              TextButton(
                onPressed: () => s.toggleFollow(n),
                style: TextButton.styleFrom(
                  foregroundColor: s.followed.contains(n.authorId)
                      ? muted
                      : accent,
                  side: BorderSide(
                    color: s.followed.contains(n.authorId)
                        ? const Color(0xFFE6E6E8)
                        : accent,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(s.followed.contains(n.authorId) ? '已关注' : '关注'),
              ),
            IconButton(
              tooltip: '复制笔记内容',
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text:
                        '${n.title}\n${n.body}\n${n.tags.map((t) => '#$t').join(' ')}',
                  ),
                );
                if (context.mounted) toast(context, '笔记内容已复制');
              },
              icon: const Icon(CupertinoIcons.square_arrow_up, size: 22),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: wide
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFEEEEF0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 6, child: gallery(n)),
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                child: content(n, s),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: (MediaQuery.sizeOf(context).width / n.ratio)
                              .clamp(280, 520),
                          child: gallery(n),
                        ),
                        content(n, s),
                      ],
                    ),
                  ),
          ),
        ),
        bottomNavigationBar: KeyboardBar(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF0F0F2))),
            ),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1030),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('note-comment'),
                        controller: comment,
                        focusNode: focus,
                        maxLength: 500,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => send(),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: '说点什么吧…',
                          counterText: '',
                          isDense: true,
                          prefixIcon: Icon(CupertinoIcons.pencil, size: 17),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (comment.text.trim().isNotEmpty)
                      TextButton(
                        onPressed: sending ? null : send,
                        child: Text(sending ? '发送中' : '发送'),
                      )
                    else ...[
                      _action(
                        s.liked.contains(n.id)
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        countLabel(n.likes + (s.liked.contains(n.id) ? 1 : 0)),
                        () => s.toggleLike(n),
                        s.liked.contains(n.id),
                        '点赞',
                      ),
                      _action(
                        s.saved.contains(n.id)
                            ? CupertinoIcons.star_fill
                            : CupertinoIcons.star,
                        countLabel(n.saves + (s.saved.contains(n.id) ? 1 : 0)),
                        () => s.toggleSave(n),
                        s.saved.contains(n.id),
                        '收藏',
                      ),
                      _action(
                        CupertinoIcons.chat_bubble,
                        '${s.commentsFor(n).length}',
                        () => focus.requestFocus(),
                        false,
                        '评论',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  Widget _action(
    IconData icon,
    String count,
    VoidCallback tap,
    bool active,
    String label,
  ) => Semantics(
    key: ValueKey('note-action-$label'),
    label: label,
    button: true,
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 23, color: active ? accent : ink),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(fontSize: 12, color: active ? accent : ink),
            ),
          ],
        ),
      ),
    ),
  );
}
