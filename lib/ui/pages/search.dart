import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../theme.dart';
import '../widgets/note_grid.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.store});
  final AppStore store;
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final controller = TextEditingController();
  String query = '';
  bool searched = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit(String q) {
    if (q.trim().isEmpty) return;
    widget.store.addSearch(q);
    controller.text = q;
    setState(() {
      query = q;
      searched = true;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: submit,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: '搜索笔记、作者、生活灵感',
            isDense: true,
            prefixIcon: const Icon(CupertinoIcons.search, size: 19),
            suffixIcon: IconButton(
              tooltip: '清空',
              onPressed: () {
                controller.clear();
                setState(() => searched = false);
              },
              icon: const Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 17,
                color: muted,
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => submit(controller.text),
          child: const Text('搜索'),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        if (searched) {
          final result = widget.store.filter(query: query);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
                child: Text(
                  '“$query”的搜索结果 · ${result.length} 篇',
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
              ),
              Expanded(
                child: result.isEmpty
                    ? const EmptyState(
                        title: '还没找到相关笔记',
                        subtitle: '试试“春日”“猫咪”“阳光”，或者搜索作者名字。',
                        icon: CupertinoIcons.search,
                      )
                    : NoteGrid(notes: result, store: widget.store),
              ),
            ],
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    const Text(
                      '最近搜索',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (widget.store.history.isNotEmpty)
                      IconButton(
                        tooltip: '删除搜索历史',
                        onPressed: widget.store.clearHistory,
                        icon: const Icon(
                          CupertinoIcons.trash,
                          size: 18,
                          color: muted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (widget.store.history.isEmpty)
                  const Text('搜一搜，发现新的喜欢', style: TextStyle(color: muted))
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.store.history
                        .map(
                          (h) => ActionChip(
                            label: Text(h),
                            onPressed: () => submit(h),
                            side: BorderSide.none,
                            backgroundColor: canvas,
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 40),
                const Text(
                  '大家都在搜',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ...['春日', '治愈', '阳光', '美食', '猫咪', '文艺'].asMap().entries.map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => submit(e.value),
                    leading: Text(
                      '${e.key + 1}'.padLeft(2, '0'),
                      style: TextStyle(
                        color: e.key < 3 ? accent : muted,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    title: Text(e.value),
                    trailing: const Icon(
                      CupertinoIcons.arrow_up_left,
                      size: 14,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
