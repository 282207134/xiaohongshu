import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../data/app_store.dart';
import '../../data/models.dart';
import '../theme.dart';
import '../pages/note_detail.dart';

String countLabel(int count) =>
    count >= 10000 ? '${(count / 10000).toStringAsFixed(1)}万' : '$count';

class NoteGrid extends StatelessWidget {
  const NoteGrid({
    super.key,
    required this.notes,
    required this.store,
    this.embedded = false,
  });
  final List<Note> notes;
  final AppStore store;
  final bool embedded;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth > 1150
          ? 5
          : box.maxWidth > 850
          ? 4
          : box.maxWidth > 600
          ? 3
          : 2;
      return MasonryGridView.count(
        key: const PageStorageKey('note-grid'),
        crossAxisCount: columns,
        mainAxisSpacing: 20,
        crossAxisSpacing: box.maxWidth > 600 ? 20 : 10,
        shrinkWrap: embedded,
        physics: embedded ? const NeverScrollableScrollPhysics() : null,
        padding: EdgeInsets.fromLTRB(
          box.maxWidth > 600 ? 28 : 10,
          12,
          box.maxWidth > 600 ? 28 : 10,
          32,
        ),
        itemCount: notes.length,
        itemBuilder: (context, i) => _NoteCard(note: notes[i], store: store),
      );
    },
  );
}

class _NoteCard extends StatefulWidget {
  const _NoteCard({required this.note, required this.store});
  final Note note;
  final AppStore store;
  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool hovered = false;

  void openDetail() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NoteDetail(note: widget.note, store: widget.store),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final n = widget.note;
    final store = widget.store;
    final isLiked = store.liked.contains(n.id);
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: '查看笔记：${n.title}',
            child: GestureDetector(
              onTap: openDetail,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: n.ratio.clamp(.68, 1.25),
                      child: AnimatedScale(
                        scale: hovered ? 1.035 : 1,
                        duration: const Duration(milliseconds: 260),
                        child: AppImage(n.images.first),
                      ),
                    ),
                    if (n.images.length > 1)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.square_on_square,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
            child: InkWell(
              onTap: openDetail,
              child: Text(
                n.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 4),
              Avatar(n.avatar, size: 21),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  n.authorId == 'me' ? store.nickname : n.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ),
              Semantics(
                label: isLiked ? '取消点赞' : '点赞',
                button: true,
                toggled: isLiked,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => store.toggleLike(n),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          size: 17,
                          color: isLiked ? accent : muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          countLabel(n.likes + (isLiked ? 1 : 0)),
                          style: TextStyle(
                            fontSize: 11,
                            color: isLiked ? accent : muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
